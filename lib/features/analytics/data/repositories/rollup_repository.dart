import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arclock/core/storage/hive_service.dart';
import '../models/daily_rollup.dart';

/// Date utilities used by the rollup engine.
String _dateKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

DateTime _parseDateKey(String key) =>
    DateTime.parse(key);

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Threshold for "leaking revenue": jobs in quoted/in_progress that are
/// this many days past their jobDate without reaching invoiced.
const int _leakingThresholdDays = 7;

/// Repository for pre-computed daily analytics rollups.
///
/// Three execution paths:
/// 1. **Fast path** — read N existing rollups from the box, sum them.
///    No job/part/expense reads. Used when all requested dates are clean.
/// 2. **Targeted recompute** — recompute a single dirty date from its
///    jobs/parts/expenses (max ~8 jobs). Used on invalidation.
/// 3. **Full seed** — scan all jobs/parts/expenses/customers once, write
///    rollups for every date with data. Used on first run (empty box).
class RollupRepository {
  final Box _rollupsBox;
  final Box _jobsBox;
  final Box _partsBox;
  final Box _expensesBox;
  final Box _customersBox;

  RollupRepository()
      : _rollupsBox = Hive.box(HiveService.analyticsDailyRollupsBox),
        _jobsBox = Hive.box(HiveService.jobsBox),
        _partsBox = Hive.box(HiveService.jobPartsBox),
        _expensesBox = Hive.box(HiveService.jobExpensesBox),
        _customersBox = Hive.box(HiveService.customersBox);

  // ────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ────────────────────────────────────────────────────────────────

  /// Returns true if the rollups box is empty (needs initial seed).
  bool get isEmpty => _rollupsBox.isEmpty;

  /// Returns true if any dirty rollup or pending invalidation WAL falls
  /// within [start]..[end].
  ///
  /// Checks both:
  /// 1. Rollups box for `dirty: true` flags (runtime dirty mark).
  /// 2. Meta box for `analytics_dirty:*` keys (WALs written by
  ///    [markAnalyticsDirty] at job mutation time — only processed at
  ///    startup by [reconcileAnalyticsInvalidations]).
  bool hasDirtyInRange(DateTime start, DateTime end) {
    final startKey = _dateKey(start);
    final endKey = _dateKey(end);

    // Check rollups box for dirty flags
    for (final key in _rollupsBox.keys) {
      final k = key.toString();
      if (k.compareTo(startKey) >= 0 && k.compareTo(endKey) <= 0) {
        final raw = _rollupsBox.get(k);
        if (raw is Map && raw['dirty'] == true) return true;
      }
    }

    // Also check meta box for pending invalidation WALs
    final meta = Hive.box(HiveService.metaBox);
    const prefix = 'analytics_dirty:';
    for (final key in meta.keys) {
      final ks = key.toString();
      if (!ks.startsWith(prefix)) continue;
      final dateStr = ks.substring(prefix.length);
      if (dateStr.compareTo(startKey) >= 0 && dateStr.compareTo(endKey) <= 0) {
        return true;
      }
    }

    return false;
  }

