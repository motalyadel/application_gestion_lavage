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
  )

  .post(
    "/register-public",
    async ({ body, set }) => {
      const {
        name,
        email,
        password,
        contact,
        start_date,
        status,
        details,
        photo,
      } = body;

      try {
        // Create user
        const { data: createdUser, error } =
          await supabase.auth.admin.createUser({
            email,
            password,
            email_confirm: true,
            user_metadata: { name, roles: ["client"], status },
          });

        if (error || !createdUser?.user?.id) {
          set.status = 400;
          return {
            success: false,
            error: error?.message ?? "Failed to create user",
          };
        }

        const userId = createdUser.user.id;

        // Handle photo upload if provided
        let photoUrl = photo || null;
        if (photo && typeof photo !== "string") {
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

          photoUrl = supabase.storage.from("avatars").getPublicUrl(photoPath)
            .data.publicUrl;
        }

        // Insert into client table
        const insert = await supabase.from("client").insert({
          id: userId,
          contact,
          details,
          photo: photoUrl,
          start_date,
        });

        if (insert.error) {
          set.status = 500;
          return { success: false, error: insert.error.message };
        }

        // Update user metadata with photo URL
        if (photoUrl) {
          await supabase.auth.admin.updateUserById(userId, {
            user_metadata: { name, roles: ["client"], status, photo: photoUrl },
          });
        }

        return { success: true, user_id: userId };
      } catch (e) {
        console.error("Error in register-public:", e);
        set.status = 500;
        return { success: false, error: "Internal server error" };
      }
    },
    {
      // beforeHandle: isAdmin,
      body: t.Object({
        name: t.String(),
        email: t.String(),
        password: t.String(),
        contact: t.String(),
        start_date: t.String(),
        status: t.Optional(t.String()),
        details: t.Optional(t.String()),
        photo: t.Optional(t.Union([t.File(), t.String()])),
      }),
    }
  )

  .post(
    "/update-client",
    async ({ body, set }) => {
      const { id, name, status, contact, details, photo, start_date } = body;

      try {
        // Update user metadata using admin API
        const metadata = {
          name: name || undefined,
          roles: ["client"],
          status: status || "active",
          ...(photo && { photo }), // Only include photo if provided
        };
        const { data: updatedUser, error: userError } =
          await supabase.auth.admin.updateUserById(id, {
            user_metadata: metadata, // Pass metadata as an object
          });

        if (userError) {
          set.status = 400;
          return { success: false, error: userError.message };
        }
        console.log(`Updated user metadata for ID: ${id}`);

        // Handle photo (string URL or file)
        let photoUrl = typeof photo === "string" ? photo : null;
        if (photo && typeof photo !== "string") {
          const photoPath = `client/${id}/${Date.now()}.jpg`;
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

          photoUrl = supabase.storage.from("avatars").getPublicUrl(photoPath)
            .data.publicUrl;
          console.log(`Uploaded photo: ${photoUrl}`);

          // Update metadata with new photo URL
          await supabase.auth.admin.updateUserById(id, {
            user_metadata: { ...metadata, photo: photoUrl },
          });
        }

        // Update client table
        const updateData = {
          ...(contact !== undefined && { contact }),
          ...(details !== undefined && { details }),
          ...(photoUrl !== null && { photo: photoUrl }),
          ...(start_date !== undefined && { start_date }),
        };

        if (Object.keys(updateData).length > 0) {
          const { error: clientError } = await supabase
            .from("client")
            .update(updateData)
            .eq("id", id);

          if (clientError) {
            set.status = 500;
            return { success: false, error: clientError.message };
          }
          console.log("Updated client table");
        }

        // Update users table (only name and status if provided)
        const userUpdateData = {
          ...(name !== undefined && { name }),
          ...(status !== undefined && { status }),
        };

        if (Object.keys(userUpdateData).length > 0) {
          const { error: usersError } = await supabase
            .from("users")
            .update(userUpdateData)
            .eq("id", id);

          if (usersError) {
            set.status = 500;
            return {
              success: false,
              error: "Failed to update users table",
              details: usersError.message,
            };
          }
          console.log("Updated users table");
        }

        return { success: true, user_id: id };
      } catch (e) {
        console.error("Error in update-client:", e);
        set.status = 500;
        return {
          success: false,
          error: "Internal server error",
          details: "ERROR",
        };
      }
    },
    {
      body: t.Object({
        id: t.String(),
        name: t.Optional(t.String()),
        status: t.Optional(t.String()),
        contact: t.Optional(t.String()),
        details: t.Optional(t.String()),
        photo: t.Optional(t.Union([t.File(), t.String()])),
        start_date: t.Optional(t.String()),
      }),
    }
  )
  .post(
    "/delete-client",
    async ({ body, set }) => {
      const { id } = body;

      try {
        // Delete from user_roles table first (to avoid foreign key constraints)
        const { error: roleError } = await supabase
          .from("user_roles")
          .delete()
          .eq("user_id", id);

        if (roleError) {
          set.status = 500;
          return {
            success: false,
            error: "Failed to delete from user_roles",
            details: roleError.message,
          };
        }
        console.log("Deleted from user_roles");

        // Delete from client table
        const { error: clientError } = await supabase
          .from("client")
          .delete()
          .eq("id", id);

        if (clientError) {
          set.status = 500;
          return {
            success: false,
            error: "Failed to delete from client table",
            details: clientError.message,
          };
        }
        console.log("Deleted from client table");

        // Delete from users table
        const { error: usersError } = await supabase
          .from("users")
          .delete()
          .eq("id", id);

        if (usersError) {
          set.status = 500;
          return {
            success: false,
            error: "Failed to delete from users table",
            details: usersError.message,
          };
        }
        console.log("Deleted from users table");

        // Delete from auth.users
        const { error: userError } = await supabase.auth.admin.deleteUser(id);

        if (userError) {
          set.status = 500;
          return {
            success: false,
            error: "Failed to delete auth user",
            details: userError.message,
          };
        }
        console.log("Deleted from auth.users");

        return { success: true, user_id: id };
      } catch (e) {
        console.error("Error in delete-client:", e);
        set.status = 500;
        return { success: false, error: "Internal server error", details: e };
      }
    },
    {
      body: t.Object({
        id: t.String(),
      }),
    }
  )

  //   // Update client (admin only)
  // .post(
  //   "/update-client",
  //   async ({ body, set }) => {
  //     const { id, name, status, contact, details, photo, start_date } = body;

  //     try {
  //       // Update user metadata
  //       const { data: updatedUser, error: userError } = await supabase.auth.admin.updateUserById(id, {
  //         user_metadata: { name, roles: ["client"], status },
  //       });

  //       if (userError) {
  //         set.status = 400;
  //         return { success: false, error: userError.message };
  //       }

  //       // Handle photo upload if provided
  //       let photoUrl = photo || null;
  //       if (photo && typeof photo !== 'string') {
  //         const photoPath = `client/${id}/${Date.now()}.jpg`;
  //         const { error: uploadError } = await supabase.storage
  //           .from("avatars")
  //           .upload(photoPath, photo, {
  //             contentType: photo.type,
  //             upsert: true,
  //           });

  //         if (uploadError) {
  //           set.status = 500;
  //           return { success: false, error: "Failed to upload photo", details: uploadError.message };
  //         }

  //         photoUrl = supabase.storage.from("avatars").getPublicUrl(photoPath).data.publicUrl;
  //       }

  //       // Update client table
  //       const { error: clientError } = await supabase
  //         .from("cleint")
  //         .update({
  //           contact,
  //           details,
  //           photo: photoUrl,
  //           start_date,
  //         })
  //         .eq('id', id);

  //       if (clientError) {
  //         set.status = 500;
  //         return { success: false, error: clientError.message };
  //       }

  //       // Update user metadata with photo URL if changed
  //       if (photoUrl) {
  //         await supabase.auth.admin.updateUserById(id, {
  //           user_metadata: { name, roles: ["client"], status, photo: photoUrl },
  //         });
  //       }

  //       return { success: true, user_id: id };
  //     } catch (e) {
  //       console.error("Error in update-client:", e);
  //       set.status = 500;
  //       return { success: false, error: "Internal server error"};
  //     }
  //   },
  //   {
  //     // beforeHandle: isAdmin,
  //     body: t.Object({
  //       id: t.String(),
  //       name: t.Optional(t.String()),
  //       status: t.Optional(t.String()),
  //       contact: t.Optional(t.String()),
  //       details: t.Optional(t.String()),
  //       photo: t.Optional(t.Union([t.File(), t.String()])),
  //       start_date: t.Optional(t.String()),
  //     }),
  //   }

  // );

  .post(
    "/car",
    async ({ body, headers, set }) => {
      const { client_id, marque, modele, immatriculation } = body;
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
      // Check authorization: admins can add for any client, users can only add for themselves
      if (!isAdmin && client_id !== currentUser.id) {
        set.status = 403;
        return {
          success: false,
          error: "You can only add cars for your own account",
        };
      }
      try {
        const data = {
          client_id: client_id,
          marque: marque?.trim(),
          modele: modele?.trim(),
          immatriculation: immatriculation.trim(),
          updated_at: new Date().toISOString(),
        };
        const { data: createdCar, error } = await supabase
          .from("cars")
          .insert(data)
          .select()
          .single();
        if (error) {
          set.status = 400;
          return { success: false, error: error.message, details: error };
        }
        return {
          success: true,
          car: createdCar,
          message: "Car added successfully",
        };
      } catch (err) {
        console.error("Error adding car:", err);
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
        client_id: t.String(),
        marque: t.Optional(t.String()),
        modele: t.Optional(t.String()),
        immatriculation: t.String(),
      }),
    }
  );

