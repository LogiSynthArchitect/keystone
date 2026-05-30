import 'package:flutter/material.dart';

enum AnalyticsPeriod { thisMonth, lastMonth, last3Months, custom, allTime }

extension AnalyticsPeriodLabel on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.thisMonth:   return 'THIS MONTH';
      case AnalyticsPeriod.lastMonth:   return 'LAST MONTH';
      case AnalyticsPeriod.last3Months: return 'LAST 3 MONTHS';
      case AnalyticsPeriod.custom:      return 'CUSTOM';
      case AnalyticsPeriod.allTime:     return 'ALL TIME';
    }
  }
}

DateTimeRange defaultRangeFor(AnalyticsPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case AnalyticsPeriod.thisMonth:
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
    case AnalyticsPeriod.lastMonth:
      final last = DateTime(now.year, now.month - 1, 1);
      return DateTimeRange(
        start: last,
        end: DateTime(last.year, last.month + 1, 0, 23, 59, 59),
      );
    case AnalyticsPeriod.last3Months:
      return DateTimeRange(
        start: DateTime(now.year, now.month - 2, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
    case AnalyticsPeriod.custom:
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      );
    case AnalyticsPeriod.allTime:
      return DateTimeRange(
        start: DateTime(2020, 1, 1),
        end: now,
      );
  }
}

class ServiceTypeBreakdown {
  final String serviceType;
  final int jobCount;
  final int revenue;
  final int grossProfit; // revenue - parts cost
  final int netProfit;   // grossProfit - expenses
  final int previousRevenue;
  final int previousJobCount;
  final int previousGrossProfit;

  const ServiceTypeBreakdown({
    required this.serviceType,
    required this.jobCount,
    required this.revenue,
    required this.grossProfit,
    required this.netProfit,
    this.previousRevenue = 0,
    this.previousJobCount = 0,
    this.previousGrossProfit = 0,
  });

  double? get revenueChange {
    if (revenue == 0 && previousRevenue == 0) return null;
    if (previousRevenue == 0) return 100.0;
    return ((revenue - previousRevenue) / previousRevenue * 100);
  }

  double? get gpChange {
    if (grossProfit == 0 && previousGrossProfit == 0) return null;
    if (previousGrossProfit == 0) return 100.0;
    return ((grossProfit - previousGrossProfit) / previousGrossProfit * 100);
  }
}

class PaymentHealthData {
  final int unpaidAmount;
  final int partialAmount;
  final int paidAmount;
  final int unpaidCount;
  final int partialCount;
  final int paidCount;

  const PaymentHealthData({
    this.unpaidAmount = 0,
    this.partialAmount = 0,
    this.paidAmount = 0,
    this.unpaidCount = 0,
    this.partialCount = 0,
    this.paidCount = 0,
  });

  int get totalAmount => unpaidAmount + partialAmount + paidAmount;
  int get totalCount => unpaidCount + partialCount + paidCount;
  double get unpaidPercent => totalAmount > 0 ? (unpaidAmount / totalAmount * 100) : 0;
  double get paidPercent => totalAmount > 0 ? (paidAmount / totalAmount * 100) : 0;
}

class LeadSourceBreakdown {
  final String source;
  final int customerCount;
  final int jobCount;
  final int revenue;

  const LeadSourceBreakdown({
    required this.source,
    required this.customerCount,
    required this.jobCount,
    required this.revenue,
  });
}

class PartsUsage {
  final String partName;
  final int totalQuantity;
  final int totalCost;

  const PartsUsage({
    required this.partName,
    required this.totalQuantity,
    required this.totalCost,
  });
}

class ExpenseCategoryBreakdown {
  final String category;
  final int amount;

  const ExpenseCategoryBreakdown({required this.category, required this.amount});
}

class TopCustomer {
  final String customerId;
  final String customerName;
  final int revenue;
  final int jobCount;

  const TopCustomer({
    required this.customerId,
    required this.customerName,
    required this.revenue,
    required this.jobCount,
  });
}

class DayOfWeekData {
  final int weekday; // 1=Mon, 7=Sun
  final String label;
  final int jobCount;
  final int revenue;

  const DayOfWeekData({
    required this.weekday,
    required this.label,
    required this.jobCount,
    required this.revenue,
  });
}

class RevenueTrendPoint {
  final String label;
  final int revenue;
  final int jobCount;

  const RevenueTrendPoint({
    required this.label,
    required this.revenue,
    required this.jobCount,
  });
}

