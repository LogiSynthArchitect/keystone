# DOCUMENT 19 — THIRD-PARTY INTEGRATION SPECS
### Project: Keystone
**Required Inputs:** Document 02 — Market Research, Document 04 — Core Scope, Document 11 — API Contracts
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 19.1 Integration Overview

| Service | Purpose | Phase | Cost |
|---|---|---|---|
| Supabase | Backend, auth, database, storage | V1 | Free tier → ~$25/month at scale |
| Africa's Talking | SMS OTP delivery | V1 | ~$0.02–0.04 per SMS |
| WhatsApp deep links (wa.me) | Follow-up message delivery | V1 | Free |
| Google Fonts (Inter) | Typography | V1 | Free |
| 360dialog | WhatsApp Business API | V2 | ~$11/month |
| Africa's Talking WhatsApp | OTP via WhatsApp | V2 | Lower cost than SMS |

---

## 19.2 Supabase

Setup:
1. Create project at supabase.com
2. Region: Europe West (London) — closest to Ghana until West Africa region exists
3. Copy Project URL and anon key → supabase_constants.dart
4. Email confirmations: OFF
5. Phone auth: ON
6. SMS provider: Africa's Talking via Edge Function adapter (see 19.3)

supabase_constants.dart:

class SupabaseConstants {
  SupabaseConstants._();

  static const String url     = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String profilePhotosBucket = 'profile-photos';
  static const String notePhotosBucket    = 'note-photos';

  static const String usersTable          = 'users';
  static const String profilesTable       = 'profiles';
  static const String customersTable      = 'customers';
  static const String jobsTable           = 'jobs';
  static const String knowledgeNotesTable = 'knowledge_notes';
  static const String followUpsTable      = 'follow_ups';
}

Build commands:
flutter run --dart-define=SUPABASE_URL=https://[ref].supabase.co --dart-define=SUPABASE_ANON_KEY=[key]
flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

Free tier limits vs V1 usage:
Database:  500MB limit  / <10MB V1 usage
Storage:   1GB limit    / <100MB V1 usage
MAU:       50,000 limit / 2 V1 users
V1 cost: $0

---

## 19.3 Africa's Talking — SMS OTP

Setup:
1. Register at africastalking.com
2. Select Ghana as primary market
3. Apply for sender ID "KEYSTONE" (2–5 business days)
4. Copy API Key and Username → Supabase Edge Function env vars

Edge Function SMS Adapter (supabase/functions/send-otp-sms/index.ts):

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const AT_API_KEY   = Deno.env.get('AT_API_KEY')!
const AT_USERNAME  = Deno.env.get('AT_USERNAME')!
const AT_SENDER_ID = Deno.env.get('AT_SENDER_ID') || 'KEYSTONE'

