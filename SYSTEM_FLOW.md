# Keystone — Complete System Flow

---

## 1. AUTH FLOW

```
[App Launch] → [Auth Guard: check session]
                      │
                ┌─────┴──────┐
                │ Has session? │
                └─────┬──────┘
                 No   │   Yes
                  │   │
[LandingScreen] ◄─┘   │
  │                   │
  │ "GET STARTED"     │
  ▼                   │
[PhoneEntryScreen]    │
  │                   │
  │ Enter phone (233) │
  ▼                   │
─── ALWAYS: requestOtp() ─────────────────
  │
  ▼
[OtpVerify] (6-digit code)
  │ verifyOTP() → session created
  │ authStateProvider fires
  ▼
[Router — check order]
  │
  ├── !hasProfile → [OnboardingScreen]
  │     │ Step 1: Display Name
  │     │ Step 2: Service Categories
  │     │ completeOnboarding() → profile created
  │     │ Router re-evaluates:
  │     │   hasProfile=true, needsUpgrade=true → [UpgradeAccount]
  │     ▼
  │
  ├── hasProfile + needsUpgrade → [UpgradeAccount]
  │     │ enter password → updateUser()
  │     │ success → prompt PIN/Biometric
  │     │         → [TransitionScreen] → [Dashboard]
  │     │ skip (3x max, persistent)
  │     │         → [TransitionScreen] → [Dashboard]
  │     ▼
  │
  └── hasProfile + !needsUpgrade → [TransitionScreen]
        │ wait 800ms
        │ tryAutoLogin()
        ▼
┌────────┼────────┐
│        │        │
UnlockSuccess  │   UnlockLocked
│        │        │
▼        │        ▼
[Dashboard]    │   [PinEntryScreen]
               │        │ 3 fails?
               │        ├──► [PasswordEntry]
               │        │ correct?
               │        └──► [TransitionScreen] → [Dashboard]
               │
       UnlockNeedsOnline
               │
               ▼
       [StaleDataScreen]
         │              │
   "VERIFY"        "PROCEED CACHED"
   │ refresh           │ (offline only)
   │ session &         │
   │ markSync          │
   ▼                   ▼
[Dashboard]        [Dashboard]

──────────────────────────────
  Returning user (fast unlock):
──────────────────────────────
[TransitionScreen]
  │ tryAutoLogin()
  │   ├── AuthMethod.none → UnlockNeedsNetwork → [PasswordEntry]
  │   ├── AuthMethod.biometric → authenticate()
  │   │     ├── success → check session validity
  │   │     │              ├── session null → UnlockNeedsNetwork → [PasswordEntry]
  │   │     │              └── session valid → check staleness (24h)
  │   │     │                    ├── fresh → UnlockSuccess → [Dashboard]
  │   │     │                    └── stale → UnlockNeedsOnline → [StaleDataScreen]
  │   │     └── failed → UnlockLocked → [PinEntryScreen]
  │   └── AuthMethod.pin → check session + staleness (same as biometric)
  │
  │ Session loss (auth guard listener):
  │   supabase.onAuthStateChange
  │     ├── session == null → clearAll Hive boxes + vault
  │     └── invalidate(authStateProvider)
```
[App Launch] → [Auth Guard: check session]
                      │
                ┌─────┴──────┐
                │ Has session? │
                └─────┬──────┘
                 No   │   Yes
                  │   │
[LandingScreen] ◄─┘   │
  │                   │
  │ "GET STARTED"     │
  ▼                   │
[PhoneEntryScreen]    │
  │                   │
  │ Enter phone (233) │
  ▼                   │
─── RPC: get_auth_strategy(phone) ─────────────────
  │                   │              │
  ▼                   ▼              ▼
NEW_USER          PASSWORD_USER   OTP_USER
  │                   │              │
  ▼                   ▼              ▼
