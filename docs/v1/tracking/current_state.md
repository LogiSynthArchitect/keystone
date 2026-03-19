# CURRENT STATE — KEYSTONE V1
### Last Updated: March 19 2026
### Session: 26 (INPUT/UX AUDIT)

---

## Build Status
- **flutter analyze:** 0 errors, 0 warnings ✅
- **flutter test:** 80+ tests passing, zero failures ✅
- **Supabase:** All migrations and resilient RPC fixes applied to Staging & Production. ✅
- **Web Build:** Lightweight Gateway (main_web.dart) live on Vercel. ✅
- **UI Aesthetic:** Circular Identity and Tactical Grid overhaul complete. ✅

---

## Core Feature Completion (All 100%)
- **Tactical Terminal:** Language simplified for human-friendly field use. ✅
- **Environment Sanctity:** Hardened Staging/Prod separation in GEMINI.md. ✅
- **Offline Backbone:** Resilient Hive/Supabase sync engine (Fixed handshake). ✅
- **Seamless Continuity:** Flicker-free transition from OS Splash to App Animation. ✅
- **Vector Integrity:** Sharp XML Vector Splash Logo replacing blurry PNG. ✅
- **Narrative Tracking:** LinkedIn Content Roadmap established. ✅
- **Field Guidance:** Integrated "Field Hints" on all forms. ✅
- **Admin Control:** In-app Correction Request & Admin Approval UI. ✅
- **Tactical UI:** Dark Industrial theme, Receipt Typography, and Haptics. ✅
- **Identity:** Verified public profile links & sharing (no more 404s). ✅
- **Data Integrity:** Case-insensitive slug matching and high fetch limits. ✅
- **Reliability Hardening:** Silent error swallowing eliminated, unsafe auth access guarded, Hive recovery narrowed, currency rounding fixed. ✅

---

## Environment Registry
- **Testing:** https://mxkkntxemrcjbxvlzfbt.supabase.co
- **Production:** https://ifzpdizxitlvjbmzozew.supabase.co

---

## Pilot Provisioning
- **Jeremie Kouassi:** Authorized (`053 589 1956`)
- **Jean Mensah:** Authorized (`053 130 7502`)
- **Bypass OTP:** Active (`123456`) — intentional, SMS provider not yet wired up. Remove when Twilio/real SMS is live.

---

## Known Open Bugs (See `open_bugs.md` for full surgical specs)
| ID      | Severity | Description                                                  | Status      |
|---------|----------|--------------------------------------------------------------|-------------|
| BUG-001 | High     | Failed remote job create → permanently stuck as `failed`     | ✅ Fixed    |
| BUG-002 | Medium   | New customer missing from list after job log                 | ✅ Fixed    |
| BUG-003 | Medium   | Keyboard dismissed / focus lost when typing "0"              | ✅ Fixed    |
| BUG-004 | High     | Archived jobs reappear after next sync                       | ✅ Fixed    |
| BUG-005 | Low      | `getCustomerById` throws `StateError` on missing record      | ✅ Fixed    |
| BUG-006 | High     | `currentUser!` force unwrap in 3 places → crash on expiry   | ✅ Fixed    |
| BUG-007 | High     | `archiveNote` no offline guard → note reappears after sync   | ✅ Fixed    |
| BUG-008 | High     | SQL RPC `batch_sync_jobs` returns `local_id: null` → jobs stuck pending | ✅ Fixed |
| BUG-009 | Medium   | `profile._authUserId` returns `''` not throw on null session | ✅ Fixed    |
| BUG-010 | Medium   | Offline notes never re-synced (no `syncPendingNotes`)        | ✅ Fixed    |
| BUG-011 | Low      | `getCustomerById` fetches 1000 customers to find one         | ✅ Fixed    |
| BUG-012 | Low      | Missing `flush()` in customer and note datasources           | ✅ Fixed    |
| BUG-013 | High     | `onChanged: setState` keyboard focus loss on 3 more screens  | Open        |
| BUG-014 | High     | Phone fields missing Ghana format + 10-digit limit           | Open        |
| BUG-015 | Medium   | No sync status indicator — background sync invisible to user  | Open        |
| BUG-016 | Medium   | No `maxLength` on form fields — DB constraint errors on sync  | Open        |
| BUG-017 | Medium   | Amount field accepts negatives and invalid input             | Open        |
| BUG-018 | Low      | Search fields call Riverpod + setState redundantly           | Open        |

---

## Next Action
Fix in this order:
1. **BUG-013 + BUG-014** (High) — keyboard focus + phone validation, same 3 screens, fix together
2. **BUG-017** (Medium) — amount field formatter, 1 screen, ~5 lines
3. **BUG-016** (Medium) — add `maxLength` to all form fields (mechanical, all screens)
4. **BUG-015** (Medium) — sync indicator in job list UI
5. **BUG-018** (Low) — remove redundant `setState` from 3 search fields
