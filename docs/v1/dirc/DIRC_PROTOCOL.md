# DOMAIN CONCEPTUAL REVIEW PROTOCOL
### Project: Keystone
### Purpose: Structured simulation of the entire system to find logical failures before they reach users
### When to run: Before major releases, after significant changes, when something feels wrong
### Output: Findings report using REVIEW_FINDINGS_TEMPLATE.md

---

## What This Review Is

A Domain Conceptual Review is not a code test. It does not run flutter test. It does not check syntax.

It is a structured simulation where an AI reads all the documentation and asks: does this system actually work in the real world under real conditions for real people?

It catches things that unit tests cannot catch — because unit tests only verify what you already thought of. A conceptual review finds what you forgot to think of.

---

## Who Runs This Review

Any AI with access to the full docs folder can run this review. The AI must read the following documents before starting:

1. docs/v1/00_master_index.md — understand the full project
2. docs/v1/problem/01_problem_brief.md — understand who this is for and why
3. docs/v1/problem/05_user_personas.md — understand Jeremie and Jean specifically
4. docs/v1/systems/06_user_flows.md — understand every user journey
5. docs/v1/systems/08_state_machines.md — understand every state transition
6. docs/v1/systems/09_permission_matrix.md — understand who can do what
7. docs/v1/models/10_validation_rules.md — understand every validation rule
8. docs/v1/implementation/20_error_handling.md — understand every error response
9. docs/v1/dirc/UI_COMPLIANCE_CHECK.md — understand the visual standards
10. docs/v1/dirc/ARCHITECTURE_COMPLIANCE_CHECK.md — understand the structural standards

---

## The Review Methodology

The review runs in 5 passes. Each pass looks at the system from a different angle.

---

### PASS 1 — USER REALITY SIMULATION

Simulate every user flow from Document 06 under real Ghana conditions.

For each flow ask:
- Does this flow make sense for a locksmith technician in Accra?
- What happens if Jeremie is on a job site with no signal?
- What happens if Jean types something unexpected?
- What happens if the app is interrupted mid-flow — phone call, low battery, notification?
- What happens if the same action is triggered twice rapidly?
- Does the error message sense to someone who is not technical?
- Is the flow achievable in under the time specified in the docs?

Conditions to simulate:
- No internet connection
- Slow 2G connection
- Phone runs out of storage
- User enters data in wrong format
- User abandons the flow halfway
- User returns to the app after hours away
- Two actions happen at the same time

---

### PASS 2 — DATA INTEGRITY SIMULATION

Simulate every data flow from UI through domain to database.

For each entity ask:
- Can this data be saved in a state that violates the business rules?
- Can two records conflict with each other?
- What happens when local data and remote data disagree?
- What happens when a sync fails halfway through?
- Is the user_id correctly scoped on every write?
- Can an action by one user affect another user's data?
- Is every required field actually enforced before saving?
- What happens to child records when a parent is deleted?

Entities to check: User, Profile, Customer, Job, KnowledgeNote, FollowUp

---

### PASS 3 — EDGE CASE SIMULATION

Test the boundaries of every rule defined in Document 10.

For each validation rule ask:
- What happens at exactly the boundary — not over, not under, exactly at the limit?
- What happens with special characters in text fields?
- What happens with very long input?
- What happens with emoji in text fields?
- What happens with a Ghana phone number that starts with an unusual prefix?
- What happens if amount charged is entered as text instead of number?
- What happens if the job date is today but in a different timezone?

---

### PASS 4 — STATE MACHINE SIMULATION

Walk through every state transition defined in Document 08.

For each state machine ask:
- Can the system get stuck in an invalid state?
- Can a terminal state be reached accidentally?
- What triggers the transition and is that trigger reliable?
- What happens if the trigger fires but the network fails before the state is saved?
- Is every state visually communicated to the user?
- Can the user recover from every non-terminal bad state?

State machines to check:
- User account status: pending, active, suspended
- Job sync status: pending, synced, failed
- Follow-up status: not sent, sent
- Knowledge note visibility: active, archived
- User role: technician, founding technician, admin

---

### PASS 5 — PERMISSION BOUNDARY SIMULATION

Verify that every permission boundary defined in Document 09 actually holds.

For each permission ask:
- Can a technician access another technician's data through any known path?
- Can a technician escalate their own role?
- Can a suspended user access any feature?
- Is the public profile truly public and is private data truly private?
- Can a follow-up be sent twice for the same job through any known path?
- Can a job be edited after the 24 hour lock through any known path?

---

## After All 5 Passes

Collect all findings and fill in REVIEW_FINDINGS_TEMPLATE.md.
Append the completed template to docs/dirc_log.md.
Fix every finding before the next commit.
Re-run the review after fixes to confirm resolution.

---

## Severity Levels

CRITICAL — system can lose user data or expose one user's data to another
HIGH — a user flow breaks completely under a realistic condition
MEDIUM — a user flow degrades or produces wrong output under a realistic condition
LOW — a minor inconsistency that does not affect core function
INFO — an observation or suggestion that improves quality but is not a defect

---

## Pass Criteria

A domain review passes when:
- Zero CRITICAL findings
- Zero HIGH findings
- All MEDIUM findings have a documented fix plan
- All findings are recorded in dirc_log.md
