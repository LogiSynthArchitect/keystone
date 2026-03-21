# Keystone — Job Management for Locksmiths

A production Flutter app for independent locksmith technicians in Accra, Ghana. Handles job logging, customer tracking, WhatsApp follow-ups, and public profile links with offline-first sync.

**Status:** V1 in production pilot with 2 real users in the field.

---

## Features

- **Job Logging** — Log service calls, location, amount charged. Works offline; syncs when online.
- **Customer History** — Automatic deduplication by phone. Track all jobs per customer.
- **Knowledge Base** — Personal notes on techniques, tagged and searchable. Syncs to device.
- **WhatsApp Follow-up** — One-tap follow-up messages with job details.
- **Public Profile** — Light-themed web profile link to share with customers (`keystone-inky-five.vercel.app/p/your-slug`).
- **Offline-First** — Full app functionality without internet. Automatic sync when connection returns.
- **Admin Corrections** — Users can request corrections to locked jobs; admins review and apply.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3.22+ (mobile + web) |
| **State** | Riverpod (FutureProvider, StateNotifier) |
| **Backend** | Supabase (PostgreSQL + RLS + RPC) |
| **Local Storage** | Hive (offline cache) |
| **Hosting** | Vercel (web), direct APK (mobile) |
| **CI/CD** | GitHub Actions (scheduled builds) / Vercel (web builds) |

---

## Project Structure

```
lib/
  core/              # Shared utilities, theme, constants
  features/          # Domain-driven features (6 total)
    job_logging/
    customer_history/
    knowledge_base/
    whatsapp_followup/
    technician_profile/
    auth/
  main.dart          # Mobile entry point
  main_web.dart      # Web entry point (public profile only)

docs/
  v1/                # V1 specification, architecture, lessons
    systems/         # Architecture decisions
    implementation/  # Tech specs, design system
    models/          # Domain model, database schema
    problem/         # Problem statement, market research
    testing/         # Testing strategy
  patterns.md        # 37 reusable patterns from this project

scripts/
  vercel_build.sh    # Web build automation
```

---

## Getting Started

### Prerequisites
- Flutter 3.3.0+ (stable channel)
- Dart 3.0+
- Android SDK 21+ / Xcode 14+ (for mobile)

### Local Development

```bash
# Install dependencies
flutter pub get

# Run on Android
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Web Profile (Vercel)

The lightweight web app (`lib/main_web.dart`) serves only the public profile page at `/p/:slug`.

Build locally:
```bash
flutter build web --target lib/main_web.dart --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

### Production APK

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-supabase.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Architecture Highlights

### Offline-First Sync
Jobs and notes are written to Hive immediately, then synced to Supabase via RPC. Status field tracks: `pending` (not synced), `synced` (confirmed), `failed` (rejected by server).

### Clean Architecture
- **Domain:** Use cases, entities, repositories (interfaces)
- **Data:** Datasources (local + remote), repositories (impl), models
- **Presentation:** Screens, providers, widgets

### Environment Separation
- **Staging:** Default for local development
- **Production:** Restricted access, requires explicit environment flag

This separation prevents accidental production changes. Any change to production data requires an intentional, documented action.

---

## Key Decisions & Lessons Learned

See `docs/patterns.md` for 37 reusable patterns on:
- Offline-first sync conflict resolution
- Flutter web performance optimization
- Service worker caching strategies
- Null-safe auth checks
- And more — directly applicable to other projects

---

## Database Schema

6 core tables with RLS (Row-Level Security):
- `users` — auth + roles (technician, founding_technician, admin)
- `profiles` — public profiles with services, contact info
- `jobs` — work logs, location, amount, sync status
- `customers` — contact info, deduplication by phone
- `knowledge_notes` — personal notes, searchable
- `follow_ups` — WhatsApp message history
- `correction_requests` — requests to fix locked jobs
- `app_events` — event logging (scaffolded, not active)

All writes enforce RLS policies. Sensitive data is never exposed client-side.

---

## Testing

- **Unit tests:** 36 passing (formatters, use cases)
- **Integration tests:** Scaffolded, can hit real Supabase
- **E2E tests:** Manual on-device testing with pilot users

```bash
flutter test
```

---

## Deployment

**Mobile:** APK builds can be run locally with credentials via `--dart-define`. V2 will publish to Google Play Store.

**Web:** Public profile deployed on Vercel. Updates automatically on code push.

See `docs/v1/implementation/21_deployment_strategy.md` for technical details.

---

## What's Next (V2 Roadmap)

- **Google Play Store** — Wider distribution for Android users
- **SMS OTP** — Secure verification for new users
- **Analytics** — Track feature usage and growth insights
- **Admin Dashboard** — Role management and job oversight UI
- **Multi-language** — Support for local languages beyond English

See `PUBLIC_ROADMAP.md` for the full V2 vision.

---

## Documentation

Complete V1 specification in `docs/v1/`:
- **Systems:** Architecture, navigation, state machines
- **Implementation:** Deployment, design system, component inventory
- **Models:** Domain model, database schema, API contracts, validation rules
- **Problem:** Market research, user personas, core hypothesis

Start with `docs/v1/00_master_index.md`.

---

## Contributing

See `CONTRIBUTING.md` for full guidelines. Quick summary:
1. Read `docs/patterns.md` before making changes
2. Follow clean architecture (domain / data / presentation)
3. Run `flutter analyze` and `flutter test` before committing
4. Docs must be updated alongside code

---

## License

MIT License — See LICENSE file for details.

---

## Author

Built by LogiSynthArchitect for locksmiths in Accra, Ghana.

**Pilot Users:** 2 active technicians logging jobs daily in the field.

**Status:** V1 actively maintained. V2 in development (Play Store launch planned).

---

## Links

- **Live Web Profile:** https://keystone-inky-five.vercel.app
- **GitHub:** https://github.com/LogiSynthArchitect/keystone
- **LinkedIn:** Follow the build journey on LinkedIn

---

## Questions or Issues?

Open an issue on GitHub. For architecture questions, start with `docs/v1/systems/` and `docs/patterns.md`.