[CreatePassword]  [PasswordEntry]  [OtpVerify]
  │                   │              │
  │                   │              ▼
  │                   │         [UpgradeAccount]
  │                   │              │
  └───────┬───────────┘              │
          │                          │
          ▼                          ▼
     [BiometricEnroll]
          │ Skip
          ├─────► [OnboardingScreen]
          │           │ Step 1: Display Name
          │           │ Step 2: Service Categories
          │           ▼
          │       completeOnboarding()
          │           │
          └─────► [TransitionScreen]
                     │ wait 800ms
                     │ tryAutoLogin()
                     ▼
            ┌────────┼────────┐
            │        │        │
     UnlockSuccess  │   UnlockLocked
            │       │        │
            ▼       │        ▼
     [Dashboard]    │   [PinEntryScreen]
                    │        │ 3 fails?
                    │        ├──► [PasswordEntry]
                    │        │ correct?
                    │        └──► [TransitionScreen] → [Dashboard]
                    │
            UnlockNeedsOnline
                    │
                    ▼
            [StaleDataScreen]
              │              │
        "VERIFY"        "PROCEED CACHED"
        │ refresh           │ (offline only)
        │ session &         │
        │ markSync          │
        ▼                   ▼
    [Dashboard]        [Dashboard]

──────────────────────────────────────────────
  Password Upgrade Flow (OTP legacy users):
──────────────────────────────────────────────

[UpgradeAccount] → enter password → updateUser()
  │ success      │ skip (3x max, persistent)
  ▼               ▼
[Transition]   [Transition]

──────────────────────────────────────────────
  Returning user (fast unlock):
──────────────────────────────────────────────
[TransitionScreen]
  │ tryAutoLogin()
  │   ├── AuthMethod.none → UnlockNeedsNetwork → [PasswordEntry]
  │   ├── AuthMethod.biometric → authenticate()
  │   │     ├── success → check session validity
  │   │     │              ├── session null → UnlockNeedsNetwork → [PasswordEntry]
  │   │     │              └── session valid → check staleness (24h)
  │   │     │                    ├── fresh → UnlockSuccess → [Dashboard]
  │   │     │                    └── stale → UnlockNeedsOnline → [StaleDataScreen]
  │   │     └── failed → UnlockLocked → [PinEntryScreen]
  │   └── AuthMethod.pin → check session + staleness (same as biometric)
  │
  │ Session loss (auth guard listener):
  │   supabase.onAuthStateChange
  │     ├── session == null → clearAll Hive boxes + vault
  │     └── invalidate(authStateProvider)
