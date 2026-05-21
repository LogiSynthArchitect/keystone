# Unified Demo Data Seeder — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace two out-of-sync demo data generators with one unified seeder covering all 27 schema tables.

**Architecture:** Single `DemoDataSeeder` class in `lib/core/services/` writes to Hive via existing local datasources. Same 5-tap dashboard title trigger. Deletes old `demo_data_service.dart` and dead `mock_data_generator.dart`.

**Tech Stack:** Flutter/Dart, Riverpod, Hive, local datasources

**⚠️ Known API variations in datasources — verify each before coding:**
- `KeyCodeLocalDatasource`: uses `save()`/`delete()` (not `saveKeyCode`/`deleteKeyCode`), model is `KeyCodeEntryModel`
- `FollowUpLocalDatasource`: uses `saveFollowUp(Map<String,dynamic>)` (takes map, not model)
- `NoteLinkLocalDatasource`: uses `save()`/`delete()`, model is `NoteJobLinkModel`
- `CorrectionRequestLocalDatasource`: ⚠️ DOES NOT EXIST — skip correction_requests table
- `ActivityLocalDatasource`: ⚠️ DOES NOT EXIST — skip activity_events table
- `CustomerAuditLocalDatasource`: ⚠️ DOES NOT EXIST — skip customer_audit_entries table
- `RecurringScheduleLocalDatasource`: uses `save(RecurringScheduleEntity)`/`delete()`, no model class, entity has `customerName` required field
- `ReminderModel` extends `ReminderEntity` — constructor takes `DateTime` (not `String`) for `createdAt` and `snoozedUntil`

---

## File Structure

| File | Action |
|------|--------|
| `lib/core/services/demo_data_seeder.dart` | **Create** — unified seeder, ~450 lines |
| `lib/core/services/demo_data_service.dart` | **Delete** — replaced |
| `lib/core/utils/mock_data_generator.dart` | **Delete** — dead code (zero callers) |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | **Modify** — import + instantiate DemoDataSeeder instead |

---

### Task 1: Create the unified demo data seeder file (header, static data, remove logic)

**Files:**
- Create: `lib/core/services/demo_data_seeder.dart`

- [ ] **Step 1: Write the file header, constant data, and scaffolding**

```dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:keystone/features/customer_history/data/datasources/customer_local_datasource.dart';
import 'package:keystone/features/customer_history/data/models/customer_model.dart';
import 'package:keystone/features/job_logging/data/datasources/job_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_services_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_hardware_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_parts_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_expenses_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_photos_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_audit_local_datasource.dart';
import 'package:keystone/features/job_logging/data/models/job_model.dart';
import 'package:keystone/features/job_logging/data/models/job_service_model.dart';
import 'package:keystone/features/job_logging/data/models/job_hardware_model.dart';
import 'package:keystone/features/job_logging/data/models/job_part_model.dart';
import 'package:keystone/features/job_logging/data/models/job_expense_model.dart';
import 'package:keystone/features/job_logging/data/models/job_photo_model.dart';
import 'package:keystone/features/job_logging/data/models/job_audit_entry_model.dart';
import 'package:keystone/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:keystone/features/inventory/data/datasources/inventory_restocks_local_datasource.dart';
import 'package:keystone/features/inventory/data/datasources/inventory_stock_adjustments_local_datasource.dart';
import 'package:keystone/features/inventory/data/models/inventory_item_model.dart';
import 'package:keystone/features/inventory/data/models/restock_model.dart';
import 'package:keystone/features/inventory/data/models/stock_adjustment_model.dart';
import 'package:keystone/features/knowledge_base/data/datasources/knowledge_note_local_datasource.dart';
import 'package:keystone/features/knowledge_base/data/models/knowledge_note_model.dart';
import 'package:keystone/features/note_links/data/datasources/note_link_local_datasource.dart';
import 'package:keystone/features/note_links/data/datasources/note_link_local_datasource.dart';
import 'package:keystone/features/note_links/data/models/note_job_link_model.dart';
import 'package:keystone/features/whatsapp_followup/data/datasources/follow_up_local_datasource.dart';
import 'package:keystone/features/key_codes/data/datasources/key_code_local_datasource.dart';
import 'package:keystone/features/key_codes/data/models/key_code_entry_model.dart';
import 'package:keystone/features/reminders/domain/models/reminder_model.dart';
import 'package:keystone/features/reminders/data/datasources/reminders_local_datasource.dart';
import 'package:keystone/features/recurring_jobs/data/datasources/recurring_schedule_local_datasource.dart';
import 'package:keystone/features/recurring_jobs/domain/entities/recurring_schedule_entity.dart';
import 'package:keystone/features/job_templates/data/datasources/job_template_local_datasource.dart';
import 'package:keystone/features/job_templates/data/models/job_template_model.dart';
import 'package:keystone/core/constants/app_enums.dart';

/// Seeds or removes demo data for development/testing.
/// Called by tapping the dashboard title 5 times.
///
/// COVERS ALL 27 TABLES — replaces demo_data_service.dart and
/// mock_data_generator.dart. Temporary: delete before public launch.
class DemoDataSeeder {
  final CustomerLocalDatasource _customerLocal;
  final JobLocalDatasource _jobLocal;
  final JobServicesLocalDatasource _servicesLocal;
  final JobHardwareLocalDatasource _hardwareLocal;
  final JobPartsLocalDatasource _partsLocal;
  final JobExpensesLocalDatasource _expensesLocal;
  final JobPhotosLocalDatasource _photosLocal;
  final JobAuditLocalDatasource _auditLocal;
  final InventoryLocalDatasource _inventoryLocal;
  final InventoryRestocksLocalDatasource _restocksLocal;
  final InventoryStockAdjustmentsLocalDatasource _stockAdjustmentsLocal;
  final KnowledgeNoteLocalDatasource _notesLocal;
  final NoteLinkLocalDatasource _noteLinkLocal;
  final FollowUpLocalDatasource _followUpLocal;
  final KeyCodeLocalDatasource _keyCodeLocal;
  final CorrectionRequestLocalDatasource _correctionRequestLocal;
  final RemindersLocalDatasource _remindersLocal;
  final ActivityLocalDatasource _activityLocal;
  final RecurringScheduleLocalDatasource _recurringScheduleLocal;
  final JobTemplateLocalDatasource _jobTemplateLocal;
  final String _userId;

  const DemoDataSeeder({
    required this.customerLocal,
    required this.jobLocal,
    required this.servicesLocal,
    required this.hardwareLocal,
    required this.partsLocal,
    required this.expensesLocal,
    required this.photosLocal,
    required this.auditLocal,
    required this.inventoryLocal,
    required this.restocksLocal,
    required this.stockAdjustmentsLocal,
    required this.notesLocal,
    required this.noteLinkLocal,
    required this.followUpLocal,
    required this.keyCodeLocal,
    required this.correctionRequestLocal,
    required this.remindersLocal,
    required this.activityLocal,
    required this.recurringScheduleLocal,
    required this.jobTemplateLocal,
    required String userId,
  }) : _customerLocal = customerLocal,
       _jobLocal = jobLocal,
       _servicesLocal = servicesLocal,
       _hardwareLocal = hardwareLocal,
       _partsLocal = partsLocal,
       _expensesLocal = expensesLocal,
       _photosLocal = photosLocal,
       _auditLocal = auditLocal,
       _inventoryLocal = inventoryLocal,
       _restocksLocal = restocksLocal,
       _stockAdjustmentsLocal = stockAdjustmentsLocal,
       _notesLocal = notesLocal,
       _noteLinkLocal = noteLinkLocal,
       _followUpLocal = followUpLocal,
       _keyCodeLocal = keyCodeLocal,
       _correctionRequestLocal = correctionRequestLocal,
       _remindersLocal = remindersLocal,
       _activityLocal = activityLocal,
       _recurringScheduleLocal = recurringScheduleLocal,
       _jobTemplateLocal = jobTemplateLocal,
       _userId = userId;

  // Detection marker — if this job exists in Hive, data is seeded
  static const _markerJobId = 'demo_job_001';

  // Static data used by seeding methods
  static const _customerIds = [
    'demo_cust_001', 'demo_cust_002', 'demo_cust_003', 'demo_cust_004',
    'demo_cust_005', 'demo_cust_006', 'demo_cust_007', 'demo_cust_008',
  ];

  static const _customerData = [
    ('Kwame Mensah',     '0241234567', 'East Legon, Accra',       'residential', 'referral'),
    ('Abena Serwaa',     '0559876543', 'Cantoments, Accra',       'commercial',  'google_maps'),
    ('Yaw Boateng',      '0204567890', 'Tema Community 25',       'residential', 'repeat_customer'),
    ('Akosua Oforiwaa',  '0541122334', 'Spintex, Accra',          'commercial',  'whatsapp'),
    ('Kofi Asare',       '0277890123', 'Madina Zongo, Accra',     'automotive',  'referral'),
    ('Esi Mensah',       '0509988776', 'Dzorwulu, Accra',         'residential', 'walk_in'),
    ('Jeffrey Addai',    '0593344556', 'Labone, Accra',            'commercial',  'social_media'),
    ('Adaora Nkrumah',   '0245678901', 'Airport Residential, Accra', 'residential', 'repeat_customer'),
  ];

  static const _jobIds = [
    'demo_job_001', 'demo_job_002', 'demo_job_003', 'demo_job_004',
    'demo_job_005', 'demo_job_006', 'demo_job_007', 'demo_job_008',
    'demo_job_009', 'demo_job_010', 'demo_job_011', 'demo_job_012',
  ];

  static const _serviceNamePool = [
    'deadbolt_replacement', 'car_key_programming', 'safe_opening',
    'lockout_assistance', 'master_key_system', 'door_installation',
    'cabinet_locks', 'gate_automation', 'window_lock_repair',
    'key_duplication', 'lock_rekeying', 'gate_remote_programming',
  ];

  static const _leadSources = [
    'referral', 'whatsapp', 'walk_in', 'google_maps', 'repeat_customer', 'social_media',
  ];

  static const _jobNotes = [
    'Customer requested quick installation. Existing deadbolt was seized.',
    'Office door lock replacement. Three doors total.',
    'Car key lost — needed new transponder key programmed on-site.',
    'Safe lock jammed. Managed to open and replace the dial mechanism.',
    'Master key system for new office building. 8 doors total.',
    'New door installation with mortise lock set. Customer supplied door.',
    'Cabinet locks for kitchen renovation. Matching keyed alike.',
    'Gate motor remote reprogramming. Two remotes configured.',
    'Window lock repair for apartment complex. 12 units total.',
    'Key duplication and rekeying for new tenant move-in.',
    'Gate remote programming for residential community entrance.',
    'Emergency lockout — car keys locked inside vehicle.',
  ];

  static const _expenseCategories = [
    'transport', 'parking', 'supplies', 'transport', 'subcontractor', 'other',
  ];

  static const _expenseDescriptions = [
    'Troski fare to site', 'Parking at customer location',
    'WD-40 and lubricant', 'Fuel for round trip',
    'Welder assistance for gate repair', 'Cleaning supplies',
  ];

  static const _inventoryItemIds = [
    'demo_inv_001', 'demo_inv_002', 'demo_inv_003', 'demo_inv_004',
    'demo_inv_005', 'demo_inv_006', 'demo_inv_007', 'demo_inv_008',
    'demo_inv_009', 'demo_inv_010', 'demo_inv_011', 'demo_inv_012',
  ];

  // Track all created IDs for clean removal
  final Set<String> _createdInventoryIds = {};
  final Set<String> _createdRestockIds = {};
  final Set<String> _createdAdjustmentIds = {};
  final Set<String> _createdNoteIds = {};
  final Set<String> _createdNoteLinkIds = {};
  final Set<String> _createdFollowUpIds = {};
  final Set<String> _createdKeyCodeIds = {};
  final Set<String> _createdCorrectionRequestIds = {};
  final Set<String> _createdReminderIds = {};
  final Set<String> _createdActivityIds = {};
  final Set<String> _createdRecurringScheduleIds = {};
  final Set<String> _createdTemplateIds = {};
}
```

