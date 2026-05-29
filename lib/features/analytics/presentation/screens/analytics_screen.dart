import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/models/analytics_models.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: "ANALYTICS", showBack: true),
      body: Column(
        children: [
          _PeriodSelector(state: state),
          Expanded(
            child: state.isLoading
                ? const Center(child: KsLoadingIndicator())
                : state.errorMessage != null
                    ? _ErrorView(message: state.errorMessage!)
                    : _AnalyticsBody(state: state),
          ),
        ],
      ),
    );
  }
}

// -- Period selector --

class _PeriodSelector extends ConsumerWidget {
  final AnalyticsState state;
  const _PeriodSelector({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: context.ksc.primary800,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...AnalyticsPeriod.values
                .where((p) => p != AnalyticsPeriod.custom)
                .map((p) => _PeriodChip(
                      label: p.label,
                      selected: state.period == p,
                      onTap: () => ref.read(analyticsProvider.notifier).setPeriod(p),
                    )),
            _PeriodChip(
              label: 'CUSTOM',
              selected: state.period == AnalyticsPeriod.custom,
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: state.period == AnalyticsPeriod.custom ? state.range : null,
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: ctx.ksc.accent500,
                        onPrimary: ctx.ksc.primary900,
                        surface: ctx.ksc.primary800,
                        onSurface: ctx.ksc.white,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  ref.read(analyticsProvider.notifier).setCustomRange(picked);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? context.ksc.accent500 : context.ksc.primary700,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionMedium.copyWith(
            color: selected ? context.ksc.primary900 : context.ksc.neutral400,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ── Revenue trend chart ────────────────────────────────────────────────────────

class _RevenueTrendChart extends StatelessWidget {
  final List<RevenueTrendPoint> trend;
  const _RevenueTrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxRev = trend.map((t) => t.revenue).reduce((a, b) => a > b ? a : b).toDouble();
    final spots = trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble())).toList();
    final accent = context.ksc.accent500;
    final neutral = context.ksc.neutral500;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REVENUE TREND', style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxRev > 0 ? (maxRev / 4).ceilToDouble().clamp(1, double.infinity) : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: context.ksc.primary700.withValues(alpha: 0.5),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (trend.length > 10 ? (trend.length / 5).ceil() : 1).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(trend[i].label,
                              style: AppTextStyles.caption.copyWith(color: neutral, fontSize: 9)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(CurrencyFormatter.formatShort(value.toInt()),
                              style: AppTextStyles.caption.copyWith(color: neutral, fontSize: 9)),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: maxRev * 1.15,
                clipData: const FlClipData.none(),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: accent,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3,
                        color: accent,
                        strokeWidth: 1.5,
                        strokeColor: context.ksc.primary800,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accent.withValues(alpha: 0.15),
                      cutOffY: 0,
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => context.ksc.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final i = spot.spotIndex;
                        final pt = trend[i];
                        return LineTooltipItem(
                          '${CurrencyFormatter.formatShort(pt.revenue)}\n${pt.jobCount} job${pt.jobCount == 1 ? '' : 's'}',
                          TextStyle(
                            color: context.ksc.primary900,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  final AnalyticsState state;
  const _AnalyticsBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge),
      children: [
        _RevenueTrendChart(trend: state.revenueTrend),
        const SizedBox(height: AppSpacing.xl),
        if (state.uninvoicedValue > 0) ...[
          _LeakingRevenueCard(uninvoiced: state.uninvoicedValue),
          const SizedBox(height: AppSpacing.xl),
        ],
        _SummaryCards(state: state),
        const SizedBox(height: AppSpacing.xxl),
        _CustomerRetentionSection(state: state),
        const SizedBox(height: AppSpacing.xxl),
        _DayOfWeekSection(data: state.dayOfWeekBreakdown),
        const SizedBox(height: AppSpacing.xxl),
        _ServiceTypeSection(breakdown: state.serviceTypeBreakdown),
        const SizedBox(height: AppSpacing.xxl),
        _ExpenseBreakdownSection(expenses: state.expenseCategoryBreakdown),
        const SizedBox(height: AppSpacing.xxl),
        _PaymentHealthSection(health: state.paymentHealth),
        const SizedBox(height: AppSpacing.xxl),
        _LeadSourceSection(breakdown: state.leadSourceBreakdown),
        const SizedBox(height: AppSpacing.xxl),
        _TopCustomersSection(customers: state.topCustomers),
        const SizedBox(height: AppSpacing.xxl),
        _PartsUsageSection(parts: state.partsUsage),
      ],
    );
  }
}

// ── Leaking revenue card ──────────────────────────────────────────────────────

class _LeakingRevenueCard extends StatelessWidget {
  final int uninvoiced;
  const _LeakingRevenueCard({required this.uninvoiced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.ksc.error500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: context.ksc.error500.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LineAwesomeIcons.exclamation_triangle_solid,
                  size: 14, color: context.ksc.error500),
              const SizedBox(width: AppSpacing.xs),
              Text('LEAKING REVENUE',
                  style: AppTextStyles.captionMedium.copyWith(
                      color: context.ksc.error500, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(CurrencyFormatter.format(uninvoiced),
              style: AppTextStyles.h2.copyWith(
                  color: context.ksc.error500, letterSpacing: -0.5)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Jobs stuck in quoted/progress past 7 days',
            style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400),
          ),
        ],
      ),
    );
  }
}

