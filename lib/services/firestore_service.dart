import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_settings.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../models/reminder.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── User profile ───────────────────────────────────────────────────────────

  static Future<void> saveUserProfile(String uid, Map<String, dynamic> data) =>
      _db.doc('users/$uid').set(data, SetOptions(merge: true));

  static Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final doc = await _db.doc('users/$uid').get();
    return doc.data();
  }

  static Future<void> updateUserDoc(String uid, Map<String, dynamic> data) =>
      _db.doc('users/$uid').set(data, SetOptions(merge: true));

  // ── Settings ───────────────────────────────────────────────────────────────

  static Future<AppSettings> loadSettings(String uid) async {
    final doc = await _db.doc('users/$uid/data/settings').get();
    if (!doc.exists) return AppSettings();
    return AppSettings.fromJson(doc.data()!);
  }

  static Future<void> saveSettings(String uid, AppSettings settings) =>
      _db.doc('users/$uid/data/settings').set(settings.toJson());

  // ── Profiles ───────────────────────────────────────────────────────────────

  static Future<List<KidProfile>> loadProfiles(String uid) async {
    final snap = await _db.collection('users/$uid/profiles').get();
    final profiles = <KidProfile>[];
    for (final doc in snap.docs) {
      final profile = KidProfile.fromJson(doc.data());
      final (milestones, reminders) = await (
        _loadMilestones(uid, profile.id),
        _loadReminders(uid, profile.id),
      ).wait;
      profiles.add(profile.copyWith(milestones: milestones, reminders: reminders));
    }
    return profiles;
  }

  static Future<List<Milestone>> _loadMilestones(
      String uid, String profileId) async {
    final snap = await _db
        .collection('users/$uid/profiles/$profileId/milestones')
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => Milestone.fromJson(d.data())).toList();
  }

  static Future<List<Reminder>> _loadReminders(
      String uid, String profileId) async {
    final snap = await _db
        .collection('users/$uid/profiles/$profileId/reminders')
        .orderBy('dateTime')
        .get();
    return snap.docs.map((d) => Reminder.fromJson(d.data())).toList();
  }

  static Future<void> saveProfile(String uid, KidProfile profile) =>
      _db.doc('users/$uid/profiles/${profile.id}').set(profile.toJson());

  static Future<void> deleteProfile(String uid, String profileId) async {
    final msSnap = await _db
        .collection('users/$uid/profiles/$profileId/milestones')
        .get();
    final batch = _db.batch();
    for (final doc in msSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.doc('users/$uid/profiles/$profileId'));
    await batch.commit();
  }

  static Future<void> saveMilestone(
          String uid, String profileId, Milestone milestone) =>
      _db
          .doc('users/$uid/profiles/$profileId/milestones/${milestone.id}')
          .set(milestone.toJson());

  static Future<void> deleteMilestone(
          String uid, String profileId, String milestoneId) =>
      _db
          .doc('users/$uid/profiles/$profileId/milestones/$milestoneId')
          .delete();

  // ── Reminders ──────────────────────────────────────────────────────────────

  static Future<void> saveReminder(
          String uid, String profileId, Reminder reminder) =>
      _db
          .doc('users/$uid/profiles/$profileId/reminders/${reminder.id}')
          .set(reminder.toJson());

  static Future<void> deleteReminder(
          String uid, String profileId, String reminderId) =>
      _db
          .doc('users/$uid/profiles/$profileId/reminders/$reminderId')
          .delete();

  // Atomic partial update — no full doc read required because attachments are
  // stored as a keyed map and Firestore supports dot-notation field paths.
  static Future<void> updateAttachmentBackup({
    required String uid,
    required String profileId,
    required String milestoneId,
    required String attachmentId,
    required String? driveFileId,
    required BackupStatus status,
  }) =>
      _db
          .doc('users/$uid/profiles/$profileId/milestones/$milestoneId')
          .update({
        'attachments.$attachmentId.driveFileId': driveFileId,
        'attachments.$attachmentId.backupStatus': status.name,
      });
}
