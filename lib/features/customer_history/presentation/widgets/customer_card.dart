import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
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
          color: AppColors.primary800,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary900,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Center(
                child: Text(
                  customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : "?",
                  style: AppTextStyles.h3.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900),
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
                          customer.fullName, 
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)
                        )
                      ),
                      if (customer.isRepeatCustomer)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent500.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: AppColors.accent500.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            "REPEAT", 
                            style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent500, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.phoneNumber, 
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral400, fontWeight: FontWeight.w600)
                  ),
                  if (customer.lastJobAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Last job: ${DateFormatter.relative(customer.lastJobAt!)}", 
                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral500)
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LineAwesomeIcons.angle_right_solid, color: AppColors.neutral500, size: 16),
          ],
        ),
      ),
    );
  }
}
