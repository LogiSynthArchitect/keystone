import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';

/// Step 3 of the Add New Job wizard: Customer name + phone with lookup.
class JobStepCustomer extends ConsumerWidget {
  final TextEditingController customerController;
  final TextEditingController phoneController;
  final String? matchedCustomerName;
  final String? matchedCustomerId;
  final bool preSelectedCustomerId;
  final ValueChanged<String> onPhoneChanged;

  const JobStepCustomer({
    super.key,
    required this.customerController,
    required this.phoneController,
    this.matchedCustomerName,
    this.matchedCustomerId,
    required this.preSelectedCustomerId,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("CUSTOMER",
          style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        _buildCustomerField(
          context: context,
          icon: LineAwesomeIcons.user_solid,
          label: "Customer Name",
          hint: "Kwame Mensah",
          controller: customerController,
          readOnly: preSelectedCustomerId,
          maxLength: 100,
        ),
        if (!preSelectedCustomerId) ...[
          const SizedBox(height: 16),
          _buildCustomerField(
            context: context,
            icon: LineAwesomeIcons.phone_alt_solid,
            label: "Phone Number",
            hint: "024 123 4567",
            controller: phoneController,
            fieldHint: "Required for WhatsApp follow-ups.",
            isNumeric: true,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: onPhoneChanged,
          ),
          if (matchedCustomerName != null && matchedCustomerId != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.ksc.accent500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.ksc.accent500.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(LineAwesomeIcons.check_circle_solid, size: 20, color: context.ksc.accent500),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("LINKED TO EXISTING CUSTOMER",
                            style: AppTextStyles.caption.copyWith(
                              color: context.ksc.accent500,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(matchedCustomerName!.toUpperCase(),
                            style: AppTextStyles.body.copyWith(
                              color: context.ksc.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCustomerField({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String hint,
    required TextEditingController controller,
    bool readOnly = false,
    bool isNumeric = false,
    String? fieldHint,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
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
              Text(label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: context.ksc.neutral500,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (fieldHint != null) ...[
                const SizedBox(height: 2),
                Text(fieldHint,
                  style: AppTextStyles.caption.copyWith(
                    color: context.ksc.accent500.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                readOnly: readOnly,
                maxLength: maxLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                inputFormatters: inputFormatters,
                onChanged: onChanged,
                keyboardType: isNumeric ? TextInputType.phone : TextInputType.text,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: readOnly ? context.ksc.neutral500 : context.ksc.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: AppTextStyles.bodyLarge.copyWith(
                    color: context.ksc.neutral600,
                    fontWeight: FontWeight.bold,
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
}
