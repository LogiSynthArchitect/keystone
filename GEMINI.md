# GEMINI SYSTEM COMMANDS (KEYSTONE)
### Foundational Mandates for AI Agents

You are an expert engineer working on **Keystone**, a military-grade tactical terminal for locksmiths. You must adhere to the following protocols without exception.

---

## 0. ENVIRONMENT SANCTITY (CRITICAL)
*   **Production is Sanctified:** Unless a Directive explicitly specifies "PRODUCTION," all development, research, and testing MUST target the Staging URL (`mxkknt...`).
*   **Zero-Production Policy:** Never apply migrations or destructive SQL to Production without a specific, double-verified Directive.
*   **Flavor Verification:** All `run` or `build` commands MUST use `--flavor dev` for Staging or `--flavor prod` for Production.

## 1. THE "SEARCH-FIRST" PROTOCOL
*   **Zero Assumption Policy:** Never assume a file exists or a variable is named a certain way. You MUST `grep_search` or `glob` before you speak or act.
*   **Pattern Matching:** Before writing new code, find the "Keystone way" of doing it (e.g., how we handle Snackbars, how we use Riverpod).
*   **Context Verification:** Always `read_file` the specific lines you intend to edit to ensure your `old_string` matches perfectly.

## 2. SURGICAL IMPLEMENTATION
*   **Minimal Surface Area:** Apply the smallest possible change to achieve the goal. Targeted `replace` calls are preferred over `write_file`.
*   **Haptic & Tactical Polish:** Every primary action must include `HapticFeedback.mediumImpact()`. Every numeric value must use `fontFeatures: [FontFeature.tabularFigures()]`.
*   **Integrated Guidance:** Never leave a user guessing. Use the `fieldHint` property in forms to provide at-a-glance technical instructions.

## 3. DOCUMENTATION & CONTINUITY (MANDATORY)
You are responsible for keeping the "Blueprints" synced with the "Building." You MUST update these files after every significant change:
1.  **`docs/v1/tracking/dev_log.md`**: Append your session details (Built/Broke/Learned).
2.  **`docs/v1/tracking/current_state.md`**: Reflect 100% accurate completion states.
3.  **`docs/patterns.md`**: Document any new architectural patterns or specific fixes found.
4.  **`docs/v1/models/12_database_schema.md`**: Keep the SQL blueprints in sync with actual migrations.

## 4. KEYSTONE ARCHITECTURE DNA
*   **Offline-First:** Hive is the UI source of truth. Remote sync is a background reconciliation process.
*   **Dark Industrial:** Use `AppColors.primary900` for backgrounds, `AppColors.accent500` for primary actions, and `Barlow Semi Condensed` (weight 600+) for all text.
*   **Clean Architecture:** Isolated features communicating ONLY through `shared_feature_providers.dart`.

## 5. DATABASE & ADMIN
*   **Admin Control:** Admins bypass RLS isolation via specialized `admin_all` policies to resolve technician errors.
*   **Querying:** Use `./query_db.sh "YOUR SQL" --staging` or `./query_db.sh "YOUR SQL" --prod`. Defaulting to `prod` is forbidden.
*   **Migration Verification:** Every migration MUST be tested on the Staging environment before being proposed for Production.

## 6. GLOBAL IMPACT ANALYSIS (PAUSE-AND-MAP)
*   **The "Whole-System" Scan:** Before any file creation, modification, or deletion, you MUST perform a `grep_search` or `glob` to identify all downstream dependencies (e.g., related tests, shared providers, and feature-bridged modules).
*   **Circular Dependency Prevention:** Every change must be verified against `shared_feature_providers.dart` to ensure feature isolation is maintained and no circular dependencies are introduced.
*   **The Pre-Flight Declaration:** Before executing a `replace` or `write_file`, you must state the potential side effects and how you have mitigated them (e.g., "Updated provider X; verified features Y and Z for breaking changes").
*   **Architectural DNA Verification:** You must confirm that your proposed change matches the established "Keystone Way" (e.g., check `docs/patterns.md`) before implementation.

---
**FAILURE TO ADHERE TO THESE MANDATES IS AN ARCHITECTURAL BREACH.**
