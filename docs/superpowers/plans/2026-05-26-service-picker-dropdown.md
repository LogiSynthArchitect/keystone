# Service Picker Dropdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the inline service type list in Add New Job Step 0 with a compact dropdown that opens a bottom sheet drawer.

**Architecture:** Create a new `ServicePickerDropdown` widget (compact filed-style selector → bottom sheet) to replace `ServiceTypePickerV2` inside `JobStepService`. Remove the TEMPLATES button from step 0. Update existing test.

**Tech Stack:** Flutter, Riverpod, mocktail, KsStepDrawer pattern

---

### Task 1: Write failing test for ServicePickerDropdown

**Files:**
- Modify: `test/features/job_logging/presentation/screens/log_job_wizard_test.dart`

- [ ] **Step 1: Update test to expect new dropdown widget**

Replace the `ServiceTypePickerV2` import with the new widget import. Change the test from tapping `ServiceTypePickerV2` to tapping the dropdown field that shows "SELECT SERVICE TYPE".

```dart
// In log_job_wizard_test.dart:
// Replace lines 7-8:
import 'package:keystone/features/job_logging/presentation/widgets/service_picker_dropdown.dart';
// Remove: import 'package:keystone/features/service_types/presentation/widgets/service_type_picker_v2.dart';

// Replace test 'starts on Step 1 (SERVICE) and Next is disabled initially':
// Expect "SELECT SERVICE TYPE" placeholder text
expect(find.text('SELECT SERVICE TYPE'), findsOneWidget);

// Replace test 'enabling a service type enables the Next button':
// Tap the dropdown field to open the sheet
await tester.tap(find.text('SELECT SERVICE TYPE'));
await tester.pump();
// Then tap the first service type option
await tester.tap(find.text('Safe Opening').last);
await tester.pump();
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/job_logging/presentation/screens/log_job_wizard_test.dart`
Expected: FAIL - "ServicePickerDropdown not found" / "SELECT SERVICE TYPE not found"

- [ ] **Step 3: Commit**

```bash
git add test/features/job_logging/presentation/screens/log_job_wizard_test.dart
git commit -m "test: update log_job_wizard_test to expect dropdown picker"
```

### Task 2: Create ServicePickerDropdown widget

**Files:**
- Create: `lib/features/job_logging/presentation/widgets/service_picker_dropdown.dart`
- No test file needed (test from Task 1 covers this)

- [ ] **Step 1: Write failing test for new widget**

```dart
// test/features/job_logging/presentation/widgets/service_picker_dropdown_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/features/job_logging/presentation/widgets/service_picker_dropdown.dart';
import 'package:keystone/features/service_types/presentation/providers/service_type_provider.dart';
import 'package:keystone/features/service_types/domain/entities/service_type_entity.dart';
import 'package:keystone/core/providers/supabase_provider.dart';
import 'package:keystone/core/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class _TestServiceTypeNotifier extends ServiceTypeNotifier {
  _TestServiceTypeNotifier(super.ref) {
    state = AsyncValue.data([
      ServiceTypeEntity(
        id: 'st1', userId: 'u1', name: 'Safe Opening',
        createdAt: DateTime(2024), updatedAt: DateTime(2024),
      ),
      ServiceTypeEntity(
        id: 'st2', userId: 'u1', name: 'Deadbolt Replacement',
        createdAt: DateTime(2024), updatedAt: DateTime(2024),
      ),
    ]);
  }
  @override
  Future<void> loadServiceTypes() async {}
}

void main() {
  group('ServicePickerDropdown', () {
    testWidgets('shows placeholder when nothing selected', (tester) async {
      String? selected;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
          serviceTypeProvider.overrideWith((ref) => _TestServiceTypeNotifier(ref)),
        ],
        child: MaterialApp(
          theme: buildDarkAppTheme(),
          home: Scaffold(
            body: ServicePickerDropdown(
              selected: null,
              onSelected: (t) => selected = t,
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('SELECT SERVICE TYPE'), findsOneWidget);
    });

    testWidgets('shows chip when service is selected', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
          serviceTypeProvider.overrideWith((ref) => _TestServiceTypeNotifier(ref)),
        ],
        child: MaterialApp(
          theme: buildDarkAppTheme(),
          home: Scaffold(
            body: ServicePickerDropdown(
              selected: 'Safe Opening',
              onSelected: (t) {},
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('SAFE OPENING'), findsOneWidget);
    });

    testWidgets('opens bottom sheet on tap', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
          serviceTypeProvider.overrideWith((ref) => _TestServiceTypeNotifier(ref)),
        ],
        child: MaterialApp(
          theme: buildDarkAppTheme(),
          home: Scaffold(
            body: ServicePickerDropdown(
              selected: null,
              onSelected: (t) {},
            ),
          ),
        ),
      ));
      await tester.pump();

      // Tap the dropdown field
      await tester.tap(find.text('SELECT SERVICE TYPE'));
      await tester.pumpAndSettle();

      // Sheet should show service options
      expect(find.text('SAFE OPENING'), findsOneWidget);
    });

    testWidgets('selecting a service type calls onSelected', (tester) async {
      String? selected;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          supabaseClientProvider.overrideWithValue(MockSupabaseClient()),
          serviceTypeProvider.overrideWith((ref) => _TestServiceTypeNotifier(ref)),
        ],
        child: MaterialApp(
          theme: buildDarkAppTheme(),
          home: Scaffold(
            body: ServicePickerDropdown(
              selected: null,
              onSelected: (t) => selected = t,
            ),
          ),
        ),
      ));
      await tester.pump();

      // Open sheet
      await tester.tap(find.text('SELECT SERVICE TYPE'));
      await tester.pumpAndSettle();

      // Tap first option
      await tester.tap(find.text('Safe Opening').last);
      await tester.pumpAndSettle();

      expect(selected, equals('Safe Opening'));
    });
  });
}
```

