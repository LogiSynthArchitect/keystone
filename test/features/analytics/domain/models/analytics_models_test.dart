import 'package:flutter_test/flutter_test.dart';
import 'package:keystone/features/analytics/domain/models/analytics_models.dart';

void main() {
  group('AnalyticsState gross profit', () {
    test('grossProfit equals revenue minus parts cost', () {
      // Job charged 5000 pesewas; 3 parts costing 1000 + 500 + 250 = 1750
      const revenue = 5000;
      const partsCost = 1750;
      const expected = revenue - partsCost;

      final state = AnalyticsState(
        range: defaultRangeFor(AnalyticsPeriod.thisMonth),
        totalRevenue: revenue,
        grossProfit: revenue - partsCost,
      );

      expect(state.grossProfit, equals(expected));
    });

    test('grossProfit can be negative when parts cost exceeds revenue', () {
      final state = AnalyticsState(
        range: defaultRangeFor(AnalyticsPeriod.thisMonth),
        totalRevenue: 1000,
        grossProfit: 1000 - 2000,
      );

      expect(state.grossProfit, equals(-1000));
    });

    test('grossProfit is zero when no jobs', () {
      final state = AnalyticsState(
        range: defaultRangeFor(AnalyticsPeriod.thisMonth),
      );

      expect(state.grossProfit, equals(0));
      expect(state.totalRevenue, equals(0));
    });
  });

  group('defaultRangeFor', () {
    test('thisMonth range starts at day 1 of current month', () {
      final range = defaultRangeFor(AnalyticsPeriod.thisMonth);
      final now = DateTime.now();
      expect(range.start.year, equals(now.year));
      expect(range.start.month, equals(now.month));
      expect(range.start.day, equals(1));
    });

    test('lastMonth range covers exactly one month', () {
      final range = defaultRangeFor(AnalyticsPeriod.lastMonth);
      expect(range.start.day, equals(1));
      // end must be in the same month as start
      expect(range.end.month, equals(range.start.month));
    });

    test('last3Months range starts 2 months before current month', () {
      final range = defaultRangeFor(AnalyticsPeriod.last3Months);
      final now = DateTime.now();
      final expectedStartMonth = now.month - 2 <= 0
          ? now.month - 2 + 12
          : now.month - 2;
      expect(range.start.month, equals(expectedStartMonth));
    });
  });

  group('ServiceTypeBreakdown', () {
    test('grossProfit stored correctly', () {
      const breakdown = ServiceTypeBreakdown(
        serviceType: 'car_lock',
        jobCount: 3,
        revenue: 15000,
        grossProfit: 12000,
      );

      expect(breakdown.grossProfit, equals(12000));
      expect(breakdown.revenue - breakdown.grossProfit, equals(3000)); // parts cost
    });
  });

  group('PaymentHealthData', () {
    test('defaults to all zeros', () {
      const health = PaymentHealthData();
      expect(health.unpaidAmount, equals(0));
      expect(health.partialAmount, equals(0));
      expect(health.paidAmount, equals(0));
      expect(health.unpaidCount, equals(0));
      expect(health.partialCount, equals(0));
      expect(health.paidCount, equals(0));
    });

    test('stores amounts correctly', () {
      const health = PaymentHealthData(
        unpaidAmount: 5000,
        partialAmount: 2000,
        paidAmount: 10000,
        unpaidCount: 2,
        partialCount: 1,
        paidCount: 4,
      );

      expect(health.unpaidAmount + health.partialAmount + health.paidAmount, equals(17000));
      expect(health.unpaidCount + health.partialCount + health.paidCount, equals(7));
    });
  });
}
