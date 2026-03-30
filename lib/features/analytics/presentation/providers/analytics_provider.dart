import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/job_logging/data/datasources/job_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_parts_local_datasource.dart';
import 'package:keystone/features/job_logging/data/models/job_part_model.dart';
import 'package:keystone/features/customer_history/data/datasources/customer_local_datasource.dart';
import '../../domain/models/analytics_models.dart';

final analyticsJobLocalProvider = Provider<JobLocalDatasource>(
  (ref) => JobLocalDatasource());

final analyticsCustomerLocalProvider = Provider<CustomerLocalDatasource>(
  (ref) => CustomerLocalDatasource());

final analyticsPartsLocalProvider = Provider<JobPartsLocalDatasource>(
  (ref) => JobPartsLocalDatasource());

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;
  AnalyticsNotifier(this._ref)
    : super(AnalyticsState(range: defaultRangeFor(AnalyticsPeriod.thisMonth))) {
    loadAnalytics(state.range);
  }

  void reset() => state = AnalyticsState(range: defaultRangeFor(AnalyticsPeriod.thisMonth));

  Future<void> setPeriod(AnalyticsPeriod period) async {
    if (period == AnalyticsPeriod.custom) return; // custom handled by setCustomRange
    final range = defaultRangeFor(period);
    state = state.copyWith(period: period, range: range);
    await loadAnalytics(range);
  }

  Future<void> setCustomRange(DateTimeRange range) async {
    state = state.copyWith(period: AnalyticsPeriod.custom, range: range);
    await loadAnalytics(range);
  }

  Future<void> loadAnalytics(DateTimeRange range) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final jobs      = await _ref.read(analyticsJobLocalProvider).getJobs();
      final customers = await _ref.read(analyticsCustomerLocalProvider).getCustomers();

      // All parts from Hive — more efficient than per-job queries
      final allParts  = HiveService.jobParts.values
          .map((e) => JobPartModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // Filter jobs to the selected period (non-archived, non-deleted)
      final periodJobs = jobs.where((j) {
        final d = j.jobDate;
        return !j.isArchived && !j.isDeleted &&
               !d.isBefore(range.start) &&
               !d.isAfter(range.end);
      }).toList();

      // -- Summary --
      final totalRevenue = periodJobs.fold<int>(0, (s, j) => s + (j.amountCharged ?? 0));
      final totalJobs    = periodJobs.length;

      // Parts cost indexed by jobId for period jobs
      final periodJobIds = periodJobs.map((j) => j.id).toSet();
      final periodParts  = allParts.where((p) => periodJobIds.contains(p.jobId)).toList();
      final totalPartsCost = periodParts.fold<int>(0, (s, p) {
        final qty = p.quantity ?? 0;
        final price = p.unitPrice ?? 0;
        return s + qty * price;
      });
      final grossProfit = totalRevenue - totalPartsCost;

      // -- Service type breakdown --
      final stMap = <String, _StAccumulator>{};
      for (final j in periodJobs) {
        final acc = stMap.putIfAbsent(j.serviceType, () => _StAccumulator());
        acc.jobs++;
        acc.revenue += j.amountCharged ?? 0;
      }
      for (final p in periodParts) {
        final jobModel = periodJobs.where((j) => j.id == p.jobId).firstOrNull;
        if (jobModel != null) {
          final acc = stMap.putIfAbsent(jobModel.serviceType, () => _StAccumulator());
          acc.partsCost += (p.quantity ?? 0) * (p.unitPrice ?? 0);
        }
      }
      final serviceTypeBreakdown = stMap.entries.map((e) => ServiceTypeBreakdown(
        serviceType: e.key,
        jobCount: e.value.jobs,
        revenue: e.value.revenue,
        grossProfit: e.value.revenue - e.value.partsCost,
      )).toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));

      // -- Payment health --
      var unpaidAmt = 0, partialAmt = 0, paidAmt = 0;
      var unpaidCnt = 0, partialCnt = 0, paidCnt = 0;
      for (final j in periodJobs) {
        final amt = j.amountCharged ?? 0;
        switch (j.paymentStatus) {
          case 'unpaid':   unpaidAmt  += amt; unpaidCnt++;  break;
          case 'partial':  partialAmt += amt; partialCnt++; break;
          case 'paid':     paidAmt    += amt; paidCnt++;    break;
        }
      }
      final paymentHealth = PaymentHealthData(
        unpaidAmount: unpaidAmt, partialAmount: partialAmt, paidAmount: paidAmt,
        unpaidCount: unpaidCnt, partialCount: partialCnt, paidCount: paidCnt,
      );

      // -- Lead source breakdown --
      final customerMap = {for (final c in customers) c.id: c};
      final sourceMap = <String, _LeadAccumulator>{};
      for (final j in periodJobs) {
        final customer = customerMap[j.customerId];
        final source = customer?.leadSource ?? 'other';
        final acc = sourceMap.putIfAbsent(source, () => _LeadAccumulator());
        acc.revenue += j.amountCharged ?? 0;
      }
      // Count unique customers by lead source
      final customerLeadCount = <String, Set<String>>{};
      for (final c in customers) {
        if (c.leadSource != null) {
          customerLeadCount.putIfAbsent(c.leadSource!, () => {}).add(c.id);
        }
      }
      final leadSourceBreakdown = sourceMap.entries
          .where((e) => e.value.revenue > 0 || (customerLeadCount[e.key]?.isNotEmpty ?? false))
          .map((e) => LeadSourceBreakdown(
            source: e.key,
            customerCount: customerLeadCount[e.key]?.length ?? 0,
            revenue: e.value.revenue,
          )).toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue));

      // -- Parts usage --
      final partsMap = <String, _PartsAccumulator>{};
      for (final p in periodParts) {
        final acc = partsMap.putIfAbsent(p.partName, () => _PartsAccumulator());
        acc.quantity += p.quantity ?? 0;
        acc.cost     += (p.quantity ?? 0) * (p.unitPrice ?? 0);
      }
      final partsUsage = partsMap.entries.map((e) => PartsUsage(
        partName: e.key,
        totalQuantity: e.value.quantity,
        totalCost: e.value.cost,
      )).toList()
        ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

      state = state.copyWith(
        isLoading: false,
        totalRevenue: totalRevenue,
        totalJobs: totalJobs,
        grossProfit: grossProfit,
        serviceTypeBreakdown: serviceTypeBreakdown.take(10).toList(),
        paymentHealth: paymentHealth,
        leadSourceBreakdown: leadSourceBreakdown,
        partsUsage: partsUsage.take(10).toList(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Could not load analytics.');
    }
  }
}

class _StAccumulator {
  int jobs = 0;
  int revenue = 0;
  int partsCost = 0;
}

class _LeadAccumulator {
  int revenue = 0;
}

class _PartsAccumulator {
  int quantity = 0;
  int cost = 0;
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>(
  (ref) => AnalyticsNotifier(ref));
