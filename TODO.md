# Reviewer Remediation Todo — Knowledge Base + Inventory

## P0 — Inventory: Replace Full-Delete Sync with Diff-Based Push-Before-Pull
- [x] **Add `syncStatus` to `InventoryItemEntity`** — `'pending'` for new/edited items, `'synced'` after server confirms
- [x] **Repository `createItem`/`updateItem`:** Mark entity as `syncStatus: 'pending'` on local save (already client UUIDv4 — no remapping needed)
- [x] **SyncOrchestrator inventory phase:** PUSH all `pending` items to Supabase (upsert `ON CONFLICT (id) DO UPDATE`) before any PULL
- [x] **Replace timestamp LWW with OCC lock array:** Do NOT diff by `updated_at` — mobile clocks are untrustworthy. Use the same `correction_fields` / lock array pattern already built for Jobs. When Admin edits an item on the web, Supabase locks specific fields. The PULL phase respects those locks regardless of local clock skew.
- [x] **If OCC is over-engineered for single-user case, use server-authoritative clock:** Fetch server time from response `Date` header during sync handshake, calculate drift offset, apply to all local timestamps before diffing. Recalculate offset every sync cycle.
- [x] **Diff merge logic (using OCC):** For each remote item: compare field-level lock array. If a field is locked by Admin → overwrite local. If local has unsaved edits → preserve local. Mixed → merge field-by-field.
- [x] **Never call `_box.clear()` again.** This is a hard ban.

## P0 — Inventory: `file://` Photo Poison Removed
- [x] **Remove DEV-TEMP bypass** in `_pickInventoryImage()` — stop storing local file paths as `coverImageUrl`
- [x] **Inventory photo goes through 3-Phase Orchestrator:** (1) upload to Storage → (2) save `remote_url` to local Hive → (3) only then sync item record to DB
- [x] Same per-file idempotency as Notes: `remoteUrl` persisted immediately on upload, retries skip already-uploaded files

## P0 — Inventory: Weighted-Average Cost Integrity
- [x] **Restock flow:** Enforce `unitCost > 0` validation. If user enters 0, show dialog: "Zero cost will skew Auto-COGS profit calculations. Proceed?"
- [x] **Manual stock additions (non-restock):** Option (b): `adjustStock` recalculates weighted-average using current `defaultCostPrice` as implied unit cost for `manual_add` — average unchanged but math is explicit
- [x] **Add Write-Ahead Log (WAL) transaction pattern** for restock: `PendingRestockWal` written to `_meta` box before any mutation. On crash `reconcilePendingRestocks()` replays via `appliedTransactionIds` idempotency gate.

## P0 — Inventory: `search_index` + Isolate Offloading
- [x] **Add `search_index` field to `InventoryItemEntity`** — single concatenated string built at save time: `InventoryItemEntity.buildSearchIndex()` static helper lowercases and deduplicates
- [x] **Search bar filters against `search_index` only** — `_filtered()` uses `searchIndex.contains(query)` (fallback) or isolate `List<int>` index-set lookup
- [x] **Offload filtering to persistent Isolate worker (actor model):** `InventorySearchIsolate` spawned once on screen load, indexes loaded once via `SendPort`. Each keystroke sends only `String query`. Sequence-counter prevents stale-result flicker.

## P0 — Knowledge Base: Idempotent Binary Uploads to Storage
- [x] `NoteAttachmentModel` gains `remoteUrl` (canonical, synced via JSONB) + `localPath` (transient Hive-only field) — entity + model + copyWith updated
- [x] **Per-file upload:** Each attachment uploaded to Cloudinary (primary) + Supabase Storage fallback via `_uploadAttachment()` immediately after local save
- [x] **Idempotent retry:** `_uploadAttachment` skips if `attachment.remoteUrl` is already set — no orphan re-upload
- [x] If any file fails upload, attachment keeps `localPath`, note stays `pending`, already-uploaded files retain `remoteUrl`
- [x] `toJson()` outputs `remote_url` (not `localPath`); detail screen `_resolvedPath` prefers `localPath` → `remoteUrl` → legacy `url`

