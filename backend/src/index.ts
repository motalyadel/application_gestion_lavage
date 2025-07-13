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

  app.listen(3000, () => {
    console.log("✅ Server running on http://localhost:3000");
  });



