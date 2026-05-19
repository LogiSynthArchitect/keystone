import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keystone/core/storage/hive_service.dart';
import 'package:keystone/features/job_logging/data/datasources/job_local_datasource.dart';
import 'package:keystone/features/job_logging/data/datasources/job_parts_local_datasource.dart';
import 'package:keystone/features/job_logging/data/models/job_part_model.dart';
import 'package:keystone/features/job_logging/data/models/job_expense_model.dart';
import 'package:keystone/features/customer_history/data/datasources/customer_local_datasource.dart';
import 'package:keystone/features/inventory/data/models/inventory_item_model.dart';
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
    if (period == AnalyticsPeriod.custom) return;
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

      final allParts  = HiveService.jobParts.values
          .map((e) => JobPartModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final allExpenses = HiveService.jobExpenses.values
          .map((e) => JobExpenseModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // ── Stock value from inventory ──
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

      // ── Compute helpers ──
      (int rev, int jobs, int gp, int np) compute(DateTimeRange targetRange) {
        final periodJobs = jobs.where((j) {
          final d = j.jobDate;
          return !j.isArchived && !j.isDeleted && !d.isBefore(targetRange.start) && !d.isAfter(targetRange.end);
        }).toList();

        final revenue = periodJobs.fold<int>(0, (s, j) => s + (j.amountCharged ?? 0));
        final count   = periodJobs.length;

        final periodJobIds = periodJobs.map((j) => j.id).toSet();
        final partsCost = allParts
            .where((p) => periodJobIds.contains(p.jobId))
            .fold<int>(0, (s, p) => s + (p.quantity ?? 0) * (p.unitPrice ?? 0));
        final expensesCost = allExpenses
            .where((e) => periodJobIds.contains(e.jobId))
            .fold<int>(0, (s, e) => s + e.amount);
        final gp = revenue - partsCost;
        final np = gp - expensesCost;

        return (revenue, count, gp, np);
      }

      // ── Current period ──
      final cur = compute(range);
      final curRev = cur.$1;
      final curJobs = cur.$2;

      // ── Previous period ──
      final duration = range.end.difference(range.start);
      final prevEnd  = range.start.subtract(const Duration(days: 1));
      final prevStart = prevEnd.subtract(duration);
      final prevRange = DateTimeRange(start: prevStart, end: prevEnd);
      final prev = compute(prevRange);
      final prevRev = prev.$1;
      final prevJobs = prev.$2;
      final prevGp = prev.$3;
      final prevNp = prev.$4;

      // ── Previous period breakdown for service type GP trend ──
      final prevPeriodJobs = jobs.where((j) {
        final d = j.jobDate;
        return !j.isArchived && !j.isDeleted && !d.isBefore(prevRange.start) && !d.isAfter(prevRange.end);
      }).toList();
      final prevPeriodJobIds = prevPeriodJobs.map((j) => j.id).toSet();
      final prevPeriodParts = allParts.where((p) => prevPeriodJobIds.contains(p.jobId)).toList();

      final prevStMap = <String, _StAccumulator>{};
      for (final j in prevPeriodJobs) {
        final acc = prevStMap.putIfAbsent(j.serviceType, () => _StAccumulator());
        acc.jobs++;
        acc.revenue += j.amountCharged ?? 0;
      }
      for (final p in prevPeriodParts) {
        final jobModel = prevPeriodJobs.where((j) => j.id == p.jobId).firstOrNull;
        if (jobModel != null) {
          final acc = prevStMap.putIfAbsent(jobModel.serviceType, () => _StAccumulator());
          acc.partsCost += (p.quantity ?? 0) * (p.unitPrice ?? 0);
        }
      }

      // ── Filter for breakdowns ──
      final periodJobs = jobs.where((j) {
        final d = j.jobDate;
        return !j.isArchived && !j.isDeleted && !d.isBefore(range.start) && !d.isAfter(range.end);
      }).toList();
      final periodJobIds = periodJobs.map((j) => j.id).toSet();
      final periodParts  = allParts.where((p) => periodJobIds.contains(p.jobId)).toList();
      final periodExpenses = allExpenses.where((e) => periodJobIds.contains(e.jobId)).toList();

      final totalPartsCost = periodParts.fold<int>(0, (s, p) {
        return s + (p.quantity ?? 0) * (p.unitPrice ?? 0);
      });
      final totalExpensesCost = periodExpenses.fold<int>(0, (s, e) => s + e.amount);
      final grossProfit = curRev - totalPartsCost;
      final netProfit   = grossProfit - totalExpensesCost;

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
      for (final e in periodExpenses) {
        final jobModel = periodJobs.where((j) => j.id == e.jobId).firstOrNull;
        if (jobModel != null) {
          final acc = stMap.putIfAbsent(jobModel.serviceType, () => _StAccumulator());
          acc.expensesCost += e.amount;
        }
      }
      final serviceTypeBreakdown = stMap.entries.map((e) {
        final prev = prevStMap[e.key];
        return ServiceTypeBreakdown(
          serviceType: e.key,
          jobCount: e.value.jobs,
          revenue: e.value.revenue,
          grossProfit: e.value.revenue - e.value.partsCost,
          netProfit: e.value.revenue - e.value.partsCost - e.value.expensesCost,
          previousRevenue: prev?.revenue ?? 0,
          previousJobCount: prev?.jobs ?? 0,
          previousGrossProfit: prev != null ? prev.revenue - prev.partsCost : 0,
        );
      }).toList()
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
        acc.jobCount++;
      }
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
            jobCount: e.value.jobCount,
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

      // -- Expense category breakdown --
      final expenseCatMap = <String, int>{};
      for (final e in periodExpenses) {
        expenseCatMap[e.category] = (expenseCatMap[e.category] ?? 0) + e.amount;
      }
      final expenseCategoryBreakdown = expenseCatMap.entries
          .map((e) => ExpenseCategoryBreakdown(category: e.key, amount: e.value))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));

      // -- New vs repeat customers --
      final customerIds = periodJobs.map((j) => j.customerId).toSet();
      int newCount = 0, repeatCount = 0;
      for (final cid in customerIds) {
        final cust = customerMap[cid];
        if (cust != null) {
          if (cust.totalJobs > 1) {
            repeatCount++;
          } else {
            newCount++;
          }
        }
      }

      // -- Top 5 customers --
      final custRevenueMap = <String, _TopAccumulator>{};
      for (final j in periodJobs) {
        final acc = custRevenueMap.putIfAbsent(j.customerId, () => _TopAccumulator());
        acc.revenue += j.amountCharged ?? 0;
        acc.jobCount++;
      }
      final topCustomers = custRevenueMap.entries
          .map((e) {
            final cust = customerMap[e.key];
            return TopCustomer(
              customerId: e.key,
              customerName: cust?.fullName ?? 'Unknown',
              revenue: e.value.revenue,
              jobCount: e.value.jobCount,
            );
          })
          .toList()
        ..sort((a, b) => b.revenue.compareTo(a.revenue))
        ..take(5).toList();

      // -- Day-of-week breakdown --
      final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dowMap = <int, _DowAccumulator>{};
      for (final j in periodJobs) {
        final wd = j.jobDate.weekday;
        final acc = dowMap.putIfAbsent(wd, () => _DowAccumulator());
        acc.jobCount++;
        acc.revenue += j.amountCharged ?? 0;
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

      // -- Revenue trend (weekly or monthly buckets by period length) --
      final revenueTrend = <RevenueTrendPoint>[];
      if (periodJobs.isNotEmpty) {
        final sorted = [...periodJobs]..sort((a, b) => a.jobDate.compareTo(b.jobDate));
        final periodDays = range.end.difference(range.start).inDays;
        final useMonthly = periodDays > 45;

        if (useMonthly) {
          final monthMap = <String, _TrendAccumulator>{};
          for (final j in sorted) {
            final key = '${j.jobDate.year}-${j.jobDate.month.toString().padLeft(2, '0')}';
            final acc = monthMap.putIfAbsent(key, () => _TrendAccumulator());
            acc.revenue += j.amountCharged ?? 0;
            acc.jobCount++;
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
          final weekStarts = <DateTime>[];
          DateTime? cursor;
          for (final j in sorted) {
            final weekStart = j.jobDate.subtract(Duration(days: j.jobDate.weekday - 1));
            if (cursor == null || !weekStart.isAtSameMomentAs(cursor)) {
              cursor = weekStart;
              weekStarts.add(weekStart);
            }
          }
          for (final ws in weekStarts) {
            final weekEnd = ws.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
            final weekJobs = periodJobs.where((j) => !j.jobDate.isBefore(ws) && !j.jobDate.isAfter(weekEnd)).toList();
            revenueTrend.add(RevenueTrendPoint(
              label: '${ws.day}/${ws.month}',
              revenue: weekJobs.fold<int>(0, (s, j) => s + (j.amountCharged ?? 0)),
              jobCount: weekJobs.length,
            ));
          }
        }
      }

      // -- Derived metrics --
      final avgJobValue = curJobs > 0 ? curRev ~/ curJobs : 0;
      final margin = curRev > 0 ? (grossProfit / curRev * 100) : 0.0;
      final expenseRatio = curRev > 0 ? (totalExpensesCost / curRev * 100) : 0.0;

      final prevAvgJobValue = prevJobs > 0 ? prevRev ~/ prevJobs : 0;

      state = state.copyWith(
        isLoading: false,
        totalRevenue: curRev,
        totalJobs: curJobs,
        grossProfit: grossProfit,
        netProfit: netProfit,
        profitMargin: margin,
        averageJobValue: avgJobValue,
        stockValue: stockValue,
        lowStockCount: lowStockCount,
        totalExpenses: totalExpensesCost,
        expenseToRevenuePercent: expenseRatio,
        newCustomerCount: newCount,
        repeatCustomerCount: repeatCount,
        previousRevenue: prevRev,
        previousJobs: prevJobs,
        previousGrossProfit: prevGp,
        previousNetProfit: prevNp,
        previousAverageJobValue: prevAvgJobValue,
        serviceTypeBreakdown: serviceTypeBreakdown.take(10).toList(),
        paymentHealth: paymentHealth,
        leadSourceBreakdown: leadSourceBreakdown,
        partsUsage: partsUsage.take(10).toList(),
        expenseCategoryBreakdown: expenseCategoryBreakdown,
        topCustomers: topCustomers,
        dayOfWeekBreakdown: dayOfWeekBreakdown,
        revenueTrend: revenueTrend,
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
  int expensesCost = 0;
}

class _LeadAccumulator {
  int revenue = 0;
  int jobCount = 0;
}

class _PartsAccumulator {
  int quantity = 0;
  int cost = 0;
}

class _TopAccumulator {
  int revenue = 0;
  int jobCount = 0;
}

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
