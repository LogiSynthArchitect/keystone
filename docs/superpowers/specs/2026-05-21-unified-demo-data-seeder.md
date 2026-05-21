# Unified Demo Data Seeder

**Date:** 2026-05-21
**Status:** Design (pending implementation)
**Motivation:** Two existing generators (`DemoDataService`, `MockDataGenerator`) are out of sync with the current 27-table schema, have compile errors, and miss entire feature modules (inventory, photos, follow-ups, reminders, etc.).

---

## Scope

Replace `demo_data_service.dart` and `mock_data_generator.dart` with a single `demo_data_seeder.dart`. Both old files are deleted.

The seeder is **temporary** — used for development/testing and removed before public launch.

---

## Trigger

Same as current: 5 taps on the dashboard title.

- **First 5-tap:** If no demo data exists → seed all tables.
- **Second 5-tap:** If demo data already exists → remove all demo data.
- Detection: check if a known `demo_job_001` exists in Hive.

---

## Tables Seeded

All 27 tables are covered. Data is written to **Hive local datasources** (offline-first cache). The app's normal sync process propagates to Supabase.

### Core entities

| Table | Count | Key details |
|-------|-------|-------------|
| **customers** | 8 | Ghanaian names, phone prefixes (024/055/020/054/027), varied property_types, lead_sources. `totalJobs` reflects real count, `lastJobAt` set. |
| **jobs** | 12 | Mix: 3 quoted, 3 in_progress, 4 completed, 2 invoiced. `quotedAt`/`inProgressAt`/`completedAt`/`invoicedAt` set accordingly. `followUpSentAt` set when `followUpSent=true`. Service types use valid text names from service_types table. |

### Child entities (per job)

| Table | Per job | Notes |
|-------|---------|-------|
| **job_services** | 2-4 | `domain` and `notes` populated. |
| **job_hardware** | 0-2 | Where applicable (not all jobs have hardware). `keySpec`, `material`, `finish`, `dimensions` set. |
| **job_parts** | 0-3 | `inventoryItemId` linked to a seeded inventory item where possible. |
| **job_expenses** | 0-2 | Categories: transport, parking, supplies, subcontractor. |
| **job_photos** | 0-1 | `storage_path` placeholder, `media_type` set to 'image'. |
| **job_audit_log** | 1-2 | Status transition entries. `userId` and `oldValues` populated. |

### Feature entities

| Table | Count | Notes |
|-------|-------|-------|
| **service_types** | 0 | Already seeded by migration (39 per user). Not duplicated. |
| **inventory_items** | 12 | Mix: 6 parts (screws, batteries, lubricant, etc.) + 6 hardware (Yale/Abus deadbolts, cylinders). Prices in pesewas. Varied quantities, some below low_stock_threshold to trigger alerts. |
| **inventory_restocks** | 4 | Linked to inventory items. `supplier_phone` set. |
| **inventory_stock_adjustments** | 4 | Mix of restock, job_use, manual_add, correction types. |
| **follow_ups** | 4 | 2 sent, 1 responded, 1 no_response. `sentAt` and `responseUpdatedAt` set correctly. |
| **correction_requests** | 2 | 1 pending, 1 approved. |
| **knowledge_notes** | 6 | Mix of text notes + 1 with photo. Tags, media_type set. |
| **note_job_links** | 3 | Links 3 notes to 3 different jobs. |
| **reminders** | 3 | 1 active, 1 snoozed, 1 resolved. |
| **activity_events** | 8 | Recent activity items for the dashboard activity feed. |
| **key_code_history** | 4 | Various key types (deadbolt, cabinet, padlock, auto) with realistic bitting_data. |
| **customer_audit_entries** | 4 | Field changes on 2 edited customers (phone, location, property_type). |
| **recurring_job_schedules** | 2 | 1 weekly (Mondays), 1 monthly (1st). |
| **job_templates** | 2 | 1 residential lock replacement template, 1 commercial master key template. |
| **app_events** | 0 | Skipped — deprecated table. |
| **password_reset_codes** | 0 | Skipped — service-role only. |
| **app_config** | 0 | Skipped — already has row from migration. |

---

## Key Fixes vs. Current Generators

| Issue | Current | Fixed |
|-------|---------|-------|
| `mock_data_generator.dart` won't compile | `quotedPrice: amt` (int → double) | Use `.toDouble()` |
| `totalJobs` always 0 | Hardcoded | Count actual jobs per customer |
| `lastJobAt` not set | Omitted | Set to most recent job date |
| `followUpSentAt` null when sent | Omitted | Set to job date + 1 day |
| Status timestamps null | All omitted | Set according to status: quoted→quotedAt, in_progress→inProgressAt, etc. |
| Inventory zero data | Not generated | 12 inventory items + restocks + adjustments |
| `domain`/`notes` on job_services | Omitted | Filled with realistic values |
| `keySpec`/`material`/`finish` on hardware | Omitted | Filled with realistic values |
| `inventoryItemId` on parts | Not linked | Linked to seeded inventory items |
| `userId` on audit entries | Omitted | Set to current user |
| Names are repetitive | Random suffixes | More varied name pool |

---

## Data Quality

- **Phone numbers:** Realistic Ghanaian prefixes: 024, 055, 020, 054, 027, 050, 059
- **Locations:** Real Accra neighborhoods: East Legon, Cantonments, Osu, Spintex, Tema, Madina, Dzorwulu, Labone
- **Prices:** In pesewas (GHS × 100). Realistic ranges: 50-500 GHS for service calls, 200-2000 GHS for full jobs
- **Dates:** Skewed recent: 70% within last 30 days, 30% within last 90 days
- **Names:** Real Ghanaian first names + surnames (Kwame Mensah, Abena Osei, Yaw Boateng, etc.)

---

## File Structure

**New file:**
```
lib/core/services/demo_data_seeder.dart
```

**Files deleted:**
```
lib/core/services/demo_data_service.dart
lib/core/utils/mock_data_generator.dart
```

**Dashboard trigger update:** `lib/features/dashboard/presentation/screens/dashboard_screen.dart` changes its import from `DemoDataService` to `DemoDataSeeder` and instantiates the new class instead. The 5-tap gesture handler logic stays the same.

**Dead code deleted:** `mock_data_generator.dart` has zero callers — confirmed via grep. Deleted alongside `demo_data_service.dart`.

---

## Detect / Remove

- `seeded()` returns true if `demo_job_001` exists in Hive jobs box.
- `remove()` deletes all seeded entities by known ID prefix/suffix pattern:
  - Job IDs: `demo_job_001` through `demo_job_012`
  - Customer IDs: `demo_cust_001` through `demo_cust_008`
  - Inventory IDs: tracked in a static list
  - Child entities: deleted by parent ID via existing `deleteXxxForJob()` methods
  - Independent entities (reminders, follow_ups, etc.): tracked by stored ID list
