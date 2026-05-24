# Job Template System — Redesign Specification

> **Status:** Approved for implementation  
> **Last updated:** 2026-05-24  
> **Design pattern:** Independent entity first → relational later

---

## 1. Problem Statement

Job Templates currently save correctly (Direction A) but **cannot be used to create a job** (Direction B). The `onSelectTemplate` callback has zero consumers making the feature incomplete dead weight. Templates are also local-only (Hive) despite the Supabase table existing.

For a locksmith business doing 5–10 jobs per day per technician, templates eliminate 15–30 minutes of repetitive data entry by pre-populating services, hardware, and parts that are identical across job types.

---

## 2. Overview

### Direction A — SAVE job as template (EXISTS, works)

```
LogJobScreen → Fill form → Save job → "Save as template?" prompt
    → Name it → Snapshot saved to Hive (local only)
```

### Direction B — CREATE job FROM template (MISSING, to build)

```
LogJobScreen → Tap TEMPLATES button → Picker sheet (bottom sheet)
    → Tap template card → Form pre-filled → User adjusts → Save job
```

### Sync (MISSING, to build)

```
Local Hive ←→ Supabase (table + RLS already exist)
    → Templates available across all devices
```

---

## 3. Data Model

### 3.1 Typed Snapshot Items (replace raw `List<Map>`)

```dart
class TemplateServiceItem {
  final String id;
  final String serviceType;   // matches service_types.name
  final int quantity;
  final int? unitPrice;       // in pesewas, snapshot at save time
  final int sortOrder;

  const TemplateServiceItem({...});

  Map<String, dynamic> toJson();
  factory TemplateServiceItem.fromJson(Map<String, dynamic> json);
}

class TemplateHardwareItem {
  final String id;
  final String name;
  final int quantity;
  final int? unitSalePrice;       // snapshot at save time
  final String? inventoryItemId;  // optional link back to inventory

  const TemplateHardwareItem({...});

  Map<String, dynamic> toJson();
  factory TemplateHardwareItem.fromJson(Map<String, dynamic> json);
}

class TemplatePartItem {
  final String id;
  final String name;
  final int quantity;
  final int? unitPrice;          // snapshot at save time
  final String? inventoryItemId; // optional link back to inventory

  const TemplatePartItem({...});

  Map<String, dynamic> toJson();
  factory TemplatePartItem.fromJson(Map<String, dynamic> json);
}
```

### 3.2 Updated JobTemplateEntity

```dart
class JobTemplateEntity {
  final String id;
  final String userId;
  final String name;
  final String serviceType;
  final String? notes;
  final List<TemplateServiceItem> services;
  final List<TemplateHardwareItem> hardwareItems;
  final List<TemplatePartItem> parts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JobTemplateEntity({...});

  // copyWith, toModel, fromModel
}
```

### 3.3 Supabase Schema (already exists, no migration needed)

```sql
CREATE TABLE IF NOT EXISTS public.job_templates (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  service_type text NOT NULL,
  notes text,
  services_json jsonb DEFAULT '[]'::jsonb,      -- stores List<TemplateServiceItem.toJson>
  hardware_json jsonb DEFAULT '[]'::jsonb,       -- stores List<TemplateHardwareItem.toJson>
  parts_json jsonb DEFAULT '[]'::jsonb,          -- stores List<TemplatePartItem.toJson>
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
```

---

## 4. Implementation Phases

### Phase 1 — Template Infrastructure

| # | Task | Current State | Action |
|---|------|--------------|--------|
| 1.1 | Create typed value classes | Raw `List<Map>` | New: `TemplateServiceItem`, `TemplateHardwareItem`, `TemplatePartItem` |
| 1.2 | Update JobTemplateEntity | Uses `List<Map>` | Change entity + model serialization to use typed items |
| 1.3 | Supabase remote datasource | Table exists, no datasource | New: `JobTemplateRemoteDatasource` |
| 1.4 | Repository sync | Local only | Update: sync local ↔ remote on save/get/delete |

#### 1.1 Files to create
- `lib/features/job_templates/domain/entities/template_service_item.dart`
- `lib/features/job_templates/domain/entities/template_hardware_item.dart`
- `lib/features/job_templates/domain/entities/template_part_item.dart`