Run: `flutter test test/features/job_logging/presentation/widgets/service_picker_dropdown_test.dart`
Expected: FAIL - "cannot find ServicePickerDropdown"

- [ ] **Step 2: Implement the ServicePickerDropdown widget**

The widget:
- Shows a compact underlined field with icon + placeholder or selected chip
- Tap opens a bottom sheet listing service types (from `serviceTypeProvider`)
- Each row has icon + name + checkmark if selected
- Tap a type → close sheet → call `onSelected`
- Selected state shows a gold chip with ✕ to clear

```dart
// lib/features/job_logging/presentation/widgets/service_picker_dropdown.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/service_icon_map.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';

class ServicePickerDropdown extends ConsumerWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const ServicePickerDropdown({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconName = selected != null
        ? _iconNameFor(ref, selected!)
        : null;

    return InkWell(
      onTap: () => _openSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected != null
                  ? context.ksc.accent500
                  : context.ksc.primary700,
              width: selected != null ? 1.5 : 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              iconName != null ? ServiceIconMap.resolve(iconName) : LineAwesomeIcons.wrench_solid,
              size: 20,
              color: selected != null ? context.ksc.accent500 : context.ksc.neutral500,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: selected != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.ksc.accent500.withValues(alpha: 0.1),
                        border: Border.all(color: context.ksc.accent500),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selected!.replaceAll('_', ' ').toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: context.ksc.accent500,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => onSelected(''),
                            child: Icon(
                              LineAwesomeIcons.times_solid,
                              size: 12,
                              color: context.ksc.accent500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      'SELECT SERVICE TYPE',
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.neutral500,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
            Icon(
              LineAwesomeIcons.angle_down_solid,
              size: 14,
              color: selected != null ? context.ksc.accent500 : context.ksc.neutral500,
            ),
          ],
        ),
      ),
    );
  }

  String? _iconNameFor(WidgetRef ref, String name) {
    final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
    return types.where((t) => t.name == name).firstOrNull?.iconName;
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
    if (types.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ksc.primary800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = searchCtrl.text.toLowerCase().trim();
            final filtered = query.isEmpty
                ? types
                : types.where((t) =>
                    t.name.toLowerCase().contains(query) ||
                    (t.category?.toLowerCase().contains(query) ?? false))
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: context.ksc.neutral600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text("SELECT SERVICE",
                            style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(LineAwesomeIcons.times_solid, color: context.ksc.neutral500, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.ksc.primary900,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.ksc.primary700),
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        onChanged: (_) => setSheetState(() {}),
                        style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600),
                        cursorColor: context.ksc.accent500,
                        decoration: InputDecoration(
                          hintText: "Search services...",
                          hintStyle: AppTextStyles.caption.copyWith(color: context.ksc.neutral600),
                          prefixIcon: Icon(LineAwesomeIcons.search_solid, size: 16, color: context.ksc.neutral600),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Service list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text("No services found")),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) {
                              final type = filtered[i];
                              final isSelected = selected == type.name;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: InkWell(
                                  onTap: () {
                                    onSelected(type.name);
                                    Navigator.pop(ctx);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? context.ksc.accent500.withValues(alpha: 0.1)
                                          : context.ksc.primary900,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected
                                            ? context.ksc.accent500
                                            : context.ksc.primary700,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          ServiceIconMap.resolve(type.iconName),
                                          size: 20,
                                          color: isSelected ? context.ksc.accent500 : context.ksc.neutral500,
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            type.name.toUpperCase(),
                                            style: AppTextStyles.bodyMedium.copyWith(
                                              color: isSelected ? context.ksc.white : context.ksc.neutral400,
                                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Icon(LineAwesomeIcons.check_circle_solid, size: 18, color: context.ksc.accent500),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `flutter test test/features/job_logging/presentation/widgets/service_picker_dropdown_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/job_logging/presentation/widgets/service_picker_dropdown.dart
