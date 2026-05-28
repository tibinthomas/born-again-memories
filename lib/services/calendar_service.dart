import 'package:device_calendar/device_calendar.dart' hide Reminder;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder.dart';

class CalendarService {
  static final _plugin = DeviceCalendarPlugin();
  static const _calendarScope =
      'https://www.googleapis.com/auth/calendar.events';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Adds a reminder to the appropriate calendar and returns the external
  /// event ID, or null if the operation was skipped or failed.
  static Future<String?> addEvent(
    Reminder reminder,
    String kidName, {
    required bool isAppleUser,
    GoogleSignIn? googleSignIn,
  }) async {
    try {
      if (kIsWeb) {
        if (googleSignIn == null) return null;
        return await _googleCalAdd(reminder, kidName, googleSignIn);
      }
      return await _deviceCalAdd(reminder, kidName);
    } catch (e) {
      debugPrint('[CalendarService] addEvent failed: $e');
      return null;
    }
  }

  /// Updates an existing calendar event.
  static Future<void> updateEvent(
    String calendarEventId,
    Reminder reminder,
    String kidName, {
    required bool isAppleUser,
    GoogleSignIn? googleSignIn,
  }) async {
    try {
      if (kIsWeb) {
        if (googleSignIn == null) return;
        await _googleCalUpdate(calendarEventId, reminder, kidName, googleSignIn);
      } else {
        await _deviceCalUpdate(calendarEventId, reminder, kidName);
      }
    } catch (e) {
      debugPrint('[CalendarService] updateEvent failed: $e');
    }
  }

  /// Removes a calendar event.
  static Future<void> deleteEvent(
    String calendarEventId, {
    required bool isAppleUser,
    GoogleSignIn? googleSignIn,
  }) async {
    try {
      if (kIsWeb) {
        if (googleSignIn == null) return;
        await _googleCalDelete(calendarEventId, googleSignIn);
      } else {
        await _deviceCalDelete(calendarEventId);
      }
    } catch (e) {
      debugPrint('[CalendarService] deleteEvent failed: $e');
    }
  }

  // ── device_calendar (iOS / Android) ──────────────────────────────────────

  static Future<String?> _deviceCalAdd(Reminder reminder, String kidName) async {
    final perms = await _plugin.requestPermissions();
    if (perms.data != true) return null;
    final calId = await _defaultCalendarId();
    if (calId == null) return null;
    final result = await _plugin.createOrUpdateEvent(
        _buildDeviceEvent(calId, reminder, kidName));
    return (result?.isSuccess == true) ? result!.data : null;
  }

  static Future<void> _deviceCalUpdate(
      String eventId, Reminder reminder, String kidName) async {
    final perms = await _plugin.requestPermissions();
    if (perms.data != true) return;
    final calId = await _defaultCalendarId();
    if (calId == null) return;
    await _plugin.createOrUpdateEvent(
        _buildDeviceEvent(calId, reminder, kidName, existingId: eventId));
  }

  static Future<void> _deviceCalDelete(String eventId) async {
    final perms = await _plugin.requestPermissions();
    if (perms.data != true) return;
    final calId = await _defaultCalendarId();
    if (calId == null) return;
    await _plugin.deleteEvent(calId, eventId);
  }

  static Future<String?> _defaultCalendarId() async {
    final result = await _plugin.retrieveCalendars();
    final calendars = result.data ?? [];
    return (calendars
            .where((c) => !(c.isReadOnly ?? true) && (c.isDefault ?? false))
            .firstOrNull ??
        calendars.where((c) => !(c.isReadOnly ?? true)).firstOrNull)?.id;
  }

  static Event _buildDeviceEvent(
    String calendarId,
    Reminder reminder,
    String kidName, {
    String? existingId,
  }) {
    final start = TZDateTime.from(reminder.dateTime, tz.local);
    final end = start.add(const Duration(hours: 1));

    RecurrenceRule? recurrence;
    if (reminder.repeat != ReminderRepeat.none) {
      recurrence = RecurrenceRule(
        switch (reminder.repeat) {
          ReminderRepeat.daily => RecurrenceFrequency.Daily,
          ReminderRepeat.weekly => RecurrenceFrequency.Weekly,
          ReminderRepeat.monthly => RecurrenceFrequency.Monthly,
          ReminderRepeat.yearly => RecurrenceFrequency.Yearly,
          ReminderRepeat.none => RecurrenceFrequency.Daily,
        },
      );
    }

    return Event(
      calendarId,
      eventId: existingId,
      title: '${reminder.type.emoji} ${reminder.title} · $kidName',
      description: reminder.notes,
      start: start,
      end: end,
      recurrenceRule: recurrence,
    );
  }

  // ── Google Calendar API (web) ─────────────────────────────────────────────

  static Future<gcal.CalendarApi?> _gcalApi(GoogleSignIn gs) async {
    final hasScope = await gs.canAccessScopes([_calendarScope]);
    if (!hasScope) {
      final granted = await gs.requestScopes([_calendarScope]);
      if (!granted) return null;
    }
    final client = await gs.authenticatedClient();
    if (client == null) return null;
    return gcal.CalendarApi(client);
  }

  static Future<String?> _googleCalAdd(
      Reminder reminder, String kidName, GoogleSignIn gs) async {
    final api = await _gcalApi(gs);
    if (api == null) return null;
    final created = await api.events.insert(_buildGoogleEvent(reminder, kidName), 'primary');
    return created.id;
  }

  static Future<void> _googleCalUpdate(
      String eventId, Reminder reminder, String kidName, GoogleSignIn gs) async {
    final api = await _gcalApi(gs);
    if (api == null) return;
    await api.events.update(_buildGoogleEvent(reminder, kidName), 'primary', eventId);
  }

  static Future<void> _googleCalDelete(String eventId, GoogleSignIn gs) async {
    final api = await _gcalApi(gs);
    if (api == null) return;
    await api.events.delete('primary', eventId);
  }

  static gcal.Event _buildGoogleEvent(Reminder reminder, String kidName) {
    final rrule = switch (reminder.repeat) {
      ReminderRepeat.none => null,
      ReminderRepeat.daily => 'RRULE:FREQ=DAILY',
      ReminderRepeat.weekly => 'RRULE:FREQ=WEEKLY',
      ReminderRepeat.monthly => 'RRULE:FREQ=MONTHLY',
      ReminderRepeat.yearly => 'RRULE:FREQ=YEARLY',
    };
    return gcal.Event()
      ..summary = '${reminder.type.emoji} ${reminder.title} · $kidName'
      ..description = reminder.notes
      ..start = gcal.EventDateTime(dateTime: reminder.dateTime)
      ..end = gcal.EventDateTime(
          dateTime: reminder.dateTime.add(const Duration(hours: 1)))
      ..recurrence = rrule != null ? [rrule] : null;
  }
}