```

---

## 2. NAVIGATION ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────────┐
│                     BOTTOM NAV BAR                                  │
│  [Dashboard]  [Jobs]  [Customers]  [More]                          │
│     tab:0       1          2          3                             │
└─────────────────────────────────────────────────────────────────────┘

═══ TAB 0: DASHBOARD ═══════════════════════════════════════════════════

[DashboardScreen] ←── default landing after auth/login
  │
  ├── Quick Actions
  │     ├── [+ NEW JOB] ───────────► [LogJobScreen]
  │     └── [+ NEW CUSTOMER] ──────► [AddCustomerScreen]
  │
  ├── Summary Cards
  │     ├── TODAY: job count + revenue
  │     ├── THIS MONTH: job count + revenue
  │     └── REVENUE: formatted GHS
  │
  ├── [Reminder Card] ──► [RemindersScreen]
  │     (count of pending reminders)
  │
  ├── Recent Jobs (last 5)
  │     └── tap any job ────────────► [JobDetailScreen]
  │
  └── Quick Links (3×2 grid)
        ├── Analytics ──────────────► [AnalyticsScreen]
        ├── Inventory ──────────────► [InventoryScreen]
        ├── Knowledge Base ─────────► [NotesListScreen]
        ├── Activity ───────────────► [TimelineScreen]
        ├── Service Pricing ────────► [PricingScreen]
        └── Templates ──────────────► [JobTemplatesScreen]


═══ TAB 1: JOBS ═══════════════════════════════════════════════════════

[JobListScreen] ←── app bar icons → [SearchScreen], [AnalyticsScreen], [RemindersScreen]
  │                  FAB → [LogJobScreen]
  │
  ├── Search bar (no debounce)
  ├── Filter bottom sheet: STATUS | PAYMENT | SERVICE TYPE | DATE RANGE
  ├── Summary strip: Total Logs | This Month | Pending Upload
  ├── Infinite scroll job cards
  │     └── tap card ───────────────► [JobDetailScreen]
  │           │
  │           ├── Header: service type, date, sync status
  │           ├── Status badge (tappable) → bottom sheet
  │           │     quoted → in_progress → completed → invoiced
  │           ├── Payment badge (tappable) → bottom sheet
  │           │     unpaid ↔ partial → paid (requires invoiced status)
  │           ├── Financials: quoted price, final charge, payment method
  │           ├── Customer module (tappable → [CustomerDetailScreen])
  │           ├── Hardware: brand, keyway
  │           ├── Services list
  │           ├── Parts & Profit: parts cost, revenue, gross profit
  │           ├── Expenses section: by category
  │           ├── Photos grid: before/after, add (camera), delete
  │           ├── Notes section
  │           ├── Communication: WhatsApp follow-up preview + send/resend
  │           ├── Linked notes section
  │           ├── Audit timeline (edit history)
  │           ├── App bar: back, edit [EditJobScreen], archive (admin)
  │           └── Bottom bar: FollowUp button / Job Actions
  │                 ├── [SEND WHATSAPP FOLLOW-UP] → opens WhatsApp
  │                 ├── After sent: [RESEND] + status chips
  │                 ├── [SHARE INVOICE] (PDF)
  │                 └── [RECEIPT] (PDF, paid only)
  │
  ├── Multi-select mode (long-press card)
  │     └── Bulk actions: ARCHIVE, EXPORT CSV
  │
  └── FAB ───► [LogJobScreen]
        │ 4-step wizard:
        │   1: SERVICE (type + status)
        │   2: CUSTOMER (name + phone)
        │   3: DETAILS (pricing + payment + location + date + lead source)
        │   4: EXTRAS (hardware + parts + expenses + photos + notes + load template)
        │
        │ Save flow:
        │   logJobUsecase → create JobEntity (pending sync)
        │     → save parts locally
        │     → save services locally
        │     → save hardware locally
        │     → save photos locally
        │     → save expenses locally
        │     → auto-COGS deduction (inventory, best-effort)
        │     → incrementCustomerJobCount
        │     → optional: save as template
        │     → optional: create recurring schedule

[EditJobScreen] ←── load job by ID
  ├── Service type picker
  ├── Status selector
  ├── Financials: quoted amount, final amount (read-only w/o permission)
  ├── Payment status selector (VALIDATED — no paid→unpaid bypass)
  ├── Hardware: brand, keyway
  ├── Parts sub-list (add/remove)
  ├── Services sub-list (add/remove)
  ├── Location + Notes
  └── Save → compute diff → audit log → updateJob → refresh

[AdminRequestsScreen] (admin only)
  └── Pending correction requests list
        ├── REJECT → dialog with reason → reject()
        └── APPROVE → dialog with service type + date → approve()


═══ TAB 2: CUSTOMERS ═════════════════════════════════════════════════

[CustomerListScreen]
  ├── Search bar (300ms debounce)
  ├── Filter chips: ALL / RECENT / REPEAT
  ├── Property type chips: ALL / RESIDENTIAL / COMMERCIAL / AUTOMOTIVE
  ├── Lead source chips: ALL / REFERRAL / WHATSAPP / GOOGLE / WORD OF MOUTH / CARD
  ├── Infinite scroll cards
  │     └── tap card ───────────────► [CustomerDetailScreen]
  │           │
  │           ├── Profile card: avatar, name, property badge, phone, lead source, location
  │           ├── Stats: TOTAL JOBS | STATUS | LIFETIME REVENUE
  │           ├── Commonly used: brands + parts chips (from job history)
  │           ├── Tab 1: KEY CODES (add/edit/delete, permission-gated)
  │           ├── Tab 2: SERVICE HISTORY (visual timeline)
  │           ├── App bar: EDIT, MERGE, DELETE
  │           └── Bottom bar: LOG NEW JOB
  │
  ├── Contact Import (app bar icon)
  │     └── ContactImportSheet → load contacts → detect duplicates → bulk import
  │
  └── FAB ───► [AddCustomerScreen]
        │ 2-step wizard:
        │   1: name + phone (duplicate detection on phone)
        │   2: property type + lead source + location + notes
        └── Save → createCustomer → add to list → sync pending

[EditCustomerScreen] ←── load by ID
  ├── Name, phone, property type, lead source, location, notes
  └── Save → updateCustomer → invalidate detail → reload list

[MergeCustomerSheet] (bottom sheet)
  ├── Search customers
  ├── Select source → confirmation dialog
  └── mergeCustomers: cascade jobs → sum totalJobs → tombstone source


═══ TAB 3: MORE (HUB) ════════════════════════════════════════════════

[HubScreen]
  │
  ├── Profile mini card ──► [ProfileScreen]
  │     └── Photo, name, badge, phone, bio, member since, services chips
  │         └── Share link: web URL + preview in browser + share sheet
  │         └── EDIT PROFILE → [EditProfileScreen]
  │               └── name, bio, photo (camera+gallery), WhatsApp, services toggle
  │
  ├── TOOLS
  │     ├── Knowledge Base ─────────► [NotesListScreen]
  │     ├── Inventory ──────────────► [InventoryScreen]
  │     ├── Service Pricing ────────► [PricingScreen]
  │     ├── Job Templates ──────────► [JobTemplatesScreen]
  │     ├── Activity Timeline ──────► [TimelineScreen]
  │     └── Analytics ──────────────► [AnalyticsScreen]
  │
  ├── SETTINGS
  │     ├── Appearance (Dark/Light toggle)
  │     ├── Reminder Settings ──────► [ReminderSettingsScreen]
  │     ├── Recurring Jobs ─────────► [RecurringSchedulesScreen]
  │     └── Service Types ──────────► [ServiceTypesScreen]
  │
  ├── DATA
  │     ├── Export Jobs CSV
  │     ├── Export Customers CSV
  │     └── Export All JSON
  │
  ├── ADMINISTRATION (admin only)
  │     ├── Correction Requests ────► [AdminRequestsScreen]
  │     └── Technician Permissions ──► [PermissionsScreen]
  │
  └── Setup Guide ──► [SetupScreen]


═══ KNOWLEDGE BASE (sub-feature) ═════════════════════════════════════

[NotesListScreen]
  ├── Search bar
  ├── Filter chips: ALL / CAR KEY / INSTALL / REPAIR / SMART
  ├── Archive toggle (active/archived)
  ├── Infinite scroll NoteCards
  │     ├── tap ───────────────────► [NoteDetailScreen]
  │     │     ├── Title, description, photo, tags, linked jobs
  │     │     ├── Share (text), Pin/Unpin, Duplicate, Edit, Archive
  │     │     └── LINK JOB ────────► [NoteJobLinkScreen]
  │     └── swipe → archive (with undo)
  └── FAB ───► [AddNoteScreen] (2-step wizard: content + tags)

[NoteJobLinkScreen]
  ├── Searchable job list
  └── Tap to toggle link on/off


═══ INVENTORY (sub-feature) ═════════════════════════════════════════

[InventoryScreen]
  ├── Filter tabs: ALL / PARTS / HARDWARE
  ├── Location chips + search bar
  ├── Group by location toggle
  ├── Item cards: name, brand, category, quantity, low-stock badge,
  │              auto-cogs badge, location, sale price
  │     ├── ADJUST → dialog: add/remove qty + reason → stock audit trail
  │     ├── RESTOCK → dialog: qty + unit cost + vendor + phone → auto-adjust stock
  │     ├── HISTORY → dialog: adjustments + restocks timeline
  │     └── long-press: DELETE
  ├── Archived items toggle
  └── FAB ───► Add/Edit Item dialog (name, type, category, brand, model, key spec,
               material, finish, dimensions, cost+sale price, quantity, threshold,
               location, auto-cogs toggle)

  Auto-COGS deduction on job save:
    job_providers.dart: for each part with inventoryItemId/isAutoCogs
      → adjustStock(itemId, -qty, 'job_use')
    log_job_screen.dart: for each hardware item with inventoryItemId
      → adjustStock(itemId, -qty, 'job_use')  (no name fallback)

  Stock restoration on job archive:
    job_providers.dart: for each part matched by id or name
      → adjustStock(itemId, +qty, 'job_unarchive')


═══ SETTINGS SUB-SCREENS ═════════════════════════════════════════════

[ReminderSettingsScreen] ─── 4 sliders: unpaid, stuck, follow-up, no-response (0-14d)
[RecurringSchedulesScreen] ─ list + add/remove recurring jobs
[ServiceTypesScreen] ─────── list + add/edit/delete service types (admin)
[PricingScreen] ──────────── search + collapsible categories + inline GHS editing
[PermissionsScreen] ──────── 4 toggles (admin only): edit price, delete, view key codes, require after-photo


═══ ADMIN SCREENS ════════════════════════════════════════════════════

[Correction Requests] ────── list → approve (with service type/date) / reject (with reason)
[Technician Permissions] ─── 4 toggle switches → immediate Hive write


═══ SUB-SCREENS (accessible from various locations) ═════════════════

[AnalyticsScreen] ──── period selector → summary + trends + breakdowns + CSV export
[RemindersScreen] ──── computed from activeJobs → unpaid, stuck, follow-up due
[SearchScreen] ──────── global search: jobs + customers + notes
[TimelineScreen] ────── full activity timeline grouped by date

```

