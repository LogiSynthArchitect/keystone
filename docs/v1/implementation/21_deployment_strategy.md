# DOCUMENT 21 — DEPLOYMENT STRATEGY
### Project: Keystone
**Required Inputs:** Document 04 — Core Scope, Document 12 — Database Schema, Document 19 — Integrations
**Platform:** Android only (V1)
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 21.1 Environments

| | Development | Production |
|---|---|---|
| Supabase project | keystone-dev | keystone-prod |
| App ID | com.keystone.app.dev | com.keystone.app |
| App name | Keystone (Dev) | Keystone |
| Database | Dev schema — can be wiped | Prod schema — never wiped |
| OTP SMS | Sandbox (free, no real SMS) | Live (real SMS, costs money) |

Environment constant:
static const AppEnvironment environment = AppEnvironment.values.byName(
  String.fromEnvironment('APP_ENV', defaultValue: 'development'),
);

---

## 21.2 Android Configuration

namespace:        com.keystone.app
compileSdkVersion: 34
minSdkVersion:    21    # Android 5.0 — covers 99%+ of Ghana devices
targetSdkVersion: 34
versionCode:      1     # increment by 1 per Play Store release
versionName:      1.0.0 # semantic version shown to users

Flavors:
dev:  applicationIdSuffix ".dev" / versionNameSuffix "-dev" / app_name "Keystone (Dev)"
prod: app_name "Keystone"

---

## 21.3 Signing Configuration

Generate keystore (one-time):
keytool -genkey -v -keystore keystone-release.jks -alias keystone -keyalg RSA -keysize 2048 -validity 10000

WARNING: losing keystone-release.jks means you can never update the app on Play Store.
Backup: encrypted copy in password manager + offline USB drive.

key.properties (NEVER commit — add to .gitignore):
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=keystone
storeFile=../keystone-release.jks

build.gradle: load key.properties → signingConfigs.release → buildTypes.release
minifyEnabled true / shrinkResources true for release builds

.gitignore additions:
*.jks
*.keystore
key.properties
.env
*.env

---

## 21.4 Build Commands

Development (dev flavor):
flutter run --flavor dev --dart-define=APP_ENV=development \
  --dart-define=SUPABASE_URL=$DEV_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$DEV_SUPABASE_ANON_KEY

Debug APK for testing:
flutter build apk --flavor dev --debug \
  --dart-define=APP_ENV=development \
  --dart-define=SUPABASE_URL=$DEV_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$DEV_SUPABASE_ANON_KEY

Production APK (direct install):
flutter build apk --flavor prod --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=$PROD_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$PROD_SUPABASE_ANON_KEY \
  --dart-define=APP_NAME="Keystone"
Output: build/app/outputs/flutter-apk/app-prod-release.apk

App Bundle (Play Store V2):
flutter build appbundle --flavor prod --release \
  --dart-define=APP_ENV=production \
  --dart-define=SUPABASE_URL=$PROD_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$PROD_SUPABASE_ANON_KEY
Output: build/app/outputs/bundle/prodRelease/app-prod-release.aab

---

## 21.5 Web Deployment — Vercel (Public Profile Gateway)

**Host:** Vercel (keystone-inky-five.vercel.app)
**Entry point:** `lib/main_web.dart` (lightweight — no Hive, no mobile plugins)
**Build file:** `scripts/vercel_build.sh`

### How it works
Vercel has no Flutter installed. The build script installs it at build time:
1. `git clone --depth 1 -b stable https://github.com/flutter/flutter.git /tmp/flutter`
2. `export PATH="$PATH:/tmp/flutter/bin"`
3. `flutter precache --web`
4. `flutter pub get`
5. `flutter build web --release`

Output directory: `build/web` (set in `vercel.json` as `outputDirectory`)

### Build trigger
Automatic on every push to `main` via Vercel's GitHub integration.
`vercel.json` contains `buildCommand: "bash scripts/vercel_build.sh"`.

### Renderer
Flutter 3.22+ removed the `--web-renderer` flag. Default is now **skwasm** (WebAssembly-based).
Do NOT pass `--web-renderer` — it will error with exit 64.

