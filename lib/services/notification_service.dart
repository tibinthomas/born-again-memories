import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // 25 slots per reminder: initial + 24 follow-ups every 30 min.
  // 85 000 000 * 25 = 2 125 000 000 < Int32 max (2 147 483 647).
  static int _baseId(String id) => (id.hashCode.abs() % 85000000) * 25;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const macos = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios, macOS: macos),
    );
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    bool granted = false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final darwin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
      await android.requestExactAlarmsPermission();
    } else if (darwin != null) {
      granted = await darwin.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    } else if (macos != null) {
      granted = await macos.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return granted;
  }

  static Future<void> scheduleReminder(Reminder reminder, String kidName) async {
    if (kIsWeb || !_initialized) return;
    if (reminder.isMuted) return;

    final now = DateTime.now();
    if (reminder.dateTime.isBefore(now)) return;

    final base = _baseId(reminder.id);
    final tzTime = tz.TZDateTime.from(reminder.dateTime, tz.local);
    final title = '${reminder.type.emoji} $kidName — ${reminder.title}';
    final body = reminder.notes ?? reminder.type.label;

    final androidDetails = AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Baby milestone reminders',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(reminder.notes ?? ''),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails, macOS: const DarwinNotificationDetails());

    final RepeatInterval? repeatInterval = switch (reminder.repeat) {
      ReminderRepeat.daily => RepeatInterval.daily,
      ReminderRepeat.weekly => RepeatInterval.weekly,
      _ => null,
    };

    if (repeatInterval != null) {
      await _plugin.periodicallyShowWithDuration(
        base,
        title,
        body,
        repeatInterval == RepeatInterval.daily
            ? const Duration(days: 1)
            : const Duration(days: 7),
        details,
      );
    } else {
      await _plugin.zonedSchedule(
        base,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: reminder.repeat == ReminderRepeat.monthly
            ? DateTimeComponents.dayOfMonthAndTime
            : reminder.repeat == ReminderRepeat.yearly
                ? DateTimeComponents.dateAndTime
                : null,
      );

      // Follow-up pings every 30 min (up to 12 hours) for one-time reminders.
      if (reminder.repeat == ReminderRepeat.none) {
        for (int i = 1; i <= 24; i++) {
          final followUp = reminder.dateTime.add(Duration(minutes: 30 * i));
          if (followUp.isBefore(now)) continue;
          await _plugin.zonedSchedule(
            base + i,
            title,
            body,
            tz.TZDateTime.from(followUp, tz.local),
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }
  }

  static Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb || !_initialized) return;
    final base = _baseId(reminderId);
    for (int i = 0; i < 25; i++) {
      await _plugin.cancel(base + i);
    }
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }

  static Future<void> showSharedMilestoneNotification({
    required String senderName,
    required String milestoneTitle,
  }) async {
    if (kIsWeb || !_initialized) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'shared_memories',
        'Shared Memories',
        channelDescription: 'Notifications when someone shares a new memory',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 & 0x7FFFFFFF,
      '$senderName added a new memory ✨',
      milestoneTitle,
      details,
    );
  }
}
