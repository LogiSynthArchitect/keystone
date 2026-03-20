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

---

## Full File Map — What Updates When

This is the definitive map of every file in docs/ and when it changes.

### ALWAYS updated every session (no exceptions):
| File | Why |
|---|---|
| `docs/v1/tracking/current_state.md` | Session number, date, build status, bug table |
| `docs/v1/tracking/dev_log.md` | Append-only session entry |

### Updated when bugs are found and fixed:
| File | Why |
|---|---|
| `docs/v1/tracking/open_bugs.md` | New bug entries with status |
| `docs/v1/tracking/DIAGNOSTIC_MANUAL.md` | Cause + remedy writeups for each bug category |

### Updated when screens change or features are added:
| File | Why |
|---|---|
| `docs/v1/implementation/25_v1_polish.md` | Screen status, feature additions, session additions |
| `docs/v1/00_master_index.md` | Last Updated date, status line, verification counts |

### Updated when new lessons are learned:
| File | Why |
|---|---|
| `docs/patterns.md` | New reusable pattern with context/problem/solution/applies-to |

### Updated when a formal domain review is run:
| File | Why |
|---|---|
| `docs/dirc_log.md` | DIRC entry using REVIEW_FINDINGS_TEMPLATE.md |

### FROZEN — never update unless the thing itself changes:
| File | Frozen because |
|---|---|
| `docs/v1/problem/01–05` | Problem definition, market research, personas — set at project start |
| `docs/v1/systems/04,06,08,09,13,17,19` | Architecture blueprints — only change if architecture changes |
| `docs/v1/models/07,10,11,12` | Domain model + DB schema — only change if schema changes |
| `docs/v1/design/UI_UX_SYSTEM.md` | Design constitution — frozen |
| `docs/v1/testing/18_testing_strategy.md` | Testing strategy — frozen unless strategy changes |
| `docs/v1/roadmap/23_product_roadmap.md` | Roadmap — frozen at V1 |
| `docs/v1/migration/` | Historical migration plan — frozen |
| `docs/v1/dirc/DIRC_PROTOCOL.md` etc. | Protocol templates — frozen |
| `docs/v1/tracking/admin_runbook.md` | Admin procedures — only change if procedures change |
| `docs/v1/tracking/query_standards.md` | SQL standards — only change if standards change |
| `docs/v1/tracking/linkedin_roadmap.md` | Content roadmap — only change if content plan changes |
| `docs/v1/tracking/22_monitoring_analytics.md` | Analytics plan — frozen |
| `docs/v1/implementation/14_design_system.md` | Moved to UI_UX_SYSTEM.md — do not edit |
| `docs/v1/implementation/16_screen_inventory.md` | Screen list — frozen at 16 screens |
| `docs/v1/implementation/20_error_handling.md` | Error handling — only change if approach changes |
| `docs/v1/implementation/21_deployment_strategy.md` | Deployment config — only change if hosting changes |
| `docs/v1/implementation/24_implementation_guide.md` | Implementation guide — frozen unless stack changes |
