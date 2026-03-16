# DOMAIN REVIEW FINDINGS TEMPLATE
### Project: Keystone
### Purpose: Standardized output format for every domain review
### Instructions: Copy this template, fill it in, append to docs/dirc_log.md

---

## REVIEW HEADER

Review ID: DIRC-[NUMBER]
Date: [DATE]
Reviewer: [AI name and model / Developer name]
Trigger: [What triggered this review — pre-release / post-change / scheduled / concern]
Scope: [What was reviewed — full system / specific feature / UI only / architecture only]
Documents Read: [List every document read before starting]

---

## PASS 1 — USER REALITY SIMULATION

### Findings

[List each finding in this format]

ID: P1-001
Severity: [CRITICAL / HIGH / MEDIUM / LOW / INFO]
Flow affected: [Which user flow from Document 06]
Condition: [What real world condition triggered this]
Finding: [What is wrong]
Expected: [What should happen]
Actual: [What actually happens]
Fix: [Recommended fix]
Status: [OPEN / FIXED / ACCEPTED RISK]

---

## PASS 2 — DATA INTEGRITY SIMULATION

### Findings

[Same format as Pass 1]

---

## PASS 3 — EDGE CASE SIMULATION

### Findings

[Same format as Pass 1]

---

## PASS 4 — STATE MACHINE SIMULATION

### Findings

[Same format as Pass 1]

---

## PASS 5 — PERMISSION BOUNDARY SIMULATION

### Findings

[Same format as Pass 1]

---

## UI COMPLIANCE CHECK FINDINGS

[For each non-compliant screen]

ID: UI-001
Screen: [Screen name]
File: [lib/features/.../screen_name.dart]
Rule violated: [Rule from UI_COMPLIANCE_CHECK.md]
Finding: [What is wrong]
Fix: [What it should be]
Status: [OPEN / FIXED / ACCEPTED RISK]

---

## ARCHITECTURE COMPLIANCE CHECK FINDINGS

[For each architecture violation]

ID: ARCH-001
File: [lib/features/.../filename.dart]
Rule violated: [Rule from ARCHITECTURE_COMPLIANCE_CHECK.md]
Finding: [What is wrong]
Fix: [What it should be]
Status: [OPEN / FIXED / ACCEPTED RISK]

---

## SUMMARY

Total findings: [NUMBER]
Critical: [NUMBER]
High: [NUMBER]
Medium: [NUMBER]
Low: [NUMBER]
Info: [NUMBER]

Overall status: [PASS / FAIL / CONDITIONAL PASS]

Pass criteria:
- PASS: Zero critical, zero high
- CONDITIONAL PASS: Zero critical, high findings have fix plan
- FAIL: One or more critical findings open

---

## ACTION PLAN

Priority 1 — Fix immediately before any commit:
[List CRITICAL findings]

Priority 2 — Fix before next release:
[List HIGH findings]

Priority 3 — Fix in next session:
[List MEDIUM findings]

---

## SIGN OFF

Review completed: [DATE TIME]
Next review scheduled: [DATE or TRIGGER]
Appended to dirc_log.md: [YES / NO]