  /// Fast path: read rollups in [start]..[end] and return a merged DailyRollup
  /// representing the sum of all non-dirty rollups.
  /// Throws if any rollup in range is dirty — caller must recompute first.
  DailyRollup sumInRange(DateTime start, DateTime end) {
    final startKey = _dateKey(start);
    final endKey = _dateKey(end);

    var revenue = 0, partsCost = 0, expensesCost = 0;
    var jobCount = 0, completedJobCount = 0;
    var uninvoicedValue = 0;
    var unpaidAmt = 0, partialAmt = 0, paidAmt = 0;
    var unpaidCnt = 0, partialCnt = 0, paidCnt = 0;
    var newCustCount = 0;
    final customerRevenue = <String, int>{};
    final stRevenue = <String, int>{};
    final stJobs = <String, int>{};
    final stPartsCost = <String, int>{};
    final partsUsage = <String, int>{};
    final expenseCategories = <String, int>{};
    final leadSourceRevenue = <String, int>{};
    final leadSourceJobs = <String, int>{};
    final locationRevenue = <String, int>{};
    final locationJobs = <String, int>{};
    final propertyTypeRevenue = <String, int>{};
    final propertyTypeJobs = <String, int>{};
    final paymentMethodRevenue = <String, int>{};
    final paymentMethodJobs = <String, int>{};
    final statusRevenue = <String, int>{};
    final statusJobs = <String, int>{};
    var recurringRevenue = 0, recurringJobs = 0;
    var oneOffRevenue = 0, oneOffJobs = 0;
    final sourceJobIds = <String>{};

    for (final key in _rollupsBox.keys) {
      final k = key.toString();
      if (k.compareTo(startKey) < 0 || k.compareTo(endKey) > 0) continue;

      final raw = _rollupsBox.get(k);
      if (raw is! Map) continue;

      final r = DailyRollup.fromJson(Map<String, dynamic>.from(raw));
      if (r.dirty) {
        throw StateError('Rollup $k is dirty — must reconcile before sum');
      }

      revenue += r.revenue;
      partsCost += r.partsCost;
      expensesCost += r.expensesCost;
      jobCount += r.jobCount;
      completedJobCount += r.completedJobCount;
      uninvoicedValue += r.uninvoicedValue;
      unpaidAmt += r.unpaidAmount;
      partialAmt += r.partialAmount;
      paidAmt += r.paidAmount;
      unpaidCnt += r.unpaidCount;
      partialCnt += r.partialCount;
      paidCnt += r.paidCount;
      newCustCount += r.newCustomerCount;

      _mergeMap(customerRevenue, r.customerRevenue);
      _mergeMap(stRevenue, r.stRevenue);
      _mergeMap(stJobs, r.stJobs);
      _mergeMap(stPartsCost, r.stPartsCost);
      _mergeMap(partsUsage, r.partsUsage);
      _mergeMap(expenseCategories, r.expenseCategories);
      _mergeMap(leadSourceRevenue, r.leadSourceRevenue);
      _mergeMap(leadSourceJobs, r.leadSourceJobs);
      _mergeMap(locationRevenue, r.locationRevenue);
      _mergeMap(locationJobs, r.locationJobs);
      _mergeMap(propertyTypeRevenue, r.propertyTypeRevenue);
      _mergeMap(propertyTypeJobs, r.propertyTypeJobs);
      _mergeMap(paymentMethodRevenue, r.paymentMethodRevenue);
      _mergeMap(paymentMethodJobs, r.paymentMethodJobs);
      _mergeMap(statusRevenue, r.statusRevenue);
      _mergeMap(statusJobs, r.statusJobs);
      recurringRevenue += r.recurringRevenue;
      recurringJobs += r.recurringJobs;
      oneOffRevenue += r.oneOffRevenue;
      oneOffJobs += r.oneOffJobs;

      for (final jid in r.sourceJobIds) {
        sourceJobIds.add(jid);
      }
    }

    return DailyRollup(
      dateKey: 'aggregate',
      revenue: revenue,
      partsCost: partsCost,
      expensesCost: expensesCost,
      jobCount: jobCount,
      completedJobCount: completedJobCount,
      uninvoicedValue: uninvoicedValue,
      unpaidAmount: unpaidAmt,
      partialAmount: partialAmt,
      paidAmount: paidAmt,
      unpaidCount: unpaidCnt,
      partialCount: partialCnt,
      paidCount: paidCnt,
      newCustomerCount: newCustCount,
      customerRevenue: customerRevenue,
      stRevenue: stRevenue,
      stJobs: stJobs,
      stPartsCost: stPartsCost,
      partsUsage: partsUsage,
      expenseCategories: expenseCategories,
      leadSourceRevenue: leadSourceRevenue,
      leadSourceJobs: leadSourceJobs,
      locationRevenue: locationRevenue,
      locationJobs: locationJobs,
      propertyTypeRevenue: propertyTypeRevenue,
      propertyTypeJobs: propertyTypeJobs,
      paymentMethodRevenue: paymentMethodRevenue,
      paymentMethodJobs: paymentMethodJobs,
      statusRevenue: statusRevenue,
      statusJobs: statusJobs,
      recurringRevenue: recurringRevenue,
      recurringJobs: recurringJobs,
      oneOffRevenue: oneOffRevenue,
      oneOffJobs: oneOffJobs,
      sourceJobIds: sourceJobIds.toList(),
    );
  }

