import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_button.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';
import '../../../../core/widgets/ks_filter_sheet.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/router/route_names.dart';
import '../../domain/models/analytics_models.dart';
import '../../data/models/daily_rollup.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: KsAppBar(
        title: "ANALYTICS",
        showBack: true,
        actions: [
          _FilterIconButton(state: state, ref: ref),
        ],
      ),
      body: state.isLoading
          ? const Center(child: KsLoadingIndicator())
          : state.errorMessage != null
              ? _ErrorView(message: state.errorMessage!)
              : _AnalyticsBody(state: state),
    );
  }
}

// ── Filter icon with badge ──────────────────────────────────────────────────────

class _FilterIconButton extends ConsumerWidget {
  final AnalyticsState state;
  final WidgetRef ref;
  const _FilterIconButton({required this.state, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = state.filters.activeCount;
    return GestureDetector(
      onTap: () => _showFilterSheet(context, ref, state),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              LineAwesomeIcons.filter_solid,
              size: 18,
              color: activeCount > 0
                  ? context.ksc.accent500
                  : context.ksc.neutral500,
            ),
            if (activeCount > 0)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: context.ksc.accent500,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$activeCount',
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.primary900,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter sheet ────────────────────────────────────────────────────────────────

void _showFilterSheet(BuildContext context, WidgetRef ref, AnalyticsState state) {
  final notifier = ref.read(analyticsProvider.notifier);
  final filters = state.filters;

  // ── Draft state (single-select per dimension) ──
  var draftServiceType = filters.serviceTypes?.firstOrNull;
  var draftPaymentStatus = filters.paymentStatuses?.firstOrNull;
  var draftJobStatus = filters.jobStatuses?.firstOrNull;
  var draftLocation = filters.locations?.firstOrNull;
  var draftLeadSource = filters.leadSources?.firstOrNull;
  var draftPropertyType = filters.propertyTypes?.firstOrNull;
  var draftPaymentMethod = filters.paymentMethods?.firstOrNull;

  int draftActive() => [
    draftServiceType, draftPaymentStatus, draftJobStatus,
    draftLocation, draftLeadSource, draftPropertyType, draftPaymentMethod,
  ].where((v) => v != null).length;

  // Build option chips from available data
  final agg = AggData._fromState(state);
  final serviceTypeOptions = agg.serviceTypes.entries.map((e) => KsFilterOption(
    value: e.key,
    display: e.key.toUpperCase(),
    count: e.value,
    icon: null,
  )).toList();

  final locationOptions = agg.locations.entries.map((e) => KsFilterOption(
    value: e.key,
    display: e.key.toUpperCase(),
    count: e.value,
  )).toList();

  final leadSourceOptions = agg.leadSources.entries.map((e) => KsFilterOption(
    value: e.key,
    display: e.key.replaceAll('_', ' ').toUpperCase(),
    count: e.value,
  )).toList();

  final propertyTypeOptions = [
    const KsFilterOption(value: 'residential', display: 'RESIDENTIAL'),
    const KsFilterOption(value: 'commercial', display: 'COMMERCIAL'),
    const KsFilterOption(value: 'automotive', display: 'AUTOMOTIVE'),
  ];

  final paymentMethodOptions = [
    const KsFilterOption(value: 'cash', display: 'CASH'),
    const KsFilterOption(value: 'mobile_money', display: 'MOBILE MONEY'),
    const KsFilterOption(value: 'bank_transfer', display: 'BANK TRANSFER'),
  ];

  final jobStatusOptions = [
    const KsFilterOption(value: 'quoted', display: 'QUOTED'),
    const KsFilterOption(value: 'in_progress', display: 'IN PROGRESS'),
    const KsFilterOption(value: 'completed', display: 'COMPLETED'),
    const KsFilterOption(value: 'invoiced', display: 'INVOICED'),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.ksc.primary800,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setInnerState) => KsFilterSheet(
        title: 'FILTER ANALYTICS',
        onApply: () {
          notifier.setFilters(AnalyticsFilters(
            serviceTypes: draftServiceType != null ? [draftServiceType!] : null,
            paymentStatuses: draftPaymentStatus != null ? [draftPaymentStatus!] : null,
            jobStatuses: draftJobStatus != null ? [draftJobStatus!] : null,
            locations: draftLocation != null ? [draftLocation!] : null,
            leadSources: draftLeadSource != null ? [draftLeadSource!] : null,
            propertyTypes: draftPropertyType != null ? [draftPropertyType!] : null,
            paymentMethods: draftPaymentMethod != null ? [draftPaymentMethod!] : null,
          ));
        },
        onClear: () {
          draftServiceType = null;
          draftPaymentStatus = null;
          draftJobStatus = null;
          draftLocation = null;
          draftLeadSource = null;
          draftPropertyType = null;
          draftPaymentMethod = null;
          setInnerState(() {});
        },
        activeLabel: draftActive() > 0 ? '${draftActive()} active' : null,
        totalCount: draftActive() > 0 ? draftActive() : null,
        heightFraction: 0.85,
        children: [
          // TIME PERIOD — fixed top
          _FilterSection(
            label: 'TIME PERIOD',
            child: Row(children: [
              _PeriodChipInline(
                label: 'ALL TIME',
                selected: state.period == AnalyticsPeriod.allTime,
                onTap: () {
                  notifier.setPeriod(AnalyticsPeriod.allTime);
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(width: 8),
              _PeriodChipInline(
                label: 'CUSTOM',
                selected: state.period == AnalyticsPeriod.custom,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: state.period == AnalyticsPeriod.custom ? state.range : null,
                    builder: (ctx2, child) => Theme(
                      data: Theme.of(ctx2).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: ctx2.ksc.accent500,
                          onPrimary: ctx2.ksc.primary900,
                          surface: ctx2.ksc.primary800,
                          onSurface: ctx2.ksc.white,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    notifier.setCustomRange(picked);
                  }
                },
              ),
            ]),
          ),

          // SERVICE TYPE
          if (serviceTypeOptions.isNotEmpty)
            KsFilterChipGroup(
              label: 'SERVICE TYPE',
              options: serviceTypeOptions,
              selected: draftServiceType,
              onSelect: (v) => setInnerState(() {
                draftServiceType = (draftServiceType == v) ? null : v;
              }),
            ),

          // PAYMENT STATUS
          KsFilterChipGroup(
            label: 'PAYMENT STATUS',
            options: [
              const KsFilterOption(value: 'paid', display: 'PAID'),
              const KsFilterOption(value: 'unpaid', display: 'UNPAID'),
              const KsFilterOption(value: 'partial', display: 'PARTIAL'),
            ],
            selected: draftPaymentStatus,
            onSelect: (v) => setInnerState(() {
              draftPaymentStatus = (draftPaymentStatus == v) ? null : v;
            }),
          ),

          // JOB STATUS
          KsFilterChipGroup(
            label: 'JOB STATUS',
            options: jobStatusOptions,
            selected: draftJobStatus,
            onSelect: (v) => setInnerState(() {
              draftJobStatus = (draftJobStatus == v) ? null : v;
            }),
          ),

          // LOCATION
          if (locationOptions.isNotEmpty)
            KsFilterChipGroup(
              label: 'LOCATION',
              options: locationOptions,
              selected: draftLocation,
              onSelect: (v) => setInnerState(() {
                draftLocation = (draftLocation == v) ? null : v;
              }),
            ),

          // LEAD SOURCE
          if (leadSourceOptions.isNotEmpty)
            KsFilterChipGroup(
              label: 'LEAD SOURCE',
              options: leadSourceOptions,
              selected: draftLeadSource,
              onSelect: (v) => setInnerState(() {
                draftLeadSource = (draftLeadSource == v) ? null : v;
              }),
            ),

          // PROPERTY TYPE
          KsFilterChipGroup(
            label: 'PROPERTY TYPE',
            options: propertyTypeOptions,
            selected: draftPropertyType,
            onSelect: (v) => setInnerState(() {
              draftPropertyType = (draftPropertyType == v) ? null : v;
            }),
          ),

          // PAYMENT METHOD
          KsFilterChipGroup(
            label: 'PAYMENT METHOD',
            options: paymentMethodOptions,
            selected: draftPaymentMethod,
            onSelect: (v) => setInnerState(() {
              draftPaymentMethod = (draftPaymentMethod == v) ? null : v;
            }),
          ),
        ],
      ),
    ),
  );
}

/// Inline period chip for the filter sheet's time section.
class _PeriodChipInline extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PeriodChipInline({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? context.ksc.accent500 : context.ksc.primary700,
          borderRadius: BorderRadius.circular(20),
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

/// Helper to extract breakdown data from state for filter option generation.
class AggData {
  final Map<String, int> serviceTypes;
  final Map<String, int> locations;
  final Map<String, int> locationJobs;
  final Map<String, int> leadSources;

  AggData._({
    required this.serviceTypes,
    required this.locations,
    required this.locationJobs,
    required this.leadSources,
  });

  static AggData _fromState(AnalyticsState state) {
    final st = <String, int>{};
    for (final b in state.serviceTypeBreakdown) {
      st[b.serviceType] = b.jobCount;
    }
    final loc = <String, int>{};
    final locJobs = <String, int>{};
    final ls = <String, int>{};
    try {
      final rollupsBox = Hive.box(HiveService.analyticsDailyRollupsBox);
      for (final key in rollupsBox.keys) {
        final raw = rollupsBox.get(key.toString());
        if (raw is! Map) continue;
        final r = DailyRollup.fromJson(Map<String, dynamic>.from(raw));
        for (final e in r.locationRevenue.entries) {
          loc[e.key] = (loc[e.key] ?? 0) + e.value;
        }
        for (final e in r.locationJobs.entries) {
          locJobs[e.key] = (locJobs[e.key] ?? 0) + e.value;
        }
        for (final e in r.leadSourceRevenue.entries) {
          ls[e.key] = (ls[e.key] ?? 0) + e.value;
        }
        for (final e in r.leadSourceJobs.entries) {
          if (!ls.containsKey(e.key)) {
            ls[e.key] = 0;
          }
        }
      }
    } catch (_) {}
    return AggData._(serviceTypes: st, locations: loc, locationJobs: locJobs, leadSources: ls);
  }
}

/// Simple labeled section wrapper for filter sheet.
class _FilterSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FilterSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: context.ksc.neutral500,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.0)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// ── Period selector (unused — handled in filter drawer) ──

// ── Revenue trend chart ────────────────────────────────────────────────────────

class _RevenueTrendChart extends StatelessWidget {
  final List<RevenueTrendPoint> trend;
  const _RevenueTrendChart({required this.trend});

  /// Convert "05-25" → "May 25", keep "Jan"/"Feb" as-is.
  String _prettyLabel(String label) {
    if (label.length == 5 && label.contains('-')) {
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final parts = label.split('-');
      final m = int.tryParse(parts[0]) ?? 0;
      if (m >= 1 && m <= 12) return '${months[m]} ${parts[1]}';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxRev = trend.map((t) => t.revenue).reduce((a, b) => a > b ? a : b).toDouble();
    final spots = trend.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue.toDouble())).toList();
    final accent = context.ksc.accent500;
    final neutral = context.ksc.neutral500;
    final primary700 = context.ksc.primary700;

    // Show every, every 2nd, or every 3rd label based on data density
    final labelInterval = trend.length > 16 ? 3 : (trend.length > 8 ? 2 : 1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.ksc.primary800,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Text('REVENUE TREND', style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.md),

          // ── Chart ──
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxRev > 0 ? (maxRev / 4).ceilToDouble().clamp(1, double.infinity) : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: primary700.withValues(alpha: 0.5),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: labelInterval.toDouble(),
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_prettyLabel(trend[i].label),
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
                          '${_prettyLabel(pt.label)}\n${CurrencyFormatter.formatShort(pt.revenue)}\n${pt.jobCount} job${pt.jobCount == 1 ? '' : 's'}',
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

          // ── Legend ──
          const SizedBox(height: 6),
          Row(
            children: [
              Container(width: 16, height: 2, color: accent),
              const SizedBox(width: 6),
              Text('Revenue', style: AppTextStyles.caption.copyWith(color: neutral, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _AnalyticsBody extends ConsumerStatefulWidget {
  final AnalyticsState state;
  const _AnalyticsBody({required this.state});

  @override
  ConsumerState<_AnalyticsBody> createState() => _AnalyticsBodyState();
}

class _AnalyticsBodyState extends ConsumerState<_AnalyticsBody> {
  bool _showMore = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final theme = context.ksc;
    final neutral500 = theme.neutral500;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge),
      children: [
        // ── Unified hero card (revenue + 3 metrics in one container) ──
        _HeroCard(
          revenue: s.totalRevenue,
          revenueChange: s.revenueChange,
          jobs: s.totalJobs,
          jobsChange: s.jobsChange,
          profit: s.grossProfit,
          profitChange: s.grossProfitChange,
          margin: s.profitMargin,
          filterCount: s.filters.activeCount,
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Revenue trend ──
        _RevenueTrendChart(trend: s.revenueTrend),
        const SizedBox(height: AppSpacing.xl),

        // ── Service type breakdown with mini bars ──
        if (s.serviceTypeBreakdown.isNotEmpty) ...[
          _SectionHeader('SERVICE TYPE BREAKDOWN'),
          _ServiceTypeBreakdownBars(breakdown: s.serviceTypeBreakdown),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── Payment health + Leaking revenue ──
        _SectionHeader('PAYMENT HEALTH'),
        _PaymentHealthCompact(health: s.paymentHealth),
        const SizedBox(height: AppSpacing.sm),
        if (s.uninvoicedValue > 0)
          _LeakingRevenueBanner(uninvoiced: s.uninvoicedValue)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(color: theme.success500.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSpacing.radiusSm), border: Border.all(color: theme.success500.withValues(alpha: 0.2))),
            child: Row(children: [
              const Icon(Icons.check_circle, size: 14, color: Color(0xFF4ADE80)),
              const SizedBox(width: 8),
              Text('No overdue jobs', style: AppTextStyles.caption.copyWith(color: const Color(0xFF4ADE80), fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('All jobs paid', style: AppTextStyles.caption.copyWith(color: neutral500, fontSize: 9)),
            ]),
          ),
        const SizedBox(height: AppSpacing.xl),

        // ── Location breakdown ──
        if (s.serviceTypeBreakdown.isNotEmpty) ...[
          _SectionHeader('LOCATION BREAKDOWN'),
          _LocationBreakdown(state: s),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── Show more / Show less ──
        GestureDetector(
          onTap: () => setState(() => _showMore = !_showMore),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.primary700))),
            child: Row(
              children: [
                Text(_showMore ? '▲ SHOW LESS' : '▼ SHOW MORE STATS',
                    style: AppTextStyles.caption.copyWith(color: neutral500, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 10)),
                const Spacer(),
              ],
            ),
          ),
        ),

        if (_showMore) ...[
          const SizedBox(height: AppSpacing.lg),
          _DayOfWeekSection(data: s.dayOfWeekBreakdown),
          const SizedBox(height: AppSpacing.xxl),
          _ExpenseBreakdownSection(expenses: s.expenseCategoryBreakdown),
          const SizedBox(height: AppSpacing.xxl),
          _LeadSourceSection(breakdown: s.leadSourceBreakdown),
          const SizedBox(height: AppSpacing.xxl),
          _TopCustomersSection(customers: s.topCustomers),
          const SizedBox(height: AppSpacing.xxl),
          _PartsUsageSection(parts: s.partsUsage),
        ],
      ],
    );
  }
}

Widget _vertDivider(KsColors c) {
  return Container(width: 1, height: 32, color: c.primary700);
}

/// Unified hero card — revenue + Jobs/Profit/Margin metrics in one container.
class _HeroCard extends StatelessWidget {
  final int revenue;
  final double? revenueChange;
  final int jobs;
  final double? jobsChange;
  final int profit;
  final double? profitChange;
  final double margin;
  final int filterCount;

  const _HeroCard({
    required this.revenue,
    this.revenueChange,
    required this.jobs,
    this.jobsChange,
    required this.profit,
    this.profitChange,
    required this.margin,
    required this.filterCount,
  });

  String _marginStatus() {
    if (margin >= 50) return 'Good';
    if (margin >= 25) return 'OK';
    return 'Low';
  }

  Color _marginColor(KsColors c) {
    if (margin >= 50) return c.success500;
    if (margin >= 25) return c.accent500;
    return c.error500;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ksc;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = c.accent500;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isLight ? c.primary800 : null,
        gradient: isLight ? null : LinearGradient(colors: [accent.withValues(alpha: 0.12), c.primary800], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: isLight ? c.neutral200 : accent.withValues(alpha: 0.2)),
        boxShadow: isLight ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))] : null,
      ),
      child: Column(
        children: [
          // ── Top: label + value + change badge ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL REVENUE',
                        style: AppTextStyles.caption.copyWith(color: c.neutral500, letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(CurrencyFormatter.format(revenue),
                        style: AppTextStyles.h1.copyWith(color: isLight ? c.white : accent, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -0.5)),
                  ],
                ),
              ),
              if (revenueChange != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLight ? c.accent100 : accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isLight ? c.accent500 : accent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '↑ ${revenueChange!.toStringAsFixed(0)}%',
                    style: AppTextStyles.caption.copyWith(color: isLight ? c.accent600 : accent, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
            ],
          ),

          // ── Gradient divider ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(height: 1, decoration: BoxDecoration(
              gradient: LinearGradient(colors: isLight
                ? [c.white.withValues(alpha: 0.3), c.neutral300, c.white.withValues(alpha: 0)]
                : [accent.withValues(alpha: 0.25), c.primary800, accent.withValues(alpha: 0)]),
            )),
          ),

          // ── Metrics row: Jobs | Profit | Margin ──
          Row(
            children: [
              _MetricCell(value: '$jobs', label: 'JOBS',
                trend: jobsChange != null ? TrendData(change: jobsChange!, positive: (jobsChange ?? 0) >= 0) : null,
                isLight: isLight),
              _vertDivider(c),
              _MetricCell(value: CurrencyFormatter.formatShort(profit), label: 'PROFIT',
                trend: profitChange != null ? TrendData(change: profitChange!, positive: (profitChange ?? 0) >= 0) : null,
                isLight: isLight),
              _vertDivider(c),
              _MetricCell(value: '${margin.toStringAsFixed(0)}%', label: 'MARGIN',
                statusText: _marginStatus(),
                statusColor: _marginColor(c),
                isLight: isLight),
            ],
          ),

          // ── Filter hint ──
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '◈ $filterCount filter${filterCount == 1 ? '' : 's'} active',
                style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One metric cell inside the hero card (e.g. Jobs, Profit, or Margin).
