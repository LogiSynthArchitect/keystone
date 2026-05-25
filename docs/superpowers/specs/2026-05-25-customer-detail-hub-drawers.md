# Customer Detail — Hub + Drawers Redesign

**Date:** 2026-05-25
**Project:** Keystone
**Feature:** Customer Detail screen reorganization

---

## Overview

Replace the current tab-based Customer Detail screen (Key Codes | Service History) with a **Hub + Drawers** layout: a compact overview card at the top, then a grid of action tiles. Each tile opens a modal bottom sheet drawer showing the full section content. This matches the bottom-sheet drawer pattern already used across Inventory, Notes Add, Pricing, and Customer Add screens.

---

## Layout

```
┌──────────────────────────────────┐
│  KsAppBar — "CUSTOMER DETAILS"   │ ← Edit + Merge + Delete actions
├──────────────────────────────────┤
│  ┌────────────────────────────┐  │
│  │  Compact Hero Card         │  │ ← Avatar initial, Name, Property badge
│  │  📞 +233 24 123 4567  💬   │  │    Phone (tappable WhatsApp), Location
│  │  📝 Notes preview (if any)  │  │
│  └────────────────────────────┘  │
│  ┌────────────────────────────┐  │
│  │  05 JOBS | ₵4.2K | 12 DAYS │  │ ← Minimal stats row (3 metrics)
│  └────────────────────────────┘  │
│                                  │
│  ┌──────┐ ┌──────┐ ┌──────┐    │
│  │ 🔑   │ │ 📋   │ │ 📎   │    │ ← Action tiles (2 columns, 2-3 rows)
│  │KEYS  │ │HISTORY│ │NOTES │    │    Each shows label + count/preview
│  │ 2    │ │ 5    │ │ 3    │    │
│  └──────┘ └──────┘ └──────┘    │
│  ┌──────┐ ┌──────┐              │
│  │ 🔄   │ │ 📞   │              │ ← Recurring + WhatsApp direct
│  │REPEAT│ │ MSG  │              │
│  │ Qtrly │ │      │              │
│  └──────┘ └──────┘              │
│                                  │
│  ┌────────────────────────────┐  │
│  │       + LOG NEW JOB         │  │ ← Full-width gold button
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

---

## Components

### 1. Compact Hero Card
- Avatar initial circle (60px)
- Name (uppercase) + Property type badge
- Phone number (tappable → WhatsApp) with WhatsApp icon
- Location with map pin
- Customer notes (if non-empty, max 2 lines with ellipsis)

Reuses existing patterns from `_buildProfileModule` — just more compact.

### 2. Stats Row
3 metrics inline:
- Total Jobs
- Lifetime Revenue (formatted short)
- Days since last visit (or "NEW" if no jobs)

### 3. Action Tiles (2-column grid)

Each tile is a `GestureDetector` → `Container` with:
- Emoji/icon at top
- Section label (uppercase, small)
- Preview text or count

| Tile | Content when tapped |
|------|-------------------|
| **Key Codes** | `showModalBottomSheet` with existing key code list + Add button |
| **Service History** | `showModalBottomSheet` with filtered job timeline |
| **Notes** | `showModalBottomSheet` with notes linked to this customer's jobs |
| **Recurring** | `showModalBottomSheet` with recurring schedules for this customer |
| **WhatsApp** | Directly opens WhatsApp (no drawer) |

### 4. Bottom Sheets (Drawers)
Each drawer follows the established pattern:
- Dark background (`primary800`)
- Drag handle at top
- Title header
- Scrollable content
- Close button or swipe-down dismiss

### 5. Bottom Action Bar
- Full-width gold `KsButton` → "LOG NEW JOB"
- Same as current bottom bar — no change needed

---

## Reusable Components Used

| Component | Usage |
|-----------|-------|
| `KsAppBar` | App bar (already used) |
| `KsButton` | LOG NEW JOB, ADD KEY CODE (already added) |
| `KsStepDrawer` | Not directly — sections are single-view sheets, not multi-step |
| `showModalBottomSheet` + `DraggableScrollableSheet` | Each tile's drawer |
| `WhatsAppLauncher` | Phone tap action (already wired) |
| `DateFormatter` | Last visit display |
| `CurrencyFormatter` | Revenue display |

---

## Sections Implementation

### Key Codes Drawer
Reuses existing `_KeyCodesTab` widget — extract into a reusable widget `KeyCodesListSheet` that renders in a bottom sheet.

### Service History Drawer
Reuses existing `_ServiceHistoryTab` widget — extract into `ServiceHistorySheet`. Keeps the timeline layout, summary header (total visits + total spent).

### Notes Drawer
NEW — queries `noteJobLinkRepository` for links to this customer's jobs, then fetches linked notes. Shows a list of note titles with service type badges. Tap opens existing NoteDetailScreen.

### Recurring Schedules Drawer
NEW — queries `recurringScheduleLocalDatasource` for schedules where `customerId` matches. Shows upcoming schedule with next due date, interval type, service type.

---

## File Changes

| File | Change |
|------|--------|
| `customer_detail_screen.dart` | Replace tabbed layout with hub + tile grid. Move Key Codes + History content into reusable widgets. |
| NEW: `key_codes_sheet.dart` | Extracted from `_KeyCodesTab` — bottom sheet version |
| NEW: `service_history_sheet.dart` | Extracted from `_ServiceHistoryTab` — bottom sheet version |
| NEW: `customer_notes_sheet.dart` | Query notes linked to customer's jobs, display in sheet |
| NEW: `recurring_schedules_sheet.dart` | Query recurring schedules, display in sheet |

---

## Future Considerations
- Notes tile requires `noteJobLinkRepository` integration
- Recurring schedules tile requires datasource integration
- Both are independent — can add tiles incrementally without breaking existing functionality
