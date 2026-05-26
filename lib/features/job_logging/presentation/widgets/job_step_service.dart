import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/service_icon_map.dart';
import '../../../../core/widgets/ks_empty_state.dart';
import '../../../service_types/presentation/providers/service_type_provider.dart';
import 'service_picker_dropdown.dart';
import '../widgets/job_step_types.dart';

/// Step 1 of the Add New Job wizard: Main service selection + Additional Services.
class JobStepService extends ConsumerWidget {
  final String? serviceType;
  final List<ServiceRow> additionalServices;
  final ValueChanged<String?> onServiceTypeChanged;
  final VoidCallback onOpenAdditionalServices;

  const JobStepService({
    super.key,
    required this.serviceType,
    required this.additionalServices,
    required this.onServiceTypeChanged,
    required this.onOpenAdditionalServices,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SERVICE PERFORMED",
          style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("The main reason for this visit",
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 8),
        ServicePickerDropdown(
          selected: serviceType,
          onSelected: (t) => onServiceTypeChanged(t),
        ),
        const SizedBox(height: 48),
        Text("ADDITIONAL SERVICES (OPTIONAL)",
          style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("Other services performed during this visit",
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 16),
        if (additionalServices.isEmpty)
          KsEmptyState(
            icon: LineAwesomeIcons.tools_solid,
            title: "NO ADDITIONAL SERVICES",
            subtitle: "Tap the button below to add services performed during this visit",
          )
        else
          ...additionalServices.asMap().entries.map((entry) {
            final svc = entry.value;
            final qty = int.tryParse(svc.qtyController.text) ?? 1;
            final unitPrice = CurrencyFormatter.parseToPesewas(svc.priceController.text.trim()) ?? 0;
            final total = qty * unitPrice;
            final types = ref.read(serviceTypeProvider).valueOrNull ?? [];
            final svcType = types.where((t) => t.name == svc.serviceType).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: onOpenAdditionalServices,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.ksc.primary800,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.ksc.primary700),
                  ),
                  child: Row(
                    children: [
                      Icon(ServiceIconMap.resolve(svcType?.iconName), size: 16, color: context.ksc.accent500),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          svc.serviceType?.replaceAll('_', ' ').toUpperCase() ?? '',
                          style: AppTextStyles.caption.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        total > 0 ? CurrencyFormatter.format(total) : "GHS 0.00",
                        style: AppTextStyles.caption.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenAdditionalServices,
            icon: Icon(LineAwesomeIcons.plus_solid, size: 16, color: context.ksc.accent500),
            label: Text("ADD SERVICE",
              style: AppTextStyles.label.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w800)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.ksc.accent500.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }
}