/// Filter dimensions for analytics.
///
/// All dimensions are AND-logic: only jobs matching ALL non-null filters
/// are included in computed metrics.
/// - null = "All" (no filter)
/// - non-null list = only jobs matching any value in the list (OR within dimension)
class AnalyticsFilters {
  final List<String>? serviceTypes;
  final List<String>? paymentStatuses;
  final List<String>? locations;
  final List<String>? leadSources;
  final List<String>? propertyTypes;
  final List<String>? paymentMethods;
  final List<String>? jobStatuses;
  final bool? onlyRecurring; // null=all, true=recurring, false=one-off
  final List<String>? hardwareBrands;
  final List<String>? hardwareKeyways;

  const AnalyticsFilters({
    this.serviceTypes,
    this.paymentStatuses,
    this.locations,
    this.leadSources,
    this.propertyTypes,
    this.paymentMethods,
    this.jobStatuses,
    this.onlyRecurring,
    this.hardwareBrands,
    this.hardwareKeyways,
  });

  int get activeCount {
    int count = 0;
    if (serviceTypes != null && serviceTypes!.isNotEmpty) count++;
    if (paymentStatuses != null && paymentStatuses!.isNotEmpty) count++;
    if (locations != null && locations!.isNotEmpty) count++;
    if (leadSources != null && leadSources!.isNotEmpty) count++;
    if (propertyTypes != null && propertyTypes!.isNotEmpty) count++;
    if (paymentMethods != null && paymentMethods!.isNotEmpty) count++;
    if (jobStatuses != null && jobStatuses!.isNotEmpty) count++;
    if (onlyRecurring != null) count++;
    if (hardwareBrands != null && hardwareBrands!.isNotEmpty) count++;
    if (hardwareKeyways != null && hardwareKeyways!.isNotEmpty) count++;
    return count;
  }

  bool get isClear => activeCount == 0;

  AnalyticsFilters clear() => const AnalyticsFilters();

  AnalyticsFilters copyWith({
    List<String>? serviceTypes,
    List<String>? paymentStatuses,
    List<String>? locations,
    List<String>? leadSources,
    List<String>? propertyTypes,
    List<String>? paymentMethods,
    List<String>? jobStatuses,
    bool? onlyRecurring,
    bool clearOnlyRecurring = false,
    List<String>? hardwareBrands,
    List<String>? hardwareKeyways,
  }) {
    return AnalyticsFilters(
      serviceTypes: serviceTypes ?? this.serviceTypes,
      paymentStatuses: paymentStatuses ?? this.paymentStatuses,
      locations: locations ?? this.locations,
      leadSources: leadSources ?? this.leadSources,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      jobStatuses: jobStatuses ?? this.jobStatuses,
      onlyRecurring: clearOnlyRecurring ? null : (onlyRecurring ?? this.onlyRecurring),
      hardwareBrands: hardwareBrands ?? this.hardwareBrands,
      hardwareKeyways: hardwareKeyways ?? this.hardwareKeyways,
    );
  }
}

class AnalyticsState {
  final AnalyticsPeriod period;
  final DateTimeRange range;
  final bool isLoading;
  final String? errorMessage;

  // Summary
  final int totalRevenue;
  final int totalJobs;
  final int grossProfit;  // revenue - parts cost
  final int netProfit;    // grossProfit - expenses
  final double profitMargin;
  final int averageJobValue;

  // Stock
  final int stockValue;
  final int lowStockCount;

  // Expense ratio
  final int totalExpenses;
  final double expenseToRevenuePercent;

  // Leaking revenue (jobs stuck in quoted/in_progress > 7 days)
  final int uninvoicedValue;

  // Customer retention
  final int newCustomerCount;
  final int repeatCustomerCount;

  // Previous period (for trend comparison)
  final int previousRevenue;
  final int previousJobs;
  final int previousGrossProfit;
  final int previousNetProfit;
  final int previousAverageJobValue;

  // Breakdowns
  final List<ServiceTypeBreakdown> serviceTypeBreakdown;
  final PaymentHealthData paymentHealth;
  final List<LeadSourceBreakdown> leadSourceBreakdown;
  final List<PartsUsage> partsUsage;
  final List<ExpenseCategoryBreakdown> expenseCategoryBreakdown;
  final List<TopCustomer> topCustomers;
  final List<DayOfWeekData> dayOfWeekBreakdown;
  final List<RevenueTrendPoint> revenueTrend;

  // Filters
  final AnalyticsFilters filters;