// app.post(
//   "/delete-car",
//   async ({ body, set }) => {
//     const { id } = body;
//     try {
//       // Delete from cars table
//       const { error: carError } = await supabase
//         .from("cars")
//         .delete()
//         .eq("id", id);

//       if (carError) {
//         set.status = 500;
//         return {
//           success: false,
//           error: "Failed to delete from cars table",
//           details: carError.message,
//         };
//       }

//       console.log(`Deleted car with id: ${id}`);

//       return { success: true, car_id: id };
//     } catch (e) {
//       console.error("Error in delete-car:", e);
//       set.status = 500;
//       return { success: false, error: "Internal server error", details: e };
//     }
//   },
//   {
//     body: t.Object({
//       id: t.String(),
//     }),
//   }
// );

// DELETE /cars/:id - Delete car
app.post(
  "/delete-car",
  async ({ body, set }) => {
    const { id } = body;

    try {
      // Check if car exists
      const { data: car, error: carError } = await supabase
        .from("cars")
        .select("id, user_id")
        .eq("id", id)
        .single();

      if (carError || !car) {
        console.error("Car fetch error:", carError?.message || "No car found");
        set.status = 404;
        return {
          success: false,
          error: "Car not found",
          details: carError?.message,
        };
      }
      console.log("Car found:", car);

      // Delete from cars table
      const { error: deleteError } = await supabase
        .from("cars")
        .delete()
        .eq("id", id);

      if (deleteError) {
        console.error("Delete car error:", deleteError.message);
        set.status = 500;
        return {
          success: false,
          error: "Failed to delete from cars table",
          details: deleteError.message,
        };
      }
      console.log("Deleted from cars table");

      // Optional: Check if user_id has other cars before deleting from user_roles
      const { count, error: countError } = await supabase
        .from("cars")
        .select("id", { count: "exact", head: true })
        .eq("user_id", car.user_id);

      if (countError) {
        console.error("Count cars error:", countError.message);
      }

      if (!countError && count === 0) {
        // No other cars for this user, proceed to delete user-related data

        // Delete from user_roles
        const { error: roleError } = await supabase
          .from("user_roles")
          .delete()
          .eq("user_id", car.user_id);

        if (roleError) {
          console.error("Delete user_roles error:", roleError.message);
          set.status = 500;
          return {
            success: false,
            error: "Failed to delete from user_roles",
            details: roleError.message,
          };
        }
        console.log("Deleted from user_roles");

        // NEW: Delete from profile tables (admin and client) to avoid FK violations
        // These will do nothing if no rows exist
        const { error: adminError } = await supabase
          .from("admin")
          .delete()
          .eq("id", car.user_id);

        if (adminError) {
          console.error("Delete admin error:", adminError.message);
          set.status = 500;
          return {
            success: false,
            error: "Failed to delete from admin table",
            details: adminError.message,
          };
        }
        console.log("Deleted from admin table (if existed)");

        const { error: clientError } = await supabase
          .from("client")
          .delete()
          .eq("id", car.user_id);

        if (clientError) {
          console.error("Delete client error:", clientError.message);
          set.status = 500;
          return {
            success: false,
            error: "Failed to delete from client table",
            details: clientError.message,
          };
        }
        console.log("Deleted from client table (if existed)");

        // Now safe to delete from users table
        const { error: usersError } = await supabase
          .from("users")
          .delete()
          .eq("id", car.user_id);

        if (usersError) {
          console.error("Delete users error:", usersError.message);
          set.status = 500;
          return {
            success: false,
            error: "Failed to delete from users table",
            details: usersError.message,
          };
        }
        console.log("Deleted from users table");

        // Delete from auth.users
        const { error: userError } = await supabase.auth.admin.deleteUser(
          car.user_id
        );

        if (userError) {
          console.error("Delete auth user error:", userError.message);
          set.status = 500;
          return {
            success: false,
            error: "Failed to delete auth user",
            details: userError.message,
          };
        }
        console.log("Deleted from auth.users");
      }

      return { success: true, car_id: id };
    } catch (e) {
      console.error("Error in delete-car:", e);
      set.status = 500;
      return { success: false, error: "Internal server error", details: e };
    }
  },
  {
    body: t.Object({
      id: t.String(),
    }),
  }
);

