import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

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
    if (reminder.dateTime.isBefore(DateTime.now())) return;

    final tzDateTime = tz.TZDateTime.from(reminder.dateTime, tz.local);
    final id = reminder.id.hashCode.abs() % 2147483647;

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

    if (repeatInterval != null && reminder.repeat != ReminderRepeat.monthly && reminder.repeat != ReminderRepeat.yearly) {
      await _plugin.periodicallyShowWithDuration(
        id,
        '${reminder.type.emoji} $kidName — ${reminder.title}',
        reminder.notes ?? reminder.type.label,
        repeatInterval == RepeatInterval.daily
            ? const Duration(days: 1)
            : const Duration(days: 7),
        details,
      );
    } else {
      await _plugin.zonedSchedule(
        id,
        '${reminder.type.emoji} $kidName — ${reminder.title}',
        reminder.notes ?? reminder.type.label,
        tzDateTime,
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
    }
  }

  static Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb || !_initialized) return;
    final id = reminderId.hashCode.abs() % 2147483647;
    await _plugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }
}
