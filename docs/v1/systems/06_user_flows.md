# DOCUMENT 06 — CORE USER FLOW
### Project: Keystone
**Required Inputs:** Document 04 — Core Scope Definition, Document 05 — User Personas
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## Flow 1 — Onboarding (First Time Setup)

**Persona:** Jeremie or Jean
**Goal:** Get the app set up and ready to use in under 10 minutes
**Entry Point:** Opens app for the first time after installation

| Step | Actor | Action | System Response | Notes / Edge Cases |
|---|---|---|---|---|
| 1 | User | Opens app for the first time | Show welcome screen with Keystone logo and single CTA: Get Started | Keep it minimal — no feature tour |
| 2 | User | Taps Get Started | Show profile setup screen | Ask only: name, phone number, profile photo optional, services offered |
| 3 | User | Enters name and phone number | Validate phone number format | Phone number is used for WhatsApp integration — must be valid |
| 4 | User | Selects services offered | Show service type options as multi-select | Car Lock and Key Programming, Door Lock Installation and Repair, Smart Lock Installation |
| 5 | User | Taps Save Profile | System creates account, generates unique profile link, saves locally and syncs | Show success confirmation — profile is live |
| 6 | System | Profile created | Show home dashboard with empty state | Empty state must feel welcoming not broken |
| 7 | User | Sees home dashboard for first time | System shows a single prompt: Log your first job | Guide them directly to the core loop |

**Happy Path Summary:**
Technician opens app, enters name, phone, selects services, saves profile, lands on dashboard ready to log first job — all in under 3 minutes.

**Key Decision Points:**
- Step 3: If phone number is invalid — show inline error and ask to correct
- Step 4: If no service is selected — show reminder but do not block progress

**Error Paths:**
- No internet on first open: Allow full onboarding offline, sync profile when connection returns
- Profile photo upload fails: Skip photo silently, technician can add it later from settings

**Drop-off Risks:**
- Asking too many questions during onboarding — only ask what is absolutely needed
- Showing a complex dashboard before the technician has logged anything

---

## Flow 2 — Log a Job (Core Loop)

**Persona:** Jeremie or Jean
**Goal:** Record a completed job in under 60 seconds
**Entry Point:** Technician has just completed a job at a customer location

| Step | Actor | Action | System Response | Notes / Edge Cases |
|---|---|---|---|---|
| 1 | User | Taps Log Job button on home dashboard | Open job logging screen | Button must be the most prominent element on the dashboard |
| 2 | User | Enters customer name | System searches existing customers as user types | If customer exists show suggestion — tap to auto-fill their details |
| 3 | User | Enters customer phone number | Validate phone number format | Auto-filled if returning customer was selected in step 2 |
| 4 | User | Selects service type | Show service type options as quick-select chips | One tap selection |
| 5 | User | Enters job location | Text field with optional map pin | Optional — not required |
| 6 | User | Enters job notes | Free text field — optional | Short or long — technician decides |
| 7 | User | Enters amount charged | Numeric field in GHS | Optional in V1 |
| 8 | User | Taps Save Job | System saves job locally immediately | Do not wait for cloud sync — save locally first always |
| 9 | System | Job saved | Show success confirmation with two options: Send WhatsApp Follow-up or Done | Always offer follow-up immediately after saving |
| 10 | User | Chooses Send WhatsApp Follow-up or Done | If follow-up: proceed to Flow 3. If Done: return to dashboard | |

**Happy Path Summary:**
Technician taps Log Job, enters customer name, phone, selects service type, adds quick note, taps Save — job recorded in under 60 seconds.

**Key Decision Points:**
- Step 2: Returning customer found — auto-fill reduces friction significantly
- Step 9: Technician can skip follow-up — it is offered not forced

**Error Paths:**
- No internet: Job saves locally, syncs automatically when connection returns
- Required fields missing: Highlight missing field with inline message — no popup alerts
- Duplicate customer phone detected: Show suggestion to confirm or create new entry

**Drop-off Risks:**
- Too many required fields — only name, phone, and service type are truly required
- Slow save — must feel instant because it saves locally first

---

