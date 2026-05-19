import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MONTHLY_LIMIT = 2;

interface RequestBody {
  phone: string;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { phone } = (await req.json()) as RequestBody;

    if (!phone || phone.length < 9) {
      return new Response(JSON.stringify({ error: "Invalid phone number" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // ── MONTHLY LIMIT CHECK ────────────────────────────────────────────
    const now = new Date();
    const firstOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString();

    const { count, error: countError } = await supabase
      .from("password_reset_codes")
      .select("*", { count: "exact", head: true })
      .eq("phone", phone)
      .gte("created_at", firstOfMonth);

    if (countError) {
      console.error("Count query error:", countError);
      return new Response(JSON.stringify({ error: "Failed to verify limit" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (count != null && count >= MONTHLY_LIMIT) {
      return new Response(
        JSON.stringify({
          error: `Monthly recovery limit reached (${count}/${MONTHLY_LIMIT}). Try again next month.`,
        }),
        { status: 429, headers: { "Content-Type": "application/json" } },
      );
    }

    // ── GENERATE + STORE CODE ──────────────────────────────────────────
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

    const { error: dbError } = await supabase
      .from("password_reset_codes")
      .insert({ phone, code, expires_at: expiresAt });

    if (dbError) {
      console.error("DB insert error:", dbError);
      return new Response(JSON.stringify({ error: "Failed to store code" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // ── SEND VIA AFRICA'S TALKING ──────────────────────────────────────
    const atApiKey = Deno.env.get("AFRICASTALKING_API_KEY");
    const atUsername = Deno.env.get("AFRICASTALKING_USERNAME");

    if (atApiKey && atUsername) {
      const atResponse = await fetch(
        "https://api.africastalking.com/version1/messaging",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "ApiKey": atApiKey,
            "Accept": "application/json",
          },
          body: new URLSearchParams({
            username: atUsername,
            to: phone,
            message: `Keystone recovery code: ${code}. Valid for 5 minutes.`,
          }),
        },
      );

      if (!atResponse.ok) {
        console.error("AT SMS send error:", await atResponse.text());
      }
    } else {
      console.log(
        `[MOCK] Recovery code for ${phone}: ${code} (expires ${expiresAt})`,
      );
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("send-password-reset error:", error);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
