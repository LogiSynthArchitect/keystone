# Inventory Category System

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the generic `part`/`hardware` item type with a category system that shows type-specific fields (keys, locks, automotive, electronic, safe, consumable).

**Architecture:** Base `inventory_items` table with shared fields + a `jsonb attributes` column for type-specific data. A new `InventoryItemCategory` enum replaces the old `itemType` string. The UI renders conditional fields per category on the GENERAL tab using a category field registry.

**Tech Stack:** Flutter/Dart, Supabase (Postgres + jsonb), Riverpod

---

### Task 1: Database migration — category enum + attributes column

**Files:**
- Modify: `supabase/migrations/20260518000000_inventory_items.sql`
- Create: `supabase/migrations/20260522000000_inventory_categories.sql`

Create a new migration that:
1. Creates a Postgres enum: `CREATE TYPE item_category AS ENUM ('key', 'lock', 'automotive', 'electronic', 'safe', 'consumable');`
2. Adds `ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS category item_category NOT NULL DEFAULT 'consumable';`
3. Adds `ALTER TABLE inventory_items ADD COLUMN IF NOT EXISTS attributes jsonb NOT NULL DEFAULT '{}'::jsonb;`
4. Drops the old `item_type` column check constraint: `ALTER TABLE inventory_items DROP CONSTRAINT IF EXISTS inventory_items_item_type_check;`
5. Creates a GIN index on the attributes column: `CREATE INDEX IF NOT EXISTS idx_inventory_items_attributes ON inventory_items USING GIN (attributes);`

The `attributes` jsonb stores fields like:
```json
{
  "blankNumber": "SC1",
  "keywayType": "Schlage C",
  "hasTransponder": false
}
```

- [ ] **Step 1: Create migration file**

Write `supabase/migrations/20260522000000_inventory_categories.sql` with the SQL above.

- [ ] **Step 2: Run migration against dev**

Run: `supabase db push` or equivalent.
Expected: No errors, columns added.

---

### Task 2: Update entity and model

**Files:**
- Modify: `lib/features/inventory/domain/entities/inventory_item_entity.dart`
- Modify: `lib/features/inventory/data/models/inventory_item_model.dart`

**Entity changes:**
- Replace `final String itemType` with `final InventoryItemCategory category`
- Replace type-specific fields (brand, model, keySpec, material, finish, dimensions) with `final Map<String, dynamic> attributes`
- Keep all shared fields (name, cost, sale, quantity, etc.)
- Add `InventoryItemCategory` enum class above the entity:

```dart
enum InventoryItemCategory {
  key, lock, automotive, electronic, safe, consumable;

  String get displayName {
    switch (this) {
      case InventoryItemCategory.key: return 'KEY';
      case InventoryItemCategory.lock: return 'LOCK';
      case InventoryItemCategory.automotive: return 'AUTOMOTIVE';
      case InventoryItemCategory.electronic: return 'ELECTRONIC';
      case InventoryItemCategory.safe: return 'SAFE';
      case InventoryItemCategory.consumable: return 'CONSUMABLE';
    }
  }
}
```

**Model changes:**
- Map `category` from/to the new DB column
- Map `attributes` from/to `jsonb` column
- Implement `toJson`/`fromJson` for attributes

- [ ] **Step 1: Define `InventoryItemCategory` enum in entity file**
- [ ] **Step 2: Update entity — replace `itemType` string with `category` enum, replace old fields with `attributes` map**
- [ ] **Step 3: Update model — map new DB columns, handle jsonb serialization**
- [ ] **Step 4: Update `copyWith` on entity**
- [ ] **Step 5: Verify analysis**

---

### Task 3: Update repository and datasources

**Files:**
- Modify: `lib/features/inventory/domain/repositories/inventory_repository.dart`
- Modify: `lib/features/inventory/data/repositories/inventory_repository_impl.dart`
- Modify: `lib/features/inventory/data/datasources/inventory_local_datasource.dart`
- Modify: `lib/features/inventory/data/datasources/inventory_remote_datasource.dart` (if exists)

Update all repository/datasource methods to use the new `category` field instead of `itemType`. The filter/search logic changes from `itemType == 'part'` to `category == InventoryItemCategory.key`.

- [ ] **Step 1: Update repository interface**
- [ ] **Step 2: Update repository implementation**
- [ ] **Step 3: Update local datasource (Hive box schema)**
- [ ] **Step 4: Update remote datasource (Supabase queries)**
- [ ] **Step 5: Handle Hive schema migration for existing data**

---

### Task 4: Create category field registry

