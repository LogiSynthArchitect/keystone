# DOCUMENT 10 — VALIDATION RULES
### Project: Keystone
**Required Inputs:** Document 07 — Domain Model, Document 08 — State Machines
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## 10.1 Field Validation Rules

### Entity: User

| Field | Rule | Error Message |
|---|---|---|
| full_name | Required. Min 2 characters. Max 100 characters. Emojis and standard symbols allowed. | "Please enter your full name." |
| phone_number | Required. Must be valid Ghana format: 024XXXXXXX, 054XXXXXXX, 055XXXXXXX, 059XXXXXXX, 020XXXXXXX, 050XXXXXXX or international format +233XXXXXXXXX. No spaces or dashes. | "Please enter a valid Ghana phone number." |
| email | Optional. If provided must be valid email format. Max 255 characters. | "Please enter a valid email address." |
| password | Required. Min 6 characters. No maximum. At least one number. | "Password must be at least 6 characters and include one number." |
| role | Required. Must be one of: technician, founding_technician, admin. | System field — not user-facing. |
| status | Required. Must be one of: pending, active, suspended. | System field — not user-facing. |
| profile_slug | Auto-generated. Must be unique. Lowercase letters, numbers, and hyphens only. Max 50 characters. | System field — not user-facing. |

**Password Note:**
Minimum 6 characters not 8. Ghanaian informal workers are not accustomed to complex
password requirements. Matches MTN Mobile Money PIN complexity expectations.

---

### Entity: Profile

| Field | Rule | Error Message |
|---|---|---|
| display_name | Required. Min 2 characters. Max 100 characters. | "Please enter your display name." |
| bio | Optional. Max 300 characters. | "Bio cannot exceed 300 characters." |
| photo_url | Optional. If provided must be a valid HTTPS URL pointing to cloud storage. Max 500 characters. | "Profile photo could not be saved. Please try again." |
| services | Required. Must contain at least one valid service type from the enum. Max 10 services. | "Please select at least one service you offer." |
| whatsapp_number | Required. Must match same rules as User.phone_number. | "Please enter a valid WhatsApp number." |
| is_public | Required. Must be boolean true or false. | System field — not user-facing. |

---

### Entity: Customer

| Field | Rule | Error Message |
|---|---|---|
| full_name | Required. Min 2 characters. Max 100 characters. | "Please enter the customer name." |
| phone_number | Required. Must be valid phone format — Ghana or international. Must be unique per technician (user_id scope). | "Please enter a valid phone number." / "This customer is already in your list." |
| location | Optional. Max 255 characters. Free text. | "Location is too long." |
| notes | Optional. Max 1000 characters. Free text. | "Notes cannot exceed 1000 characters." |

---

### Entity: Job

| Field | Rule | Error Message |
|---|---|---|
| customer_id | Required. Must reference a valid Customer owned by the same user_id. | System field — customer selected from list. |
| service_type | Required. Must be one of the defined enum values. | "Please select a service type." |
| job_date | Required. Must be today or a past date. Cannot be a future date. | "Job date cannot be in the future." |
| location | Optional. Max 255 characters. | "Location is too long." |
| latitude | Optional. If provided must be valid float between -90 and 90. | System field — set by map pin. |
| longitude | Optional. If provided must be valid float between -180 and 180. | System field — set by map pin. |
| notes | Optional. Max 2000 characters. Free text. | "Notes cannot exceed 2000 characters." |
| amount_charged | Optional. If provided must be positive number greater than 0. Max 99999.99 GHS. Max 2 decimal places. | "Please enter a valid amount." / "Amount cannot be negative." |

---

### Entity: KnowledgeNote

| Field | Rule | Error Message |
|---|---|---|
| title | Required. Min 3 characters. Max 200 characters. | "Please enter a title for this note." |
| description | Required. Min 10 characters. No maximum. | "Please add a description to this note." |
| tags | Optional. Each tag min 2 max 30 characters. Max 10 tags per note. Lowercase only. No spaces — use underscores. | "Tag must be between 2 and 30 characters." / "Maximum 10 tags per note." |
| photo_url | Optional. Valid HTTPS URL. Image types: jpg, jpeg, png, webp. Max 5MB before compression. | "Photo could not be saved. Please try again." |
| service_type | Optional. If provided must be one of the defined enum values. | System field — selected from dropdown. |

---

### Entity: FollowUp

| Field | Rule | Error Message |
|---|---|---|
| job_id | Required. Must reference valid Job owned by same user_id. One follow-up per job only. | System field — not user-facing. |
| message_text | Required. Min 10 characters. Max 1000 characters. | System field — pre-filled from template. |
| sent_at | Required. Auto-set to current timestamp when record is created. | System field. |

---

## 10.2 Business Logic Rules

**Rule 1 — Duplicate Customer Prevention**
Condition: Technician enters a phone number that already exists in their customer list.
Behavior: Show inline suggestion — "This looks like [Customer Name]. Use existing customer?"
If Yes: Link job to existing customer.
If No: Allow creation of new customer entry with same number.
Rationale: A customer may have two numbers — do not force deduplication.

