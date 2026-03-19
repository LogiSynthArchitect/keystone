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

---

## Pattern 08 — Tactical Step-by-Step Wizards
**Context:** High-density forms in specialized technical tools.
**Problem:** Long single-page forms increase cognitive load and error rates in the field.
**Pattern:**
  1. Break input into logical "Logistics," "Entity," and "Financial" steps.
  2. Implement a global "Step Indicator" (e.g., 01 / 03).
  3. Toggle the bottom action bar between "NEXT" and "SAVE".
  4. Use AnimatedSwitcher for high-performance visual transitions.
**Result:** Higher data quality and reduced user fatigue.
**Applies to:** Field-entry professional applications.

---

## Pattern 09 — Data Trust via Monospace Typography
**Context:** Displaying financial or sensitive identification data (GHS, Phone Numbers).
**Problem:** Standard proportional fonts make columns of numbers look "wavy" and less professional.
**Pattern:**
  1. Use `FontFeature.tabularFigures()` or a Monospace font family for all numeric data.
  2. Increase letter spacing slightly for maximum readability in high-glare environments.
**Result:** UI feels like an official ledger or physical receipt, increasing trust in the system.
**Applies to:** Fintech or professional ledger applications.

---

## Pattern 10 — Global Theme Synchronization & Component Integrity
**Context:** Scaling a "Dark Industrial" aesthetic across a Flutter codebase with legacy or third-party components.
**Problem:** Hardcoding backgrounds in individual screens leaves global components (e.g., Dialogs, SearchBars, TextFields) with white/light defaults, causing "white-on-white" visibility issues.
**Solution:**
  1. Define a strict global `ThemeData` with `brightness: Brightness.dark` and `scaffoldBackgroundColor`.
  2. Map all `InputDecorationTheme` and `CardTheme` to brand-compliant primary/secondary colors.
  3. Update global `AppTextStyles` to default to white or high-contrast accent colors.
  4. Use a shared `KsSearchBar` and `KsConfirmDialog` instead of generic Material variants to ensure 100% theme compliance.
**Result:** Unified visual language with zero "bleeding" from default light-theme values.
**Applies to:** Any project migrating from a default theme to a highly customized aesthetic.

---

## Pattern 11 — Data Integrity for Tactical Dashboards
**Context:** Calculating real-time summaries (e.g., "THIS MONTH") from a local-first offline database.
**Problem:** Default fetch limits in repositories (e.g., 25) can omit newer/older records from local calculations if the database grows beyond the limit.
**Solution:**
  1. Increase fetch limits for summary-critical data (e.g., 200+ for Jobs).
  2. Implement robust date comparisons in state getters that account for timezone/parsing variations (e.g. YYYY-MM-DD vs UTC).
  3. Use `CurrencyFormatter` consistently at the presentation layer to prevent "Pesewas vs GHS" multiplier display errors.
**Result:** Reliable, "Battle-Ready" dashboard readouts that technicians can trust for financial planning.
**Applies to:** Any offline-first app with financial or time-series dashboards.

---

## Pattern 12 — Lightweight Web Entry Points
**Context:** Hosting specific app features (like Public Profiles) on the web without the overhead of the full mobile application.
**Problem:** The full mobile app often contains dependencies (Analytics, Local Storage, Mobile-only plugins) that cause compilation errors or performance lag on Flutter Web.
**Solution:**
  1. Create a `lib/main_web.dart` file that acts as a "Lite" gateway.
  2. Isolate web-specific data providers (e.g., `public_profile_provider.dart`) that fetch data via REST instead of heavy mobile repositories.
  3. Use the `--target lib/main_web.dart` flag during the Flutter Web build.
**Result:** 10x faster build times, zero compilation errors from mobile dependencies, and a significantly smaller payload for web visitors.
**Applies to:** Any Flutter project using a "Web Portal" or "Public Profile" strategy.

---

## Pattern 13 — Resilient Offline-First Synchronization
**Context:** Mobile clients syncing local drafts to a remote SQL backend via RPC.
**Problem:** A single fatal error (network timeout, auth expiry) in a batch sync shouldn't mark all jobs as "Failed". 
**Solution:**
  1. The Repository MUST only mark jobs as "Failed" if the server explicitly rejects them with an error message.
  2. All other exceptions (connectivity, database locked) MUST keep the jobs in "Pending" status.
  3. The RPC function MUST return a mapping of `local_id` to `server_id` to ensure the app can reconcile its local cache without data loss.
**Result:** Higher user trust and less manual "Sign Failed" troubleshooting.

---