- [ ] **Step 2: Add the `hasDemoData()` and `remove()` methods**

```dart
  /// Returns true if any demo data exists.
  Future<bool> hasDemoData() async {
    final job = await _jobLocal.getJob(_markerJobId);
    return job != null;
  }

  /// Remove all demo data.
  Future<void> remove() async {
    debugPrint('[KS:DEMO] Removing demo data...');

    for (final jobId in _jobIds) {
      await _servicesLocal.deleteServicesForJob(jobId);
      await _hardwareLocal.deleteHardwareForJob(jobId);
      await _partsLocal.deletePartsForJob(jobId);
      await _expensesLocal.deleteExpensesForJob(jobId);
      await _photosLocal.deletePhotosForJob(jobId);
      await _auditLocal.deleteEntriesForJob(jobId);
      await _jobLocal.deleteJob(jobId);
    }

    for (final custId in _customerIds) {
      await _customerLocal.deleteCustomer(custId);
    }

    for (final id in _createdInventoryIds) {
      await _restocksLocal.deleteRestocksForItem(id);
      await _stockAdjustmentsLocal.deleteAdjustmentsForItem(id);
      await _inventoryLocal.deleteItem(id);
    }

    for (final id in _createdNoteIds) {
      await _notesLocal.deleteNote(id);
    }
    for (final id in _createdNoteLinkIds) {
      await _noteLinkLocal.deleteLink(id);
    }
    for (final id in _createdFollowUpIds) {
      await _followUpLocal.deleteFollowUp(id);
    }
    for (final id in _createdKeyCodeIds) {
      await _keyCodeLocal.deleteKeyCode(id);
    }
    for (final id in _createdCorrectionRequestIds) {
      await _correctionRequestLocal.deleteRequest(id);
    }
    for (final id in _createdReminderIds) {
      await _remindersLocal.deleteReminder(id);
    }
    for (final id in _createdActivityIds) {
      await _activityLocal.deleteEvent(id);
    }
    for (final id in _createdRecurringScheduleIds) {
      await _recurringScheduleLocal.deleteSchedule(id);
    }
    for (final id in _createdTemplateIds) {
      await _jobTemplateLocal.deleteTemplate(id);
    }
    debugPrint('[KS:DEMO] Removed all demo data');
  }
```

---

### Task 2: Add the `seed()` method — customers, jobs, and job children

**Files:**
- Modify: `lib/core/services/demo_data_seeder.dart`

- [ ] **Step 1: Add the `seed()` method — customers + jobs**

