# ARCHITECTURE COMPLIANCE CHECK
### Project: Keystone
### Purpose: Verify that the codebase structure matches the documented architecture
### Reference: docs/v1/systems/13_flutter_architecture.md
### Run as part of: Every Domain Conceptual Review

---

## What This Check Does

This check verifies that every file in the lib/ folder complies with the Clean Architecture rules documented in Document 13. It finds violations — features importing each other directly, presentation layer touching datasources, domain layer with Flutter imports, use cases doing more than one thing.

---

## The Architecture Rules — Non-Negotiable

Rule 1: Presentation never imports from Data layer
Rule 2: Domain has zero Flutter imports — pure Dart only
Rule 3: Features never import directly from other features
Rule 4: Features communicate only through lib/core/providers/shared_feature_providers.dart
Rule 5: One file — one class — one responsibility
Rule 6: Every use case has exactly one call() method
Rule 7: Every repository interface lives in domain — implementation lives in data
Rule 8: All external dependencies injected via Riverpod — never instantiated directly in widgets

---

## The Compliance Checks

### Check 1 — Domain Layer Purity
For every file in lib/features/*/domain/:
[ ] Zero imports from package:flutter
[ ] Zero imports from package:supabase_flutter
[ ] Zero imports from hive or any storage package
[ ] Only imports from dart: core packages and other domain files

### Check 2 — Presentation Layer Boundaries
For every file in lib/features/*/presentation/:
[ ] Zero imports from lib/features/*/data/ in the same feature
[ ] Zero direct datasource instantiation
[ ] All data access goes through providers

### Check 3 — Cross Feature Isolation
For every feature folder:
[ ] No direct imports from lib/features/[other_feature]/
[ ] All cross-feature data access goes through shared_feature_providers.dart
[ ] shared_feature_providers.dart is the only bridge

### Check 4 — Use Case Single Responsibility
For every use case file:
[ ] Exactly one public method — call()
[ ] No more than one repository dependency
[ ] Validation logic only — no UI logic — no formatting logic

### Check 5 — Repository Interface Compliance
For every repository:
[ ] Abstract interface exists in domain/repositories/
[ ] Implementation exists in data/repositories/
[ ] Presentation layer only ever references the interface — never the implementation

### Check 6 — Naming Convention Compliance
[ ] All files are snake_case
[ ] All classes are PascalCase
[ ] All providers end in Provider
[ ] All notifiers end in Notifier
[ ] All screens end in Screen
[ ] All use cases end in Usecase
[ ] All entities end in Entity
[ ] All models end in Model

### Check 7 — Offline-First Compliance
For every feature that writes data:
[ ] Local write always happens before remote write
[ ] Remote failure does not throw to UI
[ ] SyncStatus is set correctly for every write operation
[ ] Pending records are picked up by sync on reconnection

---

## How To Run This Check

Step 1: Run flutter analyze and confirm zero errors
Step 2: Check each rule manually or by reading the relevant files
Step 3: For cross-feature imports run:
        grep -r "import.*features" lib/features/ | grep -v "shared_feature_providers"
        Any result that crosses feature boundaries is a violation

Step 4: For Flutter imports in domain run:
        grep -r "import.*flutter" lib/features/*/domain/
        Any result is a violation

Step 5: Document every violation using the format below

---

## How To Report Findings

For every violation found, document it as:

FILE: [lib/features/.../filename.dart]
RULE VIOLATED: [Rule number and description]
WHAT IS WRONG: [description of the violation]
WHAT IT SHOULD BE: [correct implementation]
SEVERITY: [CRITICAL if data leak risk / HIGH if architecture broken / MEDIUM if naming only]
