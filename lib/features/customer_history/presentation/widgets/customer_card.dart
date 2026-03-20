import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerCard extends StatelessWidget {
  final CustomerEntity customer;
  final VoidCallback? onTap;

  const CustomerCard({super.key, required this.customer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: context.ksc.primary700),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.ksc.primary900,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: context.ksc.primary700),
              ),
              child: Center(
                child: Text(
                  customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : "?",
                  style: AppTextStyles.h2.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          customer.fullName.toUpperCase(),
                          style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                          overflow: TextOverflow.ellipsis,
                        )
                      ),
                      if (customer.isRepeatCustomer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.ksc.accent500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            "REPEAT",
                            style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0)
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    customer.phoneNumber,
                    style: AppTextStyles.caption.copyWith(
                      color: context.ksc.neutral400,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    )
                  ),
                  if (customer.lastJobAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(LineAwesomeIcons.history_solid, size: 10, color: context.ksc.neutral500),
                        const SizedBox(width: 4),
                        Text(
                          "LAST RECORD: ${DateFormatter.relative(customer.lastJobAt!).toUpperCase()}",
                          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral600, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.primary700, size: 16),
          ],
        ),
      ),
    );
  }
}