---

## 3. STATE MACHINES

### Job Status (forward-only)

```
  quoted ──► in_progress ──► completed ──► invoiced
     │            │              │              │
     │            │              │              │
     └───── back/blocked ────── back/blocked ──┘
     └─────────────── skip/blocked ──────────────┘

  Rules:
  - Same status: ALWAYS ALLOWED
  - null → any: ALLOWED (initial creation)
  - Forward by 1 step: ALLOWED
  - Forward skip (quoted→completed): BLOCKED
  - Backward (completed→in_progress): BLOCKED
  - Invalid target: BLOCKED
```

### Payment Status (coupled to job status)

```
                 ┌─────────────────┐
                 │    unpaid       │
                 └──┬──────────┬───┘
                    │          │
            partial │          │ unpaid → partial: ALLOWED
              ←─────┤          ├─────► paid: BLOCKED (needs invoiced)
                    │          │      paid → unpaid: BLOCKED (irreversible)
                    │          │
                 ┌──▼──────────┴───┐
                 │    partial      │
                 └──┬──────────┬───┘
                    │          │
          unpaid ←──┤          ├─────► paid: ALLOWED if status==invoiced
                    │          │
                 ┌──▼──────────┴───┐
                 │     paid        │
                 └─────────────────┘  ←── IRREVERSIBLE

  Rules:
  - partial → unpaid: ALLOWED (only revert point)
  - paid → anything: BLOCKED
  - → paid if status != invoiced: BLOCKED
  - → partial if status == quoted: BLOCKED
  - Edit screen: VALIDATED (no bypass)
```

