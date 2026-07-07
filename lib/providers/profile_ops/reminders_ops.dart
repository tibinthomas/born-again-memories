import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/kid_profile.dart';
import '../../models/reminder.dart';
import '../../services/calendar_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../auth_provider.dart';
import 'profile_mutations.dart';

mixin RemindersOps on StateNotifier<List<KidProfile>?>, ProfileMutations {
  Future<void> addReminder(int profileIndex, Reminder reminder) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final auth = ref.read(authServiceProvider);
    final calId = await CalendarService.addEvent(
      reminder, profile.name,
      isAppleUser: auth.isAppleUser,
      googleSignIn: auth.googleSignIn,
    );
    final r = calId != null ? reminder.copyWith(calendarEventId: calId) : reminder;
    setProfile(profileIndex, profile.copyWith(reminders: [...profile.reminders, r]));
    await FirestoreService.saveReminder(uid, profile.id, r);
    await NotificationService.scheduleReminder(r, profile.name);
  }

  Future<void> addReminderToProfiles(List<int> profileIndices, Reminder reminder) async {
    final auth = ref.read(authServiceProvider);
    for (final profileIndex in profileIndices) {
      final profile = (state ?? <KidProfile>[])[profileIndex];
      final calId = await CalendarService.addEvent(
        reminder, profile.name,
        isAppleUser: auth.isAppleUser,
        googleSignIn: auth.googleSignIn,
      );
      final r = calId != null ? reminder.copyWith(calendarEventId: calId) : reminder;
      setProfile(profileIndex, profile.copyWith(reminders: [...profile.reminders, r]));
      await FirestoreService.saveReminder(uid, profile.id, r);
      await NotificationService.scheduleReminder(r, profile.name);
    }
  }

  Future<void> updateReminder(int profileIndex, Reminder reminder) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final auth = ref.read(authServiceProvider);
    Reminder r = reminder;
    if (reminder.calendarEventId != null) {
      await CalendarService.updateEvent(
        reminder.calendarEventId!, reminder, profile.name,
        isAppleUser: auth.isAppleUser,
        googleSignIn: auth.googleSignIn,
      );
    } else {
      final calId = await CalendarService.addEvent(
        reminder, profile.name,
        isAppleUser: auth.isAppleUser,
        googleSignIn: auth.googleSignIn,
      );
      if (calId != null) r = reminder.copyWith(calendarEventId: calId);
    }
    final reminders = profile.reminders.map((e) => e.id == r.id ? r : e).toList();
    setProfile(profileIndex, profile.copyWith(reminders: reminders));
    await FirestoreService.saveReminder(uid, profile.id, r);
    await NotificationService.cancelReminder(r.id);
    await NotificationService.scheduleReminder(r, profile.name);
  }

  Future<void> deleteReminder(int profileIndex, String reminderId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final reminder = profile.reminders.where((r) => r.id == reminderId).firstOrNull;
    if (reminder?.calendarEventId != null) {
      final auth = ref.read(authServiceProvider);
      await CalendarService.deleteEvent(
        reminder!.calendarEventId!,
        isAppleUser: auth.isAppleUser,
        googleSignIn: auth.googleSignIn,
      );
    }
    setProfile(profileIndex,
        profile.copyWith(reminders: profile.reminders.where((r) => r.id != reminderId).toList()));
    await FirestoreService.deleteReminder(uid, profile.id, reminderId);
    await NotificationService.cancelReminder(reminderId);
  }

  Future<void> markReminderDone(int profileIndex, String reminderId, bool done) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final reminders = profile.reminders
        .map((r) => r.id == reminderId ? r.copyWith(isDone: done) : r)
        .toList();
    setProfile(profileIndex, profile.copyWith(reminders: reminders));
    final reminder = reminders.firstWhere((r) => r.id == reminderId);
    await FirestoreService.saveReminder(uid, profile.id, reminder);
    if (done) {
      await NotificationService.cancelReminder(reminderId);
    } else {
      await NotificationService.scheduleReminder(reminder, profile.name);
    }
  }

  Future<void> muteReminder(int profileIndex, String reminderId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final reminders = profile.reminders
        .map((r) => r.id == reminderId ? r.copyWith(isMuted: true) : r)
        .toList();
    setProfile(profileIndex, profile.copyWith(reminders: reminders));
    final reminder = reminders.firstWhere((r) => r.id == reminderId);
    await FirestoreService.saveReminder(uid, profile.id, reminder);
    await NotificationService.cancelReminder(reminderId);
  }

  Future<void> unmuteReminder(int profileIndex, String reminderId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final reminders = profile.reminders
        .map((r) => r.id == reminderId ? r.copyWith(isMuted: false) : r)
        .toList();
    setProfile(profileIndex, profile.copyWith(reminders: reminders));
    final reminder = reminders.firstWhere((r) => r.id == reminderId);
    await FirestoreService.saveReminder(uid, profile.id, reminder);
    await NotificationService.scheduleReminder(reminder, profile.name);
  }
}
