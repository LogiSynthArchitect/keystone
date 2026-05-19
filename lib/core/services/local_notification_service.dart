import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/reminders/domain/models/reminder_model.dart';

typedef NotificationTapCallback = void Function(String jobId);

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static NotificationTapCallback? onNotificationTap;

  static Future<void> initialize({required void Function(String? payload) onTap}) async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        onTap(response.payload);
      },
    );

    _initialized = true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  static Future<void> showReminderNotification(Reminder reminder) async {
    final title = switch (reminder.type) {
      ReminderType.unpaidJob => 'Unpaid Job Reminder',
      ReminderType.stuckInProgress => 'Job Stuck In Progress',
      ReminderType.followUpPending => 'Follow-up Pending',
      ReminderType.followUpNoResponse => 'No Response on Follow-up',
    };

    final body = switch (reminder.type) {
      ReminderType.unpaidJob => '${reminder.jobServiceType} — GHS ${reminder.amountCharged?.toStringAsFixed(0) ?? "0"} unpaid',
      ReminderType.stuckInProgress => '${reminder.jobServiceType} started ${_formatDate(reminder.jobDate)}',
      ReminderType.followUpPending => '${reminder.jobServiceType} — follow-up not sent',
      ReminderType.followUpNoResponse => '${reminder.jobServiceType} — client hasn\'t responded',
    };

    const androidDetails = AndroidNotificationDetails(
      'keystone_reminders',
      'Job Reminders',
      channelDescription: 'Reminders for unpaid, stuck, and follow-up jobs',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      reminder.jobId.hashCode,
      title,
      body,
      details,
      payload: reminder.jobId,
    );
  }

  static String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
