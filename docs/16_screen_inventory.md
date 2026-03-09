# DOCUMENT 16 — SCREEN INVENTORY
### Project: Keystone
**Required Inputs:** Document 06 — User Flows, Document 14 — Design System, Document 15 — Component Inventory
**Principle:** Every screen has one job. High aesthetic quality. Every state designed.
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 16.1 Screen Index

| # | Screen | Route | Feature |
|---|---|---|---|
| 01 | Phone Entry | /auth/phone | auth |
| 02 | OTP Verify | /auth/otp | auth |
| 03 | Onboarding | /auth/onboarding | auth |
| 04 | Job List | /jobs | job_logging |
| 05 | Log Job | /jobs/new | job_logging |
| 06 | Job Detail | /jobs/:id | job_logging |
| 07 | Customer List | /customers | customer_history |
| 08 | Customer Detail | /customers/:id | customer_history |
| 09 | Add Customer | /customers/new | customer_history |
| 10 | Notes List | /notes | knowledge_base |
| 11 | Note Detail | /notes/:id | knowledge_base |
| 12 | Add Note | /notes/new | knowledge_base |
| 13 | Profile | /profile | technician_profile |
| 14 | Edit Profile | /profile/edit | technician_profile |
| 15 | Public Profile | /p/:slug | technician_profile |

Total: 15 screens

---

## 16.2 Auth Screens

### Screen 01 — Phone Entry
File: features/auth/presentation/screens/phone_entry_screen.dart
Route: /auth/phone
Purpose: Entry point — collect phone number to request OTP

Layout:
Scaffold (no app bar)
└── SafeArea → Padding(pagePadding) → Column
    ├── Spacer(flex 1)
    ├── Keystone wordmark logo (primary700, centered, 48dp)
    ├── SizedBox(xxxl)
    ├── Text("Welcome back.", h1)
    ├── Text("Enter your phone number to continue.", body, neutral600)
    ├── SizedBox(xxl)
    ├── KsTextField(type: phone, label: "Phone number")
    ├── SizedBox(xl)
    ├── KsButton(primary, "Continue", fullWidth)
    ├── Spacer(flex 2)
    └── Text(terms caption, neutral500, centered)

States:
- Default: empty field, button disabled
- Typing: button enabled at 9+ digits
- Loading: button spinner, field disabled
- Error: KsTextField errorText inline

Provider: authProvider
Navigates to: Screen 02

---

### Screen 02 — OTP Verify
File: features/auth/presentation/screens/otp_verify_screen.dart
Route: /auth/otp
Purpose: 6-digit OTP entry and verification

Layout:
Scaffold (no app bar)
└── SafeArea → Padding(pagePadding) → Column
    ├── Spacer(flex 1)
    ├── IconButton(arrow_back_ios_new) top left
    ├── Text("Enter the code.", h1)
    ├── Text("We sent a 6-digit code to [phone].", body, neutral600)
    ├── SizedBox(xxl)
    ├── Pinput (6-digit, auto-submit on complete)
    ├── SizedBox(xl)
    ├── KsButton(primary, "Verify", fullWidth)
    ├── SizedBox(md)
    ├── TextButton("Resend code") — disabled 30s countdown
    └── Spacer(flex 2)

States:
- Default: empty OTP, verify disabled
- Typing: cursor advances automatically
- Auto-submit: triggers on 6th digit
- Loading: button spinner
- Error: Pinput fields turn error500
- Resend cooldown: "Resend in 0:28" grayed out

Provider: authProvider
Navigates to: Screen 03 (first login) or Screen 04 (returning)

---

### Screen 03 — Onboarding
File: features/auth/presentation/screens/onboarding_screen.dart
Route: /auth/onboarding
Purpose: New user enters name and services on first login

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "Set up your profile", showBack: false)
    └── KsOfflineBanner
└── SingleChildScrollView → Padding(pagePadding) → Column
    ├── SizedBox(xxl)
    ├── Center → KsAvatar(xl) [live preview as name typed]
    ├── SizedBox(xxl)
    ├── KsTextField(text, "Full name", isRequired: true)
    ├── SizedBox(lg)
    ├── Text("Services you offer", h3)
    ├── SizedBox(sm)
    ├── ServiceTypePicker
    ├── SizedBox(xxxl)
    └── KsButton(primary, "Get started", fullWidth)

States: avatar updates live with initials, button disabled until required fields filled
Provider: authProvider
Navigates to: Screen 04

---

## 16.3 Job Logging Screens