## Pattern 14 — Environment Sanctity & Mandate-Driven AI Safety
**Context:** AI Agents and developers working on multi-environment projects (Staging/Prod).
**Problem:** High risk of accidental data corruption or schema drift when working on production directly.
**Solution:**
  1. Mandate a "Staging-First" workflow in the system instructions (`GEMINI.md`).
  2. Implement "Fail-Fast" tooling (e.g., `query_db.sh`) that requires explicit environment flags.
  3. Require a "Global Impact Analysis" scan before any code changes to identify downstream side effects.
**Result:** Proactive risk mitigation and 100% predictable deployment cycles.

---

## Pattern 15 — Seamless Splash Handover
**Context:** Eliminating the "Flicker" between the native OS splash screen and the Flutter application.
**Problem:** The OS splash is static, while the app often starts with a transition animation. A "jump" or "cut" occurs when the OS hides its logo and the app hasn't perfectly lined up its own.
**Solution:**
  1. Capture `WidgetsBinding` in `main.dart` and call `FlutterNativeSplash.preserve`.
  2. In the app's first real screen (e.g., `TransitionScreen`), place the logo in the **exact same pixel coordinates** as the native splash.
  3. Call `FlutterNativeSplash.remove()` inside `addPostFrameCallback` in the first screen's `initState`.
**Result:** A professional "Optical Illusion" where the static native logo appears to come to life and animate seamlessly.

---

## Pattern 16 — Offline-First Write Conflict Resolution
**Context:** Local-first applications where local state can diverge from remote state (e.g., archiving an item offline).
**Problem:** A refresh from a remote source can overwrite a pending local action, effectively undoing user intent (e.g., an archived job reappearing).
**Solution:** Before overwriting a local record with a remote version, check for pending local actions (e.g., `isArchived: true` AND `syncStatus: pending`). If such a pending action exists, skip the remote overwrite to preserve local user intent.
**Applies to:** Any offline-first application with user-initiated actions that sync to a remote.

---

## Pattern 17 — Preventing Keyboard Dismissal on setState
**Context:** Flutter mobile applications with `TextField` widgets that dynamically update UI.
**Problem:** Using `onChanged: (_) => setState(() {})` directly on a `TextField` causes a full widget tree rebuild on every keystroke, leading to loss of `TextField` focus and keyboard dismissal.
**Solution:** Remove `onChanged: (_) => setState(() {})` from `TextField`s. Instead, attach listeners to `TextEditingController`s within `initState()`. Only trigger `setState()` in these listeners for specific visual updates that depend on the controller's value.
**Applies to:** Flutter mobile applications with interactive forms and `TextField`s.

---

## Pattern 18 — Sync Status Semantics: 'Pending' vs 'Failed'
**Context:** Offline-first synchronization logic where local data is pushed to a remote server.
**Problem:** Overwriting local data with a `failed` status prematurely for transient network errors can prevent subsequent retries, leading to orphaned records.
**Solution:** Reserve the `failed` sync status exclusively for explicit server-side rejections (e.g., validation errors). For transient issues like network timeouts, keep the local record as `pending` so that the background sync mechanism can retry the operation.
**Applies to:** Offline-first synchronization engines with retry mechanisms.

---

## Pattern 19 — Specificity in Code Replacement
**Context:** Automated code modification using string replacement tools.
**Problem:** Using overly generic "old strings" in replacement operations can lead to unintended modifications or tool failures due to multiple matches.
**Solution:** Always craft `old_string` values that are highly specific and include enough surrounding context (e.g., multiple lines of code, unique identifiers) to guarantee a single, unambiguous match.
**Applies to:** Any automated code modification or refactoring process.

---

## Pattern 20 — Prerequisite Verification in Automated Tasks
**Context:** Implementing a task that depends on specific conditions or existing code elements.
**Problem:** Proceeding with an implementation without verifying prerequisites can lead to errors, wasted effort, and broken code.
**Solution:** Before making changes, explicitly verify all dependencies and conditions (e.g., checking for the existence of a method, a variable, or a class). If a prerequisite is missing, implement it first.
**Applies to:** Any complex automated task or step-by-step implementation.

---

## Pattern 21 — Defensive Programming: Null-Safe Auth Checks
**Context:** Authenticated operations in Flutter apps using Supabase (or similar) where auth sessions can expire.
**Problem:** Force unwrapping `currentUser!.id` can lead to crashes if the authentication session is null or expired.
**Solution:** Always use null-safe checks (`currentUser?.id`) and handle the null case explicitly, either by throwing an appropriate exception (`StorageException`, `Exception`) or by displaying a user-friendly message (e.g., `KsSnackbar`). This prevents app crashes and provides better user feedback.
**Applies to:** Any Flutter application performing authenticated operations.

