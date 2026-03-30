import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_loading_indicator.dart';
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

// ── Period selector ──────────────────────────────────────────────────────────

class _PeriodSelector extends ConsumerWidget {
  final AnalyticsState state;
  const _PeriodSelector({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: context.ksc.primary800,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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

// ── Body ─────────────────────────────────────────────────────────────────────

class _AnalyticsBody extends StatelessWidget {
  final AnalyticsState state;
  const _AnalyticsBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge),
      children: [
        _SummaryCards(state: state),
        const SizedBox(height: AppSpacing.xxl),
        _ServiceTypeSection(breakdown: state.serviceTypeBreakdown),
        const SizedBox(height: AppSpacing.xxl),
        _PaymentHealthSection(health: state.paymentHealth),
        const SizedBox(height: AppSpacing.xxl),
        _LeadSourceSection(breakdown: state.leadSourceBreakdown),
        const SizedBox(height: AppSpacing.xxl),
        _PartsUsageSection(parts: state.partsUsage),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('PAYMENT HEALTH'),
        Container(
          decoration: BoxDecoration(
            color: context.ksc.primary800,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: total == 0
              ? const _EmptyRow(message: 'No jobs in this period')
              : Column(
                  children: [
                    _PaymentRow(
                      label: 'UNPAID',
                      count: health.unpaidCount,
                      amount: health.unpaidAmount,
                      color: context.ksc.error500,
                      bgColor: context.ksc.error100,
                    ),
                    Divider(height: 1, color: context.ksc.primary700),
                    _PaymentRow(
                      label: 'PARTIAL',
                      count: health.partialCount,
                      amount: health.partialAmount,
                      color: context.ksc.warning600,
                      bgColor: context.ksc.warning100,
                    ),
                    Divider(height: 1, color: context.ksc.primary700),
                    _PaymentRow(
                      label: 'PAID',
                      count: health.paidCount,
                      amount: health.paidAmount,
                      color: context.ksc.success600,
                      bgColor: context.ksc.success100,
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

class _PaymentRow extends StatelessWidget {
  final String label;
  final int count;
  final int amount;
  final Color color;
  final Color bgColor;

  const _PaymentRow({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              label,
              style: AppTextStyles.captionMedium.copyWith(
                  color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$count job${count == 1 ? '' : 's'}',
              style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500),
            ),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: AppTextStyles.bodyMedium.copyWith(color: context.ksc.white),
          ),
        ],
      ),
    );
  }
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
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(color: context.ksc.error500),
      ),
    );
  }
}
