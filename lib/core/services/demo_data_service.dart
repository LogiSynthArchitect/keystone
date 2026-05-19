import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:keystone/core/constants/app_enums.dart';
import 'package:keystone/features/customer_history/data/datasources/customer_local_datasource.dart';
import 'package:keystone/features/customer_history/data/models/customer_model.dart';
import 'package:keystone/features/job_logging/data/datasources/job_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_services_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_hardware_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_parts_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_expenses_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_audit_local_datasource.dart';
import 'package:keystone/features/job_logging/data/models/job_model.dart';
import 'package:keystone/features/job_logging/data/models/job_service_model.dart';
import 'package:keystone/features/job_logging/data/models/job_hardware_model.dart';
import 'package:keystone/features/job_logging/data/models/job_part_model.dart';
import 'package:keystone/features/job_logging/data/models/job_expense_model.dart';
import 'package:keystone/features/job_logging/data/models/job_audit_entry_model.dart';

/// Seeds or removes demo data for development/testing.
/// Called by tapping the dashboard title 5 times.
class DemoDataService {
  final CustomerLocalDatasource _customerLocal;
  final JobLocalDatasource _jobLocal;
  final JobServicesLocalDatasource _servicesLocal;
  final JobHardwareLocalDatasource _hardwareLocal;
  final JobPartsLocalDatasource _partsLocal;
  final JobExpensesLocalDatasource _expensesLocal;
  final JobAuditLocalDatasource _auditLocal;
  final String _userId;

  const DemoDataService({
    required CustomerLocalDatasource customerLocal,
    required JobLocalDatasource jobLocal,
    required JobServicesLocalDatasource servicesLocal,
    required JobHardwareLocalDatasource hardwareLocal,
    required JobPartsLocalDatasource partsLocal,
    required JobExpensesLocalDatasource expensesLocal,
    required JobAuditLocalDatasource auditLocal,
    required String userId,
  }) : _customerLocal = customerLocal,
       _jobLocal = jobLocal,
       _servicesLocal = servicesLocal,
       _hardwareLocal = hardwareLocal,
       _partsLocal = partsLocal,
       _expensesLocal = expensesLocal,
       _auditLocal = auditLocal,
       _userId = userId;

  static const _demoCustomerIds = [
    'demo_customer_001',
    'demo_customer_002',
    'demo_customer_003',
    'demo_customer_004',
    'demo_customer_005',
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
  ];

  /// Returns true if any demo data exists.
  Future<bool> hasDemoData() async {
    for (final id in _demoJobIds) {
      final job = await _jobLocal.getJob(id);
      if (job != null) return true;
    }
    return false;
  }