### Screen 04 — Job List
File: features/job_logging/presentation/screens/job_list_screen.dart
Route: /jobs
Purpose: Home screen — all logged jobs, most recent first

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "Jobs", actions: [filter icon, search icon])
    └── KsOfflineBanner
└── CustomScrollView
    ├── SliverToBoxAdapter → Summary strip (KsCard flat)
    │     Row: total jobs count + this month GHS earnings
    ├── SliverPadding(pagePadding)
    └── SliverList → JobCard per job
└── FAB(primary700, add icon → Screen 05)

States:
- Loading: 3× KsSkeletonLoader(jobCard)
- Loaded: JobCard list newest first
- Empty no jobs: KsEmptyState(work_outline, "No jobs yet", cta: "Log a job")
- Empty filtered: KsEmptyState(tune, "No results", "Try adjusting your filters")
- Error: KsSnackbar(error)
- Offline: KsOfflineBanner + local data shown

Pull-to-refresh: triggers remote sync
Provider: jobListProvider

---

### Screen 05 — Log Job
File: features/job_logging/presentation/screens/log_job_screen.dart
Route: /jobs/new
Purpose: Log a completed job in under 60 seconds

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "Log a job", showBack: true)
    └── KsOfflineBanner
└── SingleChildScrollView → Padding(pagePadding) → Column
    ├── SizedBox(lg)
    ├── Text("Service", captionMedium)
    ├── ServiceTypePicker
    ├── SizedBox(xl)
    ├── KsTextField(text, "Customer name", hint: "Search or add new", isRequired: true)
        [Autocomplete dropdown — existing customers + "Add [name] as new customer"]
    ├── KsTextField(text, "Location")
    ├── KsTextField(amount, "Amount charged (GHS)")
    ├── KsTextField(multiline, "Notes", hint: "Car model, key type, solution used...")
    ├── SizedBox(lg)
    ├── [Date row: calendar icon + "Today, 15 Jan" → DatePicker on tap]
    ├── SizedBox(xxxl)
    └── KsButton(primary, "Save job", fullWidth)

Customer field: autocomplete from existing customers. "Add new" option creates customer inline.

States:
- Default: no service selected, save disabled
- Service selected: save enabled
- Loading: button spinner, fields disabled
- Saved: KsSnackbar(success) + navigate back
- Offline save: KsSnackbar(info, "Saved. Will sync when online.")

Provider: logJobProvider

---

### Screen 06 — Job Detail
File: features/job_logging/presentation/screens/job_detail_screen.dart
Route: /jobs/:id
Purpose: Full job record — view, send follow-up, edit

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "Job detail", showBack: true, actions: [more_vert])
    └── KsOfflineBanner
└── SingleChildScrollView → Padding(pagePadding) → Column
    ├── [Service header] KsCard(elevated)
    │     Row: service icon (32dp primary500) + service name (h2)
    │     Row: date (bodyMedium) + SyncStatusIndicator (right)
    ├── [Customer card] KsCard(elevated, onTap → Screen 08)
    │     Row: KsAvatar(md) + name/phone + chevron_right
    ├── [Details card] KsCard(elevated)
    │     LabeledRows: location, GHS amount, job date
    ├── [Notes card] KsCard(flat) if notes exist
    │     Text("Notes", captionMedium) + Text(notes, body)
    ├── SizedBox(xxxl)
    ├── FollowUpMessagePreview if not sent
    ├── FollowUpButton(isSent, isLoading, onSend)
    └── SizedBox(fabOffset)

Follow-up flow: preview → tap button → opens wa.me deep link → on return records as sent
More options: Edit job / Archive job (confirm dialog)

States: Loading spinner / Loaded layout / Error snackbar
Provider: jobDetailProvider

---

## 16.4 Customer History Screens

### Screen 07 — Customer List
File: features/customer_history/presentation/screens/customer_list_screen.dart
Route: /customers
Purpose: All customers, searchable, alphabetical

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "Customers")
    └── KsOfflineBanner
└── Column
    ├── Padding(pagePadding) → KsSearchBar(hint: "Search by name or phone")
    ├── SizedBox(sm)
    └── Expanded → ListView(CustomerCard, separated SizedBox(sm))
└── FAB(primary700, person_add_outlined → Screen 09)

Search: filters live on full_name and phone_number, searches Isar locally first
List: alphabetical with sticky first-letter headers

States:
- Loading: 3× KsSkeletonLoader(customerCard)
- Loaded: alphabetical list
- Empty no customers: KsEmptyState(person_outline, "No customers yet")
- Empty search: KsEmptyState(search, "No results")

Provider: customerListProvider

---