  const AnalyticsState({
    this.period = AnalyticsPeriod.thisMonth,
    required this.range,
    this.isLoading = false,
    this.errorMessage,
    this.filters = const AnalyticsFilters(),
    this.totalRevenue = 0,
    this.totalJobs = 0,
    this.grossProfit = 0,
    this.netProfit = 0,
    this.profitMargin = 0,
    this.averageJobValue = 0,
    this.stockValue = 0,
    this.lowStockCount = 0,
    this.totalExpenses = 0,
    this.expenseToRevenuePercent = 0,
    this.uninvoicedValue = 0,
    this.newCustomerCount = 0,
    this.repeatCustomerCount = 0,
    this.previousRevenue = 0,
    this.previousJobs = 0,
    this.previousGrossProfit = 0,
    this.previousNetProfit = 0,
    this.previousAverageJobValue = 0,
    this.serviceTypeBreakdown = const [],
    this.paymentHealth = const PaymentHealthData(),
    this.leadSourceBreakdown = const [],
    this.partsUsage = const [],
    this.expenseCategoryBreakdown = const [],
    this.topCustomers = const [],
    this.dayOfWeekBreakdown = const [],
    this.revenueTrend = const [],
  });

  double _pct(int current, int previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous * 100);
  }

  double? get revenueChange => totalRevenue == 0 && previousRevenue == 0 ? null : _pct(totalRevenue, previousRevenue);
  double? get jobsChange => totalJobs == 0 && previousJobs == 0 ? null : _pct(totalJobs, previousJobs);
  double? get grossProfitChange => grossProfit == 0 && previousGrossProfit == 0 ? null : _pct(grossProfit, previousGrossProfit);
  double? get netProfitChange => netProfit == 0 && previousNetProfit == 0 ? null : _pct(netProfit, previousNetProfit);
  double? get avgJobValueChange => averageJobValue == 0 && previousAverageJobValue == 0 ? null : _pct(averageJobValue, previousAverageJobValue);

  AnalyticsState copyWith({
    AnalyticsPeriod? period,
    DateTimeRange? range,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    int? totalRevenue,
    int? totalJobs,
    int? grossProfit,
    int? netProfit,
    double? profitMargin,
    int? averageJobValue,
    int? stockValue,
    int? lowStockCount,
    int? totalExpenses,
    double? expenseToRevenuePercent,
    int? uninvoicedValue,
    int? newCustomerCount,
    int? repeatCustomerCount,
    int? previousRevenue,
    int? previousJobs,
    int? previousGrossProfit,
    int? previousNetProfit,
    int? previousAverageJobValue,
    List<ServiceTypeBreakdown>? serviceTypeBreakdown,
    PaymentHealthData? paymentHealth,
    List<LeadSourceBreakdown>? leadSourceBreakdown,
    List<PartsUsage>? partsUsage,
    List<ExpenseCategoryBreakdown>? expenseCategoryBreakdown,
    List<TopCustomer>? topCustomers,
    List<DayOfWeekData>? dayOfWeekBreakdown,
    List<RevenueTrendPoint>? revenueTrend,
    AnalyticsFilters? filters,
  }) {
    return AnalyticsState(
      period: period ?? this.period,
      range: range ?? this.range,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalJobs: totalJobs ?? this.totalJobs,
      grossProfit: grossProfit ?? this.grossProfit,
      netProfit: netProfit ?? this.netProfit,
      profitMargin: profitMargin ?? this.profitMargin,
      averageJobValue: averageJobValue ?? this.averageJobValue,
      stockValue: stockValue ?? this.stockValue,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      expenseToRevenuePercent: expenseToRevenuePercent ?? this.expenseToRevenuePercent,
      uninvoicedValue: uninvoicedValue ?? this.uninvoicedValue,
      newCustomerCount: newCustomerCount ?? this.newCustomerCount,
      repeatCustomerCount: repeatCustomerCount ?? this.repeatCustomerCount,
      previousRevenue: previousRevenue ?? this.previousRevenue,
      previousJobs: previousJobs ?? this.previousJobs,
      previousGrossProfit: previousGrossProfit ?? this.previousGrossProfit,
      previousNetProfit: previousNetProfit ?? this.previousNetProfit,
      previousAverageJobValue: previousAverageJobValue ?? this.previousAverageJobValue,
      serviceTypeBreakdown: serviceTypeBreakdown ?? this.serviceTypeBreakdown,
      paymentHealth: paymentHealth ?? this.paymentHealth,
      leadSourceBreakdown: leadSourceBreakdown ?? this.leadSourceBreakdown,
      partsUsage: partsUsage ?? this.partsUsage,
      expenseCategoryBreakdown: expenseCategoryBreakdown ?? this.expenseCategoryBreakdown,
      topCustomers: topCustomers ?? this.topCustomers,
      dayOfWeekBreakdown: dayOfWeekBreakdown ?? this.dayOfWeekBreakdown,
      revenueTrend: revenueTrend ?? this.revenueTrend,
      filters: filters ?? this.filters,
    );
  }
}
