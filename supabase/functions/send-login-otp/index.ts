import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  let raw = "";
  let body: Record<string, unknown> = {};
  try {
    raw = await req.text();
    body = JSON.parse(raw);
  } catch {
    console.error("[send-login-otp] Failed to parse body");
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const phone = String(body.phone || (body.user as Record<string, unknown>)?.phone || "");
  const otp = String((body.token as Record<string, unknown>)?.otp || "");
  const message = otp
    ? `Your Keystone verification code is: ${otp}`
    : String(body.message || "");

  console.log("[KS-OTP] ======== HOOK CALLED ========");
  console.log("[KS-OTP] RAW:", raw.substring(0, 500));
  console.log("[KS-OTP] KEYS:", Object.keys(body).join(", "));
  console.log("[KS-OTP] phone:", phone);
  console.log("[KS-OTP] otp:", otp);
  console.log("[KS-OTP] message:", message);

  if (!phone || phone.length < 5) {
    console.error("[KS-OTP] Invalid phone:", phone);
    return new Response(JSON.stringify({ error: "Invalid phone" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!otp && !body.message) {
    console.error("[KS-OTP] No otp or message in payload");
  }

  const messageId = `ks-${phone}-${Date.now()}`;

  // Fire-and-forget AT send (best effort — always return 200 to Supabase)
  const atApiKey = Deno.env.get("AFRICASTALKING_API_KEY");
  const atUsername = Deno.env.get("AFRICASTALKING_USERNAME");

  if (!atApiKey || !atUsername) {
    console.warn("[KS-OTP] AT credentials missing — OTP will NOT be sent via SMS");
    console.log(`[KS-OTP] *** OTP for ${phone}: ${otp} ***`);
  } else {
    try {
      console.log("[KS-OTP] Sending via AT...");
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
            message: message,
          }),
        },
      );
      const atResult = await atResponse.text();
      console.log("[KS-OTP] AT status:", atResponse.status);
      console.log("[KS-OTP] AT body:", atResult);
    } catch (atError) {
      console.error("[KS-OTP] AT exception:", String(atError));
    }
  }

  console.log("[KS-OTP] Returning message_id:", messageId);
  return new Response(JSON.stringify({ message_id: messageId }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
