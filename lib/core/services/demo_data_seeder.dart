import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:keystone/core/storage/hive_service.dart';
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
import 'package:keystone/features/inventory/domain/entities/inventory_item_entity.dart';
import 'package:keystone/features/knowledge_base/data/datasources/knowledge_note_local_datasource.dart';
import 'package:keystone/features/knowledge_base/data/models/knowledge_note_model.dart';
import 'package:keystone/features/knowledge_base/data/models/note_attachment_model.dart';
import 'package:keystone/features/note_links/data/datasources/note_link_local_datasource.dart';
import 'package:keystone/features/note_links/data/models/note_job_link_model.dart';
import 'package:keystone/features/whatsapp_followup/data/datasources/follow_up_local_datasource.dart';
import 'package:keystone/features/key_codes/data/datasources/key_code_local_datasource.dart';
import 'package:keystone/features/key_codes/data/models/key_code_entry_model.dart';
import 'package:keystone/features/reminders/data/models/reminder_model.dart';
import 'package:keystone/features/recurring_jobs/data/datasources/recurring_schedule_local_datasource.dart';
import 'package:keystone/features/recurring_jobs/domain/entities/recurring_schedule_entity.dart';
import 'package:keystone/features/job_templates/data/datasources/job_template_local_datasource.dart';
import 'package:keystone/features/job_templates/data/models/job_template_model.dart';
import 'package:keystone/features/job_templates/domain/entities/template_service_item.dart';
import 'package:keystone/features/job_templates/domain/entities/template_hardware_item.dart';
import 'package:keystone/features/job_templates/domain/entities/template_part_item.dart';
import 'package:keystone/features/job_templates/domain/entities/job_template_entity.dart';
import 'package:keystone/features/service_types/data/datasources/service_type_local_datasource.dart';
import 'package:keystone/features/service_types/data/models/service_type_model.dart';

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
  final RecurringScheduleLocalDatasource _recurringScheduleLocal;
  final JobTemplateLocalDatasource _jobTemplateLocal;
  final ServiceTypeLocalDatasource _serviceTypeLocal;

  final String _userId;

  final Set<String> _createdInventoryIds = {};
  final Set<String> _createdNoteIds = {};
  final Set<String> _createdNoteLinkIds = {};
  final Set<String> _createdKeyCodeIds = {};
  final Set<String> _createdReminderIds = {};
  final Set<String> _createdRecurringScheduleIds = {};


  DemoDataSeeder({
    required CustomerLocalDatasource customerLocal,
    required JobLocalDatasource jobLocal,
    required JobServicesLocalDatasource servicesLocal,
    required JobHardwareLocalDatasource hardwareLocal,
    required JobPartsLocalDatasource partsLocal,
    required JobExpensesLocalDatasource expensesLocal,
    required JobPhotosLocalDatasource photosLocal,
    required JobAuditLocalDatasource auditLocal,
    required InventoryLocalDatasource inventoryLocal,
    required InventoryRestocksLocalDatasource restocksLocal,
    required InventoryStockAdjustmentsLocalDatasource stockAdjustmentsLocal,
    required KnowledgeNoteLocalDatasource notesLocal,
    required NoteLinkLocalDatasource noteLinkLocal,
    required FollowUpLocalDatasource followUpLocal,
    required KeyCodeLocalDatasource keyCodeLocal,
    required RecurringScheduleLocalDatasource recurringScheduleLocal,
    required JobTemplateLocalDatasource jobTemplateLocal,
    required ServiceTypeLocalDatasource serviceTypeLocal,
    required String userId,
  })  : _customerLocal = customerLocal,
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
        _recurringScheduleLocal = recurringScheduleLocal,
       _jobTemplateLocal = jobTemplateLocal,
       _serviceTypeLocal = serviceTypeLocal,
       _userId = userId;

  static const _demoCustomerIds = [
    'demo_customer_001',
    'demo_customer_002',
    'demo_customer_003',
    'demo_customer_004',
    'demo_customer_005',
    'demo_customer_006',
    'demo_customer_007',
    'demo_customer_008',
  ];

  static const _demoJobIds = [
    'demo_job_001',
    'demo_job_002',
    'demo_job_003',
    'demo_job_004',
    'demo_job_005',
    'demo_job_006',
    'demo_job_007',
    'demo_job_008',
    'demo_job_009',
    'demo_job_010',
    'demo_job_011',
    'demo_job_012',
  ];

  static const _demoInventoryIds = [
    'demo_inventory_001',
    'demo_inventory_002',
    'demo_inventory_003',
    'demo_inventory_004',
    'demo_inventory_005',
    'demo_inventory_006',
    'demo_inventory_007',
    'demo_inventory_008',
    'demo_inventory_009',
    'demo_inventory_010',
    'demo_inventory_011',
    'demo_inventory_012',
  ];

  static const List<String> _demoTemplateIds = [
    'demo_template_001',
    'demo_template_002',
  ];

  Future<bool> hasDemoData() async {
    final job = await _jobLocal.getJob('demo_job_001');
    return job != null;
  }

  Future<void> seed() async {
    debugPrint('[KS:DEMO] Seeding demo data...');
    final now = DateTime.now();
    final rng = Random(42);
    const uuid = Uuid();

    // ── Customers ──────────────────────────────────────────
    final customerData = [
      (_demoCustomerIds[0], 'Kwame Mensah', '0241234567', 'East Legon, Accra', 'residential'),
      (_demoCustomerIds[1], 'Ama Serwaa', '0559876543', 'Cantoments, Accra', 'commercial'),
      (_demoCustomerIds[2], 'Yaw Boateng', '0204567890', 'Tema Community 25', 'residential'),
      (_demoCustomerIds[3], 'Abena Oforiwaa', '0541122334', 'Spintex, Accra', 'commercial'),
      (_demoCustomerIds[4], 'Kofi Asare', '0277890123', 'Madina Zongo, Accra', 'automotive'),
      (_demoCustomerIds[5], 'Efua Dadzie', '0509876123', 'Osu, Accra', 'residential'),
      (_demoCustomerIds[6], 'Kwaku Adjei', '0245566778', 'Adenta, Accra', 'commercial'),
      (_demoCustomerIds[7], 'Akosua Manu', '0203456789', 'Kasoa', 'residential'),
    ];

    for (final (id, name, phone, location, propertyType) in customerData) {
      await _customerLocal.saveCustomer(CustomerModel(
        id: id,
        userId: _userId,
        fullName: name,
        phoneNumber: phone,
        location: location,
        propertyType: propertyType,
        totalJobs: 0,
        createdAt: now.subtract(const Duration(days: 30)).toIso8601String(),
        updatedAt: now.toIso8601String(),
      ));
    }
    debugPrint('[KS:DEMO] Created 8 customers');

    // ── Jobs ───────────────────────────────────────────────
    final statuses = [
      'quoted', 'in_progress', 'completed', 'invoiced',
      'quoted', 'in_progress', 'completed', 'invoiced',
      'quoted', 'in_progress', 'completed', 'invoiced',
    ];
    final services = [
      'deadbolt_replacement', 'car_key_programming', 'safe_opening', 'lockout_assistance',
      'master_key_system', 'door_installation', 'cabinet_locks', 'gate_automation',
      'window_lock_repair', 'lock_rekeying', 'gate_remote_programming', 'key_duplication',
    ];
    final amounts = [80000, 150000, 450000, 120000, 250000, 350000, 90000, 180000, 200000, 300000, 150000, 400000];
    final leads = ['referral', 'whatsapp', 'walk_in', 'google_maps', 'repeat_customer', 'referral', 'whatsapp', 'walk_in', 'google_maps', 'repeat_customer', 'referral', 'whatsapp'];

    final jobNotes = [
      'Customer requested quick installation. Existing deadbolt was seized.',
      'Office door lock replacement. Three doors total.',
      'Car key lost — needed new transponder key programmed on-site.',
      'Safe lock jammed. Managed to open and replace the dial mechanism.',
      'Master key system for new office building. 8 doors total.',
      'New door installation with mortise lock set. Customer supplied door.',
      'Cabinet locks for kitchen renovation. Matching keyed alike.',
      'Gate motor remote reprogramming. Two remotes configured.',
      'Window latch replacement on four windows. Old latches were rusted.',
      'Rekeying all exterior locks for new homeowner. 5 locks total.',
      'Gate remote lost — replacement and reprogramming of two units.',
      'Duplicate keys for office filing cabinets. 12 copies made.',
    ];

    for (int i = 0; i < _demoJobIds.length; i++) {
      final jobId = _demoJobIds[i];
      final custIdx = i % customerData.length;
      final c = customerData[custIdx];
      final daysAgo = rng.nextInt(14);
      final status = statuses[i];
      final amount = amounts[i];
      final jobDate = DateTime(now.year, now.month, now.day - daysAgo, rng.nextInt(10) + 7, rng.nextInt(60));
      final followUpSent = status == 'completed' || status == 'invoiced';

      String? quotedAt;
      String? inProgressAt;
      String? completedAt;
      String? invoicedAt;
      DateTime? followUpSentAt;

      quotedAt = jobDate.subtract(const Duration(hours: 2)).toIso8601String();
      if (status == 'in_progress' || status == 'completed' || status == 'invoiced') {
        inProgressAt = jobDate.toIso8601String();
      }
      if (status == 'completed' || status == 'invoiced') {
        completedAt = jobDate.add(const Duration(hours: 3)).toIso8601String();
      }
      if (status == 'invoiced') {
        invoicedAt = jobDate.add(const Duration(hours: 24)).toIso8601String();
      }
      if (followUpSent) {
        followUpSentAt = jobDate.add(const Duration(hours: 48));
      }

      final job = JobModel(
        id: jobId,
        userId: _userId,
        customerId: c.$1,
        serviceType: services[i],
        jobDate: jobDate,
        location: c.$3,
        amountCharged: amount,
        status: status,
        isArchived: false,
        paymentStatus: status == 'invoiced' ? 'paid' : 'unpaid',
        quotedPrice: (amount + rng.nextInt(50000)).toDouble(),
        notes: jobNotes[i],
        followUpSent: followUpSent,
        followUpSentAt: followUpSentAt,
        syncStatus: 'synced',
        createdAt: now.subtract(Duration(days: daysAgo)).toIso8601String(),
        updatedAt: now.toIso8601String(),
        leadSource: leads[i],
        quotedAt: quotedAt,
        inProgressAt: inProgressAt,
        completedAt: completedAt,
        invoicedAt: invoicedAt,
      );
      await _jobLocal.saveJob(job);

      // Update customer totalJobs and lastJobAt
      await _customerLocal.saveCustomer(CustomerModel(
        id: c.$1,
        userId: _userId,
        fullName: c.$2,
        phoneNumber: c.$3,
        location: c.$4,
        propertyType: c.$5,
        totalJobs: ((i ~/ customerData.length) + 1),
        lastJobAt: jobDate.toIso8601String(),
        createdAt: now.subtract(const Duration(days: 30)).toIso8601String(),
        updatedAt: now.toIso8601String(),
      ));

      // ── Services (1-2 per job) ──────────────────────────
      final extraServices = [
        ['key_duplication', 'lock_lubrication'],
        ['lock_rekeying'],
        ['window_lock_repair'],
        [],
        ['key_duplication'],
        ['gate_remote_programming'],
        ['lock_lubrication'],
        [],
        ['lock_lubrication', 'key_duplication'],
        ['deadbolt_replacement'],
        ['key_duplication'],
        [],
      ];

      for (int s = 0; s < extraServices[i].length; s++) {
        await _servicesLocal.saveService(JobServiceModel(
          id: uuid.v4(),
          jobId: jobId,
          serviceType: extraServices[i][s],
          quantity: 1,
          unitPrice: rng.nextInt(50000) + 10000,
          domain: i < 3 ? 'residential' : (i < 6 ? 'commercial' : 'automotive'),
          notes: 'Demo service for ${extraServices[i][s]}',
          sortOrder: s,
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Hardware (0-2 per job) ──────────────────────────
      if (i % 3 != 0) {
        final hardwareCount = i % 2 == 0 ? 2 : 1;
        for (int h = 0; h < hardwareCount; h++) {
          await _hardwareLocal.saveHardware(JobHardwareModel(
            id: uuid.v4(),
            jobId: jobId,
            domain: i < 3 ? 'residential' : (i < 6 ? 'commercial' : 'automotive'),
            category: h == 0 ? 'deadbolt' : 'mortise_lock',
            brand: ['Yale', 'Abus', 'Master Lock'][h],
            model: ['210', '83/45', 'M1'][h],
            keySpec: 'SC1',
            material: 'brass',
            finish: h == 0 ? 'satin_nickel' : 'oil_rubbed_bronze',
            dimensions: '2.75in x 1.5in',
            quantity: rng.nextInt(3) + 1,
            unitSalePrice: amount ~/ 3,
            unitCostPrice: amount ~/ 5,
            sortOrder: h,
            createdAt: jobDate.toIso8601String(),
          ));
        }
      }

      // ── Parts (0-3 per job, linked to inventory) ────────
      final partNames = [
        'Deadbolt latch', 'Spring set', 'Transponder chip',
        'Dial mechanism', 'Master key blank', 'Mortise cylinder',
        'Cam lock', 'Remote battery', 'Window latch',
        'Screw kit', 'Gate remote', 'Key blank',
      ];

      final partsCount = i % 4;
      for (int p = 0; p < partsCount; p++) {
        final invIdx = (i + p * 2) % _demoInventoryIds.length;
        await _partsLocal.savePart(JobPartModel(
          id: uuid.v4(),
          jobId: jobId,
          partName: partNames[(i + p) % partNames.length],
          quantity: rng.nextInt(5) + 1,
          unitPrice: rng.nextInt(5000) + 1000,
          inventoryItemId: _demoInventoryIds[invIdx],
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Expenses (0-2 per job) ──────────────────────────
      final expenseCategories = ['transport', 'parking', 'supplies', 'parking', 'transport', 'subcontractor'];
      final expenseDescriptions = [
        'Troski fare to site',
        'Parking at customer location',
        'WD-40 and lubricant',
        'Mall parking fee',
        'Fuel for return trip',
        'Welder assistance for gate repair',
      ];

      final expenseCount = i % 3 == 0 ? 2 : (i % 2 == 0 ? 1 : 0);
      for (int e = 0; e < expenseCount; e++) {
        await _expensesLocal.saveExpense(JobExpenseModel(
          id: uuid.v4(),
          jobId: jobId,
          category: expenseCategories[(i + e) % expenseCategories.length],
          description: expenseDescriptions[(i + e) % expenseDescriptions.length],
          amount: (rng.nextInt(50) + 10) * 100,
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Photos (0-1 per job) ────────────────────────────
      if (i % 2 == 0) {
        await _photosLocal.savePhoto(JobPhotoModel(
          id: uuid.v4(),
          jobId: jobId,
          storagePath: 'demo/jobs/${jobId}_photo.jpg',
          label: 'Before photo',
          mediaType: 'image',
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Audit entries (1-2 per job) ─────────────────────
      await _auditLocal.saveEntry(JobAuditEntryModel(
        id: uuid.v4(),
        jobId: jobId,
        userId: _userId,
        action: 'job_created',
        newValues: {'status': status, 'service_type': services[i]},
        createdAt: jobDate.toIso8601String(),
      ));
      if (status == 'completed' || status == 'invoiced') {
        await _auditLocal.saveEntry(JobAuditEntryModel(
          id: uuid.v4(),
          jobId: jobId,
          userId: _userId,
          action: 'status_change',
          oldValues: {'status': 'in_progress'},
          newValues: {'status': 'completed'},
          createdAt: jobDate.add(const Duration(hours: 3)).toIso8601String(),
        ));
      }
    }
    debugPrint('[KS:DEMO] Created 12 demo jobs with children');

    // ── Inventory Items (12: 6 parts + 6 hardware) ────────
    final inventoryItems = [
      ('Deadbolt latch', 'part', 'deadbolt', 2500, 5000, 10, 5),
      ('Spring set', 'part', 'spring', 800, 1500, 20, 10),
      ('Transponder chip', 'part', 'electronics', 15000, 30000, 5, 3),
      ('Dial mechanism', 'part', 'safe', 20000, 45000, 3, 2),
      ('Master key blank', 'consumable', 'key_blank', 500, 1200, 30, 10),
      ('Mortise cylinder', 'lock', 'mortise_lock', 12000, 25000, 4, 2),
      ('Yale deadbolt 210', 'lock', 'deadbolt', 15000, 35000, 8, 5),
      ('Abus padlock 83/45', 'lock', 'padlock', 8000, 18000, 12, 5),
      ('Master Lock M1', 'lock', 'padlock', 5000, 12000, 6, 5),
      ('Cisa mortise K4', 'lock', 'mortise_lock', 25000, 55000, 2, 3),
      ('Mul-T-Lock MT5+', 'lock', 'mortise_lock', 30000, 65000, 1, 2),
      ('Gate remote universal', 'electronic', 'gate', 10000, 25000, 15, 10),
    ];

    for (int i = 0; i < inventoryItems.length; i++) {
      final (name, itemCat, oldCategory, cost, sale, qty, threshold) = inventoryItems[i];
      final item = InventoryItemModel(
        id: _demoInventoryIds[i],
        userId: _userId,
        category: InventoryItemCategory.fromDb(itemCat),
        name: name,
        attributes: {'type': oldCategory},
        defaultCostPrice: cost,
        defaultSalePrice: sale,
        quantity: qty,
        lowStockThreshold: threshold,
        location: 'Shelf ${(i ~/ 4) + 1}',
        createdAt: now.subtract(const Duration(days: 30)).toIso8601String(),
        updatedAt: now.toIso8601String(),
      );
      await _inventoryLocal.saveItem(item);
      _createdInventoryIds.add(_demoInventoryIds[i]);

      // Update quantity to be below threshold for some items
      if (i % 3 == 0) {
        final lowItem = InventoryItemModel(
          id: _demoInventoryIds[i],
          userId: _userId,
          category: InventoryItemCategory.fromDb(itemCat),
          name: name,
          attributes: {'type': oldCategory},
          defaultCostPrice: cost,
          defaultSalePrice: sale,
          quantity: threshold - 1,
          lowStockThreshold: threshold,
          location: 'Shelf ${(i ~/ 4) + 1}',
          createdAt: now.subtract(const Duration(days: 30)).toIso8601String(),
          updatedAt: now.toIso8601String(),
        );
        await _inventoryLocal.saveItem(lowItem);
      }
    }
    debugPrint('[KS:DEMO] Created 12 inventory items');

    // ── Inventory Restocks (4) ────────────────────────────
    final restockData = [
      (_demoInventoryIds[0], 20, 2200, 44000, 'LockMart Ltd', '0241112233'),
      (_demoInventoryIds[2], 10, 14000, 140000, 'KeyTech Supplies', '0209988776'),
      (_demoInventoryIds[6], 15, 14000, 210000, 'LockMart Ltd', '0241112233'),
      (_demoInventoryIds[10], 5, 28000, 140000, 'SafeLock Distributors', '0275566778'),
    ];

    for (final (itemId, qty, unitCost, totalCost, vendor, phone) in restockData) {
      final restock = RestockModel(
        id: uuid.v4(),
        itemId: itemId,
        userId: _userId,
        quantity: qty,
        unitCost: unitCost,
        totalCost: totalCost,
        vendor: vendor,
        supplierPhone: phone,
        notes: 'Demo restock',
        createdAt: now.subtract(const Duration(days: 7)).toIso8601String(),
      );
      await _restocksLocal.save(restock);

    }
    debugPrint('[KS:DEMO] Created 4 inventory restocks');

    // ── Inventory Stock Adjustments (4) ───────────────────
    final adjData = [
      (_demoInventoryIds[1], 'restock', 20, 25, 'Stock count correction after restock'),
      (_demoInventoryIds[5], 'job_use', -2, 2, 'Used in demo_job_003'),
      (_demoInventoryIds[7], 'correction', -1, 11, 'Found damaged in storage'),
      (_demoInventoryIds[3], 'manual_add', 5, 8, 'Added from manual count'),
    ];

    for (final (itemId, adjType, change, after, reason) in adjData) {
      final adj = StockAdjustmentModel(
        id: uuid.v4(),
        itemId: itemId,
        userId: _userId,
        adjustmentType: adjType,
        quantityChange: change,
        quantityAfter: after,
        reason: reason,
        createdAt: now.subtract(const Duration(days: 5)).toIso8601String(),
      );
      await _stockAdjustmentsLocal.save(adj);

    }
    debugPrint('[KS:DEMO] Created 4 stock adjustments');

    // ── Follow-ups (4: sent, responded, no_response, sent) ─
    final followUpJobIds = ['demo_job_002', 'demo_job_005', 'demo_job_008', 'demo_job_011'];
    final followUpStatuses = ['sent', 'responded', 'no_response', 'sent'];

    for (int i = 0; i < followUpJobIds.length; i++) {
      final fJobId = followUpJobIds[i];
      final fStatus = followUpStatuses[i];
      await _followUpLocal.saveFollowUp({
        'id': uuid.v4(),
        'job_id': fJobId,
        'user_id': _userId,
        'message_status': fStatus,
        'response_status': fStatus == 'responded' ? 'received' : null,
        'message_sent_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        'response_updated_at': fStatus == 'responded'
            ? now.subtract(const Duration(days: 2)).toIso8601String()
            : null,
        'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
      });

    }
    debugPrint('[KS:DEMO] Created 4 follow-ups');

    // ── Key Codes (4) ─────────────────────────────────────
    final keyCodeData = [
      (_demoCustomerIds[0], 'demo_job_001', 'Y101', 'deadbolt', '1-3-5-2-4', 'Front door deadbolt'),
      (_demoCustomerIds[1], 'demo_job_002', 'SC1', 'mortise', '2-4-1-3-5', 'Office main door'),
      (_demoCustomerIds[2], 'demo_job_003', 'HU66', 'car_key', '1-2-3-4', 'Toyota Camry 2019'),
      (_demoCustomerIds[4], 'demo_job_005', 'M210', 'master_key', '3-1-4-2-5', 'Building master key'),
    ];

    for (final (custId, jobId, keyCode, keyType, bitting, desc) in keyCodeData) {
      final kc = KeyCodeEntryModel(
        id: uuid.v4(),
        customerId: custId,
        jobId: jobId,
        keyCode: keyCode,
        keyType: keyType,
        bitting: bitting,
        description: desc,
        createdAt: now.subtract(const Duration(days: 7)).toIso8601String(),
      );
      await _keyCodeLocal.save(kc);
      _createdKeyCodeIds.add(kc.id);
    }
    debugPrint('[KS:DEMO] Created 4 key codes');

    // ── Knowledge Notes (6) ───────────────────────────────
    final noteData = [
      ('Yale Deadbolt Installation Guide', 'Step-by-step guide for installing Yale 210 deadbolt. Includes drilling template and screw specifications.', ['deadbolt', 'installation', 'yale'], 'document'),
      ('Common Car Key Programming Codes', 'Reference table for transponder programming codes for Toyota, Honda, Ford, and BMW models.', ['car_key', 'programming', 'reference'], 'document'),
      ('Safe Opening Techniques', 'Methods for opening common residential and commercial safes without damage.', ['safe', 'opening', 'techniques'], 'document'),
      ('Lock Lubrication Best Practices', 'Use graphite powder for pin tumblers, PTFE spray for disc detainer locks. Never use WD-40 as lubricant.', ['maintenance', 'lubrication', 'tips'], 'document'),
      ('Master Key System Planning', 'Guidelines for designing master key systems for commercial buildings of various sizes.', ['master_key', 'commercial', 'planning'], 'document'),
      ('Gate Automation Troubleshooting', 'Common issues with gate motor remote systems and their solutions.', ['gate', 'automation', 'troubleshooting'], 'document'),
    ];

    String? lastEditedAt;
    List<Map<String, dynamic>>? attachments;
    for (final (title, desc, tags, mediaType) in noteData) {
      if (rng.nextBool()) {
        lastEditedAt = now.subtract(Duration(days: rng.nextInt(14))).toIso8601String();
      }
      // Add sample attachments to first note (PDF) and fourth note (audio)
      if (title.startsWith('Yale Deadbolt')) {
        attachments = [
          NoteAttachmentModel(
            id: uuid.v4(),
            type: 'document',
            url: 'https://example.com/samples/yale-210-manual.pdf',
            name: 'Yale 210 Installation Manual.pdf',
            size: 245760,
            mimeType: 'application/pdf',
            createdAt: now.toIso8601String(),
          ).toJson(),
        ];
      } else if (title.startsWith('Lock Lubrication')) {
        attachments = [
          NoteAttachmentModel(
            id: uuid.v4(),
            type: 'audio',
            url: 'https://example.com/samples/lubrication-tips.m4a',
            name: 'Lubrication Tips Audio.m4a',
            size: 512000,
            mimeType: 'audio/mp4',
            duration: 120,
            createdAt: now.toIso8601String(),
          ).toJson(),
        ];
      } else {
        attachments = null;
      }
      final note = KnowledgeNoteModel(
        id: uuid.v4(),
        userId: _userId,
        title: title,
        description: desc,
        tags: tags,
        mediaType: mediaType,
        attachments: attachments ?? const [],
        isArchived: false,
        isPinned: rng.nextBool(),
        lastEditedAt: lastEditedAt,
        createdAt: now.subtract(const Duration(days: 30)).toIso8601String(),
        updatedAt: now.toIso8601String(),
      );
      await _notesLocal.saveNote(note);
      _createdNoteIds.add(note.id);
    }
    debugPrint('[KS:DEMO] Created 6 knowledge notes');

    // ── Note-Job Links (3) ────────────────────────────────
    final noteJobLinks = [
      (_createdNoteIds.elementAt(0), 'demo_job_001'),
      (_createdNoteIds.elementAt(2), 'demo_job_003'),
      (_createdNoteIds.elementAt(4), 'demo_job_005'),
    ];

    for (final (noteId, jobId) in noteJobLinks) {
      final link = NoteJobLinkModel(
        id: uuid.v4(),
        noteId: noteId,
        jobId: jobId,
        userId: _userId,
        createdAt: now.toIso8601String(),
      );
      await _noteLinkLocal.save(link);
      _createdNoteLinkIds.add(link.id);
    }
    debugPrint('[KS:DEMO] Created 3 note-job links');

    // ── Reminders (3: active, snoozed, resolved) ──────────
    final reminderBox = HiveService.reminders;
    final reminderData = [
      ('active', null, null),
      ('snoozed', now.add(const Duration(days: 1)), null),
      ('resolved', null, now),
    ];

    for (int i = 0; i < reminderData.length; i++) {
      final (status, snoozedUntil, dismissedAt) = reminderData[i];
      final reminder = ReminderModel(
        id: uuid.v4(),
        userId: _userId,
        jobId: _demoJobIds[i],
        type: 'unpaid_job',
        status: status,
        createdAt: now.subtract(const Duration(days: 7)),
        snoozedUntil: snoozedUntil,
        dismissedAt: dismissedAt,
      );
      await reminderBox.put(reminder.id, reminder.toJson());
      _createdReminderIds.add(reminder.id);
    }
    debugPrint('[KS:DEMO] Created 3 reminders');

    // ── Recurring Schedules (2) ───────────────────────────
    final scheduleData = [
      (_demoCustomerIds[0], 'Kwame Mensah', 'deadbolt_replacement', 'yearly', null, 1, 'Annual deadbolt check'),
      (_demoCustomerIds[3], 'Abena Oforiwaa', 'lock_rekeying', 'quarterly', null, 3, 'Quarterly rekey for office'),
    ];

    for (final (custId, custName, svcType, interval, dayOfWeek, dayOfMonth, notes) in scheduleData) {
      final schedule = RecurringScheduleEntity(
        id: uuid.v4(),
        userId: _userId,
        customerId: custId,
        customerName: custName,
        serviceType: svcType,
        intervalType: interval,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
        nextDueDate: now.add(const Duration(days: 30)),
        isActive: true,
        notes: notes,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      );
      await _recurringScheduleLocal.save(schedule);
      _createdRecurringScheduleIds.add(schedule.id);
    }
    debugPrint('[KS:DEMO] Created 2 recurring schedules');

    // ── Job Templates (2) ─────────────────────────────────
    final templateEntities = [
      JobTemplateModel.fromEntity(
        JobTemplateEntity(
          id: _demoTemplateIds[0],
          userId: _userId,
          name: 'Standard Deadbolt Install',
          serviceType: 'deadbolt_replacement',
          notes: 'Standard residential deadbolt installation template',
          services: [
            const TemplateServiceItem(id: 'demo_tpl_svc_001', serviceType: 'deadbolt_replacement', quantity: 1, unitPrice: 35000),
            const TemplateServiceItem(id: 'demo_tpl_svc_002', serviceType: 'key_duplication', quantity: 2, unitPrice: 5000),
          ],
          hardwareItems: [
            const TemplateHardwareItem(id: 'demo_tpl_hw_001', name: 'Yale 210 Deadbolt', quantity: 1, unitSalePrice: 35000),
          ],
          parts: [
            const TemplatePartItem(id: 'demo_tpl_part_001', name: 'Deadbolt latch', quantity: 1, unitPrice: 2500),
            const TemplatePartItem(id: 'demo_tpl_part_002', name: 'Screws (set)', quantity: 1, unitPrice: 500),
          ],
          createdAt: now.subtract(const Duration(days: 14)),
          updatedAt: now.subtract(const Duration(days: 14)),
        ),
      ),
      JobTemplateModel.fromEntity(
        JobTemplateEntity(
          id: _demoTemplateIds[1],
          userId: _userId,
          name: 'Car Key Programming',
          serviceType: 'car_key_programming',
          notes: 'Standard car key programming template',
          services: [
            const TemplateServiceItem(id: 'demo_tpl_svc_003', serviceType: 'car_key_programming', quantity: 1, unitPrice: 150000),
          ],
          hardwareItems: [
            const TemplateHardwareItem(id: 'demo_tpl_hw_002', name: 'Generic Transponder', quantity: 1, unitSalePrice: 30000),
          ],
          parts: [
            const TemplatePartItem(id: 'demo_tpl_part_003', name: 'Transponder chip', quantity: 1, unitPrice: 15000),
          ],
          createdAt: now.subtract(const Duration(days: 14)),
          updatedAt: now.subtract(const Duration(days: 14)),
        ),
      ),
    ];

    for (final template in templateEntities) {
      await _jobTemplateLocal.saveTemplate(template);
    }
    debugPrint('[KS:DEMO] Created 2 job templates');

    // ── Service Type Pricing (set default prices on existing types) ──
    await _seedServiceTypePricing();
    debugPrint('[KS:DEMO] Service type pricing updated');

    debugPrint('[KS:DEMO] Demo data seeding complete');
  }

  Future<void> _seedServiceTypePricing() async {
    // Map service type names to default prices in pesewas (GHS × 100)
    const defaultPrices = {
      'Car Key Replacement':        25000,
      'Transponder Key Programming': 25000,
      'Car Lockout':                6500,
      'Trunk/Boot Unlock':          5000,
      'Key Fob Programming':        20000,
      'Ignition Repair':            15000,
      'Broken Key Extraction':      12000,
      'Motorcycle Keys':            15000,
      'House Lockout':              6500,
      'Lock Installation':          15000,
      'Lock Rekeying':              8000,
      'Lock Repair':                8000,
      'Key Duplication':            1500,
      'Smart Lock Install':         25000,
      'Garage Door Locks':          12000,
      'Padlock Sales/Installation': 8000,
      'Mailbox Locks':              6000,
      'Window Locks':               6000,
      'Commercial Lockout':         8000,
      'Master Key Systems':         50000,
      'Panic Bar Installation':     25000,
      'Door Closer Install':        15000,
      'Electric Strike Installation': 18000,
      'High-Security Locks':        35000,
      'File Cabinet Locks':         8000,
      'Storefront Locks':           12000,
      'CCTV Installation':          25000,
      'Video Doorbell Installation': 15000,
      'Access Control':             30000,
      'Burglar Alarms':             20000,
      'Intercom Systems':           25000,
      'Electric Gate Motor Repair': 20000,
      'Electric Fence Installation': 35000,
      'Rolling Shutter Repair':      15000,
      'Key Cutting':                1000,
      'Safe Opening':               35000,
      'Safe Installation':          25000,
      'Gate Automation':            45000,
      'Eviction Services':          30000,
    };

    try {
      final types = await _serviceTypeLocal.getServiceTypes();
      for (final type in types) {
        final price = defaultPrices[type.name];
        if (price != null && type.defaultPrice == null) {
          final updated = ServiceTypeModel(
            id: type.id,
            userId: type.userId,
            name: type.name,
            isDefault: type.isDefault,
            category: type.category,
            iconName: type.iconName,
            defaultPrice: price,
            createdAt: type.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
          );
          await _serviceTypeLocal.saveServiceType(updated);
        }
      }
    } catch (e) {
      debugPrint('[KS:DEMO] Failed to seed service type prices: $e');
    }
  }

  Future<void> remove() async {
    debugPrint('[KS:DEMO] Removing demo data...');

    // Remove child entities for each job
    for (final jobId in _demoJobIds) {
      final auditBox = HiveService.jobAuditLog;
      final auditKeys = auditBox.values
          .where((j) => j['job_id'] == jobId)
          .map((j) => j['id'] as String)
          .toList();
      await auditBox.deleteAll(auditKeys);
      await auditBox.flush();

      await _photosLocal.deletePhotosForJob(jobId);
      await _expensesLocal.deleteExpensesForJob(jobId);
      await _partsLocal.deletePartsForJob(jobId);
      await _hardwareLocal.deleteHardwareForJob(jobId);
      await _servicesLocal.deleteServicesForJob(jobId);

      // Follow-ups use job_id as key
      await HiveService.followUps.delete(jobId);

      await _jobLocal.deleteJob(jobId);
    }

    // Remove customers
    for (final custId in _demoCustomerIds) {
      await _customerLocal.deleteCustomer(custId);
    }

    // Remove inventory items + children
    for (final invId in _createdInventoryIds) {
      await _restocksLocal.deleteForItem(invId);
      await _stockAdjustmentsLocal.deleteForItem(invId);
      await _inventoryLocal.deleteItem(invId);
    }

    // Remove knowledge notes
    for (final noteId in _createdNoteIds) {
      await _notesLocal.deleteNote(noteId);
    }

    // Remove note-job links
    for (final linkId in _createdNoteLinkIds) {
      await _noteLinkLocal.delete(linkId);
    }

    // Remove key codes
    for (final kcId in _createdKeyCodeIds) {
      await _keyCodeLocal.delete(kcId);
    }

    // Remove reminders via Hive box
    final reminderBox = HiveService.reminders;
    await reminderBox.deleteAll(_createdReminderIds.toList());
    await reminderBox.flush();

    // Remove recurring schedules
    for (final schedId in _createdRecurringScheduleIds) {
      await _recurringScheduleLocal.delete(schedId);
    }

    // Remove job templates (fixed IDs — survives app restarts)
    for (final tId in _demoTemplateIds) {
      await _jobTemplateLocal.hardDeleteTemplate(tId);
    }

    debugPrint('[KS:DEMO] Removed all demo data');
  }
}
