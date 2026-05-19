import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_snackbar.dart';
import '../../domain/models/reminder_thresholds.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});
  @override
  ConsumerState<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen> {
  late int _unpaidDays;
  late int _stuckDays;
  late int _followUpDays;
  late int _noResponseDays;

  @override
  void initState() {
    super.initState();
    final t = ReminderThresholds.load();
    _unpaidDays = t.unpaidJobDays;
    _stuckDays = t.stuckInProgressDays;
    _followUpDays = t.followUpPendingDays;
    _noResponseDays = t.followUpNoResponseDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: "REMINDER SETTINGS", showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSlider("UNPAID JOBS", "Remind about unpaid completed jobs after", _unpaidDays, (v) => setState(() => _unpaidDays = v)),
          const SizedBox(height: 32),
          _buildSlider("STUCK JOBS", "Remind about in-progress jobs after", _stuckDays, (v) => setState(() => _stuckDays = v)),
          const SizedBox(height: 32),
          _buildSlider("FOLLOW-UP PENDING", "Remind about jobs missing follow-up after", _followUpDays, (v) => setState(() => _followUpDays = v)),
          const SizedBox(height: 32),
          _buildSlider("NO RESPONSE", "Remind about follow-ups with no response after", _noResponseDays, (v) => setState(() => _noResponseDays = v)),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.ksc.accent500,
                foregroundColor: context.ksc.primary900,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () async {
                await ReminderThresholds.save(ReminderThresholds(
                  unpaidJobDays: _unpaidDays,
                  stuckInProgressDays: _stuckDays,
                  followUpPendingDays: _followUpDays,
                  followUpNoResponseDays: _noResponseDays,
                ));
                if (mounted) KsSnackbar.show(context, message: "Reminder thresholds saved", type: KsSnackbarType.success);
              },
              child: Text("SAVE SETTINGS", style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, String description, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.h3.copyWith(color: context.ksc.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(description, style: AppTextStyles.caption.copyWith(color: context.ksc.neutral500)),
        const SizedBox(height: 16),
        Row(
          children: [
            Text("$value day${value == 1 ? '' : 's'}", style: AppTextStyles.body.copyWith(color: context.ksc.accent500, fontWeight: FontWeight.w900)),
            const SizedBox(width: 16),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 14,
                divisions: 14,
                activeColor: context.ksc.accent500,
                inactiveColor: context.ksc.primary700,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
