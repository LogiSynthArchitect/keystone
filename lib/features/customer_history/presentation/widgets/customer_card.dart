import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/cover_image_widget.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerCard extends StatelessWidget {
  final CustomerEntity customer;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;
  final bool hasPendingFollowUp;

  const CustomerCard({super.key, required this.customer, this.onTap, this.onCall, this.onWhatsApp, this.hasPendingFollowUp = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.ksc.primary800,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.ksc.primary700),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverImageWidget(
              imageUrl: customer.coverImageUrl,
              fallbackIcon: LineAwesomeIcons.users_solid,
              height: 80,
              borderRadius: 8,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.ksc.primary900,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.ksc.accent500, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : "?",
                        style: AppTextStyles.h2.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.fullName.toUpperCase(),
                                style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              )
                            ),
                            if (customer.isRepeatCustomer)
                              _badge(context, "REPEAT", context.ksc.accent500),
                            if (customer.propertyType != null) ...[
                              const SizedBox(width: 4),
                              _propertyBadge(context, customer.propertyType!),
                            ],
                            if (customer.hasNotes) ...[
                              const SizedBox(width: 4),
                              Icon(LineAwesomeIcons.sticky_note_solid, size: 12, color: context.ksc.accent500),
                            ],
                            if (hasPendingFollowUp) ...[
                              const SizedBox(width: 4),
                              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF25D366), shape: BoxShape.circle)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.phoneNumber,
                                style: AppTextStyles.caption.copyWith(color: context.ksc.neutral400, fontWeight: FontWeight.w600),
                              )
                            ),
                            _actionButton(context, LineAwesomeIcons.phone_solid, context.ksc.success500, () {
                              if (onCall != null) { onCall!(); }
                              else { launchUrl(Uri.parse('tel:${customer.phoneNumber}')); }
                            }),
                            const SizedBox(width: 4),
                            _actionButton(context, LineAwesomeIcons.whatsapp, context.ksc.accent500, onWhatsApp),
                          ],
                        ),
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
                  Icon(LineAwesomeIcons.angle_right_solid, color: context.ksc.primary700, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _badge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1.0)),
    );
  }

  Widget _propertyBadge(BuildContext context, String type) {
    final (label, color) = switch (type) {
      'residential' => ('RES',  context.ksc.success500),
      'commercial'  => ('COM',  context.ksc.warning500),
      _             => ('AUTO', context.ksc.neutral500),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 0.5)),
    );
  }
}