// ── Summary cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final AnalyticsState state;
  const _SummaryCards({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SummaryCard(
          icon: LineAwesomeIcons.coins_solid,
          label: 'TOTAL REVENUE',
          value: CurrencyFormatter.format(state.totalRevenue),
          accent: true,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: LineAwesomeIcons.briefcase_solid,
                label: 'TOTAL JOBS',
                value: '${state.totalJobs}',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SummaryCard(
                icon: LineAwesomeIcons.chart_line_solid,
                label: 'GROSS PROFIT',
                value: CurrencyFormatter.format(state.grossProfit),
                positive: state.grossProfit >= 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool accent;
  final bool? positive;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accent = false,
    this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = positive == null
        ? (accent ? context.ksc.accent500 : context.ksc.white)
        : (positive! ? context.ksc.success500 : context.ksc.error500);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: context.ksc.neutral500),
              const SizedBox(width: AppSpacing.xs),
              Text(label,
                  style: AppTextStyles.captionMedium.copyWith(color: context.ksc.neutral500)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: AppTextStyles.h2.copyWith(color: valueColor, letterSpacing: -0.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral500,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ── Customer retention ────────────────────────────────────────────────────────

class _CustomerRetentionSection extends StatelessWidget {
  final AnalyticsState state;
  const _CustomerRetentionSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final total = state.newCustomerCount + state.repeatCustomerCount;
    if (total == 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('CUSTOMER RETENTION'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NEW', style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('${state.newCustomerCount}', style: AppTextStyles.h2.copyWith(color: context.ksc.accent500)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('REPEAT', style: AppTextStyles.caption.copyWith(color: context.ksc.success500, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text('${state.repeatCustomerCount}', style: AppTextStyles.h2.copyWith(color: context.ksc.success500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Visual bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Flexible(
                        flex: state.newCustomerCount,
                        child: Container(color: context.ksc.accent500),
                      ),
                      if (state.repeatCustomerCount > 0 && state.newCustomerCount > 0)
                        const SizedBox(width: 2),
                      Flexible(
                        flex: state.repeatCustomerCount,
                        child: Container(color: context.ksc.success500),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${total == 0 ? 0 : (state.repeatCustomerCount / total * 100).toStringAsFixed(0)}% repeat rate',
                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Day-of-week breakdown ─────────────────────────────────────────────────────

class _DayOfWeekSection extends StatelessWidget {
  final List<DayOfWeekData> data;
  const _DayOfWeekSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasData = data.any((d) => d.jobCount > 0);
    final maxRev = hasData ? data.map((d) => d.revenue).reduce((a, b) => a > b ? a : b).toDouble() : 1.0;
    final accent = context.ksc.accent500;
    final neutral400 = context.ksc.neutral400;
    final neutral500 = context.ksc.neutral500;
    final primary700 = context.ksc.primary700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('JOBS BY DAY'),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.lg, AppSpacing.sm, AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: !hasData
              ? const _EmptyRow(message: 'No jobs in this period')
              : SizedBox(
                  height: 170,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxRev * 1.25,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => context.ksc.white,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final d = data[group.x.toInt() - 1];
                            return BarTooltipItem(
                              '${CurrencyFormatter.formatShort(d.revenue)}\n${d.jobCount} job${d.jobCount == 1 ? '' : 's'}',
                              TextStyle(color: context.ksc.primary900, fontWeight: FontWeight.w800, fontSize: 11),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt() - 1;
                              if (i < 0 || i >= data.length) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  children: [
                                    Text(data[i].label,
                                        style: AppTextStyles.caption.copyWith(color: neutral500, fontSize: 10, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text('${data[i].jobCount}',
                                        style: AppTextStyles.caption.copyWith(color: neutral400, fontSize: 9)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (maxRev / 4).ceilToDouble().clamp(1, double.infinity),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: primary700.withValues(alpha: 0.5),
                          strokeWidth: 0.5,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.map((d) => BarChartGroupData(
                        x: d.weekday,
                        barRods: [
                          BarChartRodData(
                            toY: d.revenue.toDouble(),
                            color: accent,
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      )).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Expense breakdown ──────────────────────────────────────────────────────────

const _expenseChartColors = [
  Color(0xFFFF6B6B), Color(0xFFFFA94D), Color(0xFFFFD93D),
  Color(0xFF6BCB77), Color(0xFF4D96FF), Color(0xFF9B59B6),
  Color(0xFF1ABC9C), Color(0xFFE74C3C), Color(0xFF3498DB),
];

class _ExpenseBreakdownSection extends StatelessWidget {
  final List<ExpenseCategoryBreakdown> expenses;
  const _ExpenseBreakdownSection({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<int>(0, (sum, e) => sum + e.amount);
    final primary800 = context.ksc.primary800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('EXPENSE BREAKDOWN'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: primary800,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: expenses.isEmpty
              ? const _EmptyRow(message: 'No expenses in this period')
              : Column(
                  children: [
                    // Pie chart
                    SizedBox(
                      height: 160,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 1,
                          centerSpaceRadius: 0,
                          sections: expenses.asMap().entries.map((e) {
                            final i = e.key;
                            final row = e.value;
                            final pct = total > 0 ? (row.amount / total * 100) : 0.0;
                            return PieChartSectionData(
                              value: row.amount.toDouble(),
                              color: _expenseChartColors[i % _expenseChartColors.length],
                              radius: 50,
                              title: '${pct.toStringAsFixed(0)}%',
                              titleStyle: AppTextStyles.captionMedium.copyWith(
                                  color: context.ksc.primary900, fontWeight: FontWeight.w900, fontSize: 11),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Legend rows
                    ...expenses.asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      final pct = total > 0 ? (row.amount / total * 100) : 0.0;
                      return Padding(
                        padding: EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: i < expenses.length - 1 ? AppSpacing.sm : 0,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: _expenseChartColors[i % _expenseChartColors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(row.category.toUpperCase(),
                                  style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white)),
                            ),
                            Text('${(pct).toStringAsFixed(0)}%',
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
                            const SizedBox(width: AppSpacing.md),
                            SizedBox(
                              width: 60,
                              child: Text(
                                CurrencyFormatter.formatShort(row.amount),
                                textAlign: TextAlign.right,
                                style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.error500),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Divider(height: 24, color: context.ksc.primary700),
                    Row(
                      children: [
                        Text('TOTAL', style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Text(CurrencyFormatter.format(total),
                            style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.error500)),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Service type breakdown ────────────────────────────────────────────────────

class _ServiceTypeSection extends StatelessWidget {
  final List<ServiceTypeBreakdown> breakdown;
  const _ServiceTypeSection({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('SERVICE TYPE BREAKDOWN'),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: breakdown.isEmpty
              ? const _EmptyRow(message: 'No jobs in this period')
              : Column(
                  children: breakdown.asMap().entries.map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    return Column(
                      children: [
                        if (i > 0) Divider(height: 1, color: context.ksc.primary700),
                        _ServiceTypeRow(row: row),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _ServiceTypeRow extends StatelessWidget {
  final ServiceTypeBreakdown row;
  const _ServiceTypeRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.serviceType.toUpperCase(),
              style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${row.jobCount} job${row.jobCount == 1 ? '' : 's'}',
              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.formatShort(row.revenue),
                  style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.accent500),
                ),
                Text(
                  'GP: ${CurrencyFormatter.formatShort(row.grossProfit)}',
                  style: AppTextStyles.captionMedium.copyWith(
                    color: row.grossProfit >= 0
                        ? context.ksc.success600
                        : context.ksc.error600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment health ────────────────────────────────────────────────────────────

class _PaymentHealthSection extends StatelessWidget {
  final PaymentHealthData health;
  const _PaymentHealthSection({required this.health});

  @override
  Widget build(BuildContext context) {
    final total = health.unpaidAmount + health.partialAmount + health.paidAmount;
    final primary800 = context.ksc.primary800;

    final sections = [
      _PaymentSectionData('UNPAID', health.unpaidAmount, health.unpaidCount,
          context.ksc.error500, context.ksc.error100),
      _PaymentSectionData('PARTIAL', health.partialAmount, health.partialCount,
          context.ksc.warning600, context.ksc.warning100),
      _PaymentSectionData('PAID', health.paidAmount, health.paidCount,
          context.ksc.success600, context.ksc.success100),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('PAYMENT HEALTH'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: primary800,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: total == 0
              ? const _EmptyRow(message: 'No jobs in this period')
              : Row(
                  children: [
                    // Donut chart
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 32,
                              startDegreeOffset: -90,
                              sections: sections.asMap().entries.map((e) =>
                                PieChartSectionData(
                                  value: e.value.amount.toDouble(),
                                  color: e.value.color,
                                  radius: 40,
                                  showTitle: false,
                                ),
                              ).toList(),
                            ),
                          ),
                          Text(CurrencyFormatter.formatShort(total),
                              style: AppTextStyles.captionMedium.copyWith(
                                  color: context.ksc.white, fontWeight: FontWeight.w900, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // Legend rows
                    Expanded(
                      child: Column(
                        children: sections.asMap().entries.map((e) {
                          final s = e.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: e.key < sections.length - 1 ? AppSpacing.sm : 0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: s.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(s.label,
                                      style: AppTextStyles.captionMedium.copyWith(
                                          color: s.color, fontWeight: FontWeight.w900, fontSize: 10)),
                                ),
                                Text('${s.count} job${s.count == 1 ? '' : 's'}',
                                    style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 9)),
                                const SizedBox(width: AppSpacing.sm),
                                Text(CurrencyFormatter.formatShort(s.amount),
                                    style: AppTextStyles.captionMedium.copyWith(
                                        color: context.ksc.white, fontWeight: FontWeight.w700, fontSize: 10)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        ),
        if (total > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _PaymentBar(health: health, total: total),
        ],
      ],
    );
  }
}

class _PaymentSectionData {
  final String label;
  final int amount;
  final int count;
  final Color color;
  final Color bgColor;
  const _PaymentSectionData(this.label, this.amount, this.count, this.color, this.bgColor);
}

class _PaymentBar extends StatelessWidget {
  final PaymentHealthData health;
  final int total;
  const _PaymentBar({required this.health, required this.total});

  @override
  Widget build(BuildContext context) {
    final unpaidFrac = health.unpaidAmount / total;
    final partialFrac = health.partialAmount / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            if (unpaidFrac > 0)
              Flexible(
                flex: (unpaidFrac * 1000).round(),
                child: Container(color: context.ksc.error500),
              ),
            if (partialFrac > 0)
              Flexible(
                flex: (partialFrac * 1000).round(),
                child: Container(color: context.ksc.warning500),
              ),
            Flexible(
              flex: ((1 - unpaidFrac - partialFrac) * 1000).round().clamp(0, 1000),
              child: Container(color: context.ksc.success500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Lead source breakdown ─────────────────────────────────────────────────────

class _LeadSourceSection extends StatelessWidget {
  final List<LeadSourceBreakdown> breakdown;
  const _LeadSourceSection({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('LEAD SOURCE BREAKDOWN'),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: breakdown.isEmpty
              ? const _EmptyRow(message: 'No lead source data')
              : Column(
                  children: breakdown.asMap().entries.map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    return Column(
                      children: [
                        if (i > 0) Divider(height: 1, color: context.ksc.primary700),
                        _LeadSourceRow(row: row),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _LeadSourceRow extends StatelessWidget {
  final LeadSourceBreakdown row;
  const _LeadSourceRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.source.toUpperCase(),
              style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${row.customerCount} cust.',
              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            CurrencyFormatter.formatShort(row.revenue),
            style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.accent500),
          ),
        ],
      ),
    );
  }
}

// ── Top customers ──────────────────────────────────────────────────────────────

class _TopCustomersSection extends StatelessWidget {
  final List<TopCustomer> customers;
  const _TopCustomersSection({required this.customers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('TOP CUSTOMERS'),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: customers.isEmpty
              ? const _EmptyRow(message: 'No jobs in this period')
              : Column(
                  children: customers.asMap().entries.map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    return Column(
                      children: [
                        if (i > 0) Divider(height: 1, color: context.ksc.primary700),
                        InkWell(
                          onTap: () => context.push(RouteNames.customerDetail(row.customerId)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: context.ksc.primary700,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${i + 1}', style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    row.customerName.toUpperCase(),
                                    style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${row.jobCount} jobs',
                                  style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Text(
                                  CurrencyFormatter.formatShort(row.revenue),
                                  style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

// ── Parts usage ───────────────────────────────────────────────────────────────

class _PartsUsageSection extends StatelessWidget {
  final List<PartsUsage> parts;
  const _PartsUsageSection({required this.parts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('TOP PARTS USAGE'),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: parts.isEmpty
              ? const _EmptyRow(message: 'No parts used in this period')
              : Column(
                  children: parts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final row = entry.value;
                    return Column(
                      children: [
                        if (i > 0) Divider(height: 1, color: context.ksc.primary700),
                        _PartsRow(row: row),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _PartsRow extends StatelessWidget {
  final PartsUsage row;
  const _PartsRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.partName,
              style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'x${row.totalQuantity}',
            style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            CurrencyFormatter.formatShort(row.totalCost),
            style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.neutral300),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LineAwesomeIcons.exclamation_triangle_solid, size: 64, color: context.ksc.error500),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: context.ksc.error500),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              KsButton(
                label: "TAP TO RETRY",
                variant: KsButtonVariant.primary,
                size: KsButtonSize.small,
                fullWidth: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
