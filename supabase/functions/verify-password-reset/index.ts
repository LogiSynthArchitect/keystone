import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface RequestBody {
  phone: string;
  code: string;
  newPassword: string;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { phone, code, newPassword } = (await req.json()) as RequestBody;

    if (!phone || phone.length < 9 || !code || code.length !== 6 || !newPassword || newPassword.length < 8) {
      return new Response(JSON.stringify({ error: "Invalid request" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Verify the code against password_reset_codes table
    const { data: resetRow, error: lookupError } = await supabase
      .from("password_reset_codes")
      .select("id")
      .eq("phone", phone)
      .eq("code", code)
      .eq("used", false)
      .gte("expires_at", new Date().toISOString())
      .maybeSingle();

    if (lookupError) {
      console.error("Lookup error:", lookupError);
      return new Response(JSON.stringify({ error: "Verification failed" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!resetRow) {
      return new Response(JSON.stringify({ error: "Invalid or expired code" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Mark the code as used
    const { error: updateError } = await supabase
      .from("password_reset_codes")
      .update({ used: true })
      .eq("id", resetRow.id);

    if (updateError) {
      console.error("Mark used error:", updateError);
    }

    // 3. Look up the user's auth_id from public.users table
    const { data: userRow, error: userError } = await supabase
      .from("users")
      .select("auth_id")
      .eq("phone_number", phone)
      .maybeSingle();

    if (userError || !userRow?.auth_id) {
      console.error("User lookup error:", userError);
      return new Response(JSON.stringify({ error: "User not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Update password via Admin API (bypasses session requirement)
    const { error: authError } = await supabase.auth.admin.updateUserById(
      userRow.auth_id,
      { password: newPassword },
    );

    if (authError) {
      console.error("Admin update error:", authError);
      return new Response(JSON.stringify({ error: "Password update failed" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("verify-password-reset error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
