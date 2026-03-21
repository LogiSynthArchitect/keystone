# Universal Project Documentation Template

Applies to any project: Flutter, React Native, React, Node.js, Python, any platform.
Platform-agnostic. Scale up or down based on project type.

---

## Project Types

Before setting up, identify your project type:

| Type | Description | Repo Setup |
|---|---|---|
| **A — Public Portfolio** | Open source, building in public, showcase | Two repos (private + public) |
| **B — Private/Commercial** | Client work, company project, confidential | One private repo only |
| **C — Solo Internal** | Personal tool, no audience | One private repo only |

---

## Files That MUST Exist in Every Project (No Exceptions)

These files exist regardless of project type A, B, or C.

### Root Level

```
README.md               — What the project is, how to run it, links
AGENTS.md               — AI agent instructions (always private, never public)
PLAYBOOK.md             — Lessons learned (keep private if confidential project)
```

### docs/tracking/ (Always Private)

```
dev_log.md              — Append-only session log (date, built, broke, learned)
current_state.md        — Live project status (done, pending, blockers)
open_bugs.md            — Known bugs and their status
```

### docs/

```
docs/patterns.md        — Reusable patterns discovered during development
docs/systems/           — Architecture decisions (1 file minimum)
docs/models/            — Data model or schema (1 file minimum)
```

---

## Files That Are OPTIONAL (Based on Project Type)

### Only for Public Portfolio Projects (Type A)

```
PUBLIC_ROADMAP.md       — V1 done, V2 planned (public vision)
CONTRIBUTING.md         — How contributors should work on the project
CONTENT_STRATEGY.md     — LinkedIn/social media content guide
CONTENT_CALENDAR.md     — Track what has been posted (private)
```

### Only for Multi-Developer or Company Projects (Type B)

```
docs/onboarding.md      — How a new team member gets up to speed
docs/decisions/         — Architecture Decision Records (ADRs)
docs/runbook.md         — How to deploy, rollback, handle incidents
```

### Only When Using Two Repos (Type A)

```
scripts/push-private.sh     — Backup everything to private repo
scripts/publish-public.sh   — Push clean version to public repo
```

---

## The 3 Files Updated Every Single Session

No exceptions. These keep the project alive.

```
1. docs/tracking/dev_log.md
   → APPEND: date, what was built, what broke, what was learned
   → NEVER edit past entries — it is a log, not a living document

2. docs/tracking/current_state.md
   → REWRITE: exact status as of today
   → What is done, what is pending, what is blocked, next action

3. docs/patterns.md
   → ADD: any new pattern, fix, or decision discovered this session
   → Skip only if truly nothing new was learned
```

---

## Source Code Folder Structure (Platform-Specific)

The naming changes per platform but the concept is the same:
one folder per feature, each feature has its own layers.

### Flutter

```
lib/
  core/               — shared utilities, theme, providers, router
  features/
    feature_name/
      domain/         — entities, use cases, repository interfaces
      data/           — models, datasources, repository implementations
      presentation/   — screens, providers, widgets
  main.dart
```

### React / React Native

```
src/
  core/               — shared utilities, theme, hooks, context
  features/
    feature_name/
      domain/         — types, business logic, service interfaces
      data/           — API calls, local storage, service implementations
      presentation/   — components, screens, state (hooks/context/redux)
  App.tsx
```

### Node.js / Backend

```
src/
  core/               — shared middleware, config, errors, utilities
  features/
    feature_name/
      domain/         — entities, use cases, repository interfaces
      data/           — repository implementations, external services
      routes/         — HTTP handlers and validation
  app.ts
```

### Rule (Any Platform)

- `core/` = shared across ALL features (never import from a feature)
- `features/` = isolated. One feature does NOT import from another directly
- Communication between features = through `core/` shared providers or events
- Each feature is independently testable with mocks

---

## AGENTS.md Minimum Content (Required Sections)

Every AGENTS.md must contain at minimum:

```
1. Project overview (what it is, who it is for, current status)
2. Environment rules (staging vs production — never default to production)
3. Session start protocol (what to read first, in order)
4. Architecture rules (folder structure, layer rules, patterns)
5. Documentation rules (which files to update, when)
6. Push/repo rules (what is private, what is public)
7. Hard rules (what never to do)
```

---

## The Readiness Test

> "If a new developer — human or AI — reads only:
> `README.md`, `AGENTS.md`, `current_state.md`, and the last 3 entries of `dev_log.md`
> they should be fully operational in under 10 minutes."

If they cannot, the documentation is incomplete.

---

## Minimum Setup Checklist (New Project)

Copy this and complete before writing any code:

```
Day 1 Setup:
[ ] Create README.md (project name, what it does, tech stack)
[ ] Create AGENTS.md (environment rules, architecture rules, session protocol)
[ ] Create docs/tracking/dev_log.md (first entry: project created)
[ ] Create docs/tracking/current_state.md (initial state: scaffolding)
[ ] Create docs/tracking/open_bugs.md (empty for now)
[ ] Create docs/patterns.md (empty for now)
[ ] Create docs/systems/architecture.md (initial architecture decision)
[ ] Set up repo (private only, or private + public if Type A)

If Type A (Public Portfolio), also:
[ ] Create PUBLIC_ROADMAP.md
[ ] Create CONTRIBUTING.md
[ ] Create PLAYBOOK.md
[ ] Set up scripts/push-private.sh and scripts/publish-public.sh
```

---

**Last Updated:** March 21, 2026
**Maintained by:** LogiSynthArchitect