  /// Creates demo customers and jobs with child entities.
  Future<void> seed() async {
    debugPrint('[KS:DEMO] Seeding demo data...');

    final now = DateTime.now();
    final rng = Random(42);

    // ── Customers ──────────────────────────────────────────
    final customerData = [
      (_demoCustomerIds[0], 'Kwame Mensah',     '0241234567', 'East Legon, Accra',       'residential'),
      (_demoCustomerIds[1], 'Ama Serwaa',       '0559876543', 'Cantoments, Accra',       'commercial'),
      (_demoCustomerIds[2], 'Yaw Boateng',      '0204567890', 'Tema Community 25',       'residential'),
      (_demoCustomerIds[3], 'Abena Oforiwaa',   '0541122334', 'Spintex, Accra',          'commercial'),
      (_demoCustomerIds[4], 'Kofi Asare',       '0277890123', 'Madina Zongo, Accra',     'automotive'),
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
    debugPrint('[KS:DEMO] Created 5 customers');

    // ── Jobs ───────────────────────────────────────────────
    final statuses = ['quoted', 'in_progress', 'completed', 'invoiced'];
    final services = ['deadbolt_replacement', 'car_key_programming', 'safe_opening', 'lockout_assistance', 'master_key_system', 'door_installation', 'cabinet_locks', 'gate_automation'];
    final leads = ['referral', 'whatsapp', 'walk_in', 'google_maps', 'repeat_customer'];

    for (int i = 0; i < _demoJobIds.length; i++) {
      final jobId = _demoJobIds[i];
      final custIdx = i % customerData.length;
      final c = customerData[custIdx];
      final daysAgo = rng.nextInt(14);
      final status = statuses[i % statuses.length];
      final amount = [80000, 150000, 450000, 120000, 250000, 350000, 90000, 180000][i]; // pesewas

      final jobDate = DateTime(now.year, now.month, now.day - daysAgo, rng.nextInt(10) + 7, rng.nextInt(60));
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
        paymentStatus: status == 'invoiced' ? 'paid' : (status == 'completed' ? 'unpaid' : 'unpaid'),
        quotedPrice: (amount + rng.nextInt(50000)).toDouble(),
        notes: _demoNotes[i],
        followUpSent: status == 'completed' || status == 'invoiced',
        syncStatus: SyncStatus.synced.name,
        createdAt: now.subtract(Duration(days: daysAgo)).toIso8601String(),
        updatedAt: now.toIso8601String(),
        leadSource: leads[i % leads.length],
      );
      await _jobLocal.saveJob(job);

      // ── Services ───────────────────────────────────────
      final extraServices = [
        ['key_duplication', 'lock_lubrication'],
        ['lock_rekeying'],
        ['window_lock_repair'],
        [],
        ['key_duplication'],
        ['gate_remote_programming'],
        ['lock_lubrication'],
        [],
      ];
      for (int s = 0; s < extraServices[i].length; s++) {
        await _servicesLocal.saveService(JobServiceModel(
          id: const Uuid().v4(),
          jobId: jobId,
          serviceType: extraServices[i][s],
          quantity: 1,
          unitPrice: rng.nextInt(50000) + 10000,
          sortOrder: s,
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Hardware items ──────────────────────────────────
      if (i < 5) {
        final hardwareBrands = ['Yale', 'Abus', 'Master Lock', 'Cisa', 'Mul-T-Lock'];
        final hardwareModels = ['210', '83/45', 'M1', 'K4', 'MT5+'];
        await _hardwareLocal.saveHardware(JobHardwareModel(
          id: const Uuid().v4(),
          jobId: jobId,
          domain: i < 2 ? 'residential' : (i < 4 ? 'commercial' : 'automotive'),
          category: i < 2 ? 'deadbolt' : (i < 4 ? 'mortise_lock' : 'key_blank'),
          brand: hardwareBrands[i],
          model: hardwareModels[i],
          quantity: rng.nextInt(3) + 1,
          unitSalePrice: amount ~/ 3,
          unitCostPrice: amount ~/ 5,
          sortOrder: 0,
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Parts ───────────────────────────────────────────
      if (i % 2 == 0) {
        await _partsLocal.savePart(JobPartModel(
          id: const Uuid().v4(),
          jobId: jobId,
          partName: _demoParts[i % _demoParts.length],
          quantity: rng.nextInt(5) + 1,
          unitPrice: rng.nextInt(5000) + 1000,
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Expenses ────────────────────────────────────────
      if (i < 6) {
        await _expensesLocal.saveExpense(JobExpenseModel(
          id: const Uuid().v4(),
          jobId: jobId,
          category: _expenseCategories[i % _expenseCategories.length],
          description: _demoExpenseDescs[i],
          amount: (rng.nextInt(50) + 10) * 100, // GHS 10-50 in pesewas
          createdAt: jobDate.toIso8601String(),
        ));
      }

      // ── Audit entry ────────────────────────────────────
      await _auditLocal.saveEntry(JobAuditEntryModel(
        id: const Uuid().v4(),
        jobId: jobId,
        action: 'job_created',
        newValues: {'status': status, 'service_type': services[i]},
        createdAt: jobDate.toIso8601String(),
      ));
    }

    debugPrint('[KS:DEMO] Created 8 demo jobs with children');
  }

  /// Remove all demo data by ID prefix.
  Future<void> remove() async {
    debugPrint('[KS:DEMO] Removing demo data...');

    // Remove child entities first
    for (final jobId in _demoJobIds) {
      await _servicesLocal.deleteServicesForJob(jobId);
      await _hardwareLocal.deleteHardwareForJob(jobId);
      await _partsLocal.deletePartsForJob(jobId);
      await _expensesLocal.deleteExpensesForJob(jobId);
      await _jobLocal.deleteJob(jobId);
    }

    // Remove demo customers
    for (final custId in _demoCustomerIds) {
      await _customerLocal.deleteCustomer(custId);
    }

    debugPrint('[KS:DEMO] Removed all demo data');
  }

  // ── Static data ──────────────────────────────────────────

  static const _demoNotes = [
    'Customer requested quick installation. Existing deadbolt was seized.',
    'Office door lock replacement. Three doors total.',
    'Car key lost — needed new transponder key programmed on-site.',
    'Safe lock jammed. Managed to open and replace the dial mechanism.',
    'Master key system for new office building. 8 doors total.',
    'New door installation with mortise lock set. Customer supplied door.',
    'Cabinet locks for kitchen renovation. Matching keyed alike.',
    'Gate motor remote reprogramming. Two remotes configured.',
  ];

  static const _demoParts = [
    'Deadbolt latch',
    'Spring set',
    'Transponder chip',
    'Dial mechanism',
    'Master key blank',
    'Mortise cylinder',
    'Cam lock',
    'Remote battery',
  ];

  static const _expenseCategories = [
    'transport', 'parking', 'supplies', 'parking', 'transport', 'subcontractor',
  ];

  static const _demoExpenseDescs = [
    'Troski fare to site',
    'Parking at customer location',
    'WD-40 and lubricant',
    'Mall parking fee',
    'Fuel for return trip',
    'Welder assistance for gate repair',
  ];
}