### Offline Sync Priority

```
  Local write FIRST → syncStatus = pending → attempt remote
    ├── SUCCESS → syncStatus = synced (replace local with server entity)
    └── FAILURE → syncStatus = pending (local copy retained)
      └── Next syncPendingJobs() call → retry remote
            └── After 3+ failures → keep locally until connectivity

  Conflict resolution: SERVER WINS
  - On remote fetch, overwrite local with server version
  - Local-only changes (pending status) protected from overwrite
```

### TotalJobs Lifecycle

```
  Customer.totalJobs
    ├── Job created → incrementJobCount(customerId) → totalJobs + 1
    ├── Job archived → decrementJobCount(customerId) → totalJobs - 1 (clamped ≥ 0)
    ├── Customer merge → target.totalJobs + source.totalJobs
    └── DB trigger: on INSERT to jobs → sync (but local NOT auto-synced back)
```

### Auto-COGS Stock Deduction/Restoration

```
  Job SAVED (with parts/hardware):
    → for each part with inventoryItemId + isAutoCogs:
        adjustStock(itemId, -quantity, 'job_use')
    → for each hardware item with inventoryItemId + isAutoCogs:
        adjustStock(itemId, -quantity, 'job_use')
    → errors caught, logged, non-blocking

  Job ARCHIVED:
    → for each part (matched by id or name + isAutoCogs):
        adjustStock(itemId, +quantity, 'job_unarchive')
    → for each hardware item (matched by brand name + isAutoCogs):
        adjustStock(itemId, +quantity, 'job_unarchive')
    → errors caught, logged, non-blocking

  Quantity: clamped to [0, 999999] (no negative stock errors)

  Hardware matching: brand name only (no inventoryItemId field on entity).
  Hardware deduction: on job save in log_job_screen.dart (inventoryItemId from UI state).
```

