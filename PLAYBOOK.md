# Keystone Project Playbook — V1 Snapshot

**Status:** Living document. V1 foundation. Grows with V2, V3, future projects.

This playbook captures how Keystone was built — decisions, processes, lessons that apply beyond this app.

---

## Part 1: Project Setup & Governance

### Environment Separation is Non-Negotiable

**The Rule:** Staging is default. Production requires explicit opt-in.

**Why:** One wrong query can corrupt live user data. Separation costs 5 minutes at setup but saves hours of recovery.

**How we do it:**
- Two Supabase projects (staging + prod)
- All tooling defaults to staging (e.g., `query_db.sh --staging` is default)
- Production requires explicit flag: `query_db.sh --prod` or env var
- Documentation in `GEMINI.md` (system instructions for AI agents working on this codebase)

**For your next project:**
- Set this up on Day 1, not Day 30
- Document the rule in your equivalent of `GEMINI.md`
- Enforce it in code reviews

---

### Documentation as Source of Truth

**The Rule:** Code and docs are committed together. Never separately.

**Why:** Code changes without docs = forgotten decisions. Docs without code = outdated instructions. Both fail teams.

**How we do it:**
- `DOC_UPDATE_GUIDE.md` lists which docs to update for each type of change
- Three docs updated every session: `dev_log.md`, `current_state.md`, `patterns.md`
- Commit message must list docs updated: `"session 30: feature X - docs updated: dev_log.md, current_state.md"`

**For your next project:**
- Create a `DOC_UPDATE_GUIDE.md` template on Day 1
- Train your team: "code + docs, always together"
- Use pre-commit hooks to remind devs

---

## Part 2: Architecture Decisions

### Offline-First Sync: Trust Local State First

**The Pattern:**
1. Write to local storage (Hive) immediately with `sync_status: 'pending'`
2. Return the local entity to UI for instant feedback (Trust Signal)
3. Sync to remote (Supabase) in background
4. Update local `sync_status: 'synced'` on success

**Why:** Users in Ghana have unreliable internet. If the app waits for server, it feels broken. Immediate local confirmation feels fast.

**Critical Detail: Write Conflict Resolution**
When syncing, check if local state has a pending action (e.g., job archived offline). Do NOT overwrite it with remote state. Example:
```
Before sync: remote job.is_archived = false
User archived it offline: local job.is_archived = true, sync_status = pending
On sync refresh: Check local state first. Skip remote overwrite if pending action exists.
```

**For your next project:**
- Always sync TO the server, then FROM the server
- Never let remote writes destroy pending local writes
- Log sync conflicts for debugging

---

### Clean Architecture: Separate Layers, Testable Units

**Structure:**
- **Domain:** Use cases, entities, repository interfaces (no imports from other layers)
- **Data:** Datasources (local + remote), repository implementations, models
- **Presentation:** Screens, providers, widgets

**Why:** Domain layer has zero dependencies. Can be tested with mocks. Easy to swap datasources (e.g., switch from Supabase to Firebase).

**For Keystone:** 6 independent features, each with its own domain/data/presentation folder. Changes in one feature rarely break another.

**For your next project:**
- Start with this structure on Day 1
- Enforce: Domain layer has NO platform code (no Flutter, no HTTP, no database)
- Unit test domain layer heavily

---

### Environment Variables: Never Hardcode, Always `--dart-define`

**The Pattern:**
```dart
static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
```

Build with:
```bash
flutter build web --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
```

**Why:** Credentials are never in code. Different build targets (staging/prod, web/mobile) get different secrets at build time, not runtime.

**For your next project:**
- Use `--dart-define` for ALL environment-specific values (URLs, keys, feature flags)
- Never commit `.env` files
- CI/CD systems pass these as environment variables

---

## Part 3: Debugging & Bug Fixes

### Silent Errors Are Worse Than Loud Errors

**The Mistake:** `try { ... } catch (_) { }` with no logging

**Why It's Bad:** User reports "the app broke" but you have no idea what failed. 6 hours of guessing.

**The Fix:** Always log:
```dart
try {
  await jobRepository.syncPendingJobs();
} catch (e) {
  debugPrint('[SYNC ERROR] $e');
  rethrow;  // or handle gracefully
}
```

**For your next project:**
- Code review: catch every `catch` block
- If you silence an error, you owe a log message
- Use structured logging (tag: category, level: info/warning/error)

---

### Bisect by Layers

When a bug appears:

1. **Is it domain logic?** — Test the use case with mocks, no database
2. **Is it data sync?** — Check local storage and remote queries separately
3. **Is it UI rendering?** — Isolate the widget, test with fake data
4. **Is it auth?** — Check session expiry, token refresh, role checks

Most bugs live in the boundary between layers (data ↔ UI, domain ↔ data).

**For your next project:**
- Know which layer owns each feature
- Test each layer independently before blaming integration

---