## P0 — Knowledge Base: Client-Side UUIDv4 as Absolute PK
- [x] **Schema migration:** `20260531000002_knowledge_notes_client_uuid.sql` — removed `DEFAULT`, added `upsert_knowledge_note()` RPC, added `trg_validate_note_uuid` BEFORE INSERT trigger for UUIDv4 validation
- [x] **Repository change:** `createNote()` includes `'id': localId` in insert payload — client UUIDv4 becomes the server PK. Removed delete-and-replace dance.
- [x] **`syncPendingNotes()` change:** Uses `_remote.upsertNote()` (RPC with `ON CONFLICT (id) DO UPDATE`) instead of INSERT. No delete-and-replace. Stable UUID marked `synced` directly.

## P0 — Service Pricing: PATCH Semantics + correction_fields OCC
- [x] **Migration:** Added `correction_fields text[] DEFAULT '{}'` and `updated_by text DEFAULT 'mobile'` to `service_types`
- [x] **Entity/Model:** Added `correctionFields` + `updatedBy` fields + `toPatchJson()` for scoped PATCH payloads
- [x] **`updateServiceType` becomes PATCH:** When `correctionFields` is non-empty, uses `toPatchJson()` (only transmits locked fields). Remote response merged into local state.
- [x] **`savePriceOnly` fires scoped PATCH:** Sets `correctionFields: ['default_price']` and `updatedBy: 'mobile'` — never transmits name/category/icon on wire
- [x] **Sync merge uses correction_fields array:** During `syncServiceTypes`, if local has pending `correctionFields`, only those fields are preserved; others accept remote values. No field-level collision.

## P0 — Service Pricing: Server-Authoritative Seeding (Kill Zombie Duplicates)
- [x] **Added `has_seeded_services bool DEFAULT false` to `user_settings` table** — `20260531000004_user_settings_seed_flag.sql` creates the table with RLS + `get_has_seeded_services` and `mark_services_seeded` RPCs. Notifier checks server-authoritative flag before seeding, then marks seeded atomically. Eliminates re-seed on e.g. Hive clear or new device.
- [x] **`seed_default_service_types(p_user_id UUID)` RPC** — `20260531000006_seed_default_services_rpc.sql`. SECURITY DEFINER, checks `has_seeded_services`, inserts all 38 default services server-side with `gen_random_uuid()`, marks seeded atomically. Never duplicates.
- [x] **`SeedDefaultServiceTypesUseCase` removed from client** — notifier calls `seed_default_service_types` RPC directly on empty fetch. Server decides.
- [x] **`loadServiceTypes` triggers RPC on empty fetch** — `supabase.rpc('seed_default_service_types', {p_user_id: userId})`. On success, pulls remote types. Never falls through to client-side seed logic.
- [x] **Guard condition:** If `getServiceTypes()` query errors (network failure) — `state = AsyncValue.error(e, st)` shows error state with retry. Never falls through to seeding.

