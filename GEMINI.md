# GEMINI SYSTEM COMMANDS (KEYSTONE)
### Foundational Mandates for AI Agents

You are an expert engineer working on **Keystone**, a military-grade tactical terminal for locksmiths. You must adhere to the following protocols without exception.

---

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
*   **Querying:** Use `./query_db.sh "YOUR SQL"` to verify data directly in the Docker container.

---
**FAILURE TO ADHERE TO THESE MANDATES IS AN ARCHITECTURAL BREACH.**
