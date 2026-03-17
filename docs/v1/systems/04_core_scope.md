# DOCUMENT 04 — CORE SCOPE DEFINITION
### Project: Keystone
**Required Inputs:** Document 01 — Problem Brief, Document 03 — Core Hypothesis
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 4.1 Core Features V1

Every feature listed here is required because without it Keystone does not solve
the core problem defined in Document 01. Nothing extra. Nothing aspirational.

---

**Feature 1 — Job Logging**
What it does: Allows a technician to record a completed job in under 60 seconds.
Why it is required: The core problem is that technicians lose customer and job information
after every job. This feature is the direct solution.
Acceptance Criteria:
- Technician can log a job with customer name, phone number, location, service type,
  job notes, and amount charged
- Logging takes under 60 seconds from opening the screen to saving
- Job is saved locally first and syncs to cloud when connection is available
- Technician receives confirmation that the job was saved

---

**Feature 2 — Customer History**
What it does: Shows a technician every job ever done for a specific customer in one place.
Why it is required: Technicians currently have no way to see past work for a returning
customer. This feature makes every returning customer call more valuable.
Acceptance Criteria:
- Technician can search for a customer by name or phone number
- All past jobs for that customer are displayed in chronological order
- Each job entry shows service type, date, location, notes, and amount charged
- Search returns results in under 2 seconds

---

**Feature 3 — Knowledge Base**
What it does: Allows a technician to save technical solutions, bypass codes, and
job-specific notes that can be searched and retrieved later by job type or keyword.
Why it is required: Technical knowledge discovered on difficult jobs is currently lost
permanently. This feature is unique — no competitor offers it. It is a core retention
driver and a genuine competitive advantage.
Acceptance Criteria:
- Technician can create a knowledge note with a title, description, tags, and optional photo
- Notes are searchable by keyword, tag, and service type
- Notes are private to each technician — not shared by default in V1
- Technician can find any saved note in under 10 seconds by searching a keyword

---

**Feature 4 — WhatsApp Follow-up**
What it does: Allows a technician to send a professional follow-up message to a customer
via WhatsApp with one tap after a job is completed.
Why it is required: Follow-up is the primary mechanism for generating repeat business.
Technicians currently never follow up. This feature makes it effortless.
Acceptance Criteria:
- After logging a job, technician sees a one-tap button to send a WhatsApp follow-up
- The message is pre-written professionally in a template format
- Tapping the button opens WhatsApp with the customer number and message pre-filled
- Technician can edit the message before sending
- Templates are available in English — Twi support in V2
- Uses WhatsApp deep links (wa.me) — no API approval required in V1

---

**Feature 5 — Technician Profile**
What it does: Gives each technician a simple shareable profile showing their name,
services offered, and contact information.
Why it is required: Technicians currently have no professional presence. A shareable
link replaces the verbal explanation and works as passive advertising on WhatsApp.
Acceptance Criteria:
- Profile shows technician name, photo, services offered, and WhatsApp contact button
- Profile is accessible via a unique shareable link
- Link can be shared directly from the app to WhatsApp or any other platform
- Profile is viewable in a browser without downloading any app
- Technician can update their profile at any time

---

**Feature 6 — Income & Earnings Summary**
What it does: Displays a real-time tactical summary of monthly and total earnings on the main dashboard.
Why it is required: Motivating technicians to log jobs by showing immediate financial progress.
Acceptance Criteria:
- Dashboard shows "THIS MONTH" earnings in GHS.
- Data updates instantly when a job is saved.
- Uses monospace typography for financial trust.

---

**Feature 7 — Admin Correction Terminal**
What it does: Provides a secure in-app dashboard for admins to approve or reject job correction requests.
Why it is required: Ensures data integrity while allowing for the correction of human errors without direct SQL intervention.
Acceptance Criteria:
- Accessible only to users with the 'admin' role.
- List of pending correction requests with technician reasons.
- One-tap "APPROVE" updates the target job automatically.

---

## 4.2 Excluded Features — V1 Backlog

**Excluded: Team Collaboration Between Jeremie and Jean**
Why excluded: Each technician operates their own independent workspace in V1.
When to reconsider: V2 — after both technicians use V1 consistently for 60+ days.

**Excluded: New Technician Onboarding and Validation System**
Why excluded: The franchise model and technician validation flow is a V3 feature.
When to reconsider: V3 — when the first external technician wants to join.

**Excluded: Automated Scheduled Follow-up Reminders**
Why excluded: V1 uses manual one-tap WhatsApp follow-ups. Automated scheduling
requires backend job scheduling infrastructure not needed for two users.
When to reconsider: V2 — when WhatsApp Business API is integrated properly.

**Excluded: Social Media Post Generation**
Why excluded: Valuable marketing feature but not part of the core problem.
When to reconsider: V2 — after the core loop is validated.