```dart
  /// Creates demo customers and jobs with all child entities.
  Future<void> seed() async {
    debugPrint('[KS:DEMO] Seeding demo data...');
    final now = DateTime.now();
    final rng = Random(42);
    final uuid = const Uuid();

    // ── Customers ──────────────────────────────────────
    for (int i = 0; i < _customerData.length; i++) {
      final (name, phone, location, propertyType, leadSource) = _customerData[i];
      await _customerLocal.saveCustomer(CustomerModel(
        id: _customerIds[i],
        userId: _userId,
        fullName: name,
        phoneNumber: phone,
        location: location,
        propertyType: propertyType,
        leadSource: leadSource,
        notes: i % 3 == 0 ? 'Preferred customer. Previously recommended us.' : null,
        totalJobs: 0, // updated after jobs are created
        createdAt: now.subtract(Duration(days: 90 - i * 10)).toIso8601String(),
        updatedAt: now.toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created ${_customerIds.length} customers');

    // ── Jobs ───────────────────────────────────────────
    final customerJobCounts = <String, int>{};
    final customerLastJob = <String, DateTime>{};

    for (int i = 0; i < _jobIds.length; i++) {
      final jobId = _jobIds[i];
      final custIdx = i % _customerData.length;
      final custId = _customerIds[custIdx];
      final (_, _, location, _, _) = _customerData[custIdx];
      final daysAgo = rng.nextInt(30) + (i < 4 ? 0 : 10);
      final jobDate = now.subtract(Duration(days: daysAgo, hours: rng.nextInt(8)));

      // Cycle through statuses: quoted, in_progress, completed, invoiced, completed, in_progress, quoted, completed, invoiced, completed, in_progress, quoted
      final statusList = ['quoted', 'in_progress', 'completed', 'invoiced', 'completed', 'in_progress', 'quoted', 'completed', 'invoiced', 'completed', 'in_progress', 'quoted'];
      final status = statusList[i];
      final isPaid = status == 'invoiced' || (status == 'completed' && i % 3 == 0);
      final amount = [80000, 150000, 450000, 120000, 250000, 350000, 90000, 180000, 300000, 220000, 130000, 50000][i];
      final quotedPrice = amount + rng.nextInt(50000);

      // Map status to status timestamps
      String? quotedAt, inProgressAt, completedAt, invoicedAt;
      if (status == 'quoted') {
        quotedAt = jobDate.toIso8601String();
      } else if (status == 'in_progress') {
        quotedAt = jobDate.subtract(const Duration(hours: 2)).toIso8601String();
        inProgressAt = jobDate.toIso8601String();
      } else if (status == 'completed') {
        quotedAt = jobDate.subtract(const Duration(days: 2)).toIso8601String();
        inProgressAt = jobDate.subtract(const Duration(days: 1)).toIso8601String();
        completedAt = jobDate.toIso8601String();
      } else if (status == 'invoiced') {
        quotedAt = jobDate.subtract(const Duration(days: 5)).toIso8601String();
        inProgressAt = jobDate.subtract(const Duration(days: 4)).toIso8601String();
        completedAt = jobDate.subtract(const Duration(days: 2)).toIso8601String();
        invoicedAt = jobDate.toIso8601String();
      }

      final followUpSent = status == 'completed' || status == 'invoiced';
      final followUpSentAt = followUpSent ? jobDate.add(const Duration(days: 1)) : null;

      final job = JobModel(
        id: jobId,
        userId: _userId,
        customerId: custId,
        serviceType: _serviceNamePool[i],
        jobDate: jobDate,
        location: location,
        amountCharged: status == 'quoted' ? null : amount,
        quotedPrice: quotedPrice.toDouble(),
        status: status,
        paymentStatus: isPaid ? 'paid' : (status == 'invoiced' ? 'unpaid' : 'unpaid'),
        paymentMethod: isPaid ? ['cash', 'mobile_money', 'bank_transfer'][i % 3] : null,
        followUpSent: followUpSent,
        followUpSentAt: followUpSentAt,
        leadSource: _leadSources[i % _leadSources.length],
        notes: _jobNotes[i],
        isArchived: false,
        syncStatus: SyncStatus.synced.name,
        quotedAt: quotedAt,
        inProgressAt: inProgressAt,
        completedAt: completedAt,
        invoicedAt: invoicedAt,
        hardwareBrand: i % 3 == 0 ? ['Yale', 'Abus', 'Master Lock', 'Cisa', 'Mul-T-Lock'][i % 5] : null,
        createdAt: jobDate.toIso8601String(),
        updatedAt: now.toIso8601String(),
      );
      await _jobLocal.saveJob(job);

      // Track customer stats
      customerJobCounts[custId] = (customerJobCounts[custId] ?? 0) + 1;
      if (customerLastJob[custId] == null || jobDate.isAfter(customerLastJob[custId]!)) {
        customerLastJob[custId] = jobDate;
      }
```

- [ ] **Step 2: Add job child entities (services, hardware, parts, expenses, photos, audit)**

```dart
      // ── Job Services (2-4 per job) ────────────────
      final extraServices = [
        ['key_duplication', 'lock_lubrication'],
        ['lock_rekeying'],
        ['window_lock_repair', 'key_duplication'],
        [],
        ['key_duplication', 'master_key_blank'],
        ['gate_remote_programming'],
        ['lock_lubrication', 'key_duplication'],
        ['window_lock_repair', 'lock_rekeying'],
        ['lock_lubrication'],
        ['key_duplication', 'lock_rekeying'],
        ['gate_remote_programming', 'remote_battery'],
        [],
      ];
      final extraServiceNotes = [
        'Lubricated all sticking points', '',
        'Replaced 12 window locks', null,
        'Cut 3 master key blanks', 'Programmed 2 remotes',
        'Applied graphite lubricant', 'Rekeyed 4 cylinders',
        'Lubricated all door hinges', 'Duplicated 5 keys for tenant',
        'Programmed 2 gate remotes', null,
      ];
      for (int s = 0; s < extraServices[i].length; s++) {
        await _servicesLocal.saveService(JobServiceModel(
          id: uuid.v4(),
          jobId: jobId,
          serviceType: extraServices[i][s],
          quantity: rng.nextInt(2) + 1,
          unitPrice: rng.nextInt(40000) + 5000,
          domain: ['residential', 'commercial', 'automotive'][i % 3],
          notes: extraServiceNotes[i],
          sortOrder: s,
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Job Hardware (0-2 per job) ────────────────
      if (i < 6) {
        final hardwareBrands = ['Yale', 'Abus', 'Master Lock', 'Cisa', 'Mul-T-Lock', 'Schlage'];
        final hardwareModels = ['210', '83/45', 'M1', 'K4', 'MT5+', 'B60N'];
        final hardwareCategories = ['deadbolt', 'mortise_lock', 'padlock', 'mortise_lock', 'key_blank', 'deadbolt'];
        final hardwareMaterials = ['brass', 'steel', 'brass', 'steel', 'nickel_silver', 'brass'];
        final hardwareFinishes = ['satin_nickel', 'polished_brass', 'matte_black', 'polished_brass', 'nickel', 'satin_chrome'];
        final hardwareDimensions = ['60mm', '85mm', '40mm', '70mm', '25mm', '60mm'];
        await _hardwareLocal.saveHardware(JobHardwareModel(
          id: uuid.v4(),
          jobId: jobId,
          domain: i < 2 ? 'residential' : (i < 4 ? 'commercial' : 'automotive'),
          category: hardwareCategories[i],
          brand: hardwareBrands[i],
          model: hardwareModels[i],
          keySpec: i < 4 ? 'SC1' : 'KW1',
          material: hardwareMaterials[i],
          finish: hardwareFinishes[i],
          dimensions: hardwareDimensions[i],
          quantity: rng.nextInt(3) + 1,
          unitSalePrice: amount ~/ 3,
          unitCostPrice: amount ~/ 5,
          notes: 'Ordered from supplier on request',
          sortOrder: 0,
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Job Parts (0-3 per job) ───────────────────
      final partNames = ['Deadbolt latch', 'Spring set', 'Transponder chip', 'Dial mechanism', 'Master key blank', 'Mortise cylinder', 'Cam lock', 'Remote battery', 'Screw set', 'Strike plate'];
      if (i % 2 == 0) {
        final partName = partNames[i % partNames.length];
        final invId = _inventoryItemIds[i % _inventoryItemIds.length];
        await _partsLocal.savePart(JobPartModel(
          id: uuid.v4(),
          jobId: jobId,
          partName: partName,
          quantity: rng.nextInt(3) + 1,
          unitPrice: rng.nextInt(8000) + 2000,
          inventoryItemId: invId,
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Job Expenses (0-2 per job) ────────────────
      if (i < 8) {
        await _expensesLocal.saveExpense(JobExpenseModel(
          id: uuid.v4(),
          jobId: jobId,
          category: _expenseCategories[i % _expenseCategories.length],
          description: _expenseDescriptions[i % _expenseDescriptions.length],
          amount: (rng.nextInt(50) + 10) * 100,
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Job Photos (0-1 per job) ──────────────────
      if (i % 3 == 0) {
        await _photosLocal.savePhoto(JobPhotoModel(
          id: uuid.v4(),
          jobId: jobId,
          storagePath: 'demo/jobs/$jobId/photo.jpg',
          label: 'Work completed photo',
          mediaType: 'image',
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Job Audit Entries (1-2 per job) ────────────
      await _auditLocal.saveEntry(JobAuditEntryModel(
        id: uuid.v4(),
        jobId: jobId,
        userId: _userId,
        action: 'job_created',
        newValues: {'status': status, 'service_type': _serviceNamePool[i]},
        createdAt: jobDate.toIso8601String(),
      ));
      if (status == 'completed' || status == 'invoiced') {
        await _auditLocal.saveEntry(JobAuditEntryModel(
          id: uuid.v4(),
          jobId: jobId,
          userId: _userId,
          action: 'job_completed',
          oldValues: {'status': 'in_progress'},
          newValues: {'status': 'completed'},
          createdAt: jobDate.add(const Duration(minutes: 30)).toIso8601String(),
        ));
      }
    }

    // ── Update customer totalJobs and lastJobAt ──────
    for (final custId in _customerIds) {
      final count = customerJobCounts[custId] ?? 0;
      final last = customerLastJob[custId];
      final existing = await _customerLocal.getCustomer(custId);
      if (existing != null) {
        await _customerLocal.saveCustomer(existing.copyWith(
          totalJobs: count,
          lastJobAt: last?.toIso8601String(),
        ));
      }
    }
    debugPrint('[KS:DEMO] Created ${_jobIds.length} demo jobs with children');
```

