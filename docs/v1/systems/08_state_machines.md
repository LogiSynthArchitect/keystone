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
| active | suspended | Admin | Violation of platform rules or manual action |
| suspended | active | Admin | Issue resolved — manual reactivation |

---

## State Machine 2 — Job Sync & Lock Lifecycle

**Entity:** Job
**Field:** sync_status, is_locked

### States

| State | Description | Is Terminal? |
|---|---|---|
| pending | Job saved locally — not yet synced to cloud | No |
| synced | Job successfully saved to cloud | No |
| locked | Job synced AND > 24 hours old. Fields are read-only. | Yes* |

### Allowed Transitions

| From | To | Triggered By | Condition Required |
|---|---|---|---|
| pending | synced | System | Internet available and cloud confirms save |
| synced | locked | System | 24 hours pass since creation |
| locked | synced | Admin | Approved Correction Request (Temporary Unlock) |

*Note: Locked is terminal for the technician, but can be bypassed by an Admin via Correction Request.

---

## State Machine 3 — Correction Request Lifecycle

**Entity:** CorrectionRequest
**Field:** status

### States

| State | Description | Is Terminal? |
|---|---|---|
| pending | Request submitted by tech — awaiting review | No |
| approved | Admin accepted the change — job updated | Yes |
| rejected | Admin denied the change | Yes |

### Allowed Transitions

| From | To | Triggered By | Condition Required |
|---|---|---|---|
| pending | approved | Admin | Admin clicks APPROVE in dashboard |
| pending | rejected | Admin | Admin clicks REJECT in dashboard |

---

## State Machine 4 — Follow-up Status

**Entity:** Job
**Fields:** follow_up_sent

### States

| State | Description | Is Terminal? |
|---|---|---|
| not_sent | No follow-up triggered | No |
| sent | Technician opened WhatsApp via Keystone | Yes |

### Allowed Transitions

| From | To | Triggered By | Condition Required |
|---|---|---|---|
| not_sent | sent | User | User taps 'Send WhatsApp' |

---

## State Machine 5 — KnowledgeNote Visibility

**Entity:** KnowledgeNote
**Field:** is_archived

### States

| State | Description | Is Terminal? |
|---|---|---|
| active | Visible in main list | No |
| archived | Hidden from main list | No |

### Allowed Transitions

| From | To | Triggered By | Condition Required |
|---|---|---|---|
| active | archived | User | User chooses to archive |
| archived | active | User | User restores from archived view |

---

## Complete State Summary

User.status: pending → active ⇄ suspended
Job.sync: pending → synced → locked
Correction: pending → approved | rejected
Job.follow_up: not_sent → sent
KnowledgeNote: active ⇄ archived
