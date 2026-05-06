import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../models/connection.dart';

class ConnectionService {
  static final _db = FirebaseFirestore.instance;
  static final _col = _db.collection('connections');

  static Future<void> sendInvite({
    required String fromUid,
    required String fromName,
    required String fromPhotoUrl,
    required String toEmail,
  }) async {
    final email = toEmail.trim().toLowerCase();
    if (email.isEmpty) return;

    // Guard: don't invite yourself
    final selfDoc = await _db.doc('users/$fromUid').get();
    if ((selfDoc.data()?['email'] as String? ?? '') == email) return;

    // Guard: connection already exists
    final existing = await _col
        .where('fromUid', isEqualTo: fromUid)
        .where('toEmail', isEqualTo: email)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    // Check if target user is already registered
    final userSnap = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    String? toUid;
    String? toName;
    String? toPhotoUrl;
    List<String> members = [fromUid];

    if (userSnap.docs.isNotEmpty) {
      final data = userSnap.docs.first.data();
      toUid = userSnap.docs.first.id;
      toName = data['displayName'] as String?;
      toPhotoUrl = data['photoUrl'] as String?;
      members = [fromUid, toUid];
    }

    final ref = _col.doc();
    await ref.set({
      'fromUid': fromUid,
      'fromName': fromName,
      'fromPhotoUrl': fromPhotoUrl,
      'toEmail': email,
      'toUid': toUid,
      'toName': toName,
      'toPhotoUrl': toPhotoUrl,
      'members': members,
      'status': ConnectionStatus.pending.name,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Notify the recipient if already registered
    if (toUid != null) {
      await _db.collection('notifications/$toUid/items').add({
        'type': NotificationType.connectionRequest.name,
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'connectionId': ref.id,
        'isRead': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  static Future<void> accept({
    required String connectionId,
    required String toUid,
    required String toName,
    required String toPhotoUrl,
  }) async {
    final ref = _col.doc(connectionId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final fromUid = doc.data()!['fromUid'] as String;
    await ref.update({
      'toUid': toUid,
      'toName': toName,
      'toPhotoUrl': toPhotoUrl,
      'members': [fromUid, toUid],
      'status': ConnectionStatus.accepted.name,
    });

    // Notify the original sender
    await _db.collection('notifications/$fromUid/items').add({
      'type': NotificationType.connectionRequest.name,
      'fromUid': toUid,
      'fromName': toName,
      'fromPhotoUrl': toPhotoUrl,
      'connectionId': connectionId,
      'isRead': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> decline(String connectionId) =>
      _col.doc(connectionId).update({'status': ConnectionStatus.declined.name});

  static Future<void> remove(String connectionId) =>
      _col.doc(connectionId).delete();

  static Stream<List<Connection>> myConnectionsStream(String uid) =>
      _col
          .where('members', arrayContains: uid)
          .where('status', isEqualTo: ConnectionStatus.accepted.name)
          .snapshots()
          .map((s) => s.docs
              .map((d) => Connection.fromMap(d.id, d.data()))
              .toList());

  static Stream<List<Connection>> receivedRequestsStream(String uid) =>
      _col
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: ConnectionStatus.pending.name)
          .snapshots()
          .map((s) => s.docs
              .map((d) => Connection.fromMap(d.id, d.data()))
              .toList());

  static Stream<List<Connection>> sentRequestsStream(String uid) =>
      _col
          .where('fromUid', isEqualTo: uid)
          .where('status', isEqualTo: ConnectionStatus.pending.name)
          .snapshots()
          .map((s) => s.docs
              .map((d) => Connection.fromMap(d.id, d.data()))
              .toList());

  // Called on sign-in: link any pending invites sent to this email
  static Future<void> claimPendingInvites({
    required String uid,
    required String email,
    required String displayName,
    required String photoUrl,
  }) async {
    final snap = await _col
        .where('toEmail', isEqualTo: email.toLowerCase())
        .where('status', isEqualTo: ConnectionStatus.pending.name)
        .get();
    if (snap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snap.docs) {
      final fromUid = doc.data()['fromUid'] as String;
      batch.update(doc.reference, {
        'toUid': uid,
        'toName': displayName,
        'toPhotoUrl': photoUrl,
        'members': [fromUid, uid],
      });
    }
    await batch.commit();
  }
}