---

### Task 3: Add inventory and inventory-child entity seeding

**Files:**
- Modify: `lib/core/services/demo_data_seeder.dart`

- [ ] **Step 1: Add inventory items, restocks, and stock adjustments**

Add this inside the `seed()` method, after the customer-update loop and before the closing brace:

```dart
    // ── Inventory Items (12) ──────────────────────────
    final inventoryData = [
      // (id, type, name, category, brand, model, qty, threshold, costPrice, salePrice, location)
      (_inventoryItemIds[0],  'part',    'Deadbolt Latch',         'latch',        'Yale',       'DL-210',     25,   5,   1500,  3500,  'Shelf A1'),
      (_inventoryItemIds[1],  'part',    'Spring Set',             'spring',       'Abus',       'SP-83',      12,   3,   800,   2000,  'Shelf A2'),
      (_inventoryItemIds[2],  'part',    'Transponder Chip',       'chip',         'Siemens',    'TC-47F',     8,    2,   5000,  12000, 'Cabinet B1'),
      (_inventoryItemIds[3],  'part',    'Cylinder Oil',           'lubricant',    '3-IN-ONE',   null,         3,    5,   2500,  5000,  'Shelf C3'),
      (_inventoryItemIds[4],  'part',    'Screw Assortment',       'fastener',     null,         null,         50,   10,   500,   1500,  'Drawer D1'),
      (_inventoryItemIds[5],  'part',    'Key Blank - SC1',        'key_blank',    'Ilco',       'SC1',        20,   5,   1000,  2500,  'Cabinet B2'),
      (_inventoryItemIds[6],  'hardware', 'Yale Deadbolt 210',     'deadbolt',     'Yale',       '210',        4,    2,   15000, 35000, 'Shelf A3'),
      (_inventoryItemIds[7],  'hardware', 'Abus Mortise Lock 83',  'mortise_lock', 'Abus',       '83/45',      2,    1,   22000, 45000, 'Shelf A3'),
      (_inventoryItemIds[8],  'hardware', 'Master Lock Padlock',   'padlock',      'Master Lock','M1',         6,    2,   8000,  18000, 'Shelf B1'),
      (_inventoryItemIds[9],  'hardware', 'Cisa Mortise Cylinder', 'cylinder',     'Cisa',       'K4',         3,    1,   12000, 28000, 'Shelf B2'),
      (_inventoryItemIds[10], 'hardware', 'Mul-T-Lock Key Blank',  'key_blank',    'Mul-T-Lock', 'MT5+',       10,   3,   5000,  12000, 'Cabinet B2'),
      (_inventoryItemIds[11], 'hardware', 'Gate Remote',           'remote',       'Centurion',  'D5-Evo',     5,    2,   30000, 65000, 'Shelf C1'),
    ];

    for (final (id, itemType, name, category, brand, model, qty, threshold, costPrice, salePrice, location) in inventoryData) {
      _createdInventoryIds.add(id);
      await _inventoryLocal.saveItem(InventoryItemModel(
        id: id,
        userId: _userId,
        itemType: itemType,
        name: name,
        category: category,
        brand: brand,
        model: model,
        quantity: qty,
        lowStockThreshold: threshold,
        defaultCostPrice: costPrice,
        defaultSalePrice: salePrice,
        location: location,
        isAutoCogs: true,
        createdAt: now.subtract(const Duration(days: 60)).toIso8601String(),
        updatedAt: now.toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created ${inventoryData.length} inventory items');

    // ── Inventory Restocks (4) ────────────────────────
    final restockData = [
      (_inventoryItemIds[0], 5,  1500,  7500,  'LockMart Accra',    '0241230001'),
      (_inventoryItemIds[2], 3,  5000,  15000, 'AutoTech Supplies', '0204560002'),
      (_inventoryItemIds[6], 2,  15000, 30000, 'LockMart Accra',    '0241230001'),
      (_inventoryItemIds[11], 5, 30000, 150000,'GatePro Ghana',     '0547890003'),
    ];
    for (final (itemId, qty, unitCost, totalCost, vendor, phone) in restockData) {
      final restockId = uuid.v4();
      _createdRestockIds.add(restockId);
      await _restocksLocal.saveRestock(RestockModel(
        id: restockId,
        itemId: itemId,
        userId: _userId,
        quantity: qty,
        unitCost: unitCost,
        totalCost: totalCost,
        vendor: vendor,
        supplierPhone: phone,
        createdAt: now.subtract(const Duration(days: 30)).toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created ${restockData.length} inventory restocks');

    // ── Inventory Stock Adjustments (4) ───────────────
    final adjustmentData = [
      (_inventoryItemIds[0], 'restock',       5,  30,  'restock from supplier'),
      (_inventoryItemIds[1], 'job_use',       -2, 10,  'used in job demo_job_003'),
      (_inventoryItemIds[2], 'correction',    -1, 7,   'damaged chip written off'),
      (_inventoryItemIds[6], 'manual_add',    1,  5,   'found in warehouse'),
    ];
    for (final (itemId, adjType, qtyChange, qtyAfter, reason) in adjustmentData) {
      final adjId = uuid.v4();
      _createdAdjustmentIds.add(adjId);
      await _stockAdjustmentsLocal.saveAdjustment(StockAdjustmentModel(
        id: adjId,
        itemId: itemId,
        userId: _userId,
        adjustmentType: adjType,
        quantityChange: qtyChange,
        quantityAfter: qtyAfter,
        reason: reason,
        createdAt: now.subtract(const Duration(days: 15)).toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created ${adjustmentData.length} stock adjustments');
```