## P0 — Service Pricing: UUID Diff-Merge (Replace Name-Based Identity)
- [x] **Replace name-based match in `syncServiceTypes` merge** — `localByUuid[remote.id]` replaces `localModels.where((l) => l.name == remote.name)`
- [x] **Never call `_local.clear()` in service type sync** — diff-merge preserves local-only services (offline creates that haven't reached server yet)
- [x] **Preserve offline-created service types** — after merging remote into local, any local entity whose UUID is not in the remote set is a local-only service. Kept in final list.

## P0 — Job Templates: Partial Update Safety (Kill the Upsert Nuke)
- [x] **`JobTemplateRemoteDatasource.renameTemplate(id, newName)`** — new method using `.update()` not `.upsert()`. Only `name` and `updated_at` columns are touched; `services_json`, `hardware_json`, `parts_json` survive unchanged
- [x] **`JobTemplateRepositoryImpl._renameRemote`** — now calls `_remote!.renameTemplate(id, newName)` instead of `_remote!.saveTemplate({id, name, updated_at})`. The generic `saveTemplate` path is reserved for fully-hydrated payloads only
- [x] **Audit all partial writes across all features** — `InventoryItemRepositoryImpl`, `ServiceTypeRepositoryImpl`, `JobRepositoryImpl`. All partial writes verified: every `.upsert()` call sends full payloads. Only the rename path (now fixed) was sending partial payloads.

## P0 — Job Templates: Tombstone Protocol (Fix Ghost Accumulation)
- [x] **Migration:** Added `is_deleted boolean NOT NULL DEFAULT false` to `job_templates`, `inventory_items`, and `service_types`
- [x] **`JobTemplateRemoteDatasource.deleteTemplate`** — repurposed from SQL `DELETE` to `UPDATE SET is_deleted = true`
- [x] **`JobTemplateLocalDatasource`** — added `softDeleteTemplate(id)` (sets is_deleted locally) + `hardDeleteTemplate(id)` (removes from Hive for tombstone cleanup) + `getAllActive()` (filters out deleted)
- [x] **`JobTemplateRepositoryImpl.deleteTemplate`** — calls `_local.softDeleteTemplate` + `_deleteRemote`. No hard deletes
- [x] **`_syncFromRemote` tombstone handler** — incoming remote row with `is_deleted == true` → `_local.hardDeleteTemplate(id)`
- [x] **`getTemplates` uses `getAllActive()`** — deleted templates hidden from UI but retained in box for sync
- [x] **Apply tombstone to Inventory** — `isDeleted` added to entity/model, remote `delete()` uses UPDATE, sync PULL phase hard-deletes tombstoned items locally
- [x] **Apply tombstone to Service Types** — `isDeleted` added to entity/model

## P0 — Job Templates: Price Snapshot at Save Time (Fix Price Mutation Paradox)
- [x] **`_saveAsTemplate` (Step 6 Extras path):** Replaced `serviceTypeProvider.where(...).firstOrNull?.defaultPrice` with `CurrencyFormatter.parseToPesewas(s.priceController.text.trim())`
- [x] **`_saveAsTemplate` (post-save prompt path):** Same replacement — snapshots the literal form field value
- [x] **Job save path (line 533):** Same fix — `e.value.priceController.text.trim()` instead of service type default lookup
- [x] **`_applyTemplate` pre-population:** `unitPrice` from `TemplateServiceItem` written to `priceController` of the new `ServiceRow`. Hardware items similarly populate `priceController` from `unitSalePrice`

## P0 — Job Templates: Forward-Compatible Serialization (Schema Versioning)
- [x] **Created `ForwardCompatible` utility** — `extractPreserved(json, knownKeys)` + `buildJson(preserved, knownFields)` — in `lib/core/utils/forward_compatible.dart`
- [x] **Applied to `JobTemplateModel`** — `_kKnown` set, preserved preserved through fromJson/toJson/copyWith
- [x] **Applied to `TemplateServiceItem`** — same pattern, known keys: `{id, service_type, quantity, unit_price, sort_order}`
- [x] **Applied to `TemplateHardwareItem`** — known keys: `{id, name, quantity, unit_sale_price, inventory_item_id}`
- [x] **Applied to `TemplatePartItem`** — known keys: `{id, name, quantity, unit_price, inventory_item_id}`
- [x] **Applied to `InventoryItemModel`** — full _kKnown set, preserved through serialization chain
- [x] **Applied to `ServiceTypeModel`** — preserved through fromJson/toJson/copyWith

## P1 — SyncOrchestrator (Unified)
- [x] **Built centralized `SyncOrchestrator`** in `lib/core/services/sync_orchestrator.dart` with DAG phase ordering: Service Types → Inventory → Customers → Jobs → Notes
- [x] **Each phase**: PUSH pending (via feature-specific sync methods), one failure doesn't block others
- [x] Reports `List<SyncPhaseResult>` with per-phase success/failure

## P1 — Note_links Sync
- [x] Add `syncStatus` field to `NoteJobLinkEntity` and `NoteJobLinkModel`
- [x] Add `getPending()` to local datasource + `syncPendingLinks()` to repository
- [x] `createLink` marks as `SyncStatus.pending`; remote success sets to `synced`
- [x] `syncPendingLinks()` iterates pending links, pushes to remote, marks synced

## P2 — Unify Edit UX
- [x] Remove `EditNoteScreen` (dead code — never navigated to from any UI; only `AddNoteScreen.show()` is used for editing)
- [x] Remove `/notes/:id/edit` route from `app_router.dart`
- [x] Remove `RouteNames.editNote` from route_names.dart
