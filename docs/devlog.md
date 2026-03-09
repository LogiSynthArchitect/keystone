# KEYSTONE DEV LOG
Running record of what was built, what broke, and what was learned.
Append-only. Never edited — only added to.

---

## SESSION 1 — 2026-03-09

### What was built
- Flutter project created (3.41.4)
- Complete folder structure from Document 13
- pubspec.yaml with all dependencies
- lib/core/theme/ — app_colors, app_spacing, app_text_styles, app_theme
- lib/core/constants/ — app_constants, supabase_constants, whatsapp_constants
- lib/core/analytics/ — analytics_constants
- lib/core/errors/ — app_exception, auth_exception, network_exception, storage_exception, validation_exception
- lib/core/network/ — supabase_client, connectivity_service
- lib/core/storage/ — hive_service (replaced Isar)
- lib/core/providers/ — supabase_provider, connectivity_provider
- lib/main.dart + lib/app.dart

### What broke and how it was fixed

BREAK 1: isar_generator ^3.1.0 conflicts with riverpod_generator ^2.4.3
  Cause: both require different versions of the analyzer package
  Fix: replaced Isar with Hive (hive_flutter ^1.1.0)
  Impact: isar_schemas folder renamed to hive_boxes, local datasource implementation will use Hive boxes instead of Isar collections. Domain layer and all layers above are unaffected.

BREAK 2: const_eval_method_invocation in app_constants.dart
  Cause: AppEnvironment.values.byName() cannot be called in a const context
  Fix: replaced const factory with a regular static getter using a conditional expression

BREAK 3: CardTheme vs CardThemeData in app_theme.dart
  Cause: Flutter 3.41.4 uses CardThemeData, not CardTheme in ThemeData
  Fix: sed replace CardTheme( → CardThemeData(

BREAK 4: widget_test.dart references MyApp which no longer exists
  Cause: Flutter default test references the default MyApp class
  Fix: replaced with empty test file — real tests added in Phase 10

### What was learned
- Isar 3.x is effectively unmaintained and conflicts with current Riverpod codegen. Hive is the safe V1 choice.
- Flutter 3.41.4 uses CardThemeData not CardTheme — API changed from earlier versions.
- Always run flutter analyze after every batch of files, not at the end.
- The --dart-define pattern for secrets works cleanly with String.fromEnvironment().

### What comes next
- Step 06: auth_provider.dart (core)
- Step 07: utility files (phone_formatter, currency_formatter, date_formatter, whatsapp_launcher)
- Step 08: route_names.dart + app_router.dart scaffold
- Then: GitHub repo + first commit
- Then: Phase 2 — domain entities

### Flutter analyze status
No issues found ✅

---