#### 1.2 Files to change
- `lib/features/job_templates/domain/entities/job_template_entity.dart`
- `lib/features/job_templates/data/models/job_template_model.dart`

#### 1.3 Files to create
- `lib/features/job_templates/data/datasources/job_template_remote_datasource.dart`

#### 1.4 Files to change
- `lib/features/job_templates/data/repositories/job_template_repository_impl.dart`
- `lib/features/job_templates/presentation/providers/job_template_provider.dart`

---

### Phase 2 — Create Job from Template (Direction B)

| # | Task | Description |
|---|------|-------------|
| 2.1 | TemplatePickerSheet widget | Bottom sheet, 2-col compact card grid, matches Option B design |
| 2.2 | TEMPLATES button in LogJobScreen | Gold pill button in app bar |
| 2.3 | Wire pre-population | `_serviceType`, `_additionalServices`, `_hardwareItems`, `_parts`, `_notesController` filled from template |
| 2.4 | Clean state tracking | Reset "from template" status if user manually modifies a field |

#### 2.1 TemplatePickerSheet design

- **Trigger:** Tapping TEMPLATES button in LogJobScreen app bar
- **Type:** `showModalBottomSheet`, `isScrollControlled: true`
- **Layout:** 2-column grid (matching pricing card Option B)
  - Each card: icon (28×28) + template name (bold, truncate) + category tag + service/part/hardware count row
  - Full-width card with gold accent border on tap
- **Behavior:** Closing the sheet without selecting does nothing
- **Filter bar (optional):** Category filter at top (All / Automotive / Residential / Commercial)

#### 2.2 LogJobScreen template integration

```dart
// In _LogJobScreenState, add:
String? _fromTemplateId;  // track which template was applied

// Template button in app bar (next to filter/search):
KsButton(
  onPressed: () => _showTemplatePicker(),
  label: "TEMPLATES",
  type: KsButtonType.gold,  // or similar
)

void _showTemplatePicker() async {
  final template = await TemplatePickerSheet.show(context);
  if (template == null) return;
  _applyTemplate(template);
}

void _applyTemplate(JobTemplateEntity template) {
  setState(() {
    _fromTemplateId = template.id;
    _serviceType = template.serviceType;
    _notesController.text = template.notes ?? '';

    // Clear existing lists
    for (final s in _additionalServices) s.dispose();
    for (final h in _hardwareItems) h.dispose();
    for (final p in _parts) p.dispose();
    _additionalServices.clear();
    _hardwareItems.clear();
    _parts.clear();

    // Populate from template
    for (final s in template.services) {
      final row = _ServiceRow();
      row.serviceType = s.serviceType;
      row.qtyController.text = s.quantity.toString();
      row.priceController.text = s.unitPrice != null
          ? (s.unitPrice! / 100.0).toStringAsFixed(2)
          : '';
      _additionalServices.add(row);
    }

    for (final h in template.hardwareItems) {
      final row = _HardwareRow();
      row.nameController.text = h.name;
      row.qtyController.text = h.quantity.toString();
      if (h.inventoryItemId != null) {
        row.inventoryItemId = h.inventoryItemId;
        // Look up inventoryItem for price
      }
      _hardwareItems.add(row);
    }

    for (final p in template.parts) {
      final row = _PartRow();
      row.nameController.text = p.name;
      row.qtyController.text = p.quantity.toString();
      row.inventoryItemId = p.inventoryItemId;
      _parts.add(row);
    }
  });
}
```

#### 2.4 Clean state tracking

If user manually changes any pre-filled field, clear `_fromTemplateId` so the
system doesn't try to track template origin — the snapshot is now a custom job.

---

### Phase 3 — Template Management

| # | Task | Description |
|---|------|-------------|
| 3.1 | Rename template | Long-press context menu on template card → inline edit dialog |
| 3.2 | Redesign JobTemplatesScreen | Replace flat list with Option B compact card grid |

#### 3.1 Rename flow

```dart
// Long press on template card in JobTemplatesScreen
onLongPress: () {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: 'RENAME TEMPLATE',
      content: TextField(initialValue: t.name, ...),
      actions: [
        TextButton('CANCEL'),
        TextButton('SAVE', onPressed: () {
          ref.read(jobTemplateProvider.notifier).renameTemplate(t.id, newName);
        }),
      ],
    ),
  );
}
```

