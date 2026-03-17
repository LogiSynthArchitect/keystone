# CROSS-PROJECT PATTERNS & LESSONS
### Project: Keystone
### Purpose: Lessons learned that apply to any future project using similar stack

---

## Pattern 01 — Supabase CLI Installation on Linux
**Context:** Pop OS Linux, Node v24
**Problem:** npm install -g supabase fails. curl install script returns 404.
**Solution:** Always use binary download for Supabase CLI on Linux:
  wget -qO- https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar xvz -C /tmp
  sudo mv /tmp/supabase /usr/local/bin/supabase
**Applies to:** Any Linux machine running Supabase CLI

---

## Pattern 02 — mocktail Requires Fallback Values for Custom Types
**Context:** Flutter unit tests with mocktail
**Problem:** any() matcher throws TypeError when used with custom domain entities
**Solution:** Always register fallback values before using any() with custom types:
  class FakeJobEntity extends Fake implements JobEntity {}
  setUpAll(() { registerFallbackValue(FakeJobEntity()); });
**Applies to:** Any Flutter project using mocktail

---

## Pattern 03 — Platform Interface Mocks Need MockPlatformInterfaceMixin
**Context:** Mocking url_launcher or any Flutter plugin platform interface
**Problem:** implements alone causes assertion failure from plugin_platform_interface
**Solution:** Always use the mixin:
  class MockUrlLauncher extends Mock with MockPlatformInterfaceMixin implements UrlLauncherPlatform {}
**Applies to:** Any Flutter project mocking platform interface plugins

---

## Pattern 04 — Supabase CLI db execute Does Not Exist in 2.x
**Context:** Trying to run raw SQL via Supabase CLI
**Problem:** supabase db execute command not found in CLI 2.78.1
**Solution:** Create a named migration and push it:
  supabase migration new your_description
  Write SQL into supabase/migrations/[timestamp]_your_description.sql
  supabase db push --linked
**Applies to:** Any project using Supabase CLI 2.x

---

## Pattern 05 — Clean Architecture Test Isolation
**Context:** Testing use cases in Clean Architecture Flutter projects
**Pattern:** Each use case test needs exactly three things:
  1. A mock of the repository interface it depends on
  2. A Fake class for each custom entity type used with any()
  3. A setUp block that creates fresh mocks before each test
**Result:** Tests run with zero network, zero database, zero Flutter binding needed
**Applies to:** Any Clean Architecture Flutter project

---

## Pattern 06 — Dark Industrial Design Wave Redesign
**Context:** Systematically migrating a legacy or generic UI to a high-signal industrial aesthetic.
**Pattern:** 
  1. Define a "Command Surface" (Bottom Action Bar with InkWell).
  2. Switch background to deepest navy/black (primary900).
  3. Use primary800 for content modules with sharp 4px radii.
  4. Global replacement of Material Icons with LineAwesomeIcons.
  5. Enforce 600+ font weight for high-contrast visibility.
**Result:** Professional tool feel that reads well in direct sunlight.
**Applies to:** Professional/Industrial tool apps.

---

## Pattern 07 — Offline-First Repository Coordination
**Context:** Handling data writes in unreliable network conditions (e.g., Accra job sites).
**Pattern:** 
  1. Write to local storage (Hive) immediately with a 'pending' status.
  2. Return the local entity to the UI for immediate feedback (The "Trust Signal").
  3. Trigger background sync to remote (Supabase).
  4. Update local storage status to 'synced' upon success.
**Result:** Zero latency for the user; guaranteed eventual consistency.
**Applies to:** Any offline-capable Flutter app.
