import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';

class DatabaseService {
  static final _db = FirebaseDatabase.instance;

  // ── User profile ───────────────────────────────────────────────────────────

  static Future<void> saveUserProfile(String uid, Map<String, dynamic> data) =>
      _db.ref('users/$uid').update(data);

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snap = await _db.ref('users/$uid').get();
    if (!snap.exists || snap.value == null) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  static Future<AppSettings> loadSettings(String uid) async {
    final snap = await _db.ref('settings/$uid').get();
    if (!snap.exists || snap.value == null) return AppSettings();
    return AppSettings.fromJson(
        Map<String, dynamic>.from(snap.value as Map));
  }

  static Future<void> saveSettings(String uid, AppSettings settings) =>
      _db.ref('settings/$uid').set(settings.toJson());

  // ── Profiles ───────────────────────────────────────────────────────────────

  static Future<List<KidProfile>> loadProfiles(String uid) async {
    final snap = await _db.ref('profiles/$uid').get();
    if (!snap.exists || snap.value == null) return [];

    final profilesMap = Map<String, dynamic>.from(snap.value as Map);
    final profiles = <KidProfile>[];
    for (final entry in profilesMap.entries) {
      final profileData =
          Map<String, dynamic>.from(entry.value as Map);
      final profile = KidProfile.fromJson(profileData);
      final milestones = await _loadMilestones(uid, profile.id);
      profiles.add(profile.copyWith(milestones: milestones));
    }
    return profiles;
  }

  static Future<List<Milestone>> _loadMilestones(
      String uid, String profileId) async {
    final snap = await _db.ref('milestones/$uid/$profileId').get();
    if (!snap.exists || snap.value == null) return [];

    final map = Map<String, dynamic>.from(snap.value as Map);
    final milestones = map.values
        .whereType<Map>()
        .map((v) => Milestone.fromJson(Map<String, dynamic>.from(v)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return milestones;
  }

  static Future<void> saveProfile(String uid, KidProfile profile) =>
      _db.ref('profiles/$uid/${profile.id}').set(profile.toJson());

  static Future<void> deleteProfile(String uid, String profileId) =>
      Future.wait([
        _db.ref('profiles/$uid/$profileId').remove(),
        _db.ref('milestones/$uid/$profileId').remove(),
      ]);

  static Future<void> saveMilestone(
          String uid, String profileId, Milestone milestone) =>
      _db
          .ref('milestones/$uid/$profileId/${milestone.id}')
          .set(milestone.toJson());

  static Future<void> deleteMilestone(
          String uid, String profileId, String milestoneId) =>
      _db.ref('milestones/$uid/$profileId/$milestoneId').remove();

  // Updates only the driveFileId + backupStatus of a single attachment.
  // Attachments are stored as a keyed map so this write is surgical.
  static Future<void> updateAttachmentBackup({
    required String uid,
    required String profileId,
    required String milestoneId,
    required String attachmentId,
    required String? driveFileId,
    required BackupStatus status,
  }) =>
      _db
          .ref('milestones/$uid/$profileId/$milestoneId/attachments/$attachmentId')
          .update({
        'driveFileId': driveFileId,
        'backupStatus': status.name,
      });

  // ── Drive stats ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getDriveStats(String uid) async {
    final snap = await _db.ref('driveStats/$uid').get();
    if (!snap.exists || snap.value == null) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  static Future<void> updateDriveStats(
          String uid, Map<String, dynamic> data) =>
      _db.ref('driveStats/$uid').update(data);

  // ── Theme color helper (legacy key migration) ──────────────────────────────

  static Color? colorFromRtdb(Object? value) {
    if (value == null) return null;
    final n = value as num?;
    if (n == null) return null;
    return Color(n.toInt());
  }
}
