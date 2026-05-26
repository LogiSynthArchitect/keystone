import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/job_providers.dart';

/// Step 6 of the Add New Job wizard: Items, Expenses, Media, Notes cards.
/// Each card opens a sub-drawer (managed by parent).
class JobStepExtras extends ConsumerWidget {
  final String? customerId;
  final int itemCount;
  final int expenseCount;
  final int expenseTotal;
  final int photoCount;
  final String? notesPreview;
  final VoidCallback onOpenItems;
  final VoidCallback onOpenExpenses;
  final VoidCallback onOpenMedia;
  final VoidCallback onOpenNotes;
  final ValueChanged<String>? onBrandSuggestionTapped;
  final ValueChanged<String>? onPartSuggestionTapped;

  const JobStepExtras({
    super.key,
    this.customerId,
    required this.itemCount,
    required this.expenseCount,
    required this.expenseTotal,
    required this.photoCount,
    this.notesPreview,
    required this.onOpenItems,
    required this.onOpenExpenses,
    required this.onOpenMedia,
    required this.onOpenNotes,
    this.onBrandSuggestionTapped,
    this.onPartSuggestionTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customerId != null)
          _buildCustomerHistorySuggestions(context, ref),
        const SizedBox(height: 24),
        _buildExtrasCard(
          context: context,
          icon: Icon(LineAwesomeIcons.box_solid, size: 16, color: context.ksc.accent500),
          title: "Items Used",
          subtitle: "Hardware, parts & supplies",
          trailing: itemCount > 0
              ? _extrasCountTrailing(context, "$itemCount item${itemCount > 1 ? 's' : ''}")
              : _extrasEmptyTrailing(context),
          onTap: onOpenItems,
        ),
        _buildExtrasCard(
          context: context,
          icon: Icon(LineAwesomeIcons.coins_solid, size: 16, color: context.ksc.accent500),
          title: "Expenses",
          subtitle: "Transport, parking, subs",
          trailing: expenseCount > 0
              ? _extrasCountTrailing(context, "$expenseCount item${expenseCount > 1 ? 's' : ''}",
                  amount: CurrencyFormatter.format(expenseTotal))
              : _extrasEmptyTrailing(context),
          onTap: onOpenExpenses,
        ),
        _buildExtrasCard(
          context: context,
          icon: Icon(LineAwesomeIcons.camera_solid, size: 16, color: context.ksc.accent500),
          title: "Media",
          subtitle: "Photos, videos & audio recordings",
          trailing: photoCount > 0
              ? _extrasCountTrailing(context, "$photoCount item${photoCount > 1 ? 's' : ''}")
              : _extrasEmptyTrailing(context),
          onTap: onOpenMedia,
        ),
        _buildExtrasCard(
          context: context,
          icon: Icon(LineAwesomeIcons.edit_solid, size: 16, color: context.ksc.accent500),
          title: "Notes",
          subtitle: "Job notes",
          trailing: _extrasNoteTrailing(context),
          onTap: onOpenNotes,
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildCustomerHistorySuggestions(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(customerHistorySuggestionsProvider(customerId!));
    return suggestions.when(
      data: (data) {
        if (data.hardwareBrands.isEmpty && data.partNames.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LineAwesomeIcons.history_solid, size: 14, color: context.ksc.accent500),
                  const SizedBox(width: 8),
                  Text("FROM PAST JOBS",
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.accent500, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ],
              ),
              const SizedBox(height: 10),
              if (data.hardwareBrands.isNotEmpty) ...[
                Text("BRANDS USED",
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 9)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: data.hardwareBrands.map((b) => GestureDetector(
                    onTap: () => onBrandSuggestionTapped?.call(b),
                    child: Text(b.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 10,
                        decoration: TextDecoration.underline)),
                  )).toList(),
                ),
                const SizedBox(height: 10),
              ],
              if (data.partNames.isNotEmpty) ...[
                Text("PARTS USED",
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 9)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: data.partNames.map((p) => GestureDetector(
                    onTap: () => onPartSuggestionTapped?.call(p),
                    child: Text(p.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: context.ksc.accent500, fontWeight: FontWeight.w800, fontSize: 10,
                        decoration: TextDecoration.underline)),
                  )).toList(),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Divider(height: 1, color: context.ksc.primary700),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildExtrasCard({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(width: 20, height: 20, child: icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
            const SizedBox(width: 8),
            Icon(LineAwesomeIcons.angle_right_solid,
              color: context.ksc.neutral500, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _extrasCountTrailing(BuildContext context, String count, {String? amount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count,
          style: AppTextStyles.caption.copyWith(
            color: context.ksc.white,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
        if (amount != null)
          Text(amount,
            style: AppTextStyles.caption.copyWith(
              color: context.ksc.accent500,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  Widget _extrasEmptyTrailing(BuildContext context) {
    return Text("No items",
      style: AppTextStyles.caption.copyWith(
        color: context.ksc.neutral600,
        fontSize: 11,
      ),
    );
  }

  Widget _extrasNoteTrailing(BuildContext context) {
    final text = notesPreview;
    if (text == null || text.isEmpty) {
      return Text("No notes",
        style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral600,
          fontSize: 11,
        ),
      );
    }
    return Text(text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.caption.copyWith(
        color: context.ksc.neutral500,
        fontSize: 11,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