## Flow 3 — Send WhatsApp Follow-up

**Persona:** Jeremie or Jean
**Goal:** Send a professional follow-up message to a customer after a job with one tap
**Entry Point:** Job has just been saved or technician opens a past job

| Step | Actor | Action | System Response | Notes / Edge Cases |
|---|---|---|---|---|
| 1 | System | Job saved successfully | Show follow-up screen with pre-written message template | Message pre-filled with customer name, service type, technician contact |
| 2 | User | Reviews pre-written message | See the full message ready to send | Message must sound human and professional — not robotic |
| 3 | User | Edits message if needed (optional) | Text field is editable | Technician may want to add a personal touch |
| 4 | User | Taps Send via WhatsApp | System opens WhatsApp with customer number and message pre-filled via wa.me deep link | WhatsApp opens automatically |
| 5 | User | Sends message inside WhatsApp | WhatsApp delivers message to customer | This step happens inside WhatsApp not inside Keystone |
| 6 | User | Returns to Keystone | System marks follow-up as sent on the job record | Technician sees confirmation that follow-up was recorded |

**Pre-written Message Template (English V1):**
Hello [Customer Name], thank you for choosing our locksmith service today.
We completed [Service Type] for you. If you have any issues within 7 days
please contact us and we will resolve it at no extra cost.
Save this number for future locksmith needs. — [Technician Name], Keystone

**Happy Path Summary:**
After saving a job, technician sees pre-written professional message, taps Send via WhatsApp, WhatsApp opens with message ready, technician sends in one tap.

**Error Paths:**
- WhatsApp not installed: Show option to copy text and send manually
- Customer phone number invalid: Show error — go back and correct in job record
- Technician closes WhatsApp without sending: Keystone cannot confirm delivery in V1 — this is a known limitation of deep link integration. WhatsApp Business API in V2 will confirm delivery.

**Drop-off Risks:**
- If opening WhatsApp feels like too many steps technicians will skip it
- Pre-written message must feel natural — robotic messages will not be used

---

## Flow 4 — Search Customer History

**Persona:** Jeremie or Jean
**Goal:** Find everything done for a specific customer before answering their call
**Entry Point:** Technician receives a call and wants to check history

| Step | Actor | Action | System Response | Notes / Edge Cases |
|---|---|---|---|---|
| 1 | User | Opens Keystone and taps Customers or uses search | Show customer search screen | Accessible from home dashboard in one tap |
| 2 | User | Types customer name or phone number | Show matching results as user types | Results appear after first character — instant search |
| 3 | User | Taps on customer from results | Show customer profile with all past jobs listed chronologically | Most recent job at the top |
| 4 | User | Reviews job history | See each job with service type, date, location, notes, and amount | All information visible without extra taps |
| 5 | User | Taps on a specific job | Show full job detail including all notes | Notes field is where the important details live |
| 6 | User | Taps WhatsApp button on customer profile | Opens WhatsApp chat with that customer directly | Quick access to contact customer from inside the app |

**Happy Path Summary:**
Customer calls, technician opens app, types name, sees full history in under 5 seconds, answers the call prepared and professional.

**Error Paths:**
- No internet: Search works offline — all customer data stored locally
- Customer not found: Show clear empty state — this person has not been logged yet
- Multiple customers with same name: Show all matches differentiated by phone number

**Drop-off Risks:**
- Slow search — must be instant, data is local
- Too many taps to reach customer history — maximum 2 taps from home

---

## Flow 5 — Save a Knowledge Note

**Persona:** Jeremie or Jean
**Goal:** Save a technical solution discovered on a difficult job so it can be found later
**Entry Point:** Technician has just solved a difficult or unusual problem