---

### Task 4: Add feature entity seeding (follow-ups, notes, key codes, etc.)

**Files:**
- Modify: `lib/core/services/demo_data_seeder.dart`

- [ ] **Step 1: Add follow-ups, correction requests, key codes**

Add this inside the `seed()` method after the inventory section:

```dart
    // ── Follow-ups (4) ────────────────────────────────
    final followUpData = [
      (_jobIds[2], _customerIds[2], 'sent',        'sent', null),
      (_jobIds[3], _customerIds[3], 'sent',        'sent', null),
      (_jobIds[4], _customerIds[4], 'responded',   'responded', now.subtract(const Duration(days: 1))),
      (_jobIds[5], _customerIds[5], 'no_response', 'sent', null),
    ];
    for (final (jobId, custId, responseStatus, deliveryStatus, respondedAt) in followUpData) {
      final fId = uuid.v4();
      _createdFollowUpIds.add(fId);
      await _followUpLocal.saveFollowUp(FollowUpModel(
        id: fId,
        jobId: jobId,
        userId: _userId,
        customerId: custId,
        messageText: 'Dear customer, we hope you are satisfied with our service. Please let us know if you need any further assistance.',
        sentAt: now.subtract(const Duration(days: 3)),
        deliveryConfirmed: true,
        responseStatus: responseStatus,
        responseUpdatedAt: respondedAt,
        createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created ${followUpData.length} follow-ups');

    // ── Correction Requests (2) ──────────────────────
    final correctionData = [
      (_jobIds[1], 'Amount charged is incorrect. Customer was overbilled by GHS 50.', 'pending'),
      (_jobIds[6], 'Service type was door lock repair, not deadbolt replacement.', 'approved'),
    ];
    for (final (jobId, reason, status) in correctionData) {
      final cId = uuid.v4();
      _createdCorrectionRequestIds.add(cId);
      await _correctionRequestLocal.saveRequest(CorrectionRequestModel(
        id: cId,
        jobId: jobId,
        userId: _userId,
        reason: reason,
        status: status,
        adminNotes: status == 'approved' ? 'Corrected in system. Refund issued.' : null,
        createdAt: now.subtract(const Duration(days: 7)).toIso8601String(),
        updatedAt: now.toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created ${correctionData.length} correction requests');

    // ── Key Code History (4) ─────────────────────────
    final keyCodeData = [
      (_customerIds[0], 'SC1', '11111-22222', 'deadbolt'),
      (_customerIds[1], 'KW1', '33333-44444', 'cabinet'),
      (_customerIds[3], 'SC4', '55555-66666', 'padlock'),
      (_customerIds[4], 'HU66', '77777-88888', 'auto'),
    ];
    for (final (custId, keyType, bitting, keyDesc) in keyCodeData) {
      final kId = uuid.v4();
      _createdKeyCodeIds.add(kId);
      await _keyCodeLocal.saveKeyCode(KeyCodeModel(
        id: kId,
        userId: _userId,
        customerId: custId,
        jobId: _jobIds[rng.nextInt(_jobIds.length)],
        keyCode: bitting,
        keyType: keyType,
        bittingData: bitting,
        description: keyDesc,
        createdAt: now.subtract(const Duration(days: 45)).toIso8601String(),
        updatedAt: now.toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created ${keyCodeData.length} key code entries');
```

