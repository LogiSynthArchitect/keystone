# Monthly Target Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace hardcoded monthly target in Dashboard with user-configurable value set via tap-to-edit dialog, visible across Dashboard, Job List (already works), and Analytics.

**Architecture:** A shared `monthlyTargetProvider` (StateProvider in `job_providers.dart`) reads/writes `HiveService.settings('monthlyTarget')`. Dashboard and Analytics `ref.watch()` it reactively. Dashboard adds an inline edit dialog. Analytics adds a read-only "vs target" progress card.

**Tech Stack:** Flutter 3.41, Riverpod, Hive, LineAwesome Icons

**Files Modified:**
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` (~40 lines)
- `lib/features/analytics/presentation/screens/analytics_screen.dart` (~40 lines)

**No new files, no migrations, no schema changes.**

---

### Task 1: Dashboard — use provider + tap-to-edit dialog

**File:** `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

- [ ] **Step 1: Replace hardcoded target in `_buildMonthlyProgress`**

Around line 387, change:
```dart
final monthlyTarget = 500000;
```
to:
```dart
final monthlyTarget = ref.watch(monthlyTargetProvider);
```

Since `_buildMonthlyProgress` is called from within a `ConsumerState` (`_DashboardScreenState`), `ref` is already available.

Verify: The build uses `ref`, which is already declared at the class level from `ConsumerState<DashboardScreen>`. The method signature stays `Widget _buildMonthlyProgress(BuildContext context, int monthRevenue)`.

- [ ] **Step 2: Add `showTargetEditDialog` method**

Add this method to `_DashboardScreenState` (after `_buildMonthlyProgress`, around line 428):

```dart
  void _showTargetEditDialog() {
    final current = ref.read(monthlyTargetProvider);
    final controller = TextEditingController(text: current.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.ksc.surface800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(LineAwesomeIcons.chart_line_solid, size: 18, color: context.ksc.accent500),
            const SizedBox(width: 10),
            Text('SET MONTHLY TARGET',
                style: AppTextStyles.label.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Enter target amount',
            hintStyle: TextStyle(color: context.ksc.neutral600, fontSize: 14),
            filled: true,
            fillColor: context.ksc.surface900,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          style: AppTextStyles.body.copyWith(color: context.ksc.white),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed <= 0) {
                KsSlidingNotification.show(context, message: 'Enter a valid amount', type: KsNotificationType.error);
                return;
              }
              HiveService.settings.put('monthlyTarget', parsed);
              ref.read(monthlyTargetProvider.notifier).state = parsed;
              Navigator.pop(ctx);
              KsSlidingNotification.show(context, message: 'Monthly target updated to ${CurrencyFormatter.format(parsed)}', type: KsNotificationType.success);
            },
            child: Text('SAVE', style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
```

Add missing imports at the top of the file if not present:
- `import 'package:flutter/services.dart';` (for `FilteringTextInputFormatter`)
- `import '../../../../core/storage/hive_service.dart';` (for `HiveService.settings`)

- [ ] **Step 3: Add tap handler to the progress card**

Wrap the `_buildMonthlyProgress` call site (line 231) with `GestureDetector`:

```dart
                    GestureDetector(
                      onTap: _showTargetEditDialog,
                      child: _buildMonthlyProgress(context, monthRevenue),
                    ),
```

Find this at line 230-231:
```dart
                    // ── Monthly target progress ──
                    _buildMonthlyProgress(context, monthRevenue),
```

Replace with:
```dart
                    // ── Monthly target progress ──
                    GestureDetector(
                      onTap: _showTargetEditDialog,
                      child: _buildMonthlyProgress(context, monthRevenue),
                    ),
```

- [ ] **Step 4: Add `import 'dart:convert';` for `FilteringTextInputFormatter`**

Check if `package:flutter/services.dart` is already imported. If not, add:
```dart
import 'package:flutter/services.dart';
```
(near top with other Flutter imports)

Check if `hive_service.dart` is imported. If not, add:
```dart
import '../../../../core/storage/hive_service.dart';
```

- [ ] **Step 5: Run build check**

```bash
cd /home/cybocrime/workspace/projects/keystone
dart analyze lib/features/dashboard/presentation/screens/dashboard_screen.dart
```

Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/features/dashboard/presentation/screens/dashboard_screen.dart
git commit -m "feat: replace hardcoded monthly target with provider + tap-to-edit dialog"
```

---

### Task 2: Analytics — add "vs target" progress card

**File:** `lib/features/analytics/presentation/screens/analytics_screen.dart`

- [ ] **Step 1: Add import for `monthlyTargetProvider`**

Add after existing job_providers-related import (or any logical place among the `../../../../` imports, around line 16):
```dart
import '../../../job_logging/presentation/providers/job_providers.dart';
```

- [ ] **Step 2: Add `_MonthlyTargetCard` widget**

Add this after the `_LeakingRevenueBanner` class (search for `class _LeakingRevenueBanner` or around line 1100):

```dart
// ── Monthly Target Card ─────────────────────────────────────────────────────

class _MonthlyTargetCard extends ConsumerWidget {
  final int revenue;
  const _MonthlyTargetCard({required this.revenue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(monthlyTargetProvider);
    if (target <= 0) return const SizedBox.shrink();

    final pct = revenue > 0 ? (revenue / target).clamp(0.0, 1.0) : 0.0;
    final pctDisplay = revenue > 0 ? ((revenue / target) * 100).round() : 0;
    final theme = context.ksc;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primary800, theme.primary800.withValues(alpha: 0.6)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: theme.primary700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LineAwesomeIcons.chart_line_solid, size: 16, color: theme.neutral500),
              const SizedBox(width: 8),
              Text("TARGET",
                  style: AppTextStyles.caption.copyWith(color: theme.neutral500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const Spacer(),
              Text("$pctDisplay%",
                  style: AppTextStyles.label.copyWith(color: theme.accent500, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: theme.primary700,
              color: theme.accent500,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text("${CurrencyFormatter.format(revenue)} of ${CurrencyFormatter.format(target)} target",
              style: AppTextStyles.caption.copyWith(color: theme.neutral500, fontSize: 10)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Insert the target card in the analytics body**

In `_AnalyticsBodyState.build`, after the `_HeroCard` section (around line 607), add:

```dart
        // ── Monthly target progress ──
        _MonthlyTargetCard(revenue: s.totalRevenue),
        const SizedBox(height: AppSpacing.xl),
```

Place it right after the hero card section (after line 608 `const SizedBox(height: AppSpacing.xl)` and before `// ── Revenue trend` at line 610):

Current:
```dart
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Revenue trend ──
```

Changed to:
```dart
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Monthly target progress ──
        _MonthlyTargetCard(revenue: s.totalRevenue),
        const SizedBox(height: AppSpacing.xl),

        // ── Revenue trend ──
```

- [ ] **Step 4: Run build check**

```bash
cd /home/cybocrime/workspace/projects/keystone
dart analyze lib/features/analytics/presentation/screens/analytics_screen.dart
```

Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/analytics/presentation/screens/analytics_screen.dart
git commit -m "feat: add monthly target progress card to analytics screen"
```

---

### Task 3: Integration verification

- [ ] **Step 1: Full project analysis**

```bash
cd /home/cybocrime/workspace/projects/keystone
dart analyze lib/
```

Expected: No errors.

- [ ] **Step 2: Push**

```bash
git push
```
