# Reviewer Remediation Todo — Knowledge Base + Inventory

## P0 — Inventory: Replace Full-Delete Sync with Diff-Based Push-Before-Pull
- [ ] **Add `syncStatus` to `InventoryItemEntity`** — `'pending'` for new/edited items, `'synced'` after server confirms
- [ ] **Repository `createItem`/`updateItem`:** Mark entity as `syncStatus: 'pending'` on local save (already client UUIDv4 — no remapping needed)
- [ ] **SyncOrchestrator inventory phase:** PUSH all `pending` items to Supabase (upsert `ON CONFLICT (id) DO UPDATE`) before any PULL
- [ ] **Replace timestamp LWW with OCC lock array:** Do NOT diff by `updated_at` — mobile clocks are untrustworthy. Use the same `correction_fields` / lock array pattern already built for Jobs. When Admin edits an item on the web, Supabase locks specific fields. The PULL phase respects those locks regardless of local clock skew.
- [ ] **If OCC is over-engineered for single-user case, use server-authoritative clock:** Fetch server time from response `Date` header during sync handshake, calculate drift offset, apply to all local timestamps before diffing. Recalculate offset every sync cycle.
- [ ] **Diff merge logic (using OCC):** For each remote item: compare field-level lock array. If a field is locked by Admin → overwrite local. If local has unsaved edits → preserve local. Mixed → merge field-by-field.
- [ ] **Never call `_box.clear()` again.** This is a hard ban.

## P0 — Inventory: `file://` Photo Poison Removed
- [ ] **Remove DEV-TEMP bypass** in `_pickInventoryImage()` — stop storing local file paths as `coverImageUrl`
- [ ] **Inventory photo goes through 3-Phase Orchestrator:** (1) upload to Storage → (2) save `remote_url` to local Hive → (3) only then sync item record to DB
- [ ] Same per-file idempotency as Notes: `remoteUrl` persisted immediately on upload, retries skip already-uploaded files

## P0 — Inventory: Weighted-Average Cost Integrity
- [ ] **Restock flow:** Enforce `unitCost > 0` validation. If user enters 0, show warning: "Zero cost will skew Auto-COGS profit calculations. Proceed?"
- [ ] **Manual stock additions (non-restock):** Either (a) require unit cost OR (b) explicitly copy item's current `defaultCostPrice` into the adjustment math so the weighted average isn't silently diluted
- [ ] **Add Write-Ahead Log (WAL) transaction pattern** for restock: write double-entry to `_meta` box before mutating item box. On crash recovery, replay WAL to reconcile restock ledger vs item cost. Same pattern as Knowledge Base.

## P0 — Inventory: `search_index` + Isolate Offloading
- [ ] **Add `search_index` field to `InventoryItemEntity`** — single concatenated string built at save time: `"${name} ${brand} ${model} ${location} ${category} ${allAttributeValues}"` — lowercased, deduplicated
- [ ] **Search bar filters against `search_index` only** — not against individual attribute maps
- [ ] **Offload filtering to persistent Isolate worker (actor model):** NOT `Isolate.run()` (which serializes 3000 strings across the boundary per keystroke). Instead: spawn one isolate on screen load, send `searchIndexes` once via `SendPort`. On each keystroke, send only the tiny `String query` across the boundary. Worker holds the full list in its own memory and returns `List<int>` matching indices. Main-thread serialization drops from megabytes to bytes.

## P0 — Knowledge Base: Idempotent Binary Uploads to Storage
- [ ] `NoteAttachmentModel` gains `remoteUrl` (canonical, synced via JSONB) + `localPath` (transient Hive-only field)
- [ ] **Per-file upload:** Upload each binary individually; immediately persist `remoteUrl` to local Hive on success
- [ ] **Idempotent retry:** Before upload, check if `remoteUrl` already exists — skip if so (eliminates orphan accumulation)
- [ ] If any file in a batch fails, note stays `pending` — but already-uploaded files are never re-uploaded
- [ ] `toJson()` only syncs `remoteUrl`; detail screen falls back to streaming from `remoteUrl` when `localPath` is null

## P0 — Knowledge Base: Client-Side UUIDv4 as Absolute PK
- [ ] **Schema migration:** Change `knowledge_notes.id` from `DEFAULT uuid_generate_v4()` to client-supplied (remove default; existing rows already have stable UUIDs)
- [ ] **Repository change:** `createNote()` includes `'id': note.id` in the insert payload — client UUIDv4 becomes the server PK
- [ ] **`syncPendingNotes()` change:** Remove the delete-and-replace dance (lines 156-158). Keep local UUID; server accepts it as-is
- [ ] **Idempotent upsert:** `syncPendingNotes()` uses `ON CONFLICT (id) DO UPDATE` instead of INSERT — same pattern as Jobs/Customers. Dropped ACK retry silently updates same row.
- [ ] **Never roll a new UUID for an existing entity.**
- [ ] **Security:** PK constraint + RLS (`auth.uid() = user_id`) + optional BEFORE INSERT trigger for UUIDv4 format validation