---

## 4. DATA FLOW: DATABASE → SCREEN

### Entity → Model → Repository → Provider → Screen (every feature)

```
  [Supabase DB]       [Hive Box]        [Repository]        [Provider]        [Screen]
      │                   │                  │                  │                │
      ▼                   ▼                  │                  │                │
  RemoteDatasource   LocalDatasource         │                  │                │
      │                   │                  │                  │                │
      └──────────┬────────┘                  │                  │                │
                 │ read: remote first,       │                  │                │
                 │       fallback to local   │                  │                │
                 │ write: local first,       │                  │                │
                 │       then remote         │                  │                │
                 └──────────┬───────────────┘                  │                │
                            │                                 │                │
                            ▼                                 │                │
                        RepositoryImpl                        │                │
                        (offline-first)                       │                │
                            │                                 │                │
                            └──────────┬──────────────────────┘                │
                                       │                                      │
                                       ▼                                      │
                                    StateNotifier / FutureProvider            │
                                       │                                      │
                                       └──────────────┬───────────────────────┘
                                                      │
                                                      ▼
                                                   Widget
```

### Key data mappings (all entities):

| Entity | Table | Hive Box | Provider | Screen(s) |
|--------|-------|----------|----------|-----------|
| JobEntity | jobs | jobs | jobListProvider | List, Detail, Edit, Log |
| JobPartEntity | job_parts | job_parts | jobPartsProvider | Detail, Edit, Log |
| JobPhotoEntity | job_photos | job_photos | jobPhotosProvider | Detail, Log |
| JobServiceEntity | job_services | job_services | jobServicesProvider | Detail, Edit, Log |
| JobHardwareEntity | job_hardware | job_hardware | jobHardwareProvider | Detail, Edit, Log |
| JobExpenseEntity | job_expenses | job_expenses | jobExpensesProvider | Detail, Log |
| CorrectionRequestEntity | correction_requests | — (no local) | adminRequestsProvider | Admin Requests |
| CustomerEntity | customers | customers | customerListProvider | List, Detail, Add, Edit |
| KnowledgeNoteEntity | knowledge_notes | notes | notesListProvider | List, Detail, Add, Edit |
| ProfileEntity | profiles | profile | profileProvider | Profile, Edit |
| InventoryItemEntity | inventory_items | inventory_items | inventoryProvider | Inventory |
| StockAdjustmentEntity | inventory_stock_adjustments | inventory_stock_adjustments | (via repo) | Inventory history |
| RestockEntity | inventory_restocks | inventory_restocks | (via repo) | Inventory history |
| NoteJobLinkEntity | note_job_links | note_job_links | noteLinkProvider | Note Detail, Job Detail |
| KeyCodeEntryEntity | key_code_history | key_code_history | keyCodeProvider | Customer Detail > Key Codes |
| ServiceTypeEntity | service_types | service_types | serviceTypeProvider | Pricing, Onboarding |

