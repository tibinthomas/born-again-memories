import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/reminder.dart';

void main() {
  test('exact alarm preference survives JSON serialization', () {
    final reminder = Reminder(
      id: 'reminder-1',
      title: 'Appointment',
      dateTime: DateTime(2026, 8, 7, 9),
      useExactAlarm: true,
    );

    final decoded = Reminder.fromJson(reminder.toJson());

    expect(decoded.useExactAlarm, isTrue);
  });

  test('legacy reminders default to inexact scheduling', () {
    final reminder = Reminder.fromJson({
      'id': 'legacy-reminder',
      'title': 'Legacy',
      'dateTime': '2026-08-07T09:00:00.000',
    });

    expect(reminder.useExactAlarm, isFalse);
  });
}
