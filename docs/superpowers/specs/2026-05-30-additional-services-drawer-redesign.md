# Additional Services — Nested Drawer Redesign

**Date:** 2026-05-30
**Project:** Keystone
**Feature:** Additional Services section in Step 1 (SERVICE) of Log Job

---

## Overview

Replace the current inline-editable service cards inside the Additional Services drawer with a two-drawer flow: a **summary list drawer** and a **detail edit drawer**. All quantity and price editing moves to the nested detail drawer — nothing is editable inline.

**Scope boundary:** Only the ADDITIONAL SERVICES section changes. The main SERVICE PERFORMED picker (ServiceTypePickerV2) stays as-is.

---

## Current Behavior

1. Tap "ADD SERVICE" → opens a single bottom sheet
2. The bottom sheet shows **selected services** with inline qty stepper + price field + total — all directly editable
3. Below that, a list of **available services** grouped by category
4. Tap an available service → it gets added to the selected list **inline**, with qty/price fields visible immediately
5. "DONE" commits back to the parent screen

**Problem:** The first drawer has too much inline editing. Selecting a service and immediately seeing editable qty/price fields makes the list long and the interaction noisy.

---

## Proposed Behavior

### Flow

```
ADD SERVICE → Drawer 1: Service List  ──tap available service──→  Drawer 2: Edit Service
                  (summary cards)       ──tap existing card───→      (qty + price)
                      ↑                                                │
                      └─────────── close (add/save) ───────────────────┘
```

### Drawer 1 — Additional Services (Summary List)

| Element | Detail |
|---------|--------|
| Purpose | Browse available services, view already-selected ones as summary cards |
| Header | "ADDITIONAL SERVICES" with count subtitle |
| Selected section | Stacked cards showing: icon + service name, qty × unit price, line total, ✕ remove button |
| Available section | Grouped by category (as currently), each row shows icon + name + default price |
| Tap available service | Opens Drawer 2 to configure qty + price |
| Tap existing card | Opens Drawer 2 to edit qty + price |
| Delete | ✕ button on card removes service immediately (local state) |
| DONE button | Commits local state to parent screen |

**Card design (selected service):**
```
┌──────────────────────────────────────────┐
│ 🔧 DOOR LOCK REPAIR              [✕]    │
│   Qty: 2 × GHS 150.00                   │
│   Total: GHS 300.00                      │
└──────────────────────────────────────────┘
```
- No fields, no steppers, no inputs — read-only summary
- Bottom border separator between cards (matching `Color(0xFF1E2A3A)` from current drawer)

### Drawer 2 — Edit Service (Detail Entry)

| Element | Detail |
|---------|--------|
| Purpose | Set quantity and unit price for one service, then confirm or cancel |
| Header | "EDIT SERVICE" with a close (✕) button |
| Service label | Read-only icon + service name |
| Qty | `_buildDrawerQtyStepper` (existing) — [-] [count] [+] |
| Unit price | TextField with underline-only decoration (no background, no box border) + "GHS" label |
| Total | Calculated below as large bold text |
| Buttons | CANCEL (TextButton, closes drawer without adding) + ADD/SAVE (ElevatedButton, commits this service) |
| Tap outside | Dismisses with discard confirmation if dirty |

**Price field style (matching existing drawer pattern):**
```
UNIT PRICE (GHS)
──────────────────  150.00
```
- `UnderlineInputBorder` only — no background fill, no `OutlineInputBorder`
- Same as `_buildDarkField` in the parent screen: `enabledBorder: UnderlineInputBorder(borderSide: Color(0xFF2A3A4A))`, `focusedBorder: UnderlineInputBorder(borderSide: Color(0xFF4A90D9))`
- `filled: false`

**Total display:**
```
TOTAL
GHS 300.00
```
- Right-aligned below the fields

---

## Drawer Pattern Consistency

Both drawers follow the existing bottom sheet pattern used across the app:

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: context.ksc.primary800,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
  ),
  builder: (ctx) {
    return StatefulBuilder(
      builder: (ctx, setSheetState) { ... },
    );
  },
);
```

Key structural elements (consistent with hardware, expenses, parts drawers):
- Drag handle (40×4 rounded container at top)
- Header row with title + close button (✕)
- Flexible scrollable content area
- Pinned DONE button at bottom
- Dirty tracking with discard confirmation dialog (`_confirmDrawerClose`)
- Local working copy pattern (changes only commit to parent on DONE)

---

## Data Model

No changes to `_ServiceRow` — it already has `serviceType`, `qtyController`, and `priceController`. The change is purely UI: how these are displayed and edited across two drawers instead of one.

---

## States

| State | Drawer 1 Behavior | Drawer 2 Behavior |
|-------|-------------------|-------------------|
| Empty (no services added) | "No additional services" empty state + available list | — |
| Adding first service | O | Opens Drawer 2 with default qty=1, price=defaultPrice if available |
| Editing existing | Tapping a card opens Drawer 2 pre-filled with current values | Shows current qty and price |
| Dirty (unsaved change in Drawer 2) | — | Close (✕ or tap outside) shows discard confirmation |

---

## Error Handling

| Condition | Behavior |
|-----------|----------|
| Invalid quantity (< 1) | Stepper prevents going below 1 |
| Invalid price (non-numeric) | CurrencyInputFormatter prevents invalid input |
| User closes Drawer 1 with pending changes | `_confirmDrawerClose` dialog |
| User closes Drawer 2 with pending changes | `_confirmDrawerClose` dialog |
| Service already added (duplicate) | Already-disabled in available list (current behavior preserved) |

---

## What Stays the Same

- `_ServiceRow` class — no changes
- `_showAdditionalServicesDrawer()` method — still the entry point from `_buildStep1()`
- ServiceType data fetching and grouping by category
- Dirty tracking + discard confirmation
- DONE button commits to parent via `setState((){ _additionalServices..clear()..addAll(localServices) })`
- Available services list appearance (icon, name, price, disabled-if-added)

## What Changes

- Selected services in Drawer 1 become read-only summary cards (remove inline fields)
- Tapping an available service → opens Drawer 2 instead of adding inline
- Tapping an existing card → opens Drawer 2 for editing
- New `_showServiceEditDrawer(...)` method for Drawer 2
- New summary card builder for Drawer 1

## Non-Goals

- No change to the main SERVICE PERFORMED picker
- No change to `ServiceTypePickerV2` widget
- No new entities, repositories, or data models
- No database changes
