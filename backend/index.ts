import { Elysia, t } from "elysia";
import { createClient } from "@supabase/supabase-js";
import { cors } from "@elysiajs/cors";

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseRoleKey = process.env.SERVICEROLEKEY!;
// const jwtSecret = process.env.JWT_SECRET!;

// Supabase client
const supabase = createClient(supabaseUrl, supabaseRoleKey);

interface SupabaseUser {
  id: string;
  user_metadata?: {
    name?: string;
    contact?: string;
    details?: string;
    photo?: string;
    status?: string;
    start_date?: string;
    roles?: string[];
    [key: string]: any;
  };
  [key: string]: any;
}

const app = new Elysia();

//  Login
app
  .post(
    "/login",
    async ({ body }) => {
      const { email, password } = body;

      try {
        const { data, error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });

        if (error) {
          if (error.message === "Email not confirmed") {
            return {
              success: false,
              error: "Please confirm your email before logging in",
            };
          }
          console.error("Error logging in:", error);
          return { success: false, error: error.message, details: error };
        }

        console.log("User logged in:", data);
        return { success: true, user: data.user, session: data.session };
      } catch (err) {
        console.error("Unexpected error:", err);
        return { success: false, error: "Internal server error", details: err };
      }
    },
    {
      body: t.Object({
        email: t.String(),
        password: t.String(),
      }),
    }
  )

  // Create user
  .post(
    "/user",
    async ({ body, headers, set }) => {
      const {
        email,
        password,
        name,
        contact,
        photo,
        details,
        start_date,
        status,
        roles,
      } = body;

      // Get current user info from Authorization header
      const token = headers.authorization?.replace("Bearer ", "");
      const { data: userInfo, error: userInfoError } =
        await supabase.auth.getUser(token);

      if (userInfoError || !userInfo?.user) {
        set.status = 401;
        return { success: false, error: "Unauthorized" };
      }

      const currentUser = userInfo.user;
      const currentRoles = currentUser.user_metadata?.roles || [];
      const isAdmin = currentRoles.includes("admin");

      if (!isAdmin) {
        set.status = 403;
        return {
          success: false,
          error: "Only admins can create users with the role",
        };
      }

      try {
        // Create user
        const { data: createdUser, error } =
          await supabase.auth.admin.createUser({
            email,
            password,
            user_metadata: {
              name,
              contact,
              details,
              start_date,
              status,
              roles,
            },
            email_confirm: true,
          });

        if (error) {
          set.status = 400;
          return { success: false, error: error.message, details: error };
        }

        const userId = createdUser.user?.id;
        if (!userId) {
          set.status = 500;
          return { success: false, error: "User created but no ID returned" };
        }

        // Handle photo upload if provided
        let photoUrl = null;
        if (photo) {
          const photoPath = `client/${userId}/${Date.now()}.jpg`;
          const { error: uploadError } = await supabase.storage
            .from("avatars")
            .upload(photoPath, photo, {
              contentType: photo.type,
              upsert: true,
            });

          if (uploadError) {
            set.status = 500;
            return {
              success: false,
              error: "Failed to upload photo",
              details: uploadError.message,
            };
          }

          // Get the public URL of the uploaded photo
          photoUrl = supabase.storage.from("avatars").getPublicUrl(photoPath)
            .data.publicUrl;

          // Update user_metadata with photoUrl
          const { error: updateError } =
            await supabase.auth.admin.updateUserById(userId, {
              user_metadata: {
                name,
                contact,
                details,
                start_date,
                status,
                roles,
                photo: photoUrl,
              },
            });

          if (updateError) {
            set.status = 500;
            return {
              success: false,
              error: "Failed to update user metadata with photo URL",
              details: updateError.message,
            };
          }
        }

        // Insert into role-specific table
        const role = roles[0]; // Assuming a single role
        let insertResult;

        switch (role) {
          case "admin":
            insertResult = await supabase.from("admin").insert({
              id: userId,
              // name,
            });
            break;

          case "client":
            insertResult = await supabase.from("client").insert({
              id: userId,
              contact,
              details,
              photo: photoUrl,
              start_date,
            });
            break;

          default:
            set.status = 400;
            return {
              success: false,
              error: `Unknown role: ${role}`,
            };
        }

        if (insertResult.error) {
          set.status = 500;
          return {
            success: false,
            error: `User created, but failed to insert into ${role} table`,
            details: insertResult.error.message,
          };
        }

        return {
          success: true,
          user: {
            id: userId,
            email,
            user_metadata: {
              name,
              contact,
              details,
              photo: photoUrl,
              start_date,
              status,
              roles,
            },
          },
          message: `User created, confirmed, and inserted into ${role} table`,
        };
      } catch (err) {
        console.error("Error creating user:", err);
        set.status = 500;
        return {
          success: false,
          error: "Internal server error",
          details: err instanceof Error ? err.message : JSON.stringify(err),
        };
      }
    },
    {
      body: t.Object({
        email: t.String(),
        password: t.String(),
        name: t.String(),
        status: t.String(),
        contact: t.Nullable(t.String()),
        details: t.Nullable(t.String()),
        start_date: t.String(),
        photo: t.Optional(t.File()),
        roles: t.Array(t.String()),
      }),
    }
  );

app.listen(3000, () => {
  console.log("✅ Server running on http://localhost:3000");
});