class _MetricCell extends StatelessWidget {
  final String value;
  final String label;
  final TrendData? trend;
  final String? statusText;
  final Color? statusColor;
  final bool isLight;

  const _MetricCell({
    required this.value,
    required this.label,
    this.trend,
    this.statusText,
    this.statusColor,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ksc;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.h2.copyWith(
              color: isLight ? c.neutral900 : c.white,
              fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(color: c.neutral500, letterSpacing: 1, fontWeight: FontWeight.w700, fontSize: 7)),
            const SizedBox(height: 4),
            if (statusText != null && statusColor != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(statusText!, style: AppTextStyles.caption.copyWith(color: statusColor!, fontWeight: FontWeight.w700, fontSize: 9)),
                ],
              )
            else if (trend != null)
              Text(
                '${trend!.positive ? '↑' : '↓'} ${trend!.change.toStringAsFixed(0)}%',
                style: AppTextStyles.caption.copyWith(
                  color: trend!.positive ? c.success500 : c.error500,
                  fontWeight: FontWeight.w700,
                  fontSize: 8,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TrendData {
  final double change;
  final bool positive;
  const TrendData({required this.change, required this.positive});
}

/// Service type breakdown with mini bars and margin badges.
class _ServiceTypeBreakdownBars extends StatelessWidget {
  final List<ServiceTypeBreakdown> breakdown;
  const _ServiceTypeBreakdownBars({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();
    final c = context.ksc;
    final sorted = List<ServiceTypeBreakdown>.from(breakdown)..sort((a, b) => b.revenue.compareTo(a.revenue));
    final totalRevenue = sorted.fold<int>(0, (s, e) => s + e.revenue);
    final show = sorted.take(6).toList();
    final othersRevenue = sorted.length > 6 ? sorted.skip(6).fold<int>(0, (s, e) => s + e.revenue) : 0;
    final othersJobs = sorted.length > 6 ? sorted.skip(6).fold<int>(0, (s, e) => s + e.jobCount) : 0;
    final maxRev = show.first.revenue.toDouble();

    return Container(
      decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Total row ──
          Row(
            children: [
              Text('Total ', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
              Text(CurrencyFormatter.formatShort(totalRevenue), style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11)),
              const Spacer(),
              Text('${sorted.length} type${sorted.length == 1 ? '' : 's'}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 8)),
            ],
          ),
          const SizedBox(height: 12),
          // ── Bars ──
          ...show.asMap().entries.map((entry) {
            final i = entry.key;
            final b = entry.value;
            final frac = maxRev > 0 ? b.revenue / maxRev : 0.0;
            final marginPct = b.revenue > 0 ? (b.grossProfit / b.revenue * 100) : 0.0;
            final barColor = marginPct >= 50 ? c.success500 : (marginPct >= 25 ? c.warning500 : c.error500);

            return Padding(
              padding: EdgeInsets.only(top: i > 0 ? 10 : 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Text(b.serviceType.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w700, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 8,
                        color: c.primary700,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: frac,
                          child: Container(color: barColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(CurrencyFormatter.formatShort(b.revenue),
                      style: AppTextStyles.caption.copyWith(color: c.accent500, fontWeight: FontWeight.w800, fontSize: 11)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${marginPct.toStringAsFixed(0)}%',
                        style: AppTextStyles.caption.copyWith(color: barColor, fontWeight: FontWeight.w800, fontSize: 9)),
                  ),
                ],
              ),
            );
          }),
          // ── Others rollup ──
          if (sorted.length > 6) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(width: 76, child: Text('Others (${sorted.length - 6})', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 10))),
                const SizedBox(width: 8),
                Expanded(child: Container()),
                const SizedBox(width: 10),
                Text(othersRevenue > 0 ? CurrencyFormatter.formatShort(othersRevenue) : '',
                    style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 10)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Payment health: stacked progress bar + compact legend rows.
class _PaymentHealthCompact extends StatelessWidget {
  final PaymentHealthData health;
  const _PaymentHealthCompact({required this.health});

  @override
  Widget build(BuildContext context) {
    final total = health.totalAmount;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(color: context.ksc.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        child: Text('No jobs in this period', style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600)),
      );
    }
    final c = context.ksc;
    final sections = [
      _Psd('Paid', health.paidAmount, health.paidCount, c.success500),
      _Psd('Partial', health.partialAmount, health.partialCount, c.warning500),
      _Psd('Unpaid', health.unpaidAmount, health.unpaidCount, c.error500),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stacked progress bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: sections.where((s) => s.amount > 0).map((s) {
                  return Expanded(
                    flex: s.amount,
                    child: Container(color: s.color),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Total label ──
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Total ', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
              Text(CurrencyFormatter.format(total), style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 10)),
              const Spacer(),
              Text('${sections[0].amount > 0 ? (sections[0].amount / total * 100).toStringAsFixed(0) : '0'}% collected',
                  style: AppTextStyles.caption.copyWith(color: c.success500, fontWeight: FontWeight.w700, fontSize: 8)),
            ],
          ),

          // ── Divider ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(height: 1, color: c.primary700.withValues(alpha: 0.5)),
          ),

          // ── Legend rows ──
          ...sections.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                SizedBox(
                  width: 52,
                  child: Text(s.label, style: AppTextStyles.caption.copyWith(color: s.color, fontWeight: FontWeight.w800, fontSize: 10)),
                ),
                Expanded(
                  child: Text(CurrencyFormatter.formatShort(s.amount),
                    style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11)),
                ),
                SizedBox(
                  width: 34,
                  child: Text('${total > 0 ? (s.amount / total * 100).toStringAsFixed(0) : '0'}%',
                    style: AppTextStyles.caption.copyWith(color: s.color, fontWeight: FontWeight.w700, fontSize: 10),
                    textAlign: TextAlign.right),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text('${s.count}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 10), textAlign: TextAlign.right),
                ),
                const SizedBox(width: 4),
                Text('job${s.count == 1 ? '' : 's'}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 8)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _Psd {
  final String label; final int amount; final int count; final Color color;
  const _Psd(this.label, this.amount, this.count, this.color);
}

/// Slim leaking revenue banner.
class _LeakingRevenueBanner extends StatelessWidget {
  final int uninvoiced;
  const _LeakingRevenueBanner({required this.uninvoiced});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: context.ksc.error500.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusSm), border: Border.all(color: context.ksc.error500.withValues(alpha: 0.25))),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFF56565)),
        const SizedBox(width: 8),
        Text(CurrencyFormatter.format(uninvoiced), style: AppTextStyles.h2.copyWith(color: const Color(0xFFF56565), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
        const SizedBox(width: 8),
        Expanded(child: Text('overdue · stuck in quoted/progress', style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 8))),
      ]),
    );
  }
}

/// Location breakdown: horizontal bars with revenue + % + jobs.
class _LocationBreakdown extends StatelessWidget {
  final AnalyticsState state;
  const _LocationBreakdown({required this.state});