**Excluded: Customer Ratings and Reviews**
Why excluded: Reviews require a customer-facing interface which is V3.
When to reconsider: V3 — when the platform has multiple technicians.

**Excluded: Customer Booking and Appointment Scheduling**
Why excluded: Marketplace feature requiring customer accounts and notification systems.
When to reconsider: V3 — when platform has enough technicians to justify it.

**Excluded: In-App Payments and Invoicing**
Why excluded: Payment processing requires Bank of Ghana compliance and business
registration not justified for V1.
When to reconsider: V2/V3 — after business is formally registered.

**Excluded: Multi-language Support (Twi, French)**
Why excluded: English is sufficient for V1 with Jeremie and Jean.
When to reconsider: V2 — before expanding beyond the founding technicians.

**Excluded: Analytics Dashboard (Advanced)**
Why excluded: Basic earnings are included in V1. Deep analytics require more data.
When to reconsider: V2 — when there are enough jobs to show meaningful patterns.

**Excluded: CCTV and Electrical Work Tracking**
Why excluded: Not core to V1 services — car lock programming, door lock, smart lock.
When to reconsider: V2 — as an additional service type option in job logging.

---

## 4.3 Core System Loop

Step 1 — TRIGGER
Technician completes a job at a customer location

Step 2 — ACTION
Technician opens Keystone and logs the job in under 60 seconds
(customer name, phone, service type, quick note, amount)

Step 3 — RESULT
Job is saved. Technician taps one button to send a professional
WhatsApp follow-up to the customer automatically.

Step 4 — RETURN
Customer calls back for a repeat job.
Technician searches their name in Keystone and sees full history
before answering — prepared and professional.

Everything in V1 exists to support this loop.
Everything outside this loop is excluded from V1.

---

## 4.4 Platform Scope

V1 Platform: Mobile App — Android First
- Android only in V1 — 80.9% of Ghanaian smartphone users are on Android
- iOS is excluded from V1 — Jeremie and Jean use Android devices
- No web dashboard in V1 — everything happens on the phone
- Offline-first — app must work without internet and sync when connected
- iOS and web dashboard considered for V2

Technology approach: Flutter — Clean Architecture — Feature-First

Framework: Flutter
- Single codebase — Android V1, iOS in V2, web dashboard in V3
- No rebuild required when expanding platforms

Architecture: Clean Architecture with Feature-First folder structure
- Every feature is a completely self-contained module
- UI is fully separated from business logic
- Business logic is fully separated from data layer
- One file = one class = one responsibility — no exceptions

Folder structure:
lib/
├── core/
│   ├── theme/
│   ├── router/
│   ├── constants/
│   └── utils/
│
├── features/
│   ├── job_logging/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── customer_history/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── knowledge_base/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── whatsapp_followup/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── technician_profile/
│       ├── data/
│       ├── domain/
│       └── presentation/

Architecture rules — never break these:
- Presentation layer talks to domain layer only — never to data directly
- Domain layer has zero Flutter dependencies — pure Dart only
- Data layer handles all external communication — database, APIs, device storage
- Features never import directly from other features
- Features communicate only through core shared layer
- No file handles more than one responsibility

---

## 4.5 Integration Scope

Required for V1 launch:
- WhatsApp deep links (wa.me) — one-tap customer follow-up — Low risk
- Firebase or Supabase — backend data storage and auth — Low risk
- Google Maps or OpenStreetMap — job location tagging — Low risk

Optional for V1 — not blocking launch:
- WhatsApp Business API — automated scheduled messages — V2
- MTN Mobile Money — subscription payments — V2/V3
- Meta Business API — social media post generation — V2

Single points of failure:
- WhatsApp availability — if down, follow-up can be done by copying pre-written message
- Backend service — if down, jobs queue locally and sync on recovery via offline-first arch

---

## 4.6 Out of Scope — Hard Boundaries for V1

The following will NOT be built or supported in V1 under any circumstances:
- No customer-facing interface of any kind
- No web application or desktop version
- No iOS version
- No multi-technician team features
- No payment processing of any kind
- No external technician onboarding
- No automated message scheduling
- No advanced analytics or reporting dashboards
- No social media integration
- No CCTV or electrical service categories
- No customer accounts or login
- No booking or appointment system

If a feature is not in Section 4.1 it does not exist in V1.
No exceptions. No quick additions. No scope creep.

---

## Validation Checklist
- [x] Every feature maps directly to the core problem in Document 01
- [x] The core system loop is exactly 4 steps
- [x] Every excluded feature has a documented reason and a phase for reconsideration
- [x] Platform scope is explicit — Android only, offline-first, Flutter
- [x] Clean Architecture with Feature-First structure is documented
- [x] Single points of failure are identified with mitigations
- [x] Hard boundaries are clearly listed with no ambiguity
