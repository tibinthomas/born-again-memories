import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class UgcSafetyService {
  static const termsVersion = '2026-07-31';
  static final _db = FirebaseFirestore.instance;

  static Future<bool> hasAcceptedTerms(String uid) async {
    final snap = await _db.doc('users/$uid/ugc/terms').get();
    return snap.data()?['version'] == termsVersion;
  }

  static Future<void> acceptTerms(String uid) =>
      _db.doc('users/$uid/ugc/terms').set({
        'version': termsVersion,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

  static Stream<Set<String>> blockedUserIds(String uid) => _db
      .collection('users/$uid/blockedUsers')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());

  static Future<void> blockUser({
    required String uid,
    required String blockedUid,
    required String blockedName,
  }) {
    if (uid == blockedUid) return Future.value();
    return _db.doc('users/$uid/blockedUsers/$blockedUid').set({
      'displayName': blockedName,
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> unblockUser(String uid, String blockedUid) =>
      _db.doc('users/$uid/blockedUsers/$blockedUid').delete();

  static Future<void> submitReport({
    required String reporterId,
    required String targetType,
    required String targetId,
    required String targetPath,
    required String authorId,
    required String reason,
    String details = '',
  }) {
    final reportId = '${reporterId}_${targetType}_$targetId'.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    return _db.doc('ugcReports/$reportId').set({
      'reporterId': reporterId,
      'targetType': targetType,
      'targetId': targetId,
      'targetPath': targetPath,
      'authorId': authorId,
      'reason': reason,
      if (details.trim().isNotEmpty) 'details': details.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