| Step | Actor | Action | System Response | Notes / Edge Cases |
|---|---|---|---|---|
| 1 | User | Taps Knowledge Base from home dashboard | Show knowledge base screen with notes and Add Note button | Empty state prompts to save first note |
| 2 | User | Taps Add Note | Open new note screen | Title, description, tags, optional photo |
| 3 | User | Enters note title | Free text field | Example: Toyota Corolla 2018 key programming bypass |
| 4 | User | Enters note description | Free text — no character limit | Full technical detail goes here |
| 5 | User | Adds tags | Tag input with common suggestions | Car Programming, Door Lock, Smart Lock, Bypass, Tip |
| 6 | User | Adds photo (optional) | Open camera or gallery picker | Photo of tool, wiring diagram, or lock mechanism |
| 7 | User | Taps Save Note | System saves locally and syncs to cloud | Confirm save with brief success message |
| 8 | User | Returns to knowledge base | See new note in the list | Sorted by most recently added by default |

**Search Flow (Finding a Note Later):**
- User opens Knowledge Base and types keyword or tag
- System shows matching notes instantly
- User taps note to see full detail and photo

**Happy Path Summary:**
Technician solves difficult job, opens Knowledge Base, taps Add Note, writes title and description, adds tags, saves — note stored and searchable forever.

**Error Paths:**
- No internet: Note saves locally, syncs when connection returns
- Photo too large: Compress automatically — do not show an error
- Note saved with no tags: Allowed — technician can edit and add tags later

**Drop-off Risks:**
- If adding a note feels like too much writing technicians will skip it
- Title field must be prominent — a good title is all that is needed for basic value
- Search must work fast — if notes are not findable the feature fails

---

## Flow 6 — View and Share Technician Profile

**Persona:** Jeremie or Jean
**Goal:** Share professional profile link with a new customer via WhatsApp
**Entry Point:** New customer asks what services the technician offers

| Step | Actor | Action | System Response | Notes / Edge Cases |
|---|---|---|---|---|
| 1 | User | Taps Profile from home dashboard | Show technician profile screen | Name, photo, services, WhatsApp contact button |
| 2 | User | Taps Share Profile | Show share options | Share via WhatsApp, copy link, or any installed share target |
| 3 | User | Taps Share via WhatsApp | WhatsApp opens with profile link and short message pre-filled | Message: Here is my professional profile — [link] |
| 4 | User | Sends to customer in WhatsApp | Customer receives link | Customer opens link in browser — no app download required |
| 5 | Customer | Opens profile link in browser | Sees technician name, photo, services, and WhatsApp contact button | Simple web page — loads fast on slow connections |
| 6 | Customer | Taps WhatsApp contact button | Opens WhatsApp chat with the technician | Customer can now contact technician directly |

**Happy Path Summary:**
New customer asks what Jeremie does. Jeremie opens Keystone, taps Share Profile, sends WhatsApp message with link. Customer opens link and sees professional profile in browser.

**Error Paths:**
- Customer on very slow connection: Profile page must be lightweight — under 200KB
- Technician has no profile photo: Show placeholder — profile still works

**Drop-off Risks:**
- Profile link must look professional and load fast
- Must work perfectly on low-end Android browsers used in Ghana

---

## Complete Flow Summary

ONBOARDING
Open app — Setup profile — Land on dashboard — Prompted to log first job

CORE LOOP (runs daily)
Complete job — Log job in 60 sec — Send WhatsApp follow-up in 1 tap — Customer returns

KNOWLEDGE (runs when needed)
Difficult job solved — Open knowledge base — Save note — Find it months later

CUSTOMER LOOKUP (runs when customer calls)
Customer calls — Search name or number — See full history — Answer prepared

PROFILE SHARING (runs when meeting new customers)
New customer asks — Share profile link via WhatsApp — Customer sees professional profile

---

## WhatsApp Integration Note
V1 uses WhatsApp deep links (wa.me) — free, no API approval needed, works immediately
V2 upgrades to WhatsApp Business API via 360dialog — approximately $11 USD per month
This upgrade enables automated scheduled follow-ups and delivery confirmation

---

## Validation Checklist
- [x] Every persona from Document 05 has at least one flow
- [x] Every flow starts from zero and reaches core value delivery
- [x] Error paths are defined for every flow
- [x] Drop-off risks are identified for every flow
- [x] Every step has both a user action and a system response
- [x] No step in any flow references a feature outside Document 04 scope
- [x] Offline behavior is defined in every flow
- [x] All 5 V1 features are covered across the 6 flows
