import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/reminders/domain/models/reminder_model.dart';

typedef NotificationTapCallback = void Function(String jobId);

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static NotificationTapCallback? _tapCallback;
  static const _pendingKey = 'pending_notification_job_id';

  /// Persist a tapped-notification payload to Hive so it survives cold starts.
  /// Checked and cleared when the callback is registered.
  static void _setPendingJobId(String jobId) {
    try {
      final box = Hive.box('meta');
      box.put(_pendingKey, jobId);
    } catch (_) {}
  }

  /// Read and clear any pending notification payload from Hive.
  static String? _consumePendingJobId() {
    try {
      final box = Hive.box('meta');
      final id = box.get(_pendingKey) as String?;
      if (id != null) box.delete(_pendingKey);
      return id;
    } catch (_) {
      return null;
    }
  }

  /// Set the tap callback (call from within ProviderScope where GoRouter is available).
  /// If a notification was tapped before the callback was registered, fires immediately.
  static set onNotificationTap(NotificationTapCallback? cb) {
    _tapCallback = cb;
    final pendingId = _consumePendingJobId();
    if (pendingId != null && cb != null) {
      cb(pendingId);
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linux = LinuxInitializationSettings(
      defaultActionName: 'Open',
    );
    const settings = InitializationSettings(
      android: android,
      iOS: ios,
      linux: linux,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          if (_tapCallback != null) {
            _tapCallback!(payload);
          } else {
            _setPendingJobId(payload);
          }
        }
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
      ReminderType.recurringJobOverdue => 'Recurring Job Overdue',
      ReminderType.lowStock => 'Low Stock Alert',
      ReminderType.dormantCustomer => 'Customer Dormant',
    };

    final body = switch (reminder.type) {
      ReminderType.unpaidJob => '${reminder.jobServiceType} — GHS ${reminder.amountCharged?.toStringAsFixed(0) ?? "0"} unpaid',
      ReminderType.stuckInProgress => '${reminder.jobServiceType} started ${_formatDate(reminder.jobDate)}',
      ReminderType.followUpPending => '${reminder.jobServiceType} — follow-up not sent',
      ReminderType.followUpNoResponse => '${reminder.jobServiceType} — client hasn\'t responded',
      ReminderType.recurringJobOverdue => '${reminder.jobServiceType} schedule is past due',
      ReminderType.lowStock => '${reminder.jobServiceType} — low stock',
      ReminderType.dormantCustomer => '${reminder.jobServiceType} — no job in ${DateTime.now().difference(reminder.jobDate).inDays} days',
    };

    const androidDetails = AndroidNotificationDetails(
      'arclock_reminders',
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