---

## Pattern 22 — Client-Server Identifier Reconciliation in Sync
**Context:** Offline-first applications synchronizing local data to a remote backend via RPC.
**Problem:** The remote RPC function might use a different identifier internally (e.g., `id`) than what the client expects for reconciliation (`local_id`), leading to skipped sync status updates.
**Solution:** Ensure the RPC function explicitly maps the client's local identifier (e.g., the `id` field sent from Flutter) to a `local_id` in its response, allowing the client to correctly update the local `sync_status`.
**Applies to:** Offline-first synchronization systems using remote procedure calls.

---

## Pattern 23 — Explicit Pending Item Synchronization
**Context:** Offline-first applications with "pending" items (e.g., notes created offline) that need to be pushed to a remote server.
**Problem:** Simply calling `load()` or `refresh()` may only fetch data from the remote, potentially ignoring or overwriting locally pending items.
**Solution:** Implement an explicit `syncPendingItems()` method in the repository. Call this method *before* refreshing the main data list (`load()`) to ensure local changes are pushed to the server first.
**Applies to:** Offline-first applications with local data that requires background synchronization.

---

## Pattern 24 — Performance Optimization: Targeted Data Fetching
**Context:** Retrieving single records from a remote database.
**Problem:** Fetching all records and then filtering client-side (e.g., `getCustomers(limit: 1000)` followed by `.firstWhere`) is inefficient and wasteful for large datasets.
**Solution:** Implement remote datasource methods that leverage database-level filtering for single-record lookups (e.g., `maybeSingle()`, `.eq('id', id)` in Supabase) to minimize network payload and processing.
**Applies to:** Applications interacting with remote databases, especially with large datasets.

---

## Pattern 25 — Data Integrity: Forced Local Persistence
**Context:** Local storage solutions (e.g., Hive) that buffer writes to disk.
**Problem:** In scenarios like hard app crashes or device restarts, buffered writes might not be flushed to disk, leading to data loss for recently saved items.
**Solution:** For critical data, explicitly call `await box.flush();` after `box.put()` operations to force immediate disk persistence, ensuring data integrity even in unforeseen circumstances.
**Applies to:** Applications using local storage where data integrity is paramount.

---

## Pattern 26 — Client-Side Input Validation and Formatting
**Context:** User input forms where data integrity and consistency are crucial, especially for fields with specific formats or constraints (e.g., phone numbers, monetary values).
**Problem:** Allowing free-form input without client-side validation can lead to invalid data being stored, database constraint errors on sync, and poor user experience.
**Solution:**
  1. Use `inputFormatters` (e.g., `FilteringTextInputFormatter`, `LengthLimitingTextInputFormatter`) on `TextField`s to guide user input to the correct format and length.
  2. Implement explicit validation checks (e.g., `startsWith('0')`, `length != 10`, `double.tryParse()`, `amount <= 0`) before saving data.
  3. Provide immediate visual feedback (e.g., `KsSnackbar`) for validation errors.
**Applies to:** Any form with structured data input.

---

## Pattern 27 — UI Feedback for Background Processes
**Context:** Applications with background synchronization or long-running operations.
**Problem:** Invisible background processes can leave users guessing whether an action is complete or if data is being updated, leading to uncertainty or repeated actions.
**Solution:**
  1. Introduce UI indicators (e.g., `isSyncing` flag in a state provider) to show when a background process is active.
  2. Display subtle visual cues (e.g., pulsing icons, spinners, chips with text like "pending sync") that provide real-time feedback on the status of these operations.
**Applies to:** Any application with asynchronous background tasks affecting data.

---

## Pattern 28 — Performance Optimization: Avoiding Redundant Rebuilds
**Context:** Flutter applications using state management solutions (e.g., Riverpod, Provider) alongside `StatefulWidget`s.
**Problem:** Calling `setState(() {})` unnecessarily within `onChanged` callbacks or `onTap` handlers of `TextField`s or other widgets that are already managed by a state provider can cause redundant widget tree rebuilds, leading to performance issues and UI glitches (e.g., keyboard dismissal).
**Solution:**
  1. When using a state management solution, let the provider handle state changes and subsequent rebuilds.
  2. Remove explicit `setState(() {})` calls from `onChanged` or `onTap` if the primary state update is already handled by a provider.
  3. For local UI state changes not managed by a provider, ensure `setState(() {})` calls are minimal and targeted.
**Applies to:** Any Flutter application using state management and `StatefulWidget`s.