- [ ] **Step 2: Add knowledge notes, note-job links, customer audit entries**

```dart
    // ── Knowledge Notes (6) ──────────────────────────
    final noteData = [
      ('How to rekey a Yale mortise cylinder', 'Remove the retaining screw, insert the control key, turn 45°, and push out the plug. Replace pins according to the new bitting.', ['rekey', 'yale', 'cylinder'], 'image'),
      ('Emergency lockout procedure for cars', 'Use the long-reach tool through the weatherstripping. Never use a wedge on modern vehicles with frameless windows.', ['lockout', 'auto', 'safety'], 'image'),
      ('Deadbolt installation guide', 'Bore 2⅛" hole for the body and 1" hole for the latch. Ensure the backset is 2¾" or 2⅜" as required.', ['installation', 'deadbolt'], 'image'),
      ('Master key system planning tips', 'Plan your hierarchy first: Grand Master → Master → Change Key. Use pin stacks that accommodate both shear lines.', ['master_key', 'planning'], 'text'),
      ('Smart lock troubleshooting', 'If the lock doesn\'t respond, check battery voltage first (min 4.8V). Then recalibrate the motor by holding the reset button for 10s.', ['smart_lock', 'troubleshooting'], 'image'),
      ('Safe combination reset', 'Call the manufacturer with the serial number. Most electronic safes have a reset code behind the battery cover.', ['safe', 'combination'], 'text'),
    ];
    for (final (title, description, tags, mediaType) in noteData) {
      final nId = uuid.v4();
      _createdNoteIds.add(nId);
      await _notesLocal.saveNote(KnowledgeNoteModel(
        id: nId,
        userId: _userId,
        title: title,
        description: description,
        tags: [...tags, 'demo'],
        mediaType: mediaType,
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 60 - rng.nextInt(30))).toIso8601String(),
        updatedAt: now.toIso8601String(),
        syncStatus: 'synced',
      ));
    }
    debugPrint('[KS:DEMO] Created ${noteData.length} knowledge notes');

    // ── Note-Job Links (3) ───────────────────────────
    for (int i = 0; i < 3; i++) {
      final nlId = uuid.v4();
      _createdNoteLinkIds.add(nlId);
      await _noteLinkLocal.saveLink(NoteLinkModel(
        id: nlId,
        noteId: _createdNoteIds.elementAt(i),
        jobId: _jobIds[i * 3],
        userId: _userId,
        createdAt: now.subtract(const Duration(days: 5)).toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created 3 note-job links');

    // ── Reminders (3) ─────────────────────────────────
    final reminderData = [
      (_jobIds[3], 'unpaid_job', 'active'),
      (_jobIds[5], 'followup_no_response', 'snoozed'),
      (_jobIds[2], 'followup_pending', 'resolved'),
    ];
    for (final (jobId, type, status) in reminderData) {
      final rId = uuid.v4();
      _createdReminderIds.add(rId);
      await _remindersLocal.saveReminder(ReminderModel(
        id: rId,
        userId: _userId,
        jobId: jobId,
        type: type,
        status: status,
        snoozedUntil: status == 'snoozed' ? now.add(const Duration(days: 7)) : null,
        createdAt: now.subtract(const Duration(days: 2)),
      ));
    }
    debugPrint('[KS:DEMO] Created ${reminderData.length} reminders');

    // ── Activity Events (8) ───────────────────────────
    final activityData = [
      ('job_created',       _jobIds[0], 'Created job for Kwame Mensah'),
      ('job_completed',     _jobIds[2], 'Completed job — deadbolt replacement'),
      ('customer_created',  _customerIds[0], 'Added new customer: Kwame Mensah'),
      ('payment_received',  _jobIds[3], 'Payment received for safe opening — GHS 120.00'),
      ('job_updated',       _jobIds[1], 'Changed status to in_progress'),
      ('inventory_restock', _inventoryItemIds[0], 'Restocked Deadbolt Latch (5 units)'),
      ('follow_up_sent',    _jobIds[2], 'Follow-up sent to Yaw Boateng'),
      ('note_created',      _createdNoteIds.isNotEmpty ? _createdNoteIds.first : _customerIds[0], 'Added note: How to rekey a Yale mortise cylinder'),
    ];
    for (final (eventType, relatedId, description) in activityData) {
      final aId = uuid.v4();
      _createdActivityIds.add(aId);
      await _activityLocal.saveEvent(ActivityEventModel(
        id: aId,
        userId: _userId,
        eventType: eventType,
        relatedId: relatedId,
        description: description,
        createdAt: now.subtract(Duration(hours: rng.nextInt(72))).toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created ${activityData.length} activity events');

    // ── Recurring Job Schedules (2) ───────────────────
    final recurringData = [
      (_customerIds[0], 'quarterly', null, 3, 'Quarterly lock maintenance for Kwame', 'Kwame Mensah'),
      (_customerIds[2], 'monthly', null, 1, 'Monthly gate check for Yaw Boateng', 'Yaw Boateng'),
    ];
    for (final (custId, interval, dayOfWeek, dayOfMonth, notes, custName) in recurringData) {
      final rsId = uuid.v4();
      _createdRecurringScheduleIds.add(rsId);
      await _recurringScheduleLocal.save(RecurringScheduleEntity(
        id: rsId,
        userId: _userId,
        customerId: custId,
        customerName: custName,
        serviceType: 'door_lock_inspection',
        intervalType: interval,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
        nextDueDate: DateTime(now.year, now.month + 1, 1),
        isActive: true,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      ));
    }
    debugPrint('[KS:DEMO] Created ${recurringData.length} recurring schedules');

    // ── Job Templates (2) ────────────────────────────
    final templateData = [
      ('Residential Deadbolt Replacement', [
        {'serviceType': 'deadbolt_replacement', 'quantity': 1, 'unitPrice': 150000, 'domain': 'residential'},
        {'serviceType': 'key_duplication', 'quantity': 2, 'unitPrice': 15000, 'domain': 'residential'},
      ], [
        {'category': 'deadbolt', 'brand': 'Yale', 'model': '210', 'quantity': 1, 'unitSalePrice': 35000},
      ], 'Standard residential deadbolt replacement template'),
      ('Commercial Master Key System', [
        {'serviceType': 'master_key_system', 'quantity': 1, 'unitPrice': 500000, 'domain': 'commercial'},
        {'serviceType': 'lock_rekeying', 'quantity': 8, 'unitPrice': 25000, 'domain': 'commercial'},
      ], [
        {'category': 'mortise_lock', 'brand': 'Cisa', 'model': 'K4', 'quantity': 8, 'unitSalePrice': 28000},
      ], 'Master key system for new office buildings'),
    ];
    for (final (name, services, hardware, notes) in templateData) {
      final tId = uuid.v4();
      _createdTemplateIds.add(tId);
      await _jobTemplateLocal.saveTemplate(JobTemplateModel(
        id: tId,
        userId: _userId,
        name: name,
        serviceType: 'door_lock_installation',
        notes: notes,
        services: services,
        hardwareItems: hardware,
        parts: [],
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created ${templateData.length} job templates');

    debugPrint('[KS:DEMO] ✅ All demo data seeded successfully');
  }
```