#### 3.2 JobTemplatesScreen redesign

- Replace `ListView.builder` with a `Wrap` grid (same pattern as pricing cards)
- Each card shows: icon, name, category, last-used date, service/hardware/part counts
- Same visual language as Pricing Option B (rounded containers, navy, gold accents)

---

### Phase 4 — Verification

| # | Task | Description |
|---|------|-------------|
| 4.1 | flutter analyze | 0 errors, 0 warnings |
| 4.2 | Hot reload test | Test Direction B end-to-end on phone |

---

## 5. Visual Reference

### 5.1 Template Picker Sheet (Phase 2.1)

```
┌─────────────────────────────────┐
│          ─── (handle)           │
│  SELECT TEMPLATE           ✕    │
│                                 │
│  ┌──────────┐ ┌──────────┐     │
│  │ 🚗       │ │ 🔐       │     │
│  │ CAR KEY  │ │ DEADBOLT │     │
│  │ DUPL.    │ │ REPL.    │     │
│  │ Auto     │ │ Res.     │     │
│  │ 1 svc    │ │ 2 svc    │     │
│  └──────────┘ └──────────┘     │
│  ┌──────────┐ ┌──────────┐     │
│  │ 🏢       │ │ 📡       │     │
│  │ MASTER   │ │ SMART    │     │
│  │ KEY SYS. │ │ LOCK     │     │
│  │ Comm.    │ │ Res.     │     │
│  │ 1 svc    │ │ 2 svc    │     │
│  └──────────┘ └──────────┘     │
└─────────────────────────────────┘
```

### 5.2 Pre-populated form (Phase 2.3)

```
┌─────────────────────────────────┐
│ ← LOG JOB        [TEMPLATES]   │
│ SERVICE     CUSTOMER  LOCATION… │
│                                 │
│ SERVICE: Deadbolt Replacement   │
│          [FROM TEMPLATE]        │
│ CUSTOMER: ____________________  │
│ PHONE:    ____________________  │
│                                 │
│ ADDITIONAL SERVICES — 2 items   │
│  Remove old deadbolt  ×1  GHS60 │
│  Install new deadbolt ×1  GHS80 │
│                                 │
│ HARDWARE — 1 item               │
│  Deadbolt lock set      ×1 GHS150│
└─────────────────────────────────┘
```

---

## 6. Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Price behavior | Snapshot at template save time | Prices change over time; template should reflect what was charged when created. User can adjust. |
| Inventory linking | Optional `inventoryItemId` | Allows future price refresh/lookup but doesn't break if item is deleted |
| Sync strategy | Local-first with remote sync | Hive is primary, Supabase mirrors. Save→local first, then remote (fire-and-forget). |
| Pre-population scope | Services, hardware, parts, notes, serviceType | Customer/location/date/amounts are per-job unique — never pre-filled |
| Template origin tracking | `_fromTemplateId` field | Used only for potential "created from template" analytics. Cleared on manual edit. |

---

## 7. File Change Summary

```
NEW FILES:
  lib/features/job_templates/domain/entities/template_service_item.dart
  lib/features/job_templates/domain/entities/template_hardware_item.dart
  lib/features/job_templates/domain/entities/template_part_item.dart
  lib/features/job_templates/data/datasources/job_template_remote_datasource.dart
  lib/features/job_templates/presentation/widgets/template_picker_sheet.dart

CHANGED FILES:
  lib/features/job_templates/domain/entities/job_template_entity.dart
  lib/features/job_templates/data/models/job_template_model.dart
  lib/features/job_templates/data/repositories/job_template_repository_impl.dart
  lib/features/job_templates/presentation/providers/job_template_provider.dart
  lib/features/job_templates/presentation/screens/job_templates_screen.dart
  lib/features/job_logging/presentation/screens/log_job_screen.dart
```

---

## 8. Rollback Plan

If Phase 2 (create from template) introduces regressions:

1. Revert changes to `log_job_screen.dart` (the TEMPLATES button and pre-population)
2. The typed item classes and remote sync (Phase 1) are backwards-compatible — old raw-map templates in Hive will still load and display
3. Template screen redesign is cosmetic — revert to previous list if needed