  @override
  Widget build(BuildContext context) {
    final agg = AggData._fromState(state);
    final locs = agg.locations.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (locs.isEmpty) return const SizedBox.shrink();

    final c = context.ksc;
    final maxVal = locs.first.value.toDouble();
    final totalRevenue = locs.fold<int>(0, (s, e) => s + e.value);

    // Palette for location bars
    const barColors = [
      Color(0xFF4ADE80), Color(0xFF60A5FA), Color(0xFFF59E0B),
      Color(0xFFA78BFA), Color(0xFFF472B6), Color(0xFF34D399),
      Color(0xFFFB923C), Color(0xFF818CF8),
    ];

    // Top 6 + Others rollup
    final show = locs.take(6).toList();
    final othersRevenue = locs.length > 6 ? locs.skip(6).fold<int>(0, (s, e) => s + e.value) : 0;
    final othersJobs = locs.length > 6 ? locs.skip(6).fold<int>(0, (s, e) => s + (agg.locationJobs[e.key] ?? 0)) : 0;

    return Container(
      decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Total row ──
          Row(
            children: [
              Text('Total ', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
              Text(CurrencyFormatter.formatShort(totalRevenue), style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11)),
              const Spacer(),
              Text('${locs.length} area${locs.length == 1 ? '' : 's'}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 8)),
            ],
          ),
          const SizedBox(height: 10),

          // ── Bars ──
          ...show.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final fraction = maxVal > 0 ? e.value / maxVal : 0.0;
            final pct = totalRevenue > 0 ? (e.value / totalRevenue * 100).toStringAsFixed(0) : '0';
            final jobs = agg.locationJobs[e.key] ?? 0;
            final color = barColors[i % barColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label row
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.key.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w700, fontSize: 10),
                          overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(width: 38, child: Text('$pct%', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.right)),
                      const SizedBox(width: 6),
                      SizedBox(width: 54, child: Text(CurrencyFormatter.formatShort(e.value), style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11), textAlign: TextAlign.right)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 8,
                      color: c.primary700,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fraction,
                        child: Container(color: color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Others rollup ──
          if (locs.length > 6) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: c.neutral600, borderRadius: BorderRadius.circular(1))),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Others (${locs.length - 6})', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 9)),
                ),
                SizedBox(width: 38, child: Text('', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.right)),
                const SizedBox(width: 6),
                SizedBox(width: 54, child: Text(othersRevenue > 0 ? CurrencyFormatter.formatShort(othersRevenue) : '', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 10), textAlign: TextAlign.right)),
              ],
            ),
          ],
        ],
      ),
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
          icon3d: '49654f-trophy.png',
          label: 'TOTAL REVENUE',
          value: CurrencyFormatter.format(state.totalRevenue),
          accent: true,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon3d: 'ff5be0-tools.png',
                label: 'TOTAL JOBS',
                value: '${state.totalJobs}',
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SummaryCard(
                icon3d: '4a4275-chart.png',
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
  final String icon3d;
  final String label;
  final String value;
  final bool accent;
  final bool? positive;

  const _SummaryCard({
    required this.icon3d,
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
              Image.asset('assets/icons/3d/transparent/$icon3d',
                  width: 20, height: 20,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
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
    final c = context.ksc;
    final hasData = data.any((d) => d.jobCount > 0);
    if (!hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('JOBS BY DAY'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            child: const _EmptyRow(message: 'No jobs in this period'),
          ),
        ],
      );
    }

    // Sorted Mon-Sun (natural order)
    final days = List<DayOfWeekData>.from(data)..sort((a, b) => a.weekday.compareTo(b.weekday));
    final maxRev = days.map((d) => d.revenue).reduce((a, b) => a > b ? a : b).toDouble();
    final totalJobs = days.fold<int>(0, (s, d) => s + d.jobCount);

    // Day-of-week bar palette: blue gradient (weekday) → amber (weekend)
    const dayColors = [
      Color(0xFF60A5FA), Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF6366F1),
      Color(0xFF8B5CF6), Color(0xFFF59E0B), Color(0xFFF97316),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('JOBS BY DAY'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          child: Column(
            children: [
              // ── Total row ──
              Row(
                children: [
                  Text('Week total ', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
                  Text(CurrencyFormatter.formatShort(days.fold<int>(0, (s, d) => s + d.revenue)),
                    style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  const Spacer(),
                  Text('$totalJobs jobs', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 8)),
                ],
              ),
              const SizedBox(height: 12),

              // ── 7 day bars ──
              ...days.map((d) {
                final i = d.weekday - 1;
                final fraction = maxRev > 0 ? d.revenue / maxRev : 0.0;
                final barColor = dayColors[i.clamp(0, dayColors.length - 1)];
                final isWeekend = d.weekday >= 6;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      // Day label
                      SizedBox(
                        width: 36,
                        child: Text(d.label,
                          style: AppTextStyles.caption.copyWith(
                            color: isWeekend ? c.warning500 : c.white,
                            fontWeight: FontWeight.w800, fontSize: 10)),
                      ),
                      const SizedBox(width: 8),

                      // Bar
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 8,
                            color: c.primary700,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: fraction,
                              child: Container(color: barColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Revenue
                      SizedBox(
                        width: 50,
                        child: Text(CurrencyFormatter.formatShort(d.revenue),
                          style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w700, fontSize: 10),
                          textAlign: TextAlign.right),
                      ),
                      const SizedBox(width: 8),

                      // Job count
                      SizedBox(
                        width: 18,
                        child: Text('${d.jobCount}',
                          style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 10),
                          textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }),
            ],
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

/// Expense breakdown: horizontal bars sorted descending.
class _ExpenseBreakdownSection extends StatelessWidget {
  final List<ExpenseCategoryBreakdown> expenses;
  const _ExpenseBreakdownSection({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final c = context.ksc;
    if (expenses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('EXPENSE BREAKDOWN'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            child: const _EmptyRow(message: 'No expenses in this period'),
          ),
        ],
      );
    }

    // Sort descending by amount
    final sorted = List<ExpenseCategoryBreakdown>.from(expenses)..sort((a, b) => b.amount.compareTo(a.amount));
    final total = sorted.fold<int>(0, (s, e) => s + e.amount);
    final show = sorted.take(6).toList();
    final maxAmt = show.first.amount.toDouble();
    final othersAmount = sorted.length > 6 ? sorted.skip(6).fold<int>(0, (s, e) => s + e.amount) : 0;
    const barColors = [Color(0xFFF87171), Color(0xFFFB923C), Color(0xFFFBBF24), Color(0xFFA78BFA), Color(0xFF60A5FA), Color(0xFF34D399)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('EXPENSE BREAKDOWN'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          child: Column(
            children: [
              // ── Total row ──
              Row(
                children: [
                  Text('Total ', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
                  Text(CurrencyFormatter.formatShort(total), style: AppTextStyles.caption.copyWith(color: c.error500, fontWeight: FontWeight.w800, fontSize: 11)),
                  const Spacer(),
                  Text('${sorted.length} categor${sorted.length == 1 ? 'y' : 'ies'}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 8)),
                ],
              ),
              const SizedBox(height: 12),

              // ── Bars ──
              ...show.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final fraction = maxAmt > 0 ? row.amount / maxAmt : 0.0;
                final pct = total > 0 ? (row.amount / total * 100) : 0.0;
                final pctLabel = pct.toStringAsFixed(0);
                final color = barColors[i % barColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
                    const SizedBox(width: 6),
                    SizedBox(width: 66, child: Text(row.category, style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w600, fontSize: 10), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 4),
                    SizedBox(width: 28, child: Text('$pctLabel%', style: AppTextStyles.caption.copyWith(color: c.neutral400, fontWeight: FontWeight.w600, fontSize: 9), textAlign: TextAlign.right)),
                    const SizedBox(width: 4),
                    Expanded(child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(height: 10, color: c.primary700,
                        child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: fraction, child: Container(color: color))),
                    )),
                    const SizedBox(width: 8),
                    Text(CurrencyFormatter.formatShort(row.amount), style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  ],
                ),
              );
              }),

              // ── Others rollup ──
              if (sorted.length > 6) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: c.neutral600, borderRadius: BorderRadius.circular(1))),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Others (${sorted.length - 6})', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 9))),
                    const SizedBox(width: 42),
                    Expanded(child: Container()),
                    const SizedBox(width: 8),
                    Text(othersAmount > 0 ? CurrencyFormatter.formatShort(othersAmount) : '', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 10)),
                  ],
                ),
              ],
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
    final c = context.ksc;
    if (breakdown.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('LEAD SOURCE BREAKDOWN'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            child: const _EmptyRow(message: 'No lead source data'),
          ),
        ],
      );
    }

    final sorted = List<LeadSourceBreakdown>.from(breakdown)..sort((a, b) => b.revenue.compareTo(a.revenue));
    final totalRev = sorted.fold<int>(0, (s, e) => s + e.revenue);
    final show = sorted.take(6).toList();
    final maxRev = show.first.revenue.toDouble();
    final othersRevenue = sorted.length > 6 ? sorted.skip(6).fold<int>(0, (s, e) => s + e.revenue) : 0;
    final othersJobs = sorted.length > 6 ? sorted.skip(6).fold<int>(0, (s, e) => s + e.jobCount) : 0;

    const barColors = [
      Color(0xFF60A5FA), Color(0xFF34D399), Color(0xFFF59E0B),
      Color(0xFFA78BFA), Color(0xFFF472B6), Color(0xFF4ADE80),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('LEAD SOURCE BREAKDOWN'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Total ', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
                  Text(CurrencyFormatter.formatShort(totalRev), style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  const Spacer(),
                  Text('${sorted.length} source${sorted.length == 1 ? '' : 's'}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 8)),
                ],
              ),
              const SizedBox(height: 12),
              ...show.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final fraction = maxRev > 0 ? row.revenue / maxRev : 0.0;
                final pct = totalRev > 0 ? (row.revenue / totalRev * 100) : 0.0;
                final color = barColors[i % barColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
                          const SizedBox(width: 6),
                          Expanded(child: Text(row.source.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w700, fontSize: 10),
                              overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 34, child: Text('${pct.toStringAsFixed(0)}%', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.right)),
                          const SizedBox(width: 6),
                          SizedBox(width: 52, child: Text(CurrencyFormatter.formatShort(row.revenue),
                              style: AppTextStyles.caption.copyWith(color: c.accent500, fontWeight: FontWeight.w800, fontSize: 11), textAlign: TextAlign.right)),
                          const SizedBox(width: 6),
                          SizedBox(width: 16, child: Text('${row.jobCount}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9), textAlign: TextAlign.right)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(height: 8, color: c.primary700,
                          child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: fraction, child: Container(color: color))),
                      ),
                    ],
                  ),
                );
              }),
              // ── Others rollup ──
              if (sorted.length > 6) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: c.neutral600, borderRadius: BorderRadius.circular(1))),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Others (${sorted.length - 6})', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 9))),
                    const SizedBox(width: 34),
                    const SizedBox(width: 6),
                    SizedBox(width: 52, child: Text(othersRevenue > 0 ? CurrencyFormatter.formatShort(othersRevenue) : '', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 10), textAlign: TextAlign.right)),
                    const SizedBox(width: 6),
                    SizedBox(width: 16, child: Text(othersJobs > 0 ? '${othersJobs}' : '', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9), textAlign: TextAlign.right)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Top customers ──────────────────────────────────────────────────────────────