---

### Task 5: Update the dashboard trigger and delete old files

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Delete: `lib/core/services/demo_data_service.dart`
- Delete: `lib/core/utils/mock_data_generator.dart`

- [ ] **Step 1: Update dashboard_screen.dart** — change imports and constructor

Replace the old import:

```dart
import '../../../../core/services/demo_data_service.dart';
```

with:

```dart
import '../../../../core/services/demo_data_seeder.dart';
```

Replace the old constructor call (lines 65-74):

```dart
    final service = DemoDataService(
      customerLocal: CustomerLocalDatasource(),
      jobLocal: JobLocalDatasource(),
      servicesLocal: JobServicesLocalDatasource(),
      hardwareLocal: JobHardwareLocalDatasource(),
      partsLocal: JobPartsLocalDatasource(),
      expensesLocal: JobExpensesLocalDatasource(),
      auditLocal: JobAuditLocalDatasource(),
      userId: userId,
    );
```

with the new seeder constructor with all 21 datasources:

```dart
    final service = DemoDataSeeder(
      customerLocal: CustomerLocalDatasource(),
      jobLocal: JobLocalDatasource(),
      servicesLocal: JobServicesLocalDatasource(),
      hardwareLocal: JobHardwareLocalDatasource(),
      partsLocal: JobPartsLocalDatasource(),
      expensesLocal: JobExpensesLocalDatasource(),
      photosLocal: JobPhotosLocalDatasource(),
      auditLocal: JobAuditLocalDatasource(),
      inventoryLocal: InventoryLocalDatasource(),
      restocksLocal: InventoryRestocksLocalDatasource(),
      stockAdjustmentsLocal: InventoryStockAdjustmentsLocalDatasource(),
      notesLocal: KnowledgeNoteLocalDatasource(),
      noteLinkLocal: NoteLinkLocalDatasource(),
      followUpLocal: FollowUpLocalDatasource(),
      keyCodeLocal: KeyCodeLocalDatasource(),
      correctionRequestLocal: CorrectionRequestLocalDatasource(),
      remindersLocal: RemindersLocalDatasource(),
      activityLocal: ActivityLocalDatasource(),
      recurringScheduleLocal: RecurringScheduleLocalDatasource(),
      jobTemplateLocal: JobTemplateLocalDatasource(),
      userId: userId,
    );
```

Add the new imports needed for the additional datasources (add to the existing import block):

```dart
import '../../../../core/services/demo_data_seeder.dart';
import '../../../../inventory/data/datasources/inventory_local_datasource.dart';
import '../../../../inventory/data/datasources/inventory_restocks_local_datasource.dart';
import '../../../../inventory/data/datasources/inventory_stock_adjustments_local_datasource.dart';
import '../../../../knowledge_base/data/datasources/knowledge_note_local_datasource.dart';
import '../../../../note_links/data/datasources/note_link_local_datasource.dart';
import '../../../../whatsapp_followup/data/datasources/follow_up_local_datasource.dart';
import '../../../../key_codes/data/datasources/key_code_local_datasource.dart';
import '../../../../correction_requests/data/datasources/correction_request_local_datasource.dart';
import '../../../../activity/data/datasources/activity_local_datasource.dart';
import '../../../../recurring_jobs/data/datasources/recurring_schedule_local_datasource.dart';
import '../../../../job_templates/data/datasources/job_template_local_datasource.dart';
```

Remove the old import:
```
import '../../../../core/services/demo_data_service.dart';
```

- [ ] **Step 2: Delete old generator files**

```bash
rm lib/core/services/demo_data_service.dart
rm lib/core/utils/mock_data_generator.dart
```

- [ ] **Step 3: Run flutter analyze to verify no compilation errors**

Run: `cd /home/cybocrime/workspace/projects/keystone && flutter analyze lib/core/services/demo_data_seeder.dart`
Expected: No errors (info/warnings acceptable)

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: unified demo data seeder covering all 27 schema tables"
```
