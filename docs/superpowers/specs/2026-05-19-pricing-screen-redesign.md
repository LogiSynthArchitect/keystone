# Pricing Screen Redesign — Icon per Row + Bottom Sheet Price Editor

**Date:** 2026-05-19
**Status:** Design Approved ✅

## Objective
Refresh the Service Pricing screen to show per-service icons and replace the cramped inline TextField with a focused bottom sheet price editor — improving readability, intentionality, and visual polish.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/features/service_types/presentation/screens/pricing_screen.dart` | Add icons, replace inline TextField with bottom sheet |
| `lib/core/utils/icon_helpers.dart` | Already exists — no changes needed |

No other files are touched.

---

## 1. Service Row Redesign

Each row in `_buildServiceRow()` changes from:

```
[name text]          [____inline price field 120px____]
```

To:

```
[icon 18px] [name bold]                  GHS 50.00
```

### Row details
- **Icon:** `Icon(getLineAwesomeIcon(service.iconName), color: neutral400, size: 18)`
- **Name:** `AppTextStyles.body.copyWith(color: white, fontWeight: FontWeight.w600)`
- **Price:** Text widget in accent500 gold, formatted as `GHS ${(defaultPrice/100).toStringAsFixed(2)}` with `FontWeight.w800`
- **Entire row tappable** via `GestureDetector` wrapping the Container — calls `_openPriceSheet(service)`
- Inline `TextField` is **removed** from row
- Price shows `"—"` when `defaultPrice` is null

---

## 2. Bottom Sheet (Price Editor)

Opened by `showModalBottomSheet()` when a service row is tapped.

### Layout (top to bottom)

| Element | Details |
|---------|---------|
| **Header** | `"SET PRICE"` text in accent500 gold, plus drag handle bar |
| **Icon** | 48px circle: `primary900` bg, `accent500 2px` border, `getLineAwesomeIcon(service.iconName)` at size 24 |
| **Service name** | 16px bold white, centered |
| **Category badge** | Small chip: `primary900` bg, `primary700` border, uppercase category text in neutral400 |
| **Current price** | Text `"Current: GHS X.XX"` in neutral500 (or `"No price set"`) |
| **Price input** | Full-width, `keyboardType: TextInputType.numberWithOptions(decimal: true)`, centered 32px bold text, accent500 cursor, wrapped in bordered container (primary700 / focused: accent500) |
| **GHS prefix** | Leading label before the input field |
| **SAVE button** | `KsButton(variant: primary)`, fullWidth — calls `_savePrice()` |
| **Dismiss** | Tap outside = cancel (default `showModalBottomSheet` behavior) |

### Interactions
- Input field is **auto-focused** when sheet opens (keyboard appears immediately)
- SAVE is **disabled** when input is empty or invalid
- On save: `CurrencyFormatter.parseToPesewas(value)` → `ref.read(serviceTypeProvider.notifier).updateServiceTypePrice(service.id, pesewas)` → `Navigator.pop()` to close sheet → state refreshes, row price text updates

---

## 3. Existing Patterns Preserved

- Category header collapse/expand ✅
- `KsSearchBar` in AppBar.bottom ✅
- `KsOfflineBanner` at body top ✅
- `KsEmptyState` for no-results ✅
- Loading + Error states ✅
- `CurrencyFormatter.parseToPesewas()` (no changes needed) ✅

---

## 4. Data Flow

```
Tap service row
  → showModalBottomSheet(PriceEditorSheet)
  → User enters new price
  → Tap SAVE
  → CurrencyFormatter.parseToPesewas(value)
  → ref.read(serviceTypeProvider.notifier).updateServiceTypePrice(id, pesewas)
  → Navigator.pop() close sheet
  → setState() refresh list (price text updates)
```

---

## 5. Out of Scope (Separate Session)

- `ServiceTypesScreen` — icon rendering (uses hardcoded `tools_solid`)
- `ServiceTypePickerV2` — icon rendering (uses hardcoded `tools_solid`)
- `job_card.dart` / `public_profile_screen.dart` — icon switch statements
- These are separate icon-fix tasks tracked for future sessions.

---

## 6. Verification

- `flutter analyze`: must pass with 0 new errors
- Build APK and run on phone
- Verify: service icons display correctly for each category
- Verify: bottom sheet opens/saves/dismisses
- Verify: search filters still work
- Verify: empty/loading/error states unchanged