## Part 4: Testing Strategies

### Unit Test the Domain, Integration Test the Data, Manual Test the UI

**Domain tests:** Use cases with mocked repositories. Should run in milliseconds. Aim for 90%+ coverage.

**Data tests:** Integration tests hitting a real Supabase instance (or local emulator). Slower but catch real schema issues.

**UI tests:** Manual on-device testing with real users. Screenshots. Forms filled. Jobs logged. Synced. This catches UX bugs that automated tests miss.

**For Keystone:** 36 passing unit tests (formatters, use cases). Integration tests scaffolded but not active. Heavy on-device testing with Jeremie and Jean.

**For your next project:**
- Start with domain unit tests (fast feedback)
- Add integration tests for critical paths (auth, sync, payments)
- Plan manual testing cycles (weekly with real users if possible)

---

## Part 5: Documentation Practices

### Session Logs: Append-Only, Never Edit

Every session gets a dated entry in `dev_log.md`:
- What was built
- What broke and how it was fixed
- What was learned

Never edit past entries. This is your project's memory. A year from now, you'll look back and say "Oh, we fixed this exact bug in Session 7."

**For your next project:**
- Create `dev_log.md` on Day 1
- Log every session, even if it's just "refactored component X"
- Review logs before major decisions (Am I repeating a past mistake?)

---

### Current State: Live Reality Check

`current_state.md` is always today's truth:
- Build status (tests passing? analyze issues? bugs?)
- What's done, what's pending
- Blockers and next action

Update it every session. When someone new joins, they read this and know exactly where you are.

**For your next project:**
- Update `current_state.md` at the end of every workday
- Link to it in Slack/email as "here's what we shipped today"

---

## Part 6: Team Handoff & Onboarding

### The CLAUDE.md File

This file contains system instructions for AI agents (Claude Code, GitHub Copilot, future AI tools) working on your codebase.

**What goes in it:**
- Environment separation rules
- Architectural constraints (always use clean arch, never hardcode secrets)
- Which docs to update for each change type
- Review checklist (flutter analyze must pass, tests must pass, docs updated)

**For Keystone:** We have `GEMINI.md` (internal instructions). For public repos, `CLAUDE.md` is the standard.

**For your next project:**
- Create `CLAUDE.md` early if you use AI tools
- Update it as rules evolve
- Link it in the README

---

## Part 7: Lessons We'll Improve in V2

### Scaling from 1 to 100 Users

V1 was built for 2 users. V2 needs to handle 100 without rewrite.

**Areas to revisit:**
- **Database indexes:** V1 is fine. V2 needs query optimization for 10,000 jobs.
- **Sync efficiency:** Currently fetches all jobs, filters client-side. V2: server-side pagination.
- **Admin dashboard:** V1 has no UI. V2 needs a proper admin panel (role assignment, job review, reports).
- **Analytics:** Scaffolded but not active. V2 activates it for growth insights.
- **Performance:** V1 works on 4G. V2 optimizes for 2G (more aggressive caching, compression).

**For your next project:**
- Build V1 for 10-50 users (premature optimization is death)
- Plan V2 scaling before it becomes urgent
- Document the transition plan in your roadmap

---

## Part 8: Communication & Shipping

### Show Progress Weekly

Every Friday: 10 minutes in a thread/email/Slack:
- 1 thing built
- 1 thing learned
- 1 screenshot or link to test

Users see momentum. Your team stays aligned. Bugs surface early.

**For Keystone:** We shipped to 2 pilot users. They log jobs daily. We see exactly where it breaks.

**For your next project:**
- Pick a cadence (weekly, bi-weekly)
- Include a link users can test
- Celebrate small wins (bug fixed, test passing, doc updated)

---

## Part 9: When to Stop & Ship

### V1 is Good Enough When

- Core feature works (V1: job logging ✓)
- Real users can use it (V1: Jeremie & Jean ✓)
- You've fixed the top 3 bugs (V1: sync issues, keyboard focus, light mode ✓)
- Docs exist so next person can understand it (V1: 40+ docs ✓)

V2 features: Play Store, SMS OTP, analytics, admin dashboard, multi-language.

**For your next project:**
- Define "V1 done" before you start (usually: core feature + 2 real users + basic docs)
- Resist feature creep into V1
- Ship V1, get feedback, build V2

---

## Summary: The Keystone Principle

**Build narrow and deep, not wide and shallow.**

V1 did ONE thing: help locksmiths log jobs and share their profile. It does that well — offline, sync, public web link. Everything else is V2.

For your next project:
1. Pick ONE core feature
2. Make it work for 5-10 real users
3. Document the journey
4. Ship it
5. Learn from feedback
6. Build V2 wider

That's how Keystone was built. That's how it'll scale.

---

**Last Updated:** Session 30 (March 20, 2026)

**Next Update:** When V2 starts (new major decisions) or major incident (lessons learned)