app.post(
  "/service",
  async ({ body, headers, set }) => {
    const { name, description, price, duration } = body;

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

    // Check authorization: only admins can add services
    if (!isAdmin) {
      set.status = 403;
      return {
        success: false,
        error: "Only admins can add services",
      };
    }

    try {
      // Handle price and duration as string or number
      const parsedPrice =
        typeof price === "string" ? parseInt(price, 10) : price;
      const parsedDuration =
        typeof duration === "string" ? parseInt(duration, 10) : duration;

      const data = {
        name: name.trim(),
        description: description?.trim(),
        price: parsedPrice,
        duration: parsedDuration,
        created_at: new Date().toISOString(),
      };

      // Validate required fields
      if (
        !data.name ||
        isNaN(data.price) ||
        data.price < 0 ||
        isNaN(data.duration) ||
        data.duration < 0
      ) {
        set.status = 400;
        return {
          success: false,
          error:
            "Invalid input: name is required, price and duration must be non-negative integers",
        };
      }

      const { data: createdService, error } = await supabase
        .from("services")
        .insert(data)
        .select()
        .single();

      if (error) {
        console.error("Error adding service:", error);
        set.status = 400;
        return { success: false, error: error.message, details: error };
      }

      return {
        success: true,
        service: createdService,
        message: "Service added successfully (price in MRU)",
      };
    } catch (err) {
      console.error("Error adding service:", err);
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
      name: t.String(),
      description: t.Optional(t.String()),
      price: t.Union([t.Number(), t.String()]), // Allow string or number
      duration: t.Union([t.Number(), t.String()]), // Allow string or number
    }),
  }
);

app.listen(3000, () => {
  console.log("✅ Server running on http://localhost:3000");
});