**Files:**
- Create: `lib/features/inventory/presentation/widgets/inventory_category_fields.dart`

This is the core UI piece — a widget that renders the right form fields for each category:

```dart
class InventoryCategoryFields extends StatelessWidget {
  final InventoryItemCategory category;
  final Map<String, dynamic> attributes;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final StateSetter rebuild;

  // Returns the list of field definitions for a given category
  static List<CategoryField> fieldsFor(InventoryItemCategory cat) {
    switch (cat) {
      case InventoryItemCategory.key:
        return [
          CategoryField(name: 'blankNumber', label: 'BLANK NUMBER', type: FieldType.text),
          CategoryField(name: 'keywayType', label: 'KEYWAY TYPE', type: FieldType.text),
          CategoryField(name: 'hasTransponder', label: 'TRANSPONDER', type: FieldType.boolean),
          CategoryField(name: 'transponderFrequency', label: 'FREQUENCY', type: FieldType.text, dependsOn: 'hasTransponder'),
          CategoryField(name: 'keyMaterial', label: 'MATERIAL', type: FieldType.text),
        ];
      // ... other categories
    }
  }
}
```

Each field type renders differently:
- `FieldType.text` → text input with underline
- `FieldType.boolean` → toggle switch
- `FieldType.number` → numeric input
- `FieldType.select` → dropdown pill chips

The widget reads/writes from the `attributes` map directly, calling `onChanged` when fields update.

- [ ] **Step 1: Define `CategoryField` data class and `FieldType` enum**
- [ ] **Step 2: Implement `fieldsFor()` for all 6 categories**
- [ ] **Step 3: Build the form UI that renders fields from the registry**
- [ ] **Step 4: Handle conditional fields (e.g. frequency only shows when transponder is yes)**
- [ ] **Step 5: Verify analysis**

---

### Task 5: Update inventory screen — GENERAL tab

**Files:**
- Modify: `lib/features/inventory/presentation/screens/inventory_screen.dart`

Replace the old GENERAL tab content (case 1 in `_buildStepContent`) with:

1. Category selection — replace the old PART/HARDWARE chips with full category list (KEY, LOCK, AUTOMOTIVE, ELECTRONIC, SAFE, CONSUMABLE) using the same `_buildTabChip` pattern
2. Category fields — when a category is selected, render `InventoryCategoryFields` below it
3. Remove the old brand/model/keySpec/material/finish/dimensions fields (they're now in `attributes` per category)

The category selection also updates the `category` variable and resets the attributes map when switching categories.

- [ ] **Step 1: Replace PART/HARDWARE chips with 6-category list**
- [ ] **Step 2: Add `InventoryCategoryFields` widget below category selector**
- [ ] **Step 3: Add category change handler that resets/retains attributes**
- [ ] **Step 4: Update save handler to pass `attributes` map**
- [ ] **Step 5: Verify analysis**

---

### Task 6: Update inventory screen — display (list view)

**Files:**
- Modify: `lib/features/inventory/presentation/screens/inventory_screen.dart`

Update the inventory item cards in the list view to show:
- Category badge (colored chip: KEY, LOCK, etc.)
- Primary identifying attribute (e.g. blank number for keys, brand for locks)
- Keep existing: name, price, stock count

- [ ] **Step 1: Update `_buildItemCard` to show category badge**
- [ ] **Step 2: Show primary identifying field from attributes**
- [ ] **Step 3: Update filter sheet to filter by category**
- [ ] **Step 4: Verify analysis**

---

### Task 7: Run migration + deploy

- [ ] **Step 1: Run Supabase migration**
- [ ] **Step 2: Full rebuild on phone (flutter run)**
- [ ] **Step 3: Add a test item for each category to verify fields render correctly**
- [ ] **Step 4: Commit all changes**

---

## File Summary

| Action | File |
|--------|------|
| Create | `supabase/migrations/20260522000000_inventory_categories.sql` |
| Modify | `lib/features/inventory/domain/entities/inventory_item_entity.dart` |
| Modify | `lib/features/inventory/data/models/inventory_item_model.dart` |
| Modify | `lib/features/inventory/presentation/providers/inventory_providers.dart` |
| Modify | `lib/features/inventory/data/datasources/inventory_local_datasource.dart` (Hive box handling) |
| Create | `lib/features/inventory/presentation/widgets/inventory_category_fields.dart` |
| Modify | `lib/features/inventory/presentation/screens/inventory_screen.dart` |
| Modify | `lib/core/services/demo_data_seeder.dart` |
| Modify | `lib/features/job_logging/presentation/screens/log_job_screen.dart` (filter by category) |
