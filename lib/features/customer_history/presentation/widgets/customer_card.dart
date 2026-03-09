import 'package:flutter/material.dart';
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary100,
              child: Text(
                customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : "?",
                style: AppTextStyles.h3.copyWith(color: AppColors.primary700),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(customer.fullName, style: AppTextStyles.bodyMedium)),
                    if (customer.isRepeatCustomer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary050, borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
                        child: Text("Repeat", style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary700)),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(customer.phoneNumber, style: AppTextStyles.caption.copyWith(color: AppColors.neutral500)),
                  if (customer.lastJobAt != null) ...[
                    const SizedBox(height: 2),
                    Text("Last job: ${DateFormatter.relative(customer.lastJobAt!)}", style: AppTextStyles.caption.copyWith(color: AppColors.neutral400)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.neutral300),
          ],
        ),
      ),
    );
  }
}