### Caching rules (vercel.json)
- `index.html` → `no-cache` (always fetched fresh)
- `flutter_service_worker.js` → `no-cache` (must be fresh to deliver updates to users)
- All other JS/WASM/assets → `max-age=31536000, immutable` (content-hashed, safe to cache forever)

### GitHub Actions fallback
`.github/workflows/deploy.yml` scaffolded as an alternative CI/CD path.
Requires GitHub secrets: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`.
Not currently active — Vercel native build is the primary pipeline.

---

## 21.6 V1 Distribution — Direct APK Install

Method: send APK via WhatsApp or USB to Jeremie and Jean

Steps:
1. Build production release APK
2. Send via WhatsApp to both phones
3. On device: Settings → Security → Unknown Sources → Enable
   Android 8.0+: Settings → Apps → Special app access → Install unknown apps → allow WhatsApp/Files
4. Open APK → Install
5. Updates: repeat with new APK

Advantage: instant, no Play Store review delay
V2: migrate to Play Store for automatic updates

---

## 21.7 Supabase Production Setup Sequence

1. Create production project at supabase.com
2. Run Document 12 schema in SQL editor (follow execution order in 12.8)
3. Verify RLS policies are active on all 6 tables
4. Create storage buckets: profile-photos, note-photos (both public)
5. Configure Africa's Talking live credentials in Edge Function env vars
6. Deploy OTP Edge Function
7. Test OTP with a real Ghana phone number
8. After Jeremie and Jean first log in — upgrade roles:

UPDATE users
SET role = 'founding_technician', status = 'active'
WHERE phone_number IN ('+233[jeremie_number]', '+233[jean_number]');

---

## 21.8 Play Store Setup (V2 preparation)

Developer account: $25 one-time fee
Required assets:
  App icon:        512×512 PNG no alpha
  Feature graphic: 1024×500 PNG
  Screenshots:     min 2, max 8 — 1080×1920
  Short desc:      80 chars max
  Full desc:       4000 chars max

Short: "Keystone — Job management for professional locksmiths in Ghana"
Category: Business / Price: Free

---

## 21.9 Pre-Release Checklist

Code:
[ ] flutter test — all passing
[ ] flutter analyze — no issues
[ ] versionCode incremented
[ ] versionName updated

Supabase:
[ ] Schema matches Document 12
[ ] RLS enabled on all tables
[ ] Storage buckets created and public
[ ] Edge Function deployed and tested
[ ] Africa's Talking live credentials active

Build:
[ ] Built with --flavor prod --release
[ ] Signed with release keystore
[ ] Dart defines point to production Supabase
[ ] APK tested on physical Android device

Data:
[ ] Jeremie role = founding_technician, status = active
[ ] Jean role = founding_technician, status = active
[ ] Both completed onboarding

Smoke test (physical device):
[ ] OTP login with real Ghana number
[ ] Log a job — saves and syncs
[ ] WhatsApp follow-up opens with correct message
[ ] Customer history shows logged job
[ ] Knowledge note saves and is searchable
[ ] Profile link opens public profile in browser
[ ] Log job offline — appears in list
[ ] Go online — job syncs

---

## 21.10 Version Naming

MAJOR.MINOR.PATCH
1.0.0 → versionCode 1  — initial release
1.0.1 → versionCode 2  — first bug fix
1.1.0 → versionCode 3  — first feature addition
2.0.0 → versionCode N  — V2 launch

MAJOR: phase milestone / MINOR: new features / PATCH: bug fixes

---

## Validation Checklist
- [x] Dev and prod environments fully separated
- [x] Android flavor configuration
- [x] Signing configuration with keystore backup warning
- [x] .gitignore rules for all secrets
- [x] Build commands for all scenarios
- [x] V1 direct APK distribution steps
- [x] Supabase production setup sequence
- [x] Founding technician role upgrade SQL
- [x] Play Store assets for V2
- [x] Pre-release checklist with smoke tests for all 5 features
