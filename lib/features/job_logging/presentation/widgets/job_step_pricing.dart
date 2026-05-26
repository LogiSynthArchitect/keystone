import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Step 4 of the Add New Job wizard: Pricing (Quoted + Final amounts, Payment status).
class JobStepPricing extends ConsumerWidget {
  final TextEditingController quotedAmountController;
  final TextEditingController amountController;
  final FocusNode? quotedFocusNode;
  final FocusNode? amountFocusNode;
  final String paymentStatus;
  final ValueChanged<String> onPaymentStatusChanged;

  const JobStepPricing({
    super.key,
    required this.quotedAmountController,
    required this.amountController,
    this.quotedFocusNode,
    this.amountFocusNode,
    required this.paymentStatus,
    required this.onPaymentStatusChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("PRICING",
          style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Set the money side of this job",
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 32),
        _buildPriceCard(
          context: context,
          icon: LineAwesomeIcons.file_invoice_dollar_solid,
          label: "Quoted Amount",
          hint: "0.00",
          controller: quotedAmountController,
          focusNode: quotedFocusNode,
        ),
        const SizedBox(height: 16),
        _buildPriceCard(
          context: context,
          icon: LineAwesomeIcons.money_bill_wave_alt_solid,
          label: "Final Amount",
          hint: "0.00",
          controller: amountController,
          focusNode: amountFocusNode,
        ),
        const SizedBox(height: 32),
        Text("PAYMENT STATUS",
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _buildPaymentStatusRow(context),
      ],
    );
  }

  Widget _buildPriceCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    FocusNode? focusNode,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Icon(icon, size: 20, color: context.ksc.accent500),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral500,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text("GHS",
                    style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [CurrencyInputFormatter()],
                style: AppTextStyles.h2.copyWith(
                  color: context.ksc.white,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.h2.copyWith(
                    color: context.ksc.neutral600,
                    fontWeight: FontWeight.w900,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.only(bottom: 4),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.ksc.primary700, width: 1),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.ksc.accent500, width: 1.5),
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.ksc.primary700),
                  ),
                  filled: false,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusRow(BuildContext context) {
    final statusOpts = [('unpaid', 'UNPAID'), ('partial', 'PARTIAL'), ('paid', 'PAID')];
    return Row(
      children: statusOpts.map((opt) {
        final isSel = paymentStatus == opt.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onPaymentStatusChanged(opt.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary800,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isSel ? context.ksc.accent500 : context.ksc.primary700),
              ),
              child: Text(opt.$2,
                style: AppTextStyles.caption.copyWith(
                  color: isSel ? context.ksc.accent500 : context.ksc.neutral400,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
