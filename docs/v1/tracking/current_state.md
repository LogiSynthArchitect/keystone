# CURRENT STATE — KEYSTONE V1
### Last Updated: March 20 2026
### Session: 30 (WEB PERFORMANCE, CI/CD PIPELINE & LANGUAGE POLISH)

---

## Build Status
- **flutter analyze:** 0 errors, 0 warnings ✅
- **flutter test:** 80+ tests passing, zero failures ✅
- **Supabase:** All migrations and resilient RPC fixes applied to Staging & Production. ✅
- **Web Build:** Profile web gateway live on Vercel (keystone-inky-five.vercel.app). ✅
- **UI Aesthetic:** Full light/dark mode migration complete. Light palette active across all screens. ✅
- **Web Redesign:** Public profile and gateway pages fully redesigned with light theme. ✅
- **Keystone Logo:** Actual SVG logo (SvgPicture.asset) used in all web top bars, footer, and loading screen. ✅
- **Language Audit:** All technical jargon removed from web-facing pages. No "terminal", "portal", "technician", "professional locksmith tools". ✅

---

## Core Feature Completion (All 100%)
- **Tactical Terminal:** Language simplified for human-friendly field use. ✅
- **Environment Sanctity:** Hardened Staging/Prod separation in GEMINI.md. ✅
- **Offline Backbone:** Resilient Hive/Supabase sync engine (Fixed handshake). ✅
- **Seamless Continuity:** Flicker-free transition from OS Splash to App Animation. ✅
- **Vector Splash:** XML vector `ic_keystone_splash_logo.xml` now wired into all Android splash configs (drawable-v21, values-v31, values-night-v31). ✅
- **Narrative Tracking:** LinkedIn Content Roadmap established. ✅
- **Field Guidance:** Integrated "Field Hints" on all forms. ✅
- **Admin Control:** In-app Correction Request & Admin Approval UI. ✅
- **Tactical UI:** Dark Industrial theme, Receipt Typography, and Haptics. ✅
- **Identity:** Verified public profile links & sharing using correct Vercel domain. ✅
- **Data Integrity:** Case-insensitive slug matching and high fetch limits. ✅
- **Reliability Hardening:** Silent error swallowing eliminated, unsafe auth access guarded, Hive recovery narrowed, currency rounding fixed. ✅
- **Plain Language:** All technical jargon (DATABASE, SYNC, RECORDS, ENTITIES, TERMINAL, INITIALIZE, etc.) replaced with plain human language across all screens. ✅
- **Profile Photo:** Circular photo shape consistent across profile screen and edit screen. ✅
- **Web UX:** Branded loading screen, OG meta tags, Vercel asset caching, proper manifest branding. ✅
- **flutter analyze:** 0 issues after `dart fix --apply` and manual corrections. ✅
- **Web Performance:** Service worker `no-cache` fix applied. 8 unused font weights removed (~400–700KB saved). Vercel build pipeline active via `scripts/vercel_build.sh`. ✅
- **Language Polish:** All remaining technical jargon removed from mobile screens — "CUSTOMER DATABASE" → "CUSTOMERS", "TECHNICAL DOCUMENTATION" → "NOTE DETAILS", step labels humanised. ✅

---

## Environment Registry
- **Testing:** https://mxkkntxemrcjbxvlzfbt.supabase.co
- **Production:** https://ifzpdizxitlvjbmzozew.supabase.co
- **Web Gateway:** https://keystone-inky-five.vercel.app

---

## Pilot Provisioning
- **Jeremie Kouassi:** Authorized (`053 589 1956`)
- **Jean Mensah:** Authorized (`053 130 7502`)
- **Bypass OTP:** Active (`123456`) — intentional, SMS provider not yet wired up. Remove when Twilio/real SMS is live.

---

## Known Open Bugs (See `open_bugs.md` for full surgical specs)
| ID      | Severity | Description                                                              | Status      |
|---------|----------|--------------------------------------------------------------------------|-------------|
| BUG-001 | High     | Failed remote job create → permanently stuck as `failed`                 | ✅ Fixed    |
| BUG-002 | Medium   | New customer missing from list after job log                             | ✅ Fixed    |
| BUG-003 | Medium   | Keyboard dismissed / focus lost when typing "0"                          | ✅ Fixed    |
| BUG-004 | High     | Archived jobs reappear after next sync                                   | ✅ Fixed    |
| BUG-005 | Low      | `getCustomerById` throws `StateError` on missing record                  | ✅ Fixed    |
| BUG-006 | High     | `currentUser!` force unwrap in 3 places → crash on expiry               | ✅ Fixed    |
| BUG-007 | High     | `archiveNote` no offline guard → note reappears after sync               | ✅ Fixed    |
| BUG-008 | High     | SQL RPC `batch_sync_jobs` returns `local_id: null` → jobs stuck pending  | ✅ Fixed    |
| BUG-009 | Medium   | `profile._authUserId` returns `''` not throw on null session             | ✅ Fixed    |
| BUG-010 | Medium   | Offline notes never re-synced (no `syncPendingNotes`)                    | ✅ Fixed    |
| BUG-011 | Low      | `getCustomerById` fetches 1000 customers to find one                     | ✅ Fixed    |
| BUG-012 | Low      | Missing `flush()` in customer and note datasources                       | ✅ Fixed    |
| BUG-013 | High     | `onChanged: setState` keyboard focus loss on 3 more screens              | ✅ Fixed    |
| BUG-014 | High     | Phone fields missing Ghana format + 10-digit limit                       | ✅ Fixed    |
| BUG-015 | Medium   | No sync status indicator — background sync invisible to user              | ✅ Fixed    |
| BUG-016 | Medium   | No `maxLength` on form fields — DB constraint errors on sync             | ✅ Fixed    |
| BUG-017 | Medium   | Amount field accepts negatives and invalid input                         | ✅ Fixed    |
| BUG-018 | Low      | Search fields call Riverpod + setState redundantly                       | ✅ Fixed    |
| BUG-019 | Medium   | Profile photo circular in edit screen but square on profile screen       | ✅ Fixed    |
| BUG-020 | Medium   | Splash screen using PNG despite XML vector being present                 | ✅ Fixed    |
| BUG-021 | Low      | Share URL used `keystone.app` domain (non-existent) instead of Vercel   | ✅ Fixed    |
| BUG-022 | Low      | Dead edit button in customer detail screen (empty onPressed)             | ✅ Fixed    |
| BUG-023 | High     | Job create FK constraint: auth UID passed instead of internal `users.id` | ✅ Fixed    |
| BUG-024 | Medium   | Amount field formatter with `^` anchor caused keyboard unfocus on "0"   | ✅ Fixed    |
| BUG-025 | High     | Light mode: white text on white/light backgrounds across multiple screens | ✅ Fixed    |
| BUG-026 | High     | Re-install: stale provider cache returns empty data after fresh login     | ✅ Fixed    |
| BUG-027 | Medium   | Communication status section blank due to race condition in init          | ✅ Fixed    |
| BUG-028 | Low      | RenderFlex overflow on small screens in admin requests + follow-up button | ✅ Fixed    |
| BUG-029 | Low      | Discard dialog buttons unstyled in log_job_screen vs other screens        | ✅ Fixed    |
| BUG-030 | Medium   | Web loading screen: brand name white text on white background (invisible) | ✅ Fixed    |
| BUG-031 | High     | job_list_screen: AppColors used in widget scope + missing () on method    | ✅ Fixed    |