## P0 — Service Pricing: PATCH Semantics + correction_fields OCC
- [ ] **Add `correction_fields text[]` and `updated_by text` columns to `service_types` table** — same schema as Jobs. Mobile sets `updated_by='mobile'`, admin web dashboard sets `updated_by='admin'`
- [ ] **`ServiceTypeRepositoryImpl.updateServiceType` becomes a PATCH** — only transmits `{default_price, correction_fields, updated_at}` when called from the pricing drawer, not the full entity. Never PUT name/category/icon from the pricing screen
- [ ] **Add `ServiceTypeRepositoryImpl.updateServiceTypeName`** — separate PATCH for admin name edits, transmits only `{name, correction_fields, updated_at}`
- [ ] **`ServiceTypeNotifier.savePriceOnly` fires scoped PATCH payload** — `copyWith` is a memory operation for UI state only. The wire format omits name, category, icon. Admin rename survives the tech's price save
- [ ] **Sync merge uses correction_fields array** — no field-level collision between price change (`['default_price']`) and name change (`['name']`). Each side only transmits what it changed. Intersection = empty → clean merge

## P0 — Service Pricing: Server-Authoritative Seeding (Kill Zombie Duplicates)
- [ ] **Add `has_seeded_services bool DEFAULT false` to `user_settings` table** — single source of truth for whether this account has been seeded
- [ ] **Create `seed_default_service_types(p_user_id UUID)` Supabase RPC** — SECURITY DEFINER, checks `has_seeded_services` before inserting, flips flag atomically. Never generates duplicate rows regardless of client retry
- [ ] **Remove `SeedDefaultServiceTypesUseCase` from client** — the client no longer guesses based on "is local empty?". Network timeout returns error (not empty list). Empty list after a successful fetch is true proof of a fresh account
- [ ] **`loadServiceTypes` triggers RPC on empty fetch** — `supabase.rpc('seed_default_service_types', {p_user_id: userId})`. Server decides. Always
- [ ] **Guard condition:** If `getServiceTypes()` query errors (network failure, 503, timeout) — show error state with retry button. Never fall through to seeding logic

