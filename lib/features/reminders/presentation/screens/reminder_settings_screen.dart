import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/ks_colors.dart';
import '../../../../core/widgets/ks_app_bar.dart';
import '../../../../core/widgets/ks_summary_strip.dart';
import 'package:arclock/core/widgets/ks_sliding_notification.dart';
import '../../domain/models/reminder_thresholds.dart';
import '../providers/reminders_provider.dart';

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
  late int _recurringOverdueDays;
  late int _dormantCustomerDays;

  @override
  void initState() {
    super.initState();
    final t = ReminderThresholds.load();
    _unpaidDays = t.unpaidJobDays;
    _stuckDays = t.stuckInProgressDays;
    _followUpDays = t.followUpPendingDays;
    _noResponseDays = t.followUpNoResponseDays;
    _recurringOverdueDays = t.recurringJobOverdueDays;
    _dormantCustomerDays = t.dormantCustomerDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.ksc.primary900,
      appBar: const KsAppBar(title: "REMINDER SETTINGS", showBack: true),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              children: [
                // Summary strip — zero margin since ListView already provides 24px padding
                KsSummaryStrip(
                  value: "6 thresholds",
                  label: "REMINDER CONFIGURATION",
                  subtitleSegments: [
                    KsSubtitleSegment('unpaid:${_unpaidDays}d', color: context.ksc.accent500),
                    KsSubtitleSegment('stuck:${_stuckDays}d', color: context.ksc.error500),
                    KsSubtitleSegment('follow-up:${_followUpDays}d', color: context.ksc.warning500),
                    KsSubtitleSegment('no-response:${_noResponseDays}d', color: context.ksc.error500),
                    KsSubtitleSegment('recurring:${_recurringOverdueDays}d', color: context.ksc.success500),
                    KsSubtitleSegment('dormant:${_dormantCustomerDays}d', color: context.ksc.neutral400),
                  ],
                  subtitleIcon: LineAwesomeIcons.bell_solid,
                  margin: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),
                // PAYMENT section
                _sectionHeader("PAYMENT"),
                const SizedBox(height: 16),
                _buildSlider("UNPAID JOBS", "Remind about unpaid completed jobs after", _unpaidDays, (v) => setState(() => _unpaidDays = v)),
                const SizedBox(height: 32),
                // PROGRESS section
                _sectionHeader("PROGRESS"),
                const SizedBox(height: 16),
                _buildSlider("STUCK JOBS", "Remind about in-progress jobs after", _stuckDays, (v) => setState(() => _stuckDays = v)),
                const SizedBox(height: 32),
                // FOLLOW-UP section
                _sectionHeader("FOLLOW-UP"),
                const SizedBox(height: 16),
                _buildSlider("FOLLOW-UP PENDING", "Remind about jobs missing follow-up after", _followUpDays, (v) => setState(() => _followUpDays = v)),
                const SizedBox(height: 16),
                _buildSlider("NO RESPONSE", "Remind about follow-ups with no response after", _noResponseDays, (v) => setState(() => _noResponseDays = v)),
                const SizedBox(height: 32),
                // SCHEDULES section
                _sectionHeader("SCHEDULES"),
                const SizedBox(height: 16),
                _buildSlider("RECURRING JOB OVERDUE", "Remind about due recurring schedules after", _recurringOverdueDays, (v) => setState(() => _recurringOverdueDays = v)),
                const SizedBox(height: 32),
                // CUSTOMERS section
                _sectionHeader("CUSTOMERS"),
                const SizedBox(height: 16),
                _buildSlider("DORMANT CUSTOMERS", "Remind about customers with no recent jobs after", _dormantCustomerDays, (v) => setState(() => _dormantCustomerDays = v)),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // Fixed bottom bar — edge-to-edge gold, matches KsStepDrawer pattern
          Container(
            width: double.infinity,
            color: context.ksc.accent500,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await ReminderThresholds.save(ReminderThresholds(
                    unpaidJobDays: _unpaidDays,
                    stuckInProgressDays: _stuckDays,
                    followUpPendingDays: _followUpDays,
                    followUpNoResponseDays: _noResponseDays,
                    recurringJobOverdueDays: _recurringOverdueDays,
                    dormantCustomerDays: _dormantCustomerDays,
                  ));
                  if (mounted) {
                    ref.invalidate(remindersProvider);
                    KsSlidingNotification.show(context, message: "Reminder thresholds saved", type: KsNotificationType.success);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("SAVE SETTINGS",
                        style: TextStyle(
                          color: context.ksc.primary900,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                      Icon(LineAwesomeIcons.check_solid,
                        color: context.ksc.primary900,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Row(
      children: [
        Container(width: 3, height: 16, color: context.ksc.accent500),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.caption.copyWith(
          color: context.ksc.neutral500,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        )),
      ],
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
