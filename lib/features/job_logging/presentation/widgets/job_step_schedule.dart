import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/utils/date_formatter.dart';

/// Step 5 of the Add New Job wizard: Recurring schedule + Date + Location.
class JobStepSchedule extends ConsumerWidget {
  final bool isRecurring;
  final String recurringInterval;
  final DateTime jobDate;
  final TextEditingController locationController;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<String> onIntervalChanged;
  final ValueChanged<DateTime> onDateChanged;

  const JobStepSchedule({
    super.key,
    required this.isRecurring,
    required this.recurringInterval,
    required this.jobDate,
    required this.locationController,
    required this.onRecurringChanged,
    required this.onIntervalChanged,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecurringToggle(context),
        const SizedBox(height: 48),
        Text("DATE & LOCATION",
          style: AppTextStyles.h2.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text("When and where this job took place",
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
        const SizedBox(height: 24),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: jobDate,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
            );
            if (picked != null) onDateChanged(picked);
          },
          child: Row(
            children: [
              Icon(LineAwesomeIcons.calendar, size: 20, color: context.ksc.accent500),
              const SizedBox(width: 14),
              Text(DateFormatter.short(jobDate),
                style: AppTextStyles.bodyLarge.copyWith(color: context.ksc.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 34, top: 4),
          child: Divider(height: 1, color: Color(0xFF2A3A4A)),
        ),
        const SizedBox(height: 32),
        _buildDarkField(
          context: context,
          label: "Location",
          hint: "East Legon, Accra",
          controller: locationController,
          maxLength: 255,
        ),
      ],
    );
  }

  Widget _buildRecurringToggle(BuildContext context) {
    final intervals = [('weekly', 'WEEKLY'), ('monthly', 'MONTHLY'), ('quarterly', 'QUARTERLY')];
    final nextDueStr = switch (recurringInterval) {
      'weekly' => DateFormatter.short(jobDate.add(const Duration(days: 7))),
      'monthly' => DateFormatter.short(jobDate.add(const Duration(days: 30))),
      'quarterly' => DateFormatter.short(jobDate.add(const Duration(days: 90))),
      _ => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onRecurringChanged(!isRecurring),
          child: Row(
            children: [
              Icon(
                isRecurring ? LineAwesomeIcons.calendar_check_solid : LineAwesomeIcons.calendar_solid,
                color: isRecurring ? context.ksc.accent500 : context.ksc.neutral500,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("REPEAT THIS JOB",
                          style: AppTextStyles.body.copyWith(color: context.ksc.white, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: "Auto-generate follow-up jobs on a schedule.\n"
                              "Weekly = every 7 days\n"
                              "Monthly = every 30 days\n"
                              "Quarterly = every 90 days\n\n"
                              "Works only after a customer is selected.",
                          preferBelow: false,
                          child: Icon(LineAwesomeIcons.question_circle_solid, size: 14, color: context.ksc.neutral500),
                        ),
                      ],
                    ),
                    Text(isRecurring ? "Next: $nextDueStr" : "Set up weekly / monthly / quarterly",
                      style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontSize: 10)),
                  ],
                ),
              ),
              Switch(
                value: isRecurring,
                onChanged: (v) => onRecurringChanged(v),
                activeColor: context.ksc.accent500,
              ),
            ],
          ),
        ),
        if (isRecurring) ...[
          const SizedBox(height: 16),
          Row(
            children: intervals.map((opt) {
              final isSelected = recurringInterval == opt.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onIntervalChanged(opt.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? context.ksc.accent500.withValues(alpha: 0.1) : context.ksc.primary700,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isSelected ? context.ksc.accent500 : context.ksc.primary700),
                    ),
                    child: Text(opt.$2,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? context.ksc.accent500 : context.ksc.neutral400,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDarkField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    bool isNumeric = false,
    String? fieldHint,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
          style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500, fontWeight: FontWeight.w800, fontSize: 10)),
        if (fieldHint != null) ...[
          const SizedBox(height: 4),
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
          keyboardType: type,
          maxLines: maxLines,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          autocorrect: !isNumeric,
          enableSuggestions: !isNumeric,
          onChanged: onChanged,
          style: AppTextStyles.body.copyWith(
            color: readOnly ? context.ksc.neutral500 : context.ksc.white,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.ksc.neutral500),
            contentPadding: const EdgeInsets.only(bottom: 8, top: 12),
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
    );
  }
}