---

## 5. FOREIGN KEY RELATIONSHIPS (DB)

```
auth.users
  ├── profiles (user_id → CASCADE)
  ├── customers (user_id → CASCADE)
  ├── users (auth_id → CASCADE)
  ├── knowledge_notes (user_id → CASCADE)
  ├── inventory_items (user_id → CASCADE)
  │     ├── inventory_restocks (item_id → CASCADE)
  │     │     └── user_id → auth.users(id) → CASCADE (fixed 20260525)
  │     └── inventory_stock_adjustments (item_id → CASCADE)
  │           └── user_id → auth.users(id) → CASCADE (fixed 20260525)
  ├── app_events (user_id → SET NULL)
  └── service_types (user_id → CASCADE)

public.users
  ├── jobs (user_id → CASCADE)
  │     ├── job_parts (job_id → CASCADE)
  │     ├── job_photos (job_id → CASCADE)
  │     ├── job_services (job_id → CASCADE)
  │     ├── job_hardware (job_id → CASCADE)
  │     ├── job_expenses (job_id → CASCADE)
  │     ├── job_audit_log (job_id → CASCADE)
  │     ├── follow_ups (job_id → CASCADE)
  │     ├── reminders (job_id → CASCADE)
  │     ├── correction_requests (job_id → CASCADE)
  │     ├── note_job_links (job_id → CASCADE)
  │     └── key_code_history (job_id → SET NULL)
  │
  ├── customers (→ jobs.customer_id [no cascade — soft delete])
  │     ├── customer_audit_entries (customer_id → CASCADE)
  │     ├── key_code_history (customer_id → CASCADE)
  │     ├── follow_ups (customer_id → [no cascade])
  │     ├── note_job_links (...) ──► knowledge_notes
  │     └── recurring_job_schedules (customer_id → CASCADE)
  │
  └── inventory_items
```

---

## 6. COMMON USER PATHS (End-to-End)

### Path A: New technician setup
```
Install app → Landing → PhoneEntry (enter 024XXXXXXX)
  → OTP sent to phone → OtpVerify (enter 6-digit code)
  → Onboarding Step 1 (enter display name)
  → Onboarding Step 2 (select services)
  → Create Password (upgrade from phone-only)
  → PIN/Biometric enrollment prompt
  → Transition → Dashboard

Technician then:
  → Sets up pricing: More → Service Pricing (enter GHS amounts per service)
  → Adds inventory: More → Inventory → FAB → add parts/hardware
  → Creates first customer: Dashboard → [+ NEW CUSTOMER]
  → Logs first job: Dashboard → [+ NEW JOB]
```

### Path B: Daily job logging
```
App open → biometric/PIN → Dashboard
  → [+ NEW JOB]
  → Step 1: select service type (e.g., "Car Key Programming"), status = in_progress
  → Step 2: search customer name or enter new
  → Step 3: enter amount GHS 350, unpaid, location, lead source
  → Step 4: add parts (1x Key Blank @ GHS 45), take after photo, add notes
  → SAVE → job saved locally (pending sync) → auto-deduct inventory

Later:
  → Go to Jobs tab → find job → tap → JobDetail → tap STATUS badge → "completed"
  → Tap PAYMENT badge → "paid" (requires "invoiced" status first)
  → Change status to "invoiced" → then change payment to "paid"
  → Receipt PDF available → share
  → SHARE INVOICE → PDF → share via WhatsApp
  → Bottom bar → Send WhatsApp follow-up
  → Customer responds → mark "RESPONDED"
```