**Rule 2 — Job Date Lock After 24 Hours**
Condition: Technician tries to edit service_type or job_date more than 24 hours after creation.
Behavior: Fields are read-only. Show tooltip: "Service type and date cannot be changed after 24 hours."
Rationale: Prevents historical record manipulation.
*Note (V1/V2 Correction Path):* If a genuine error was made, corrections must be requested manually through a Founding Technician, who will forward the request for an admin database update until an `is_verified` or correction request flow is introduced in V2.

**Rule 3 — Single Follow-up Per Job**
Condition: Technician tries to trigger a second follow-up on a job with follow_up_sent = true.
Behavior: Show message: "You already sent a follow-up for this job on [date]. To send another message, open WhatsApp directly."
Rationale: Prevents accidental duplicate messages to customers.

**Rule 4 — Minimum Job Fields**
Condition: Technician taps Save Job without filling required fields.
Behavior: Highlight empty required fields inline. No popup alerts.
Required: customer name or selection, phone number, service type.
All other fields optional — never block saving.
Rationale: 60-second job logging requirement — friction must be minimal.

**Rule 5 — Profile Must Have At Least One Service**
Condition: Technician tries to save profile with no services selected.
Behavior: Show inline message: "Please select at least one service you offer."
Rationale: A profile with no services listed is not useful for customers.

**Rule 6 — Offline Job Queue**
Condition: Technician logs a job with no internet connection.
Behavior: Save locally immediately with sync_status = pending.
No error or warning at time of save. Small sync indicator on job card only.
Sync automatically when connection is restored.
Rationale: Technicians work in areas with inconsistent connectivity.

**Rule 7 — Amount in Ghana Cedis Only**
Condition: Technician enters an amount charged.
Behavior: Currency is always GHS — no currency selection in V1.
Display as GHS [amount] — example: GHS 150.00
Rationale: V1 is Ghana-only. Multi-currency is a V3 consideration.

**Rule 8 — Knowledge Note Tag Normalization**
Condition: Technician enters a tag with uppercase letters or spaces.
Behavior: Automatically convert to lowercase and replace spaces with underscores.
Example: "Car Programming" becomes "car_programming"
Rationale: Consistent tags improve search accuracy.

---

## 10.3 State Transition Rules

**Transition: User pending → active**
All must be true:
- full_name is not empty
- phone_number is valid
- At least one service type selected in Profile
- Profile display_name is not empty
If any fails: Keep in pending state, show which field is incomplete.

**Transition: Job sync_status pending → synced**
All must be true:
- Internet connection is available
- Backend confirms successful write
- Local record ID matches cloud record ID
If any fails: Move to failed, queue retry.

**Transition: Job follow_up_sent false → true**
All must be true:
- Job has a valid customer with a phone number
- Customer phone number is not empty
- Job has not already had a follow-up sent
If any fails: Show specific error explaining why follow-up cannot be sent.

**Transition: User active → suspended**
All must be true:
- Action triggered by admin or founding_technician
- Reason documented in database
- User being suspended is not an admin
If any fails: Return 403 forbidden.

**Transition: KnowledgeNote active → archived**
No conditions required — any active note can be archived at any time.
Archive is always reversible.

---

## 10.4 Input Sanitization Rules

**All text fields:**
- Trim leading and trailing whitespace before saving
- Strip HTML tags — no HTML allowed in any field
- Strip script tags — no JavaScript allowed in any field

**Phone number fields:**
- Remove all spaces, dashes, and parentheses before validation
- Normalize 0 prefix to +233: 0244123456 → +233244123456
- Store in normalized format: +233XXXXXXXXX

**Profile slug:**
- Auto-generated from full_name
- Convert to lowercase, replace spaces with hyphens
- Remove all special characters except hyphens
- If slug exists append number: jeremie → jeremie-2

**Amount field:**
- Remove any currency symbols entered by user
- Remove commas used as thousand separators
- Round to 2 decimal places
- Example: GHS 1,500 → 1500.00

**Tags:**
- Convert to lowercase
- Replace spaces with underscores
- Remove special characters
- Deduplicate — if same tag entered twice keep one

**Photo uploads:**
- Compress images automatically before upload — target under 500KB
- Convert all images to JPEG for consistency
- Strip EXIF data — remove GPS and device metadata for privacy

---

## Domain Concept Challenge — All Passed
- Every field in Document 07 has a validation rule
- Every user flow in Document 06 has a validation backing
- Every state transition in Document 08 has conditions defined
- Every business rule in Document 09 has a validation backing
- Ghana context validated throughout
- All rules implementable as pure Dart in Flutter domain layer

---

## Validation Checklist
- [x] Every entity field has a validation rule
- [x] Every rule has a specific error message
- [x] Business rules cover all edge cases from user flows
- [x] State transition conditions complete and match Document 08
- [x] Input sanitization covers all field types
- [x] Password requirement calibrated for Ghanaian user context
- [x] Offline behavior validated — never blocks saving
- [x] Currency locked to GHS for V1