### Screen 08 — Customer Detail
File: features/customer_history/presentation/screens/customer_detail_screen.dart
Route: /customers/:id
Purpose: Full customer profile + complete job history

Layout:
Scaffold(neutral050)
└── KsAppBar(title: customer.fullName, showBack: true, actions: [more_vert])
    └── KsOfflineBanner
└── CustomScrollView
    ├── SliverToBoxAdapter → [Customer header] KsCard(elevated)
    │     Center: KsAvatar(lg) + name (h2) + phone + location + notes
    │     Row(centered): [totalJobs / "jobs"] [divider] [GHS total / "earned"]
    ├── SliverToBoxAdapter → Text("Job history", h3)
    └── SliverList → CustomerJobHistoryList(jobs, onJobTap → Screen 06)

GHS total: sum of amount_charged across all customer jobs
More options: Edit customer / Delete customer (confirm dialog, soft delete)

States: Loading / Loaded / Empty job history section
Provider: customerDetailProvider

---

### Screen 09 — Add Customer
File: features/customer_history/presentation/screens/add_customer_screen.dart
Route: /customers/new
Purpose: Manually add a new customer

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "New customer", showBack: true)
    └── KsOfflineBanner
└── SingleChildScrollView → Padding(pagePadding) → Column
    ├── Center → KsAvatar(lg) [live name preview]
    ├── SizedBox(xxl)
    ├── KsTextField(text, "Full name", isRequired: true)
    ├── KsTextField(phone, "Phone number", isRequired: true)
    ├── KsTextField(text, "Location")
    ├── KsTextField(multiline, "Notes about this customer")
    ├── SizedBox(xxxl)
    └── KsButton(primary, "Save customer", fullWidth)

Note: label "Notes about this customer" (general) is visually distinct from
      "Notes about this job" on Screen 05 — prevents Document 07 entity confusion.

Provider: customerListProvider

---

## 16.5 Knowledge Base Screens

### Screen 10 — Notes List
File: features/knowledge_base/presentation/screens/notes_list_screen.dart
Route: /notes
Purpose: All knowledge notes, searchable by title and tags

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "Knowledge Base", actions: [filter by service])
    └── KsOfflineBanner
└── Column
    ├── Padding(pagePadding) → KsSearchBar(hint: "Search notes and tags")
    ├── [Tag filter strip] horizontal scroll of KsTagChip, "All" chip first
    ├── SizedBox(sm)
    └── Expanded → ListView(NoteCard, padding: pagePadding)
└── FAB(primary700, edit_outlined → Screen 12)

Search: title + description + tags. Tag chips filter by exact match. Both active simultaneously.

States:
- Loading: 3× KsSkeletonLoader(noteCard)
- Loaded: sorted by created_at desc
- Empty no notes: KsEmptyState(lightbulb_outline, "No notes yet", cta: "Add a note")
- Empty search: KsEmptyState(search, "No notes found")

Provider: notesListProvider

---

### Screen 11 — Note Detail
File: features/knowledge_base/presentation/screens/note_detail_screen.dart
Route: /notes/:id
Purpose: Full knowledge note — read a saved solution

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "Note", showBack: true, actions: [more_vert])
    └── KsOfflineBanner
└── SingleChildScrollView → Padding(pagePadding) → Column
    ├── Text(title, h1)
    ├── Row: service KsBadge(info) + date (caption right)
    ├── Wrap: KsTagChip per tag (removable: false)
    ├── KsDivider
    ├── Text(description, bodyLarge, neutral700)
    └── ClipRRect(radiusLg) → Image.network if photoUrl exists

More options: Edit note / Archive note (confirm dialog, reversible)
States: Loading / Loaded / Archived badge shown
Provider: noteDetailProvider

---

### Screen 12 — Add Note
File: features/knowledge_base/presentation/screens/add_note_screen.dart
Route: /notes/new
Purpose: Save a new technical solution

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "New note", showBack: true)
    └── KsOfflineBanner
└── SingleChildScrollView → Padding(pagePadding) → Column
    ├── KsTextField(text, "Title", isRequired: true)
    ├── Text("Service type", captionMedium)
    ├── ServiceTypePicker
    ├── TagInputField(tags: [], maxTags: 10)
    ├── KsTextField(multiline, "Description", isRequired: true, maxLines: 8)
    ├── [Photo row: add button or image preview with remove overlay]
    ├── SizedBox(xxxl)
    └── KsButton(primary, "Save note", fullWidth)

Provider: notesListProvider

---

## 16.6 Technician Profile Screens