  /// Return individual daily rollups in [start]..[end] for trend chart use.
  List<DailyRollup> listInRange(DateTime start, DateTime end) {
    final startKey = _dateKey(start);
    final endKey = _dateKey(end);
    final results = <DailyRollup>[];
    for (final key in _rollupsBox.keys) {
      final k = key.toString();
      if (k.compareTo(startKey) < 0 || k.compareTo(endKey) > 0) continue;
      final raw = _rollupsBox.get(k);
      if (raw is! Map) continue;
      results.add(DailyRollup.fromJson(Map<String, dynamic>.from(raw)));
    }
    results.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return results;
  }

  /// Targeted recompute: read ONE date's jobs, parts, expenses and produce
  /// a fresh rollup. Marks the rollup as clean after writing.
  Future<DailyRollup> recomputeDate(String dateKey) async {
    final dt = _parseDateKey(dateKey);
    // Read all jobs for this date (raw maps)
    final dateJobs = <Map<String, dynamic>>[];
    for (final raw in _jobsBox.values) {
      if (raw is! Map) continue;
      final jobDateStr = raw['job_date'] as String?;
      if (jobDateStr == null) continue;
      final jobDt = DateTime.tryParse(jobDateStr);
      if (jobDt == null) continue;
      if (!_isSameDate(jobDt, dt)) continue;
      dateJobs.add(Map<String, dynamic>.from(raw));
    }

    if (dateJobs.isEmpty) {
      // No jobs on this date — write an empty clean rollup so the date
      // is explicitly accounted for (prevents future re-scanning)
      final empty = DailyRollup(dateKey: dateKey, dirty: false);
      await _rollupsBox.put(dateKey, empty.toJson());
      return empty;
    }

    final dateJobIds = dateJobs.map((j) => j['id']!.toString()).toSet();

    // Read parts for these jobs
    final dateParts = <Map<String, dynamic>>[];
    for (final raw in _partsBox.values) {
      if (raw is! Map) continue;
      final jobId = raw['job_id'] as String?;
      if (jobId != null && dateJobIds.contains(jobId)) {
        dateParts.add(Map<String, dynamic>.from(raw));
      }
    }

    // Read expenses for these jobs
    final dateExpenses = <Map<String, dynamic>>[];
    for (final raw in _expensesBox.values) {
      if (raw is! Map) continue;
      final jobId = raw['job_id'] as String?;
      if (jobId != null && dateJobIds.contains(jobId)) {
        dateExpenses.add(Map<String, dynamic>.from(raw));
      }
    }

    // Customer map
    final custMap = <String, Map<String, dynamic>>{};
    for (final raw in _customersBox.values) {
      if (raw is! Map) continue;
      final c = Map<String, dynamic>.from(raw);
      final cid = c['id']?.toString();
      if (cid != null) custMap[cid] = c;
    }

    final rollup = _computeFromRaw(
      dateKey,
      dateJobs,
      dateParts,
      dateExpenses,
      <String, String>{}, // custFirstJobDate — not tracked for targeted recompute
      custMap,
    );

    await _rollupsBox.put(dateKey, rollup.toJson());
    return rollup;
  }