git add test/features/job_logging/presentation/widgets/service_picker_dropdown_test.dart
git commit -m "feat: add ServicePickerDropdown widget"
```

### Task 3: Update JobStepService to use ServicePickerDropdown

**Files:**
- Modify: `lib/features/job_logging/presentation/widgets/job_step_service.dart`

- [ ] **Step 1: Replace ServiceTypePickerV2 with ServicePickerDropdown**

In `job_step_service.dart`:
- Replace import of `service_type_picker_v2.dart` with `service_picker_dropdown.dart`
- Replace `<ServiceTypePickerV2>` with `<ServicePickerDropdown>`
- Remove the `_buildExpandableSection` wrapper since the dropdown doesn't need collapse/expand

The collapsible section concept was needed because the inline list was big. The dropdown is compact, so it doesn't need collapse/expand.

- [ ] **Step 2: Run existing test**

Run: `flutter test test/features/job_logging/presentation/screens/log_job_wizard_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add lib/features/job_logging/presentation/widgets/job_step_service.dart
git commit -m "refactor: replace ServiceTypePickerV2 with ServicePickerDropdown in JobStepService"
```

### Task 4: Update log_job_screen.dart to remove TEMPLATES button from step 0

**Files:**
- Modify: `lib/features/job_logging/presentation/screens/log_job_screen.dart`

- [ ] **Step 1: Remove TEMPLATES button from step 0 stepContent**

In `log_job_screen.dart`, the `stepContent` callback for `step == 0` currently wraps `_buildStepByIndex(step)` with a TEMPLATES button below. Remove the button.

Change from:
```dart
if (step == 0) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepByIndex(step),
        const SizedBox(height: 16),
        GestureDetector(  // ← TEMPLATES button
          onTap: _pickTemplate,
          child: Container(...),
        ),
      ],
    ),
  );
}
```

To: (let it fall through to the default case that just wraps in Padding)

- [ ] **Step 2: Run existing test**

Run: `flutter test test/features/job_logging/presentation/screens/log_job_wizard_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add lib/features/job_logging/presentation/screens/log_job_screen.dart
git commit -m "refactor: remove TEMPLATES button from step 0"
```

### Task 5: Remove old ServiceTypePickerV2 if no longer used

**Files:**
- Possibly delete: `lib/features/service_types/presentation/widgets/service_type_picker_v2.dart`

- [ ] **Step 1: Check if ServiceTypePickerV2 is used elsewhere**

Run: `grep -r "ServiceTypePickerV2" lib/`
If only in the widget file itself and the test file (which we'll update), it's safe to delete.

- [ ] **Step 2: Delete the file if unused**

```bash
git rm lib/features/service_types/presentation/widgets/service_type_picker_v2.dart
```

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: remove unused ServiceTypePickerV2 widget"
```

### Task 6: Verify on device

**Files:**
- Run on phone via `run_phone.sh`

- [ ] **Step 1: Build and run on phone**

Run: `bash scripts/run_phone.sh`

- [ ] **Step 2: Verify step 0 shows dropdown instead of inline list**

Use `adb logcat` to confirm screen renders. Tap the dropdown field, verify bottom sheet opens with service types.

- [ ] **Step 3: Verify navigation still works**

Confirm step advancement, Next button enabling/disabling work correctly.
