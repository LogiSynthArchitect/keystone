import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerCard extends StatelessWidget {
  final CustomerEntity customer;
  final VoidCallback? onTap;
  final bool hasPendingFollowUp;

  const CustomerCard({super.key, required this.customer, this.onTap, this.hasPendingFollowUp = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.ksc.primary700),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F1A2E), Color(0xFF1A2A4A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.2)),
              ),
              child: Center(
                child: Text(
                  customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : "?",
                  style: AppTextStyles.h2.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row + tags
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.fullName,
                          style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (customer.isRepeatCustomer) ...[
                        const SizedBox(width: 6),
                        _badge(context, "REPEAT", context.ksc.accent500),
                      ],
                      if (customer.propertyType != null) ...[
                        const SizedBox(width: 4),
                        _badge(context, _propertyLabel(customer.propertyType!), _propertyColor(context, customer.propertyType!)),
                      ],
                      if (hasPendingFollowUp) ...[
                        const SizedBox(width: 6),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Phone
                  Text(
                    customer.phoneNumber,
                    style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600),
                  ),
                  // Last record
                  if (customer.lastJobAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LineAwesomeIcons.history_solid, size: 10, color: context.ksc.neutral500),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "LAST RECORD: ${DateFormatter.relative(customer.lastJobAt!).toUpperCase()}",
                            style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontSize: 10, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chevron
            Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.neutral500, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 9, letterSpacing: 0.5),
      ),
    );
  }

  String _propertyLabel(String type) {
    return switch (type) {
      'residential' => 'RES',
      'commercial'  => 'COM',
      _             => 'AUTO',
    };
  }

  Color _propertyColor(BuildContext context, String type) {
    return switch (type) {
      'residential' => const Color(0xFF22C55E),
      'commercial'  => const Color(0xFFF97316),
      _             => context.ksc.neutral500,
    };
  }
}