## P0 — Service Pricing: UUID Diff-Merge (Replace Name-Based Identity)
- [ ] **Replace name-based match in `syncServiceTypes` merge** — `localModels.where((l) => l.name == remote.name)` becomes UUID-based: `localByUuid[remote.id]`
- [ ] **Never call `_local.clear()` in service type sync** — same hard ban as Inventory. Diff-merge preserves local-only services (offline creates that haven't reached server yet)
- [ ] **Preserve offline-created service types** — after merging remote into local, any local entity whose UUID is not in the remote set is a local-only service. Keep it. It will sync via the SyncOrchestrator PUSH phase later
- [ ] **SyncOrchestrator phase ordering includes service_types** — PUSH pending service types → PULL service types diff-merge → advance to Customers/JOBS/Notes

## P0 — Job Templates: Partial Update Safety (Kill the Upsert Nuke)
- [ ] **`JobTemplateRemoteDatasource.renameTemplate(id, newName)`** — new dedicated method that uses `.update({'name': newName, 'updated_at': now}).eq('id', id)` instead of `.upsert({...})`. HTTP PATCH, not PUT. Only `name` and `updated_at` columns are touched; `services_json`, `hardware_json`, `parts_json` survive unchanged
- [ ] **`JobTemplateRepositoryImpl._renameRemote`** — stop calling `_remote!.saveTemplate({id, name, updated_at})`. Call `_remote!.renameTemplate(id, newName)` instead. The generic `saveTemplate` path is reserved for fully-hydrated payloads only
- [ ] **Audit all partial writes across all features** — `InventoryItemRepositoryImpl`, `ServiceTypeRepositoryImpl`, `JobRepositoryImpl`. Every partial write must use `.update()` not `.upsert()`. No column should ever be nullified by a rename or status toggle

## P0 — Job Templates: Tombstone Protocol (Fix Ghost Accumulation)
- [ ] **Add `is_deleted boolean NOT NULL DEFAULT false` to `job_templates` table** — soft-delete marker. No row is ever physically deleted from the server
- [ ] **`JobTemplateRemoteDatasource.deleteTemplate`** — repurpose from SQL `DELETE` to `UPDATE SET is_deleted = true`. The row stays in the database. All devices see the tombstone
- [ ] **`JobTemplateLocalDatasource.softDeleteTemplate(id)`** — set `is_deleted: true` in the local Hive JSON. The template is hidden from UI but remains in the box for sync reconciliation
- [ ] **`JobTemplateRepositoryImpl.deleteTemplate`** — call `_local.softDeleteTemplate` + `_remote.softDeleteTemplate`. No hard deletes anywhere
- [ ] **`_syncFromRemote` tombstone handler** — when incoming remote row has `is_deleted == true`, call `_local.deleteTemplate(id)` (hard-delete from Hive). The ghost is cleaned up immediately on all devices
- [ ] **`JobTemplateLocalDatasource.getAllActive()`** — new query method that filters by `is_deleted != true`. UI uses this instead of `getAll()`. Includes both normal + additive-merge templates
- [ ] **Revive flow (optional):** Admin toggles `is_deleted = false` on server. Next sync, remote row arrives with `is_deleted == false` → `_local.saveTemplate(remote)` restores it to Hive. The template resurrects on all devices automatically
- [ ] **Apply tombstone pattern to Inventory and Service Types too** — any feature that syncs across devices needs soft-delete. Same `is_deleted` column, same sync handler, same `getAllActive()` filter

## P0 — Job Templates: Price Snapshot at Save Time (Fix Price Mutation Paradox)
- [ ] **`_saveAsTemplate` (Step 6 Extras path, line 306-314):** Replace `serviceTypeProvider.where(...).firstOrNull?.defaultPrice` with `CurrencyFormatter.parseToPesewas(s.priceController.text.trim())`. Snapshot the literal form field value, not the global default
- [ ] **`_saveAsTemplate` (post-save prompt path, line 617-625):** Same replacement. The `_ServiceRow`'s `priceController` holds the price the tech actually entered — capture it
- [ ] **`TemplateServiceItem.unitPrice` remains `int?`** — stores the actual price from the form. If the user entered nothing, it stays null. No fallback to service type defaults
- [ ] **`_applyTemplate` pre-population:** When a template is applied to a new job, `unitPrice` from the `TemplateServiceItem` is written back to the `priceController` of the new `_ServiceRow`. The round-trip preserves the captured price. Only if null does the UI leave the field empty
- [ ] **Validation on template save:** If `parseToPesewas` returns null and the price field is non-empty, show a parse error. If the field is empty, save null (no price marked up). Never silently substitute a default

## P0 — Job Templates: Forward-Compatible Serialization (Schema Versioning)
- [ ] **Add `_preserved` envelope to `JobTemplateModel`** — in `fromJson`, extract all top-level keys not in `kKnownFields` into a `Map<String, dynamic> _preserved`. In `toJson`, start from `_preserved` then overlay known fields. Unknown fields survive round-trips across client versions
- [ ] **Add `_preserved` envelope to `TemplateServiceItem`** — same pattern. Known keys: `{id, service_type, quantity, unit_price, sort_order}`. Everything else → `_preserved`
- [ ] **Add `_preserved` envelope to `TemplateHardwareItem`** — known keys: `{id, name, quantity, unit_sale_price, inventory_item_id}`. Everything else → `_preserved`
- [ ] **Add `_preserved` envelope to `TemplatePartItem`** — known keys: `{id, name, quantity, unit_price, inventory_item_id}`. Everything else → `_preserved`
- [ ] **Apply same `_preserved` pattern to ALL model classes project-wide** — `JobModel`, `InventoryItemModel`, `ServiceTypeModel`, `NoteModel`, etc. This is a one-time ~15-line addition per model. Every class that goes through `toJson` → Hive → `fromJson` must preserve unknown fields. New fields added by future client versions survive any save/load cycle by any client version
- [ ] **Consider extracting a `ForwardCompatible` mixin** — `extractPreserved(json, knownKeys)` and `buildJson(preserved, knownFields)` reduce each model class to ~3 lines of preservation boilerplate

## P1 — SyncOrchestrator (Unified)
- [ ] **Build centralized sync daemon** with DAG phase ordering: **Service Types → Inventory → Customers → Jobs → Notes → Note-Job-Links**
- [ ] Inventory first: no FK dependencies, but Jobs reference inventory items via `job_parts.inventory_item_id`
- [ ] Each phase: PUSH pending → PULL diff merge → advance to next phase
- [ ] Individual Note sync is three-phase: (1) upload binaries with idempotent per-file progress, (2) commit DB, (3) update local cache
- [ ] Service Types sync within orchestrator: push pending → diff-merge remote by UUID with correction_fields (no clear)

## P1 — Note_links Sync
- [ ] Add `syncStatus` field to `NoteJobLinkModel`
- [ ] Add retry mechanism to `NoteLinkRepositoryImpl` (connectivity listener or sync daemon integration)
- [ ] No UUID remapping needed — client-side UUIDv4 guarantees note_id is stable across sync

## P2 — Unify Edit UX
- [ ] Remove `EditNoteScreen` (dead code — never navigated to from any UI; only `AddNoteScreen.show()` is used for editing)
- [ ] Remove `/notes/:id/edit` route from `app_router.dart`
- [ ] Replace step-drawer `AddNoteScreen` with single-scrollable full-screen form for both create and edit
