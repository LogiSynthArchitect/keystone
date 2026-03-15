# DOCUMENT 08 — STATE MACHINES
### Project: Keystone
**Required Inputs:** Document 07 — Domain Model, Document 06 — Core User Flow
**Location:** Ghana, West Africa
**Date:** 2026
**Status:** APPROVED

---

## State Machine 1 — User Account Status

**Entity:** User
**Field:** status

### States

| State | Description | Is Terminal? |
|---|---|---|
| pending | Account created but not yet verified or activated | No |
| active | Account is fully operational — can use all features | No |
| suspended | Account temporarily disabled — cannot use any features | No |

### Allowed Transitions

| From | To | Triggered By | Condition Required |
|---|---|---|---|
| pending | active | System | User completes onboarding and saves profile |
| active | suspended | Admin or Founding Technician | Violation of platform rules or manual action |
| suspended | active | Admin or Founding Technician | Issue resolved — manual reactivation |

### Invalid Transition Behavior
- pending → suspended: Not allowed — account cannot be suspended before activation
- suspended → pending: Not allowed — once activated never returns to pending
- Any invalid transition returns a silent failure — no state change occurs

### Side Effects
- pending → active: Profile made public, profile URL becomes accessible
- active → suspended: Profile URL returns 404, all features disabled, user sees suspension message on login
- suspended → active: Profile URL restored, all features re-enabled, user notified

### Terminal States
None — a suspended account can always be reactivated by an admin

---

## State Machine 2 — Job Sync Status

**Entity:** Job
**Field:** sync_status

Jobs are always saved locally first. Sync status tracks
whether the cloud copy is up to date.

### States

| State | Description | Is Terminal? |
|---|---|---|
| pending | Job saved locally — not yet synced to cloud | No |
| synced | Job successfully saved to cloud | No |
| failed | Sync attempted but failed — local copy exists, cloud copy missing | No |

### Allowed Transitions

| From | To | Triggered By | Condition Required |
|---|---|---|---|
| pending | synced | System | Internet available and cloud confirms save |
| pending | failed | System | Sync attempted but cloud returned error or timeout |
| failed | pending | System | Internet connection restored — retry queued |
| pending | pending | System | Retry in progress — stays pending until confirmed |

### Invalid Transition Behavior
- synced → pending: Not allowed
- synced → failed: Not allowed
- Any invalid transition is silently ignored

### Side Effects
- pending → synced: Sync indicator disappears from job card
- pending → failed: Small warning indicator on job card — not an error alert
- failed → pending: Retry queued silently

### Retry Rules
- Retry automatically every time internet connection is detected
- Maximum 3 automatic retries before marking as failed permanently
- After 3 failures show non-blocking warning: "Some jobs could not sync. Data is safe on your device."
- User can manually trigger sync from settings at any time

### Terminal States
None — sync can always be retried

---

## State Machine 3 — Follow-up Status

**Entity:** Job
**Fields:** follow_up_sent (Boolean) and follow_up_sent_at (Timestamp)

### States

| State | Description | Is Terminal? |
|---|---|---|
| not_sent | No follow-up has been triggered for this job | No |
| sent | Technician tapped Send via WhatsApp — follow-up recorded | Yes |

### Allowed Transitions

| From | To | Triggered By | Condition Required |
|---|---|---|---|
| not_sent | sent | User | Technician taps Send via WhatsApp inside Keystone |

### Invalid Transition Behavior
- sent → not_sent: Not allowed — a sent follow-up cannot be unsent
- Second follow-up attempt on same job: Show message "Follow-up already sent on [date]"

### Side Effects
- not_sent → sent: follow_up_sent set to true, follow_up_sent_at set to now,
  FollowUp entity created, job card shows follow-up sent badge

### V1 Limitation
The sent state means the technician tapped the button in Keystone and WhatsApp was opened.
It does NOT confirm the message was actually sent in WhatsApp.
Resolved in V2 with WhatsApp Business API.

### Terminal States
sent — once recorded as sent it cannot be reversed

---

## State Machine 4 — KnowledgeNote Visibility

**Entity:** KnowledgeNote
**Field:** is_archived

### States

| State | Description | Is Terminal? |
|---|---|---|
| active | Note visible in main knowledge base list | No |
| archived | Note hidden from main list but not deleted | No |

### Allowed Transitions

| From | To | Triggered By | Condition Required |
|---|---|---|---|
| active | archived | User | Technician chooses to archive the note |
| archived | active | User | Technician restores the note from archived view |

### Side Effects
- active → archived: Note disappears from main list, accessible via Archived filter
- archived → active: Note reappears in main list sorted by updated_at

### Terminal States
None — archived notes can always be restored

### Why No Delete?
Knowledge notes are never permanently deleted in V1.
A technician may archive a note thinking it is no longer useful
then need it months later. Hard delete is excluded from V1 entirely.

---

## State Machine 5 — User Role Progression

**Entity:** User
**Field:** role

### States (Roles)

| Role | Description | Is Terminal? |
|---|---|---|
| technician | Standard platform member — V2/V3 feature | No |
| founding_technician | Jeremie or Jean — platform validators with elevated access | No |
| admin | Developer — full system access | Yes |

### Allowed Transitions

| From | To | Triggered By | Condition Required |
|---|---|---|---|
| technician | founding_technician | Admin only | Manual promotion — exceptional cases only |
| founding_technician | technician | Admin only | Manual demotion — exceptional cases only |

### Invalid Transition Behavior
- Any role → admin: Not allowed through the app — set directly in database only
- technician → founding_technician: Cannot be self-requested — admin action only
- Any user changing their own role: Forbidden — returns 403 error

### Side Effects
- technician → founding_technician: User gains validation privileges in V3
- founding_technician → technician: User loses validation privileges, retains all personal data

### Terminal States
admin — cannot be changed through the application

---

## Complete State Summary

User.status
pending → active ⇄ suspended

Job.sync_status
pending → synced
pending → failed → pending (retry loop)

Job.follow_up_sent
not_sent → sent (terminal)

KnowledgeNote.is_archived
active ⇄ archived (fully reversible)

User.role
technician ⇄ founding_technician (admin action only)
admin (terminal — database only)

---

## Validation Checklist
- [x] Every stateful entity from Document 07 has a defined state machine
- [x] All valid transitions documented with conditions
- [x] All invalid transitions documented with behaviors
- [x] Side effects defined for every transition
- [x] Terminal states identified
- [x] V1 limitations documented honestly
- [x] Retry rules for sync defined
- [x] Role progression documented for future phases
