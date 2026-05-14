import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_settings.dart';
import '../models/attachment.dart';
import '../models/baby_document.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../models/reminder.dart';
import '../models/saved_link.dart';
import '../models/shared_feed.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── User profile ───────────────────────────────────────────────────────────

  static Future<void> saveUserProfile(String uid, Map<String, dynamic> data) =>
      _db.doc('users/$uid').set(data, SetOptions(merge: true));

  /// Persists display name + email so other users can identify this account in
  /// their shared feed. Called once per login session.
  static Future<void> saveUserMeta(
      String uid, String email, String? displayName) =>
      _db.doc('users/$uid').set(
        {
          'email': email,
          if (displayName != null && displayName.isNotEmpty)
            'displayName': displayName,
        },
        SetOptions(merge: true),
      );

  static Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    final doc = await _db.doc('users/$uid').get();
    return doc.data();
  }

  static Future<void> updateUserDoc(String uid, Map<String, dynamic> data) =>
      _db.doc('users/$uid').set(data, SetOptions(merge: true));

  static Future<void> markAccountForDeletion({
    required String uid,
    required bool deleteDriveBackup,
  }) =>
      updateUserDoc(uid, {
        'deletedAt': DateTime.now().millisecondsSinceEpoch,
        'deleteDriveBackup': deleteDriveBackup,
      });

  static Future<void> recoverAccount(String uid) =>
      _db.doc('users/$uid').update({
        'deletedAt': FieldValue.delete(),
        'deleteDriveBackup': FieldValue.delete(),
      });

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
      final (milestones, reminders, documents, links) = await (
        _loadMilestones(uid, profile.id),
        _loadReminders(uid, profile.id),
        _loadDocuments(uid, profile.id),
        _loadLinks(uid, profile.id),
      ).wait;
      profiles.add(profile.copyWith(
        milestones: milestones,
        reminders: reminders,
        documents: documents,
        links: links,
      ));
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
    final docSnap = await _db
        .collection('users/$uid/profiles/$profileId/documents')
        .get();
    final linkSnap = await _db
        .collection('users/$uid/profiles/$profileId/links')
        .get();
    final batch = _db.batch();
    for (final doc in msSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in docSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in linkSnap.docs) {
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

  // ── Documents ─────────────────────────────────────────────────────────────

  static Future<List<BabyDocument>> _loadDocuments(
      String uid, String profileId) async {
    final snap = await _db
        .collection('users/$uid/profiles/$profileId/documents')
        .orderBy('dateAdded', descending: true)
        .get();
    return snap.docs.map((d) => BabyDocument.fromJson(d.data())).toList();
  }

  static Future<List<SavedLink>> _loadLinks(
      String uid, String profileId) async {
    final snap = await _db
        .collection('users/$uid/profiles/$profileId/links')
        .orderBy('dateAdded', descending: true)
        .get();
    return snap.docs.map((d) => SavedLink.fromJson(d.data())).toList();
  }

  static Future<void> saveDocument(
          String uid, String profileId, BabyDocument doc) =>
      _db
          .doc('users/$uid/profiles/$profileId/documents/${doc.id}')
          .set(doc.toJson());

  static Future<void> saveLink(
          String uid, String profileId, SavedLink link) =>
      _db
          .doc('users/$uid/profiles/$profileId/links/${link.id}')
          .set(link.toJson());

  static Future<void> deleteLink(
          String uid, String profileId, String linkId) =>
      _db
          .doc('users/$uid/profiles/$profileId/links/$linkId')
          .delete();

  static Future<void> deleteDocument(
          String uid, String profileId, String docId) =>
      _db
          .doc('users/$uid/profiles/$profileId/documents/$docId')
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

  // ── Share invite metadata ──────────────────────────────────────────────────

  /// Records when an invite was sent (or re-sent) for [email].
  static Future<void> setInviteSentAt(String uid, String email) =>
      _db.doc('users/$uid').set(
        {'inviteMeta': {email: {'sentAt': Timestamp.now()}}},
        SetOptions(merge: true),
      );

  static Future<void> removeInviteMeta(String uid, String email) =>
      _db.doc('users/$uid').update({'inviteMeta.$email': FieldValue.delete()});

  /// Returns true if a user account with [email] exists in Firestore.
  static Future<bool> isEmailRegistered(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Shared feed ────────────────────────────────────────────────────────────

  /// Returns all milestones from users who have added [myEmail] to their
  /// sharedWithEmails list, grouped by sender.
  static Future<List<SharedSenderGroup>> loadSharedFeed(String myEmail) async {
    final snap = await _db
        .collection('users')
        .where('sharedWithEmails', arrayContains: myEmail)
        .get();

    final groups = <SharedSenderGroup>[];
    for (final doc in snap.docs) {
      final uid = doc.id;
      final data = doc.data();
      final displayName =
          data['displayName'] as String? ?? data['email'] as String? ?? uid;
      final email = data['email'] as String? ?? '';

      final profilesSnap =
          await _db.collection('users/$uid/profiles').get();
      final entries = <SharedMilestoneEntry>[];

      await Future.wait(profilesSnap.docs.map((pDoc) async {
        final profile = KidProfile.fromJson(pDoc.data());
        final msSnap = await _db
            .collection('users/$uid/profiles/${profile.id}/milestones')
            .orderBy('date', descending: true)
            .get();
        for (final msDoc in msSnap.docs) {
          entries.add(SharedMilestoneEntry(
            milestone: Milestone.fromJson(msDoc.data()),
            babyName: profile.name,
            babyGender: profile.gender,
          ));
        }
      }));

      entries.sort((a, b) => b.milestone.date.compareTo(a.milestone.date));
      groups.add(SharedSenderGroup(
        uid: uid,
        displayName: displayName,
        email: email,
        milestones: entries,
      ));
    }
    return groups;
  }

  // Atomic partial update — no full doc read required because attachments are
  // stored as a keyed map and Firestore supports dot-notation field paths.
  static Future<void> updateAttachmentBackup({
    required String uid,
    required String profileId,
    required String milestoneId,
    required String attachmentId,
    required String? driveFileId,
    String? iCloudFileId,
    required BackupStatus status,
  }) =>
      _db
          .doc('users/$uid/profiles/$profileId/milestones/$milestoneId')
          .update({
        'attachments.$attachmentId.driveFileId': driveFileId,
        'attachments.$attachmentId.iCloudFileId': iCloudFileId,
        'attachments.$attachmentId.backupStatus': status.name,
      });
}
