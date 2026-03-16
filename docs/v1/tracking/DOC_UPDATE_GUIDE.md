# DOCUMENTATION UPDATE GUIDE
### Project: Keystone
### Purpose: Protocol for any AI or developer to keep documentation alive after every session
### Rule: Documentation and code must always be committed together — never separately

---

## The Core Rule

Every time you make a change to this project — code, design, database, tests — you must update the relevant documentation before committing. A commit without updated docs is an incomplete commit.

---

## What Triggers A Documentation Update

| Trigger | Files To Update |
|---|---|
| Any code change | dev_log.md, current_state.md |
| New bug found and fixed | DIAGNOSTIC_MANUAL.md, dev_log.md |
| New screen built or redesigned | 25_v1_polish.md, current_state.md, 00_master_index.md |
| New test written | current_state.md, 00_master_index.md |
| Database schema change | 12_database_schema.md, dev_log.md |
| New pattern or lesson learned | patterns.md, DIAGNOSTIC_MANUAL.md |
| Domain review completed | dirc_log.md, current_state.md |
| Architecture decision changed | 13_flutter_architecture.md, dev_log.md |
| New feature added | 04_core_scope.md, 24_implementation_guide.md, current_state.md |
| Design decision changed | 14_design_system.md, 25_v1_polish.md |
| Dependency added or removed | 24_implementation_guide.md, dev_log.md |
| Deployment config changed | 21_deployment_strategy.md |
| Error handling changed | 20_error_handling.md |

---

## The Files That Are Updated Most Frequently

These files change every single session without exception:

### 1. docs/v1/tracking/current_state.md
Updated after every session. Always reflects today's reality.
Must contain:
- Current flutter analyze status
- Current flutter test count and pass rate
- List of screens done and pending
- List of what remains to reach the project goal
- The single next action

### 2. docs/v1/tracking/dev_log.md
Append-only. Never edit previous entries. Only add new ones.
Every new entry must contain:
- Session number and date
- What was built
- What broke and how it was fixed
- What was learned
- Flutter analyze status
- Test status

### 3. docs/v1/tracking/DIAGNOSTIC_MANUAL.md
Updated whenever a new bug is found and fixed.
Every new entry must contain:
- The context where the error occurs
- The cause of the error
- The exact remedy with code if applicable

---

## The Files That Are Updated When Relevant

### 4. docs/v1/implementation/25_v1_polish.md
Update whenever a screen is redesigned or a feature addition is completed.
Check off items in the checklist. Add new items if discovered.

### 5. docs/v1/00_master_index.md
Update whenever:
- A new document is added to the docs folder
- A screen status changes from pending to done
- Test counts change significantly
- Major project status changes

### 6. docs/patterns.md
Update whenever a lesson is learned that applies beyond this project.
Write it as a reusable pattern with context, problem, solution, and applies-to.

### 7. docs/dirc_log.md
Update after every domain review is completed.
Use the template in REVIEW_FINDINGS_TEMPLATE.md

---

## The Pre-Commit Checklist

Before every git commit run through this checklist:

CODE CHANGES
[ ] flutter analyze — zero errors
[ ] flutter test — all passing
[ ] No hardcoded credentials in any file

DOCUMENTATION
[ ] current_state.md reflects today's reality
[ ] dev_log.md has a new entry for this session
[ ] DIAGNOSTIC_MANUAL.md updated if new bugs were found and fixed
[ ] 25_v1_polish.md updated if screens were changed
[ ] patterns.md updated if new lessons were learned
[ ] Any other relevant docs updated per the trigger table above

GIT
[ ] git add -A — all files staged including docs
[ ] Commit message includes what was done, what tests pass, what docs were updated

---

## The Commit Message Format

Use this format every time:

session [N]: [one line summary]

- [what was built or changed]
- [what broke and was fixed if anything]
- [test count: X passing Y failing]
- [docs updated: list the files]

---

## What Never Gets Committed Without Docs

- A new screen without updating 25_v1_polish.md and current_state.md
- A fixed bug without updating DIAGNOSTIC_MANUAL.md and dev_log.md
- A new test without updating current_state.md
- A database change without updating 12_database_schema.md
- A new pattern learned without updating patterns.md

---

## The Golden Rule

If an AI or developer cannot find where something was decided, why it was done, or what broke before — the documentation failed. Keep the docs alive. The code is temporary. The decisions are permanent.
