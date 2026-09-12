import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/notification_service.dart';

void main() {
  test('reminder notification target round-trips through its payload', () {
    const target = ReminderNotificationTarget(
      profileId: 'profile-2',
      reminderId: 'reminder-7',
    );

    final decoded = ReminderNotificationTarget.fromPayload(target.toPayload());

    expect(decoded?.profileId, 'profile-2');
    expect(decoded?.reminderId, 'reminder-7');
  });

  test('non-reminder and malformed notification payloads are ignored', () {
    expect(ReminderNotificationTarget.fromPayload(null), isNull);
    expect(ReminderNotificationTarget.fromPayload('not-json'), isNull);
    expect(
      ReminderNotificationTarget.fromPayload('{"type":"shared-memory"}'),
      isNull,
    );
  });
}