  /// Full seed: scan ALL data once, write rollups for every date with jobs.
  /// Called only when the rollups box is empty.
  Future<void> seedAll() async {
    debugPrint('[KS:ROLLUP] Seeding daily rollups from scratch...');

    // Read all jobs as raw maps
    final allJobs = <Map<String, dynamic>>[];
    for (final raw in _jobsBox.values) {
      if (raw is! Map) continue;
      allJobs.add(Map<String, dynamic>.from(raw));
    }

    if (allJobs.isEmpty) {
      debugPrint('[KS:ROLLUP] No jobs found — skipping seed');
      return;
    }

    // Build customer map
    final custMap = <String, Map<String, dynamic>>{};
    for (final raw in _customersBox.values) {
      if (raw is! Map) continue;
      final c = Map<String, dynamic>.from(raw);
      final cid = c['id']?.toString();
      if (cid != null) custMap[cid] = c;
    }

    // Group non-deleted, non-archived jobs by date
    final jobsByDate = <String, List<Map<String, dynamic>>>{};
    final jobIdsByDate = <String, Set<String>>{};
    for (final j in allJobs) {
      if (j['is_deleted'] == true) continue;
      final dateStr = j['job_date'] as String?;
      if (dateStr == null) continue;
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) continue;
      final key = _dateKey(dt);
      jobsByDate.putIfAbsent(key, () => []).add(j);
      jobIdsByDate.putIfAbsent(key, () => {}).add(j['id']!.toString());
    }

    // Determine first-job date per customer (for newCustomerCount)
    final custFirstJobDate = <String, String>{};
    final sortedDates = jobsByDate.keys.toList()..sort();
    for (final dk in sortedDates) {
      for (final j in jobsByDate[dk]!) {
        final cid = j['customer_id']?.toString();
        if (cid != null && !custFirstJobDate.containsKey(cid)) {
          custFirstJobDate[cid] = dk;
        }
      }
    }

    // Read all parts and expenses once
    final allParts = <Map<String, dynamic>>[];
    for (final raw in _partsBox.values) {
      if (raw is! Map) continue;
      allParts.add(Map<String, dynamic>.from(raw));
    }
    final allExpenses = <Map<String, dynamic>>[];
    for (final raw in _expensesBox.values) {
      if (raw is! Map) continue;
      allExpenses.add(Map<String, dynamic>.from(raw));
    }

    // Process each date
    int count = 0;
    for (final dk in sortedDates) {
      final jobs = jobsByDate[dk]!;
      final jobIds = jobIdsByDate[dk]!;

      final dateParts = allParts
          .where((p) => jobIds.contains(p['job_id']?.toString()))
          .toList();
      final dateExpenses = allExpenses
          .where((e) => jobIds.contains(e['job_id']?.toString()))
          .toList();

      final rollup = _computeFromRaw(dk, jobs, dateParts, dateExpenses,
          custFirstJobDate, custMap);
      await _rollupsBox.put(dk, rollup.toJson());
      count++;
    }