### Path C: Customer management
```
Customers tab → search → tap customer
  → View service history, key codes
  → Tap EDIT → change phone number → SAVE
  → Tap MERGE → search duplicate → select → confirm merge
  → Tap DELETE → confirm → customer soft-deleted (jobs preserved)
  → Contact Import → permissions dialog → select contacts → bulk import
```

### Path D: Inventory management
```
More → Inventory
  → FAB → add item: "Yale Deadbolt", type=hardware, category=deadbolt,
    cost=GHS 85, sale=GHS 180, qty=10, threshold=3, auto-cogs=ON
  → ADJUST → remove 2 (broken) → audit trail created
  → RESTOCK → +5, unit cost=GHS 90, vendor="Yale Ghana Ltd", phone="024..."
  → HISTORY → view all adjustments and restocks
  → Long-press → DELETE → confirm
```

### Path E: Offline scenario
```
No internet → app starts → biometric → check last sync >24h → StaleDataScreen
  → "PROCEED WITH CACHED DATA" → Dashboard (offline mode)
  → Log new job → saves locally (syncStatus=pending)
  → Add customer → saves locally (syncStatus=pending)
  → Internet returns → auto-sync pending items to Supabase
```

### Path F: Session loss / forced re-auth
```
Active session → Supabase session expires
  → Auth guard fires → clear Hive + vault → invalidate auth
  → Router redirects to LandingScreen
  → Technician re-enters phone → RPC → PASSWORD_USER → PasswordEntry
  → BiometricEnroll (new device prompt) → Dashboard
```

---

## 7. NOTABLE DESIGN DECISIONS

- **Offline-first**: All writes go to Hive first, then attempt remote sync. Reads try remote first, fall back to local cache.
- **Concurrent sessions allowed**: No cross-device session kill. 24h staleness check guards server staleness.
- **Server-wins on sync conflict**: Remote fetch overwrites local unless local has pending status.
- **Soft-delete for everything**: Jobs use isArchived, customers use tombstone (deleted_at). Hard-delete only for pending items that never synced.
- **Job DELETE stock behavior**: Stock is restored on archive (the only deletion path). For pending-sync jobs, archive = hard delete with stock restoration. No separate "permanently delete" exists for synced jobs — would need stock restoration if added later.
- **Permissions local-only (known limitation)**: Stored in Hive, not synced to server. Admin always gets full access. Multi-device: permission changes on one device don't propagate to others. Workaround: re-login picks up Hive-stored defaults. A future sync layer would need `technician_permissions` on the profiles table.
- **Analytics fully local**: Computed in-memory from Hive data. No SQL queries.
- **Reminders computed, not stored**: Generated in-memory from active jobs + thresholds. dismissedKeys is in-memory only.
- **Auto-COGS is best-effort**: Stock deduction failures don't block job saves. Silent clamp at 0 for negative stock. Parts use dual-match (inventoryItemId → name fallback). Hardware deduction uses inventoryItemId from UI state. Hardware archive restoration uses brand name matching (entity has no inventoryItemId field). Both parts and hardware stock are restored on archive.
- **Services/hardware/expenses**: Saved AFTER job creation, not within the same transaction.
- **CorrectionRequests: remote-only (intentional)**: Admin feature requires online connectivity. No Hive box, no offline support. Admins are assumed to be online when processing corrections.
- **CASCADE policy on user_id**: All tables reference `auth.users(id)` with ON DELETE CASCADE. Exceptions: `inventory_restocks` and `inventory_stock_adjustments` — CASCADE added in migration `20260525000000_cascade_fixes.sql`. `follow_ups` — missing FKs entirely, added in same migration.
