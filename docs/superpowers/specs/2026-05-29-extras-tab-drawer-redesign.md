# Extras Tab — Modal Bottom Sheet Drawer Redesign

**Date:** 2026-05-29
**Project:** Keystone
**Feature:** Extras tab (Step 4) in Log Job screen

---

## Overview

Replace the current flat inline form layout on the Extras tab with five tappable summary cards, each opening a dedicated modal bottom sheet drawer. This reduces visual clutter and makes the tab feel cleaner and more organized ("sleeker").

---

## Main Tab Layout

Five cards stacked vertically, each showing:

| Card | Left side | Right side |
|------|-----------|------------|
| **Hardware Items** | Icon + "HARDWARE ITEMS" + "Locks, cylinders, remotes" | Item count + total GHS |
| **Expenses** | Icon + "EXPENSES" + "Transport, parking, subs" | Item count + total GHS |
| **Parts Used** | Icon + "PARTS USED" + "Parts and supplies" | Item count + total GHS |
| **Photos** | Icon + "PHOTOS" + "Before & after photos" | Photo count |
| **Notes** | Icon + "NOTES" + "Job notes" | Truncated note preview |

- Empty sections show "No items" / "No photos" / "No notes"
- Tap anywhere on a card → opens its modal bottom sheet
- Cards use existing dark theme: `ksc.primary800` background, `ksc.accent500` accent
- Customer history suggestions stay above the cards (if customer selected)

---

## Bottom Sheet Drawers (5 total)

All drawers share:
- Drag handle at top
- Header with section name, close (✕) button, and summary (count/total)
- DONE button at bottom → saves state, closes sheet, and updates main tab summary

### 1. Hardware Items Drawer
- Header: "HARDWARE ITEMS" + "N items · GHS X.XX"
- **SELECT FROM INVENTORY** button (accent, full width) → opens existing inventory picker bottom sheet (unchanged)
- Existing items rendered as compact cards with:
  - Item name, qty, unit price
  - Total line
  - Remove (✕) button
- **ADD MANUAL ENTRY** button (outlined, dashed) → appends `_HardwareRow` inline
- DONE button

### 2. Expenses Drawer
- Header: "EXPENSES" + "N items · GHS X.XX"
- Existing expense rows as compact cards showing: Category, Amount, Description, Remove button
- **ADD EXPENSE** button (outlined, dashed) → appends `_ExpenseRow` inline
- DONE button

### 3. Parts Used Drawer
- Header: "PARTS USED" + "N items · GHS X.XX"
- Existing parts as compact cards showing: Part Name, Qty, Cost, Remove button
- New part row with inline inventory typeahead suggestions (as currently implemented)
- **ADD PART** button (outlined, dashed) → appends `_PartRow` inline
- DONE button

### 4. Photos Drawer
- Header: "PHOTOS" + "N photos"
- **BEFORE** section: existing photo thumbnails + add button (camera/video/audio)
- **AFTER** section: existing photo thumbnails + add button
- Identical photo capture behavior to current inline implementation
- DONE button

### 5. Notes Drawer
- Header: "NOTES" + "Job notes"
- Multi-line text area (same as current `_notesController`)
- Character counter (N / 2000)
- DONE button

---

## Data Flow

- **State stays in `_LogJobScreenState`** — same lists (`_hardwareItems`, `_expenses`, `_parts`, `_beforePhotos`, `_afterPhotos`, `_notesController`)
- Drawers read & write to the same state objects
- DONE button: just calls `Navigator.pop()` — no persistence until full job save
- Main tab cards recompute summary counts/totals from the lists (already exist as `_isDirty`-style derived data)
- No new providers, no new entities, no new database changes

---

## Files Changed

| File | Change |
|------|--------|
| `lib/features/job_logging/presentation/screens/log_job_screen.dart` | Rewrite `_buildStep4()`, replace inline sections with card list, add 5 `_show*Drawer()` methods |

No new files. No model/entity/repo changes. Pure UI refactor.

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Empty section | Card shows "No items" / "No photos" / "No notes" in gray |
| All sections empty | All five cards show empty state — tab is clean, not crowded |
| Partial data | Each card accurately reflects its section's data |
| Photos count = 0 | "No photos" displayed; drawer still opens to allow adding |
| Notes empty | "No notes" displayed in gray on the card |
| Back navigation | Previous behavior unchanged (discard confirmation if dirty) |

---

## Non-Goals

- No changes to how data is saved/persisted
- No changes to other steps (1-3)
- No changes to edit_job_screen.dart (separate scope)
- No new design tokens or theme changes
