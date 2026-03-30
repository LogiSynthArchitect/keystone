import 'package:flutter/material.dart';

enum AnalyticsPeriod { thisMonth, lastMonth, last3Months, custom }

extension AnalyticsPeriodLabel on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.thisMonth:   return 'THIS MONTH';
      case AnalyticsPeriod.lastMonth:   return 'LAST MONTH';
      case AnalyticsPeriod.last3Months: return 'LAST 3 MONTHS';
      case AnalyticsPeriod.custom:      return 'CUSTOM';
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
  }
}

class ServiceTypeBreakdown {
  final String serviceType;
  final int jobCount;
  final int revenue;      // in pesewas
  final int grossProfit;  // revenue - parts cost (in pesewas)

  const ServiceTypeBreakdown({
    required this.serviceType,
    required this.jobCount,
    required this.revenue,
    required this.grossProfit,
  });
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
}

class LeadSourceBreakdown {
  final String source;
  final int customerCount;
  final int revenue;  // total revenue from jobs for customers with this lead source (in pesewas)

  const LeadSourceBreakdown({
    required this.source,
    required this.customerCount,
    required this.revenue,
  });
}

class PartsUsage {
  final String partName;
  final int totalQuantity;
  final int totalCost;  // in pesewas

  const PartsUsage({
    required this.partName,
    required this.totalQuantity,
    required this.totalCost,
  });
}

class AnalyticsState {
  final AnalyticsPeriod period;
  final DateTimeRange range;
  final bool isLoading;
  final String? errorMessage;

  // Summary
  final int totalRevenue;
  final int totalJobs;
  final int grossProfit;

  // Breakdowns
  final List<ServiceTypeBreakdown> serviceTypeBreakdown;
  final PaymentHealthData paymentHealth;
  final List<LeadSourceBreakdown> leadSourceBreakdown;
  final List<PartsUsage> partsUsage;

  const AnalyticsState({
    this.period = AnalyticsPeriod.thisMonth,
    required this.range,
    this.isLoading = false,
    this.errorMessage,
    this.totalRevenue = 0,
    this.totalJobs = 0,
    this.grossProfit = 0,
    this.serviceTypeBreakdown = const [],
    this.paymentHealth = const PaymentHealthData(),
    this.leadSourceBreakdown = const [],
    this.partsUsage = const [],
  });

  AnalyticsState copyWith({
    AnalyticsPeriod? period,
    DateTimeRange? range,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    int? totalRevenue,
    int? totalJobs,
    int? grossProfit,
    List<ServiceTypeBreakdown>? serviceTypeBreakdown,
    PaymentHealthData? paymentHealth,
    List<LeadSourceBreakdown>? leadSourceBreakdown,
    List<PartsUsage>? partsUsage,
  }) {
    return AnalyticsState(
      period: period ?? this.period,
      range: range ?? this.range,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalJobs: totalJobs ?? this.totalJobs,
      grossProfit: grossProfit ?? this.grossProfit,
      serviceTypeBreakdown: serviceTypeBreakdown ?? this.serviceTypeBreakdown,
      paymentHealth: paymentHealth ?? this.paymentHealth,
      leadSourceBreakdown: leadSourceBreakdown ?? this.leadSourceBreakdown,
      partsUsage: partsUsage ?? this.partsUsage,
    );
  }
}