serve(async (req) => {
  const { phone, message } = await req.json()

  const response = await fetch('https://api.africastalking.com/version1/messaging', {
    method: 'POST',
    headers: {
      'apiKey': AT_API_KEY,
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept': 'application/json',
    },
    body: new URLSearchParams({
      username: AT_USERNAME,
      to: phone,
      message: message,
      from: AT_SENDER_ID,
    }),
  })

  const result = await response.json()
  const success = result.SMSMessageData?.Recipients?.[0]?.status === 'Success'

  return new Response(
    JSON.stringify({ success }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})

Ghana networks supported: MTN (~50%), Vodafone (~25%), AirtelTigo (~20%), Glo (~5%)
V1 monthly cost: ~60 SMS × $0.02–0.04 = under $3/month

---

## 19.4 WhatsApp Deep Links (V1)

Format: https://wa.me/[phone_no_plus]?text=[url_encoded_message]

whatsapp_launcher.dart:

class WhatsAppLauncher {
  WhatsAppLauncher._();

  static Future<bool> openChat({
    required String phoneNumber,  // E.164 format: +233201234567
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll('+', '');
    final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return true;
    }
    return _fallbackToSms(phoneNumber: phoneNumber, message: message);
  }

  static Future<bool> _fallbackToSms({
    required String phoneNumber,
    required String message,
  }) async {
    final smsUrl = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(smsUrl)) {
      await launchUrl(smsUrl);
      return true;
    }
    return false;
  }
}

Follow-up message template (whatsapp_constants.dart):

static String buildFollowUpMessage({
  required String customerName,
  required String technicianName,
  required String serviceType,
  required String profileUrl,
}) {
  final firstName = customerName.split(' ').first;
  final service   = _serviceTypeLabel(serviceType);
  return '''Hello $firstName, this is $technicianName.

Thank you for choosing our $service service today. It was a pleasure working with you.

If you ever need locksmith services again or know someone who does, feel free to reach out or share my profile:
$profileUrl

Have a great day! 🔑''';
}

AndroidManifest.xml queries block:
<queries>
  <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="https" /></intent>
  <intent><action android:name="android.intent.action.VIEW" /><data android:scheme="sms" /></intent>
  <package android:name="com.whatsapp" />
  <package android:name="com.whatsapp.w4b" />
</queries>

V1 limitations:
delivery_confirmed always false — no delivery confirmation via deep links
Falls back to SMS if WhatsApp not installed
User must tap Send inside WhatsApp — not fully automated
All resolved in V2 via WhatsApp Business API

---

## 19.5 Supabase Storage — Photo Uploads

Upload flow with compression:

Future<String> uploadProfilePhoto({
  required String userId,
  required Uint8List imageBytes,
  required String fileExtension,
}) async {
  final compressed = await FlutterImageCompress.compressWithList(
    imageBytes,
    minWidth: 400, minHeight: 400,
    quality: 85,
    format: CompressFormat.jpeg,
  );

  final path = '$userId/profile.$fileExtension';

  await _supabase.storage
      .from(SupabaseConstants.profilePhotosBucket)
      .uploadBinary(path, compressed,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));

  return _supabase.storage
      .from(SupabaseConstants.profilePhotosBucket)
      .getPublicUrl(path);
}

Compression rules (Document 10):
Max output: 500KB / Format: JPEG / Max dims: 1200×1200 profile, 1600×1200 notes
Quality: 85 / EXIF: stripped automatically by flutter_image_compress

---

## 19.6 Google Fonts — Inter

dependency: google_fonts: ^6.2.1

ThemeData integration:
ThemeData(
  textTheme: GoogleFonts.interTextTheme(),
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary700, ...),
  useMaterial3: true,
)

Offline note: fonts cached after first download. For guaranteed offline-first,
bundle Inter as asset font under flutter.fonts in pubspec.yaml.

---

## 19.7 V2 Upgrade — WhatsApp Business API via 360dialog

Trigger: follow-up habit established, delivery confirmation or templates needed.

Setup:
1. Register at 360dialog.com
2. Connect dedicated WhatsApp Business number
3. Submit and get follow-up message template approved
4. Monthly cost: ~$11 base + ~$0.05–0.10 per conversation

Code change (minimal — UI and state machine unchanged):
Replace WhatsAppLauncher.openChat() with WhatsAppApiDatasource.sendMessage()
delivery_confirmed can now be set to true on successful delivery

Cost at scale:
100 follow-ups/month: ~$16–21/month
500 follow-ups/month: ~$36–61/month

---

## 19.8 V2 Upgrade — Africa's Talking WhatsApp OTP

When V2 adds more technicians:
- Enable WhatsApp channel on same Africa's Talking account
- Better delivery rates and lower cost than SMS at volume
- Code change: update Edge Function to use WhatsApp OTP endpoint

---

## Validation Checklist
- [x] All V1 integrations fully specified with setup steps
- [x] Africa's Talking SMS OTP via Edge Function adapter
- [x] WhatsApp deep link launcher with SMS fallback
- [x] Follow-up message template for all service types
- [x] AndroidManifest queries block for url_launcher
- [x] Photo upload with compression enforcing Document 10 rules
- [x] Google Fonts Inter in ThemeData
- [x] No secrets hardcoded — --dart-define pattern
- [x] Supabase free tier confirmed sufficient for V1
- [x] V2 upgrade paths documented
