import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const DEV_BYPASS_SECRET = Deno.env.get("DEV_BYPASS_SECRET") || "";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  let body;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { phone, bypass_secret } = body;

  if (bypass_secret !== DEV_BYPASS_SECRET) {
    console.warn("[dev-bypass] Invalid bypass_secret");
    return new Response(JSON.stringify({ error: "Forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!phone || typeof phone !== "string" || phone.length < 5) {
    return new Response(JSON.stringify({ error: "Invalid phone" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  console.log("[dev-bypass] phone:", phone);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") || serviceRoleKey;

  const authHeaders = {
    "Authorization": `Bearer ${serviceRoleKey}`,
    "apikey": serviceRoleKey,
    "Content-Type": "application/json",
  };

  // Strip + for GoTrue internal storage
  const dbPhone = phone.replace(/^\+/, "");
  const tempPassword = crypto.randomUUID();

  // Step 1: Create or confirm user + set temporary password
  console.log("[dev-bypass] Creating/updating user...");
  const createRes = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
    method: "POST",
    headers: authHeaders,
    body: JSON.stringify({
      phone: phone,
      phone_confirm: true,
      password: tempPassword,
    }),
  });
  const createBody = await createRes.text();

  if (createRes.ok) {
    console.log("[dev-bypass] User created");
  } else {
    const errCode = JSON.parse(createBody).error_code;
    if (errCode === "phone_exists") {
      // Update existing user with temp password
      console.log("[dev-bypass] User exists — setting temp password...");
      const listRes = await fetch(`${supabaseUrl}/auth/v1/admin/users?phone=${encodeURIComponent(dbPhone)}`, {
        headers: authHeaders,
      });
      const listData = await listRes.json();
      const existing = listData.users?.find((u: Record<string, unknown>) =>
        u.phone === phone || u.phone === dbPhone
      );

      if (!existing) {
        return new Response(JSON.stringify({ error: "User not found" }), {
          status: 500,
          headers: { "Content-Type": "application/json" },
        });
      }

      await fetch(`${supabaseUrl}/auth/v1/admin/users/${existing.id}`, {
        method: "PUT",
        headers: authHeaders,
        body: JSON.stringify({
          phone_confirm: true,
          password: tempPassword,
        }),
      });
      console.log("[dev-bypass] Existing user updated");
    } else {
      console.error("[dev-bypass] Create error:", createRes.status, createBody);
      return new Response(JSON.stringify({ error: `Create failed: ${createRes.status}` }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
  }

  // Step 2: Sign in with temporary password using anon key
  console.log("[dev-bypass] Signing in...");
  const signInRes = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${anonKey}`,
      "apikey": anonKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      phone: phone,
      password: tempPassword,
    }),
  });
  const signInBody = await signInRes.text();
  console.log("[dev-bypass] Sign-in status:", signInRes.status);

  if (!signInRes.ok) {
    console.error("[dev-bypass] Sign-in error:", signInBody);
    return new Response(JSON.stringify({ error: `Sign-in failed: ${signInRes.status}` }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const sessionData = JSON.parse(signInBody);
  console.log("[dev-bypass] Session created for:", phone);

  return new Response(JSON.stringify({
    access_token: sessionData.access_token,
    refresh_token: sessionData.refresh_token,
    user: sessionData.user,
    password_exists: true,
  }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
