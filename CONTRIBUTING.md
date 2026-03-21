# Contributing to Keystone

Thanks for your interest in Keystone! Before you contribute, read this guide.

---

## What We're Building

Keystone is offline-first job management software for independent service technicians. We're focused on real users in the field — not hypothetical users or future features.

**Core Principle:** Build narrow and deep. One problem, solved well.

---

## How to Contribute

### 1. Understand the Problem First

Read these before coding:
- `README.md` — What Keystone does
- `docs/v1/problem/01_problem_brief.md` — The problem we're solving
- `docs/v1/systems/04_core_scope.md` — What's in scope for V1/V2

**Why:** Features that seem obvious might break the focus. We say "no" to good ideas that aren't *the* problem.

### 2. Check the Roadmap

See `PUBLIC_ROADMAP.md`. If your idea is V2 or beyond, note it. If it's V1, check if it's already happening.

**Open an issue first.** Don't code features in isolation.

### 3. Follow the Architecture

Keystone uses clean architecture:
- **Domain:** Use cases, entities (pure, testable, no dependencies)
- **Data:** Repositories, datasources, models
- **Presentation:** Screens, providers, widgets

Read `docs/v1/systems/13_flutter_architecture.md` for details.

**Why:** This separation lets us swap backends, test independently, and maintain sanity as the codebase grows.

### 4. Offline-First is Sacred

Any data persistence must consider:
1. Write to local storage first (Hive)
2. Sync to remote (Supabase) in background
3. Resolve conflicts: local pending state > remote state

See `PLAYBOOK.md` Part 2 for the full pattern.

**Don't:** Ignore sync status. Design new features assuming internet is always available.

### 5. Test, Test, Test

- **Unit tests** for domain layer (use cases, formatters)
- **Integration tests** for data layer (Hive + Supabase interactions)
- **Manual testing** with real workflows (log a job, check sync, verify data)

Run: `flutter test` before committing.

### 6. Document Changes

When you change code, update docs:
- `docs/v1/tracking/DOC_UPDATE_GUIDE.md` lists what needs updating
- Commit message must mention docs updated
- Code + docs always go together

**Why:** Code without docs is a mystery. A year from now, you won't remember why you did this.

---

## What We Won't Accept

1. **Features that don't solve the core problem** — Keystone is about job logging + customer tracking, not a full CRM
2. **Code without tests** — Especially in domain layer
3. **Hardcoded values or credentials** — Use environment variables
4. **Changes that break offline-first** — Rethink your approach if it needs internet
5. **Complex abstractions for one-time use** — Keep it simple

---

## Code Review Standards

When you submit a PR, it will be reviewed against:
- ✓ `flutter analyze` passes (no lint errors)
- ✓ `flutter test` passes (all tests)
- ✓ Code follows clean architecture (domain/data/presentation)
- ✓ Docs are updated alongside code
- ✓ Commit message is clear and concise
- ✓ No hardcoded secrets or sensitive data

---

## Questions?

1. **Architecture questions** — Read `docs/v1/systems/` folder
2. **Feature scope questions** — Check `PUBLIC_ROADMAP.md`
3. **Patterns & lessons** — See `PLAYBOOK.md` and `docs/patterns.md`
4. **Debugging** — `docs/v1/tracking/DIAGNOSTIC_MANUAL.md`

---

## Thank You

Building Keystone with real users has taught us a lot. Contributing helps us build something real, used, and maintained well.

If you have questions, open an issue. If you want to add something, discuss first.

---

**Last Updated:** March 21, 2026