class _TopCustomersSection extends StatelessWidget {
  final List<TopCustomer> customers;
  const _TopCustomersSection({required this.customers});

  @override
  Widget build(BuildContext context) {
    final c = context.ksc;
    if (customers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('TOP CUSTOMERS'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            child: const _EmptyRow(message: 'No jobs in this period'),
          ),
        ],
      );
    }

    final sorted = List<TopCustomer>.from(customers)..sort((a, b) => b.revenue.compareTo(a.revenue));
    final totalRev = sorted.fold<int>(0, (s, e) => s + e.revenue);
    final show = sorted.take(6).toList();
    final maxRev = show.first.revenue.toDouble();
    final othersRevenue = sorted.length > 6 ? sorted.skip(6).fold<int>(0, (s, e) => s + e.revenue) : 0;
    final othersJobs = sorted.length > 6 ? sorted.skip(6).fold<int>(0, (s, e) => s + e.jobCount) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('TOP CUSTOMERS'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Total ', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
                  Text(CurrencyFormatter.formatShort(totalRev), style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  const Spacer(),
                  Text('${sorted.length} customer${sorted.length == 1 ? '' : 's'}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 8)),
                ],
              ),
              const SizedBox(height: 12),
              ...show.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final fraction = maxRev > 0 ? row.revenue / maxRev : 0.0;
                final pct = totalRev > 0 ? (row.revenue / totalRev * 100) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () => context.push(RouteNames.customerDetail(row.customerId)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Rank number
                            Container(
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: i < 3 ? c.accent500.withValues(alpha: 0.15) : c.primary700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text('${i + 1}', style: AppTextStyles.caption.copyWith(
                                  color: i < 3 ? c.accent500 : c.neutral400, fontWeight: FontWeight.w900, fontSize: 9)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(row.customerName.toUpperCase(),
                                  style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w700, fontSize: 10),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(width: 34, child: Text('${pct.toStringAsFixed(0)}%', style: AppTextStyles.caption.copyWith(color: c.accent500, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.right)),
                            const SizedBox(width: 6),
                            SizedBox(width: 54, child: Text(CurrencyFormatter.formatShort(row.revenue),
                                style: AppTextStyles.caption.copyWith(color: c.accent500, fontWeight: FontWeight.w800, fontSize: 11), textAlign: TextAlign.right)),
                            const SizedBox(width: 6),
                            SizedBox(width: 16, child: Text('${row.jobCount}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9), textAlign: TextAlign.right)),
                            const SizedBox(width: 2),
                            Text('j', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 7)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            height: 8, color: c.primary700,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: fraction,
                              child: Container(
                                color: i < 3
                                    ? (i == 0 ? const Color(0xFFF59E0B) : i == 1 ? const Color(0xFF94A3B8) : const Color(0xFFD4A574))
                                    : c.accent500.withValues(alpha: 0.5)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // ── Others rollup ──
              if (sorted.length > 6) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Others (${sorted.length - 6})', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 9))),
                    const SizedBox(width: 34),
                    const SizedBox(width: 6),
                    SizedBox(width: 54, child: Text(othersRevenue > 0 ? CurrencyFormatter.formatShort(othersRevenue) : '', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 10), textAlign: TextAlign.right)),
                    const SizedBox(width: 6),
                    SizedBox(width: 16, child: Text(othersJobs > 0 ? '${othersJobs}' : '', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9), textAlign: TextAlign.right)),
                    const SizedBox(width: 2),
                    Text('j', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 7)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Parts usage ────────────────────────────────────────────────────────────────

class _PartsUsageSection extends StatelessWidget {
  final List<PartsUsage> parts;
  const _PartsUsageSection({required this.parts});

  @override
  Widget build(BuildContext context) {
    final c = context.ksc;
    if (parts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('TOP PARTS USAGE'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            child: const _EmptyRow(message: 'No parts used in this period'),
          ),
        ],
      );
    }

    final sorted = List<PartsUsage>.from(parts)..sort((a, b) => b.totalCost.compareTo(a.totalCost));
    final totalCost = sorted.fold<int>(0, (s, e) => s + e.totalCost);
    final show = sorted.take(6).toList();
    final maxCost = show.first.totalCost.toDouble();
    final othersCost = sorted.length > 6 ? sorted.skip(6).fold<int>(0, (s, e) => s + e.totalCost) : 0;
    final othersQty = sorted.length > 6 ? sorted.skip(6).fold<int>(0, (s, e) => s + e.totalQuantity) : 0;

    const barColors = [
      Color(0xFF34D399), Color(0xFF60A5FA), Color(0xFFF59E0B),
      Color(0xFFA78BFA), Color(0xFFF472B6), Color(0xFF4ADE80),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('TOP PARTS USAGE'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: c.primary800, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Total ', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
                  Text(CurrencyFormatter.formatShort(totalCost), style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11)),
                  const Spacer(),
                  Text('${sorted.length} part${sorted.length == 1 ? '' : 's'}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 8)),
                ],
              ),
              const SizedBox(height: 12),
              ...show.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final fraction = maxCost > 0 ? row.totalCost / maxCost : 0.0;
                final pct = totalCost > 0 ? (row.totalCost / totalCost * 100) : 0.0;
                final color = barColors[i % barColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
                          const SizedBox(width: 6),
                          Expanded(child: Text(row.partName,
                              style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w700, fontSize: 10),
                              overflow: TextOverflow.ellipsis)),
                          SizedBox(width: 34, child: Text('${pct.toStringAsFixed(0)}%', style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 9), textAlign: TextAlign.right)),
                          const SizedBox(width: 6),
                          SizedBox(width: 52, child: Text(CurrencyFormatter.formatShort(row.totalCost),
                              style: AppTextStyles.caption.copyWith(color: c.white, fontWeight: FontWeight.w800, fontSize: 11), textAlign: TextAlign.right)),
                          const SizedBox(width: 4),
                          Text('×${row.totalQuantity}', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Container(height: 8, color: c.primary700,
                          child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: fraction, child: Container(color: color))),
                      ),
                    ],
                  ),
                );
              }),
              // ── Others rollup ──
              if (sorted.length > 6) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: c.neutral600, borderRadius: BorderRadius.circular(1))),
                    const SizedBox(width: 6),
                    Expanded(child: Text('Others (${sorted.length - 6})', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 9))),
                    const SizedBox(width: 34),
                    const SizedBox(width: 6),
                    SizedBox(width: 52, child: Text(othersCost > 0 ? CurrencyFormatter.formatShort(othersCost) : '', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontWeight: FontWeight.w600, fontSize: 10), textAlign: TextAlign.right)),
                    const SizedBox(width: 4),
                    Text(othersQty > 0 ? '×${othersQty}' : '', style: AppTextStyles.caption.copyWith(color: c.neutral500, fontSize: 9)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
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
