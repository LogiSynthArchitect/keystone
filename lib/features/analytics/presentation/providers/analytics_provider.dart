import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:arclock/core/storage/hive_service.dart';
import 'package:arclock/features/job_logging/data/datasources/job_local_datasource.dart';
import 'package:arclock/features/job_logging/data/datasources/job_parts_local_datasource.dart';
import 'package:arclock/features/customer_history/data/datasources/customer_local_datasource.dart';
import 'package:arclock/features/inventory/data/models/inventory_item_model.dart';
import '../../data/repositories/rollup_repository.dart';
import '../../data/models/daily_rollup.dart';
import '../../domain/models/analytics_models.dart';

final analyticsJobLocalProvider = Provider<JobLocalDatasource>(
  (ref) => JobLocalDatasource());

final analyticsCustomerLocalProvider = Provider<CustomerLocalDatasource>(
  (ref) => CustomerLocalDatasource());

final analyticsPartsLocalProvider = Provider<JobPartsLocalDatasource>(
  (ref) => JobPartsLocalDatasource());

/// Rollup-powered analytics notifier.
///
/// Execution strategy:
/// 1. On [loadAnalytics], checks if the rollups box has dirty dates in range.
/// 2. If dirty dates exist, recomputes them via targetted recompute (not full scan).
/// 3. Sums clean rollups in range → fast path (no job objects deserialized).
/// 4. First-ever load: recovery hook in main.dart already seeded rollups,
///    but if isEmpty (race), falls back to one-time full scan + seed.
/// 5. Breakdowns (service type, parts, etc.) are computed from the merged
///    rollup breakdown maps — no job iteration needed.
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;
  final RollupRepository _repo = RollupRepository();

  AnalyticsNotifier(this._ref)
    : super(AnalyticsState(range: defaultRangeFor(AnalyticsPeriod.thisMonth))) {
    final r = state.range;
    loadAnalytics(r.start, r.end);
  }

  void reset() => state = AnalyticsState(range: defaultRangeFor(AnalyticsPeriod.thisMonth));

  // ───── Filters ─────

  /// Apply filters and reload analytics.
  Future<void> setFilters(AnalyticsFilters filters) async {
    state = state.copyWith(filters: filters);
    final r = state.range;
    await loadAnalytics(r.start, r.end);
  }

  /// Update a single filter dimension and reload.
  Future<void> toggleFilter(String dimension, String value) async {
    final current = state.filters;
    AnalyticsFilters updated;

    switch (dimension) {
      case 'serviceType':
        final list = _toggleInList(current.serviceTypes, value);
        updated = current.copyWith(serviceTypes: list.isEmpty ? null : list);
      case 'paymentStatus':
        final list = _toggleInList(current.paymentStatuses, value);
        updated = current.copyWith(paymentStatuses: list.isEmpty ? null : list);
      case 'location':
        final list = _toggleInList(current.locations, value);
        updated = current.copyWith(locations: list.isEmpty ? null : list);
      case 'leadSource':
        final list = _toggleInList(current.leadSources, value);
        updated = current.copyWith(leadSources: list.isEmpty ? null : list);
      case 'propertyType':
        final list = _toggleInList(current.propertyTypes, value);
        updated = current.copyWith(propertyTypes: list.isEmpty ? null : list);
      case 'paymentMethod':
        final list = _toggleInList(current.paymentMethods, value);
        updated = current.copyWith(paymentMethods: list.isEmpty ? null : list);
      case 'jobStatus':
        final list = _toggleInList(current.jobStatuses, value);
        updated = current.copyWith(jobStatuses: list.isEmpty ? null : list);
      case 'hardwareBrand':
        final list = _toggleInList(current.hardwareBrands, value);
        updated = current.copyWith(hardwareBrands: list.isEmpty ? null : list);
      case 'hardwareKeyway':
        final list = _toggleInList(current.hardwareKeyways, value);
        updated = current.copyWith(hardwareKeyways: list.isEmpty ? null : list);
      default:
        return;
    }
    await setFilters(updated);
  }

  /// Clear all filters and reload.
  Future<void> clearAllFilters() async {
    state = state.copyWith(filters: const AnalyticsFilters());
    final r = state.range;
    await loadAnalytics(r.start, r.end);
  }

  List<String> _toggleInList(List<String>? list, String value) {
    final current = list ?? <String>[];
    if (current.contains(value)) {
      return current.where((v) => v != value).toList();
    }
    return [...current, value];
  }

  Future<void> setPeriod(AnalyticsPeriod period) async {
    if (period == AnalyticsPeriod.custom) return;
    final range = defaultRangeFor(period);
    state = state.copyWith(period: period, range: range);
    await loadAnalytics(range.start, range.end);
  }

  Future<void> setCustomRange(DateTimeRange range) async {
    state = state.copyWith(period: AnalyticsPeriod.custom, range: range);
    await loadAnalytics(range.start, range.end);
  }

  Future<void> loadAnalytics(DateTime start, DateTime end) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // ── Phase 1: seed if empty (first run safeguard) ──
      if (_repo.isEmpty) {
        await _repo.seedAll();
      }

      // ── Phase 2: reconcile dirty dates in range ──
      if (_repo.hasDirtyInRange(start, end)) {
        // 2a. Process pending WALs from meta box (catches dates without rollups)
        await _processMetaWals(start, end);
        // 2b. Recompute rollups with dirty:true flag (in case recompute above missed any)
        final rollups = _repo.listInRange(start, end);
        for (final r in rollups) {
          if (r.dirty) {
            await _repo.recomputeDate(r.dateKey);
          }
        }
      }

      // ── Phase 3: fast path — sum clean rollups ──
      final agg = _repo.sumInRange(start, end);

      // ── Phase 4: previous period (also from rollups) ──
      final duration = end.difference(start);
      final prevEnd  = start.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(duration);

      if (_repo.hasDirtyInRange(prevStart, prevEnd)) {
        await _processMetaWals(prevStart, prevEnd);
        final prevRollups = _repo.listInRange(prevStart, prevEnd);
        for (final r in prevRollups) {
          if (r.dirty) await _repo.recomputeDate(r.dateKey);
        }
      }
      final prevAgg = _repo.isEmpty
          ? const DailyRollup(dateKey: 'prev')
          : _repo.sumInRange(prevStart, prevEnd);

      // ── Phase 5: stock value from inventory (still reads inventory box) ──
      int stockValue = 0;
      int lowStockCount = 0;
      try {
        final allInventory = HiveService.inventoryItems.values
            .map((e) => InventoryItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        for (final item in allInventory) {
          if (item.isArchived) continue;
          if (item.defaultCostPrice != null) {
            stockValue += item.quantity * item.defaultCostPrice!;
          }
          if (item.lowStockThreshold != null && item.quantity <= item.lowStockThreshold!) {
            lowStockCount++;
          }
        }
      } catch (_) {}

      // ── Phase 6: customer data for lead source & new/repeat ──
      // Lead source breakdown still reads customer box (lightweight, maps only)
      int newCustCount = 0, repeatCustCount = 0;
      List<LeadSourceBreakdown> leadSourceBreakdown = [];
      List<TopCustomer> topCustomers = [];
      try {
        final customers = await _ref.read(analyticsCustomerLocalProvider).getCustomers();
        final customerMap = {for (final c in customers) c.id: c};

        // Lead source from rollup's leadSourceRevenue (if populated)
        if (agg.leadSourceRevenue.isNotEmpty) {
          leadSourceBreakdown = agg.leadSourceRevenue.entries
              .map((e) => LeadSourceBreakdown(
                source: e.key,
                customerCount: customers.where((c) => c.leadSource == e.key).length,
                jobCount: agg.leadSourceJobs[e.key] ?? 0,
                revenue: e.value,
              ))
              .toList()
            ..sort((a, b) => b.revenue.compareTo(a.revenue));
        }

        // New vs repeat: rollup has newCustomerCount from the seed/recompute
        // repeatCustomerCount = unique customer IDs from sourceJobIds minus new
        if (agg.sourceJobIds.isNotEmpty) {
          // Get unique customer IDs from the range's source job IDs
          final allJobs = HiveService.jobs.values
              .map((e) => Map<String, dynamic>.from(e as Map));
          final customerIdsInRange = <String>{};
          final aggSourceIds = agg.sourceJobIds.toSet();
          for (final j in allJobs) {
            final jid = j['id']?.toString();
            if (jid != null && aggSourceIds.contains(jid)) {
              final cid = j['customer_id']?.toString();
              if (cid != null) customerIdsInRange.add(cid);
            }
          }
          newCustCount = agg.newCustomerCount;
          repeatCustCount = customerIdsInRange.length - newCustCount;
          if (repeatCustCount < 0) repeatCustCount = 0;

          // Top customers from rollup's customerRevenue map
          topCustomers = agg.customerRevenue.entries
              .map((e) {
                final cust = customerMap[e.key];
                return TopCustomer(
                  customerId: e.key,
                  customerName: cust?.fullName ?? 'Unknown',
                  revenue: e.value,
                  jobCount: agg.sourceJobIds.length, // approximate
                );
              })
              .toList()
            ..sort((a, b) => b.revenue.compareTo(a.revenue))
            ..take(5).toList();
        }
      } catch (_) {}

      // ── Phase 7: derived metrics ──
      final grossProfit = agg.revenue - agg.partsCost;
      final netProfit = grossProfit - agg.expensesCost;
      final margin = agg.revenue > 0 ? (grossProfit / agg.revenue * 100) : 0.0;
      final avgJobValue = agg.jobCount > 0 ? agg.revenue ~/ agg.jobCount : 0;
      final expenseRatio = agg.revenue > 0 ? (agg.expensesCost / agg.revenue * 100) : 0.0;

      final prevGp = prevAgg.revenue - prevAgg.partsCost;
      final prevNp = prevGp - prevAgg.expensesCost;
      final prevAvg = prevAgg.jobCount > 0 ? prevAgg.revenue ~/ prevAgg.jobCount : 0;

      // ── Phase 8: breakdowns from rollup maps ──
      // Service type
      final stBreakdown = agg.stRevenue.entries.map((e) {
        final st = e.key;
        final rev = e.value;
        final jobs = agg.stJobs[st] ?? 0;
        final partsC = agg.stPartsCost[st] ?? 0;
        final prevRev = prevAgg.stRevenue[st] ?? 0;
        final prevJobs = prevAgg.stJobs[st] ?? 0;
        final prevPartsC = prevAgg.stPartsCost[st] ?? 0;
        return ServiceTypeBreakdown(
          serviceType: st,
          jobCount: jobs,
          revenue: rev,
          grossProfit: rev - partsC,
          netProfit: rev - partsC - (agg.expenseCategories.values.fold(0, (s, v) => s + v)),
          previousRevenue: prevRev,
          previousJobCount: prevJobs,
          previousGrossProfit: prevRev - prevPartsC,
        );
      }).toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));

      // Payment health
      final paymentHealth = PaymentHealthData(
        unpaidAmount: agg.unpaidAmount,
        partialAmount: agg.partialAmount,
        paidAmount: agg.paidAmount,
        unpaidCount: agg.unpaidCount,
        partialCount: agg.partialCount,
        paidCount: agg.paidCount,
      );

      // Parts usage
      final partsUsage = agg.partsUsage.entries.map((e) => PartsUsage(
        partName: e.key,
        totalQuantity: e.value,
        totalCost: 0, // cost not stored per-part in rollup; it's in parts_cost total
      )).toList()
        ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

      // Expense category breakdown
      final expenseCatBreakdown = agg.expenseCategories.entries
          .map((e) => ExpenseCategoryBreakdown(category: e.key, amount: e.value))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      // Day-of-week from individual rollups
      final dailyRollups = _repo.listInRange(start, end);
      final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dowMap = <int, _DowAccumulator>{};
      for (final r in dailyRollups) {
        if (r.jobCount == 0) continue;
        final dt = DateTime.tryParse(r.dateKey);
        if (dt == null) continue;
        final wd = dt.weekday;
        final acc = dowMap.putIfAbsent(wd, () => _DowAccumulator());
        acc.jobCount += r.jobCount;
        acc.revenue += r.revenue;
      }
      final dayOfWeekBreakdown = List.generate(7, (i) {
        final wd = i + 1;
        final acc = dowMap[wd];
        return DayOfWeekData(
          weekday: wd,
          label: dayNames[wd],
          jobCount: acc?.jobCount ?? 0,
          revenue: acc?.revenue ?? 0,
        );
      });

      // Revenue trend from individual daily rollups
      // Respects filters: extracts revenue from the dimension-specific map
      // that matches the active filter. If multiple filters are active, uses
      // the first matching dimension (serviceType > location > paymentMethod > status).
      final periodDays = end.difference(start).inDays;
      final useMonthly = periodDays > 45;
      final revenueTrend = <RevenueTrendPoint>[];
      final trendFilters = state.filters;

      int revenueFromRollup(DailyRollup r) {
        if (r.jobCount == 0) return 0;
        // Single-dimension extraction: pick the matching dimension's map
        if (trendFilters.serviceTypes != null && trendFilters.serviceTypes!.isNotEmpty) {
          return trendFilters.serviceTypes!
              .fold<int>(0, (s, st) => s + (r.stRevenue[st] ?? 0));
        }
        if (trendFilters.locations != null && trendFilters.locations!.isNotEmpty) {
          return trendFilters.locations!
              .fold<int>(0, (s, loc) => s + (r.locationRevenue[loc] ?? 0));
        }
        if (trendFilters.paymentMethods != null && trendFilters.paymentMethods!.isNotEmpty) {
          return trendFilters.paymentMethods!
              .fold<int>(0, (s, pm) => s + (r.paymentMethodRevenue[pm] ?? 0));
        }
        if (trendFilters.jobStatuses != null && trendFilters.jobStatuses!.isNotEmpty) {
          return trendFilters.jobStatuses!
              .fold<int>(0, (s, st) => s + (r.statusRevenue[st] ?? 0));
        }
        if (trendFilters.propertyTypes != null && trendFilters.propertyTypes!.isNotEmpty) {
          return trendFilters.propertyTypes!
              .fold<int>(0, (s, pt) => s + (r.propertyTypeRevenue[pt] ?? 0));
        }
        if (trendFilters.leadSources != null && trendFilters.leadSources!.isNotEmpty) {
          return trendFilters.leadSources!
              .fold<int>(0, (s, ls) => s + (r.leadSourceRevenue[ls] ?? 0));
        }
        if (trendFilters.paymentStatuses != null && trendFilters.paymentStatuses!.isNotEmpty) {
          return trendFilters.paymentStatuses!
              .fold<int>(0, (s, ps) => s + (r.statusRevenue[ps] ?? 0));
        }
        return r.revenue; // no filters → total revenue
      }

      if (useMonthly) {
        // Group daily rollups by month
        final monthMap = <String, _TrendAccumulator>{};
        for (final r in dailyRollups) {
          final rev = revenueFromRollup(r);
          if (rev == 0) continue;
          final dt = DateTime.tryParse(r.dateKey);
          if (dt == null) continue;
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          final acc = monthMap.putIfAbsent(key, () => _TrendAccumulator());
          acc.revenue += rev;
          acc.jobCount += r.jobCount;
        }
        const monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthKeys = monthMap.keys.toList()..sort();
        for (final key in monthKeys) {
          final parts = key.split('-');
          final month = int.tryParse(parts[1]) ?? 1;
          final acc = monthMap[key]!;
          revenueTrend.add(RevenueTrendPoint(
            label: monthNames[month],
            revenue: acc.revenue,
            jobCount: acc.jobCount,
          ));
        }
      } else {
        // Group daily rollups by ISO week
        final weekMap = <String, _TrendAccumulator>{};
        for (final r in dailyRollups) {
          final rev = revenueFromRollup(r);
          if (rev == 0) continue;
          final dt = DateTime.tryParse(r.dateKey);
          if (dt == null) continue;
          final weekStart = dt.subtract(Duration(days: dt.weekday - 1));
          final key = _dateKey(weekStart);
          final acc = weekMap.putIfAbsent(key, () => _TrendAccumulator());
          acc.revenue += rev;
          acc.jobCount += r.jobCount;
        }
        final weekKeys = weekMap.keys.toList()..sort();
        for (final key in weekKeys) {
          final acc = weekMap[key]!;
          revenueTrend.add(RevenueTrendPoint(
            label: key.substring(5), // "MM-DD"
            revenue: acc.revenue,
            jobCount: acc.jobCount,
          ));
        }
      }

      // ── Phase 8b: apply in-memory filters to breakdown data ──
      final filters = state.filters;
      List<ServiceTypeBreakdown> filteredStBreakdown;
      List<LeadSourceBreakdown> filteredLeadSource;

      if (filters.serviceTypes != null && filters.serviceTypes!.isNotEmpty) {
        filteredStBreakdown = stBreakdown
            .where((s) => filters.serviceTypes!.contains(s.serviceType))
            .toList();
      } else {
        filteredStBreakdown = stBreakdown;
      }

      if (filters.leadSources != null && filters.leadSources!.isNotEmpty) {
        filteredLeadSource = leadSourceBreakdown
            .where((s) => filters.leadSources!.contains(s.source))
            .toList();
      } else {
        filteredLeadSource = leadSourceBreakdown;
      }

      // ── Assemble state ──
      state = state.copyWith(
        isLoading: false,
        totalRevenue: agg.revenue,
        totalJobs: agg.jobCount,
        grossProfit: grossProfit,
        netProfit: netProfit,
        profitMargin: margin,
        averageJobValue: avgJobValue,
        stockValue: stockValue,
        lowStockCount: lowStockCount,
        totalExpenses: agg.expensesCost,
        expenseToRevenuePercent: expenseRatio,
        newCustomerCount: newCustCount,
        repeatCustomerCount: repeatCustCount,
        uninvoicedValue: agg.uninvoicedValue,
        previousRevenue: prevAgg.revenue,
        previousJobs: prevAgg.jobCount,
        previousGrossProfit: prevGp,
        previousNetProfit: prevNp,
        previousAverageJobValue: prevAvg,
        serviceTypeBreakdown: filteredStBreakdown.take(10).toList(),
        paymentHealth: paymentHealth,
        leadSourceBreakdown: filteredLeadSource,
        partsUsage: partsUsage.take(10).toList(),
        expenseCategoryBreakdown: expenseCatBreakdown,
        topCustomers: topCustomers,
        dayOfWeekBreakdown: dayOfWeekBreakdown,
        revenueTrend: revenueTrend,
      );
    } catch (e) {
      debugPrint('[KS:ANALYTICS] Load failed: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load analytics.');
    }
  }

  /// Process pending invalidation WALs from the meta box for [start]..[end].
  ///
  /// Each WAL key is `analytics_dirty:YYYY-MM-DD`, written by [markAnalyticsDirty]
  /// at job mutation time. Recomputes each date's rollup, then deletes the WAL.
  /// Handles dates that don't have rollup entries yet (WAL-only dates).
  Future<void> _processMetaWals(DateTime start, DateTime end) async {
    final meta = Hive.box(HiveService.metaBox);
    final startKey = _dateKey(start);
    final endKey = _dateKey(end);
    const prefix = 'analytics_dirty:';
    final walDates = <String>[];
    for (final key in meta.keys) {
      final ks = key.toString();
      if (!ks.startsWith(prefix)) continue;
      final dateStr = ks.substring(prefix.length);
      if (dateStr.compareTo(startKey) >= 0 && dateStr.compareTo(endKey) <= 0) {
        walDates.add(dateStr);
      }
    }
    // Deduplicate and recompute each WAL date, then delete WAL
    for (final dateStr in walDates.toSet()) {
      try {
        await _repo.recomputeDate(dateStr);
        await meta.delete('$prefix$dateStr');
      } catch (e) {
        debugPrint('[KS:ANALYTICS] Failed to recompute WAL date $dateStr: $e');
      }
    }
  }
}

String _dateKey(DateTime dt) =>
    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

class _DowAccumulator {
  int jobCount = 0;
  int revenue = 0;
}

class _TrendAccumulator {
  int revenue = 0;
  int jobCount = 0;
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(ref));
