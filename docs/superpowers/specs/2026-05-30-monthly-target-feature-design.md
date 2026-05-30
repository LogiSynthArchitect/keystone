# Monthly Target Feature — Design Spec

## Problem

The monthly revenue target is currently **hardcoded** in the dashboard (`500000`). A `monthlyTargetProvider` exists in `job_providers.dart` that reads from Hive, but no UI lets the user **set** the value. Analytics has no target awareness.

## Solution

Let the user set a monthly revenue target via a **tap-to-edit dialog on the Dashboard progress card**. The target flows into all revenue surfaces.

## Scope

- Dashboard: quick-set dialog + use `monthlyTargetProvider` instead of hardcoded `500000`
- Analytics: read-only "vs target" indicator in the this-month view
- Job list: already works (uses `monthlyTargetProvider`)
- No new screens. No backend schema changes. No sync — stored locally in Hive.

## Architecture

### Data flow
```
User taps progress bar on Dashboard
  → _showTargetEditDialog() opens
  → saves to Hive: HiveService.settings.put('monthlyTarget', value)
  → monthlyTargetProvider.notifier.state = value  (reactive)
  → Dashboard, Analytics, Job list all re-render via ref.watch(monthlyTargetProvider)
```

### Hive key
- `monthlyTarget` — already used by `monthlyTargetProvider`, fallback `800000`

## Implementation Plan

### 1. Dashboard — replace hardcoded value
**File:** `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Lines 386-428: `_buildMonthlyProgress` currently uses `final monthlyTarget = 500000;`
- Replace with `final monthlyTarget = ref.watch(monthlyTargetProvider);`
- Accept `WidgetRef ref` in method signature or use `Consumer` widget

### 2. Dashboard — add tap-to-edit dialog
- Wrap the progress card or an overlay button with `GestureDetector` or `InkWell`
- On tap: show a bottom sheet / dialog with:
  - Current target value prefilled
  - Currency text field (numeric keyboard, max 7 digits)
  - "Save" / "Cancel" buttons
- On save:
  - Write to Hive: `HiveService.settings.put('monthlyTarget', parsedValue)`
  - Update provider: `ref.read(monthlyTargetProvider.notifier).state = parsedValue`
  - Show `KsSlidingNotification.success("Monthly target updated")`

### 3. Analytics — add "vs target" card
**File:** `lib/features/analytics/presentation/screens/analytics_screen.dart`
- In the this-month view, add a compact card showing:
  - `Current Revenue / Target` (e.g. "₵350 / ₵800")
  - Progress bar (same style as dashboard)
  - Percentage label
- Read-only — no edit action. If user wants to change, navigates to Dashboard.

### 4. Analytics — add target to analytics models (optional)
If `AnalyticsState` doesn't carry period revenue, read it from the existing rollup data.

## UI Details

### Edit dialog
- Bottom sheet (consistent with KsStepDrawer pattern)
- Title: "SET MONTHLY TARGET"
- Text field with `TextInputType.number` and `ThousandsSeparatorInputFormatter`
- Prefill with current value
- Gold-accented "SAVE" button (same style as KsButton)
- Validation: value > 0

### Dashboard progress card (unchanged visual)
- Gradient container, gold progress bar
- Shows "X% of ₵Y target"
- Added invisible `InkWell` overlay for tap detection

### Analytics indicator
- Smaller variant of the dashboard card
- Shows "TARGET" label, progress bar, revenue/target text
- No edit affordance — purely informational

## Files Modified
| File | Changes |
|------|---------|
| `dashboard_screen.dart` | ~20 lines: replace hardcoded target, add tap-to-edit dialog |
| `analytics_screen.dart` | ~30 lines: add target progress indicator in this-month section |
| No new files | Everything lives in existing screens |

## Edge Cases
- **Target not set (first launch):** Falls back to `800000` from provider. User sees the default until they tap to set.
- **Zero target:** If user sets 0, treat as "no target" — hide progress bar display.
- **Revenue exceeds target:** Clamp at 100% for progress bar, but show "150% of target" text.
- **Field empty on save:** Block save, show inline validation.