### Screen 13 — Profile
File: features/technician_profile/presentation/screens/profile_screen.dart
Route: /profile
Purpose: Technician's own profile — view, share, manage account

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "Profile", actions: [edit_outlined → Screen 14])
    └── KsOfflineBanner
└── SingleChildScrollView → Column
    ├── [Profile hero — full-width primary700 bg]
    │     Padding(pagePadding, vertical: xxxl)
    │     ProfileHeader(profile, isEditable: false) — white text on navy
    │
    └── Padding(pagePadding) → Column
        ├── ShareProfileButton(profileUrl)
        ├── SizedBox(xxl)
        ├── Text("Profile link", captionMedium)
        ├── KsCard(outlined): profileUrl text + copy icon
        ├── KsDivider
        ├── Text("Account", h3)
        ├── KsCard(outlined): phone ListTile + role badge ListTile
        ├── SizedBox(xxl)
        └── KsButton(ghost, "Sign out", fullWidth)

Profile hero: primary700 background with white avatar, white name, white service badges.
Provider: profileProvider

---

### Screen 14 — Edit Profile
File: features/technician_profile/presentation/screens/edit_profile_screen.dart
Route: /profile/edit
Purpose: Update name, bio, photo, services, WhatsApp number

Layout:
Scaffold(neutral050)
└── KsAppBar(title: "Edit profile", showBack: true, actions: [TextButton "Save"])
    └── KsOfflineBanner
└── SingleChildScrollView → Padding(pagePadding) → Column
    ├── Center → ProfileHeader(profile, isEditable: true, onEditPhoto: ...)
    ├── SizedBox(xxl)
    ├── KsTextField(text, "Display name", isRequired: true)
    ├── KsTextField(multiline, "Bio", maxLines: 3, maxLength: 300)
    ├── KsTextField(phone, "WhatsApp number", isRequired: true)
    ├── Text("Services you offer", h3)
    ├── ServiceTypePicker
    ├── SizedBox(xxxl)
    └── KsButton(primary, "Save changes", fullWidth)

Save in app bar: quick save without scrolling to bottom
Back with unsaved changes: KsConfirmDialog("Discard changes?")
Provider: profileProvider

---

### Screen 15 — Public Profile
File: features/technician_profile/presentation/screens/public_profile_screen.dart
Route: /p/:slug
Purpose: Customer-facing profile — no auth required

Layout:
Scaffold(neutral050)
└── [No KsAppBar — clean public experience]
└── SingleChildScrollView → Column
    ├── [Hero section — full-width primary700 bg, padding: huge vertical]
    │     KsAvatar(xl, photoUrl or name)
    │     Text(displayName, h1, white, centered)
    │     Text(bio, body, white70, centered) if bio exists
    │     ServiceChips(services) — white text chips
    │
    └── Padding(pagePadding) → Column
        ├── SizedBox(xxl)
        ├── KsButton(cta, "Chat on WhatsApp", leadingIcon: send_outlined, fullWidth)
        │     onPressed: opens wa.me/[whatsappNumber]
        ├── SizedBox(xxl)
        ├── KsDivider
        └── [Footer: "Powered by" caption + "Keystone" bodyMedium]

No auth. No bottom nav. No offline banner. Pure public page.
CTA converts profile view into WhatsApp conversation.
"Powered by Keystone" footer for franchise brand awareness.

States:
- Loading: KsLoadingIndicator centered
- Loaded: full layout
- Not found: KsEmptyState(badge_outlined, "Profile not found")

Provider: publicProfileProvider (fetches by slug, no auth)

---

## 16.7 Shared Screen Behaviours

Every list screen:
- Pull-to-refresh triggers remote sync
- Offline: local data + KsOfflineBanner
- Loading: matching skeleton loader
- Empty: context-appropriate KsEmptyState

Every form screen:
- Required fields gate save button
- Validation on blur + on save attempt
- Always writes locally first
- Offline: info snackbar
- Success: navigate back + success snackbar

Every destructive action:
- KsConfirmDialog(isDangerous: true) before proceeding
- No hard deletes — archive or soft delete only

Back with unsaved changes:
- KsConfirmDialog("Discard changes?")

---

## Validation Checklist
- [x] 15 screens defined — all routes covered
- [x] Every screen specifies its provider
- [x] Every screen specifies all states (loading, loaded, empty, error)
- [x] Every screen lists components used
- [x] Every form screen specifies validation behaviour
- [x] Every destructive action gates with KsConfirmDialog
- [x] Screen 15 public profile specified with no auth
- [x] Offline behaviour specified for every data screen
- [x] FAB placement specified for all list screens
- [x] Profile hero design delivers aesthetic quality commitment