    await _rollupsBox.flush();
    debugPrint('[KS:ROLLUP] Seeded $count daily rollups');
  }

  /// Mark a date as dirty (needs recomputation). Called when a job from
  /// this date is created, edited, archived, or deleted.
  Future<void> markDirty(String dateKey) async {
    final raw = _rollupsBox.get(dateKey);
    if (raw is Map) {
      final r = DailyRollup.fromJson(Map<String, dynamic>.from(raw));
      if (!r.dirty) {
        await _rollupsBox.put(dateKey, r.copyWith(dirty: true).toJson());
        debugPrint('[KS:ROLLUP] Marked $dateKey dirty');
      }
    } else {
      // No rollup yet — create an empty dirty placeholder so the
      // reconciliation hook knows to compute it
      await _rollupsBox.put(dateKey,
          DailyRollup(dateKey: dateKey, dirty: true).toJson());
      debugPrint('[KS:ROLLUP] Created dirty placeholder for $dateKey');
    }
  }

  /// Mark a set of dates as dirty (batch from invalidation WAL).
  Future<void> markDatesDirty(Iterable<String> dateKeys) async {
    for (final dk in dateKeys) {
      await markDirty(dk);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // INTERNALS
  // ────────────────────────────────────────────────────────────────

  DailyRollup _computeFromRaw(
    String dateKey,
    List<Map<String, dynamic>> jobs,
    List<Map<String, dynamic>> parts,
    List<Map<String, dynamic>> expenses,
    Map<String, String> custFirstJobDate,
    Map<String, Map<String, dynamic>> custMap,
  ) {
    final dt = _parseDateKey(dateKey);
    final activeJobs = jobs.where((j) => !(j['is_archived'] == true)).toList();

    final revenue = _sumInt(activeJobs, 'amount_charged');
    final jobCount = activeJobs.length;
    final completedJobCount = activeJobs
        .where((j) => j['status'] == 'completed' || j['status'] == 'invoiced')
        .length;

    var partsCost = 0;
    final stPartsCostMap = <String, int>{};
    final partsUsageMap = <String, int>{};
    for (final p in parts) {
      final qty = p['quantity'] as int? ?? 0;
      final price = (p['unit_price'] as num?)?.toInt() ?? 0;
      final cost = qty * price;
      partsCost += cost;
      final pn = p['part_name'] as String? ?? 'Unknown';
      partsUsageMap[pn] = (partsUsageMap[pn] ?? 0) + qty;
    }

    var expensesCost = 0;
    final expenseCatMap = <String, int>{};
    for (final e in expenses) {
      final amt = (e['amount'] as num?)?.toInt() ?? 0;
      expensesCost += amt;
      final cat = e['category'] as String? ?? 'Other';
      expenseCatMap[cat] = (expenseCatMap[cat] ?? 0) + amt;
    }

    // Allocate parts cost to service type
    for (final p in parts) {
      final job = jobs.where((j) => j['id']!.toString() == p['job_id']).firstOrNull;
      if (job == null) continue;
      final st = job['service_type'] as String? ?? 'unknown';
      final qty = p['quantity'] as int? ?? 0;
      final price = (p['unit_price'] as num?)?.toInt() ?? 0;
      stPartsCostMap[st] = (stPartsCostMap[st] ?? 0) + (qty * price);
    }

    var unpaidAmt = 0, partialAmt = 0, paidAmt = 0;
    var unpaidCnt = 0, partialCnt = 0, paidCnt = 0;
    var uninvoicedValue = 0;
    int newCustCount = 0;
    final stRevMap = <String, int>{};
    final stJobMap = <String, int>{};
    final lsRevMap = <String, int>{};
    final lsJobMap = <String, int>{};
    final custRevMap = <String, int>{};
    final locRevMap = <String, int>{};
    final locJobMap = <String, int>{};
    final ptRevMap = <String, int>{};
    final ptJobMap = <String, int>{};
    final pmRevMap = <String, int>{};
    final pmJobMap = <String, int>{};
    final stRevMap2 = <String, int>{};
    final stJobMap2 = <String, int>{};
    var recurringRev = 0, recurringJobs = 0;
    var oneOffRev = 0, oneOffJobs = 0;
    final sourceIds = <String>[];

    for (final j in activeJobs) {
      final amt = (j['amount_charged'] as num?)?.toInt() ?? 0;
      final st = j['service_type'] as String? ?? 'unknown';
      final ls = (j['lead_source'] as String?) ?? 'other';
      final cid = j['customer_id']?.toString() ?? 'unknown';
      final status = j['status'] as String? ?? 'in_progress';
      final loc = j['location'] as String? ?? 'unknown';

      stRevMap[st] = (stRevMap[st] ?? 0) + amt;
      stJobMap[st] = (stJobMap[st] ?? 0) + 1;
      custRevMap[cid] = (custRevMap[cid] ?? 0) + amt;
      lsRevMap[ls] = (lsRevMap[ls] ?? 0) + amt;
      lsJobMap[ls] = (lsJobMap[ls] ?? 0) + 1;

      // Location breakdown
      locRevMap[loc] = (locRevMap[loc] ?? 0) + amt;
      locJobMap[loc] = (locJobMap[loc] ?? 0) + 1;

      // Property type (from customer map)
      final custData = custMap[cid];
      final pt = custData?['property_type'] as String? ?? 'unknown';
      ptRevMap[pt] = (ptRevMap[pt] ?? 0) + amt;
      ptJobMap[pt] = (ptJobMap[pt] ?? 0) + 1;

      // Payment method
      final pm = j['payment_method'] as String?;
      if (pm != null && pm.isNotEmpty) {
        pmRevMap[pm] = (pmRevMap[pm] ?? 0) + amt;
        pmJobMap[pm] = (pmJobMap[pm] ?? 0) + 1;
      }

      // Job status breakdown
      stRevMap2[status] = (stRevMap2[status] ?? 0) + amt;
      stJobMap2[status] = (stJobMap2[status] ?? 0) + 1;

      // Job origin
      final genFrom = j['generated_from_schedule_id'] as String?;
      if (genFrom != null && genFrom.isNotEmpty) {
        recurringRev += amt;
        recurringJobs++;
      } else {
        oneOffRev += amt;
        oneOffJobs++;
      }

      if (custFirstJobDate[cid] == dateKey) newCustCount++;

      switch (j['payment_status'] as String? ?? 'unpaid') {
        case 'unpaid':   unpaidAmt += amt; unpaidCnt++; break;
        case 'partial':  partialAmt += amt; partialCnt++; break;
        case 'paid':     paidAmt += amt; paidCnt++; break;
      }

      if ((status == 'quoted' || status == 'in_progress') &&
          dt.isBefore(DateTime.now().subtract(const Duration(days: _leakingThresholdDays)))) {
        uninvoicedValue += amt;
      }
      sourceIds.add(j['id']!.toString());
    }

    // Clean local job list for this date

    return DailyRollup(
      dateKey: dateKey,
      schemaVersion: 2,
      dirty: false,
      revenue: revenue,
      partsCost: partsCost,
      expensesCost: expensesCost,
      jobCount: jobCount,
      completedJobCount: completedJobCount,
      uninvoicedValue: uninvoicedValue,
      unpaidAmount: unpaidAmt,
      partialAmount: partialAmt,
      paidAmount: paidAmt,
      unpaidCount: unpaidCnt,
      partialCount: partialCnt,
      paidCount: paidCnt,
      newCustomerCount: newCustCount,
      customerRevenue: custRevMap,
      stRevenue: stRevMap,
      stJobs: stJobMap,
      stPartsCost: stPartsCostMap,
      partsUsage: partsUsageMap,
      expenseCategories: expenseCatMap,
      leadSourceRevenue: lsRevMap,
      leadSourceJobs: lsJobMap,
      locationRevenue: locRevMap,
      locationJobs: locJobMap,
      propertyTypeRevenue: ptRevMap,
      propertyTypeJobs: ptJobMap,
      paymentMethodRevenue: pmRevMap,
      paymentMethodJobs: pmJobMap,
      statusRevenue: stRevMap2,
      statusJobs: stJobMap2,
      recurringRevenue: recurringRev,
      recurringJobs: recurringJobs,
      oneOffRevenue: oneOffRev,
      oneOffJobs: oneOffJobs,
      sourceJobIds: sourceIds,
    );
  }

  static int _sumInt(Iterable<Map<String, dynamic>> items, String field) {
    int sum = 0;
    for (final item in items) {
      final v = item[field];
      // Hive stores some int model fields as double at runtime
      if (v is int) sum += v;
      else if (v is double) sum += v.toInt();
    }
    return sum;
  }

  static void _mergeMap(Map<String, int> target, Map<String, int> source) {
    for (final entry in source.entries) {
      target[entry.key] = (target[entry.key] ?? 0) + entry.value;
    }
  }
}
