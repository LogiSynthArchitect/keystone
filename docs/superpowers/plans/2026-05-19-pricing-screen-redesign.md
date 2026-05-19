# Pricing Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-service icons and replace cramped inline price TextField with a focused bottom sheet price editor on the Pricing Screen.

**Architecture:** Single-file change to `pricing_screen.dart`. Uses existing `getLineAwesomeIcon()` from `icon_helpers.dart` for icons and `CurrencyFormatter.parseToPesewas()` for price parsing. The `ServiceTypeProvider` already has `updateServiceTypePrice(id, pesewas)` — no provider changes needed.

**Tech Stack:** Flutter, Riverpod, Line Awesome Icons, existing pricing screen

---

### Task 1: Add service icons to each row + replace inline TextField with price text

**Files:**
- Modify: `lib/features/service_types/presentation/screens/pricing_screen.dart:170-228`

- [ ] **Step 1: Read the current file to confirm state**

- [ ] **Step 2: Replace `_buildServiceRow()` method**

Replace the current `_buildServiceRow` method (which has a Row with Text + SizedBox + TextField for inline editing) with:

```dart
Widget _buildServiceRow(ServiceTypeEntity service) {
  return GestureDetector(
    onTap: () => _openPriceSheet(service),
    child: Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.ksc.primary800.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.ksc.primary700.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            getLineAwesomeIcon(service.iconName),
            color: context.ksc.neutral400,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service.name,
              style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            service.defaultPrice != null
                ? 'GHS ${(service.defaultPrice! / 100.0).toStringAsFixed(2)}'
                : '\u2014',
            style: AppTextStyles.body.copyWith(
              color: service.defaultPrice != null ? context.ksc.accent500 : context.ksc.neutral500,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
```

Add the import for `icon_helpers.dart` at the top of the file if it's not already imported:

```dart
import '../../../../core/utils/icon_helpers.dart';
```

- [ ] **Step 3: Add `_openPriceSheet()` method**

Add this method to `_PricingScreenState` to handle the bottom sheet creation:

```dart
void _openPriceSheet(ServiceTypeEntity service) {
  final controller = TextEditingController(
    text: service.defaultPrice != null
        ? (service.defaultPrice! / 100.0).toStringAsFixed(2)
        : '',
  );

  showModalBottomSheet(
    context: context,
    backgroundColor: context.ksc.primary800,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      // Store price value for save callback
      String currentValue = controller.text;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: context.ksc.neutral600,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header
                    Text(
                      'SET PRICE',
                      style: AppTextStyles.h2.copyWith(
                        color: context.ksc.accent500,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Icon circle
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: context.ksc.primary900,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.ksc.accent500, width: 2),
                      ),
                      child: Icon(
                        getLineAwesomeIcon(service.iconName),
                        color: context.ksc.accent500,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Service name
                    Text(
                      service.name.toUpperCase(),
                      style: AppTextStyles.h3.copyWith(
                        color: context.ksc.white,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.ksc.primary900,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.ksc.primary700),
                      ),
                      child: Text(
                        service.category.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: context.ksc.neutral400,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Current price label
                    Text(
                      service.defaultPrice != null
                          ? 'Current: GHS ${(service.defaultPrice! / 100.0).toStringAsFixed(2)}'
                          : 'No price set',
                      style: AppTextStyles.body.copyWith(
                        color: context.ksc.neutral500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price input
                    Container(
                      decoration: BoxDecoration(
                        color: context.ksc.primary900,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.ksc.primary700),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            'GHS',
                            style: AppTextStyles.h2.copyWith(
                              color: context.ksc.neutral500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: controller,
                              autofocus: true,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: context.ksc.white,
                              ),
                              cursorColor: context.ksc.accent500,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (v) {
                                currentValue = v;
                                setSheetState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    KsButton(
                      label: 'SAVE CHANGES',
                      onPressed: currentValue.isNotEmpty
                          ? () {
                              final pesewas = CurrencyFormatter.parseToPesewas(currentValue);
                              ref.read(serviceTypeProvider.notifier).updateServiceTypePrice(service.id, pesewas);
                              Navigator.pop(sheetContext);
                            }
                          : null,
                      variant: KsButtonVariant.primary,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
```

- [ ] **Step 4: Remove unused imports**

After the change, the `TextField` import may no longer need the `outlineInputBorder` references since they were in the old inline TextField. Verify the import `import 'package:flutter/material.dart'` already covers everything needed.

- [ ] **Step 5: Run flutter analyze**

```bash
/home/cybocrime/Tools/flutter/bin/flutter analyze
```
Expected: 0 errors. Only pre-existing info messages and warnings.

- [ ] **Step 6: Log session action**

```bash
echo "[$(date)] build: Pricing screen redesign (icons + bottom sheet) — implemented and analyzed" >> /home/cybocrime/.config/opencode/session.log
```
