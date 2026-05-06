import 'package:firebase_database/firebase_database.dart';
import '../models/app_notification.dart';
import '../models/connection.dart';

class ConnectionService {
  static final _db = FirebaseDatabase.instance;

  static Future<void> sendInvite({
    required String fromUid,
    required String fromName,
    required String fromPhotoUrl,
    required String toEmail,
  }) async {
    final email = toEmail.trim().toLowerCase();
    if (email.isEmpty) return;

    // Guard: don't send to yourself
    final self = await _db.ref('users/$fromUid').get();
    final selfEmail =
        (self.value as Map?)?['email'] as String? ?? '';
    if (selfEmail == email) return;

    // Guard: connection already exists (sent by this user to this email)
    final existSnap = await _db
        .ref('connections')
        .orderByChild('fromUid_toEmail')
        .equalTo('${fromUid}_$email')
        .get();
    if (existSnap.exists && existSnap.value != null) return;

    // Check if target is already a registered user
    final userSnap = await _db
        .ref('users')
        .orderByChild('email')
        .equalTo(email)
        .get();

    String? toUid;
    String? toName;
    String? toPhotoUrl;

    if (userSnap.exists && userSnap.value != null) {
      final users = userSnap.children.toList();
      if (users.isNotEmpty) {
        toUid = users.first.key;
        final ud = Map<String, dynamic>.from(users.first.value as Map);
        toName = ud['displayName'] as String?;
        toPhotoUrl = ud['photoUrl'] as String?;
      }
    }

    // Write connection document
    final ref = _db.ref('connections').push();
    final connId = ref.key!;
    await ref.set({
      'fromUid': fromUid,
      'fromName': fromName,
      'fromPhotoUrl': fromPhotoUrl,
      'toEmail': email,
      'toUid': toUid,
      'toName': toName,
      'toPhotoUrl': toPhotoUrl,
      // Composite key for duplicate-check query
      'fromUid_toEmail': '${fromUid}_$email',
      'status': ConnectionStatus.pending.name,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Fan-out: track in sender's sent list
    await _db.ref('userSentRequests/$fromUid/$connId').set(true);

    // If recipient is registered, add to their pending list + notify
    if (toUid != null) {
      await _db.ref('userPendingRequests/$toUid/$connId').set(true);
      await _db.ref('notifications/$toUid').push().set({
        'type': NotificationType.connectionRequest.name,
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'connectionId': connId,
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
    final snap = await _db.ref('connections/$connectionId').get();
    if (!snap.exists || snap.value == null) return;

    final data = Map<String, dynamic>.from(snap.value as Map);
    final fromUid = data['fromUid'] as String;

    // Update connection doc
    await _db.ref('connections/$connectionId').update({
      'toUid': toUid,
      'toName': toName,
      'toPhotoUrl': toPhotoUrl,
      'status': ConnectionStatus.accepted.name,
    });

    // Fan-out: move from pending/sent lists to connected lists
    await Future.wait([
      _db.ref('userPendingRequests/$toUid/$connectionId').remove(),
      _db.ref('userSentRequests/$fromUid/$connectionId').remove(),
      _db.ref('userConnections/$fromUid/$connectionId').set(true),
      _db.ref('userConnections/$toUid/$connectionId').set(true),
    ]);

    // Notify the sender
    await _db.ref('notifications/$fromUid').push().set({
      'type': NotificationType.connectionRequest.name,
      'fromUid': toUid,
      'fromName': toName,
      'fromPhotoUrl': toPhotoUrl,
      'connectionId': connectionId,
      'isRead': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> decline(String connectionId) async {
    final snap = await _db.ref('connections/$connectionId').get();
    if (!snap.exists || snap.value == null) return;
    final data = Map<String, dynamic>.from(snap.value as Map);
    final toUid = data['toUid'] as String?;
    final fromUid = data['fromUid'] as String;

    await _db.ref('connections/$connectionId/status')
        .set(ConnectionStatus.declined.name);
    await Future.wait([
      if (toUid != null)
        _db.ref('userPendingRequests/$toUid/$connectionId').remove(),
      _db.ref('userSentRequests/$fromUid/$connectionId').remove(),
    ]);
  }

  static Future<void> remove(String connectionId) async {
    final snap = await _db.ref('connections/$connectionId').get();
    if (!snap.exists || snap.value == null) return;
    final data = Map<String, dynamic>.from(snap.value as Map);
    final fromUid = data['fromUid'] as String;
    final toUid = data['toUid'] as String?;

    await Future.wait([
      _db.ref('connections/$connectionId').remove(),
      _db.ref('userConnections/$fromUid/$connectionId').remove(),
      if (toUid != null)
        _db.ref('userConnections/$toUid/$connectionId').remove(),
    ]);
  }

  // Stream of accepted connections — fetches each connection doc on change
  static Stream<List<Connection>> myConnectionsStream(String uid) =>
      _db.ref('userConnections/$uid').onValue.asyncMap((event) async {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          return [];
        }
        final ids =
            (event.snapshot.value as Map).keys.cast<String>().toList();
        final snaps = await Future.wait(
            ids.map((id) => _db.ref('connections/$id').get()));
        return snaps
            .where((s) => s.exists && s.value != null)
            .map((s) => Connection.fromMap(
                s.key!, s.value as Map<Object?, Object?>))
            .toList();
      });

  // Stream of pending requests where the current user is the recipient
  static Stream<List<Connection>> receivedRequestsStream(String uid) =>
      _db.ref('userPendingRequests/$uid').onValue.asyncMap((event) async {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          return [];
        }
        final ids =
            (event.snapshot.value as Map).keys.cast<String>().toList();
        final snaps = await Future.wait(
            ids.map((id) => _db.ref('connections/$id').get()));
        return snaps
            .where((s) => s.exists && s.value != null)
            .map((s) => Connection.fromMap(
                s.key!, s.value as Map<Object?, Object?>))
            .toList();
      });

  // Stream of requests sent by the current user (still pending)
  static Stream<List<Connection>> sentRequestsStream(String uid) =>
      _db.ref('userSentRequests/$uid').onValue.asyncMap((event) async {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          return [];
        }
        final ids =
            (event.snapshot.value as Map).keys.cast<String>().toList();
        final snaps = await Future.wait(
            ids.map((id) => _db.ref('connections/$id').get()));
        return snaps
            .where((s) => s.exists && s.value != null)
            .map((s) => Connection.fromMap(
                s.key!, s.value as Map<Object?, Object?>))
            .toList();
      });

  // Called on sign-in: link pending invites sent to this email to this uid
  static Future<void> claimPendingInvites({
    required String uid,
    required String email,
    required String displayName,
    required String photoUrl,
  }) async {
    final snap = await _db
        .ref('connections')
        .orderByChild('toEmail')
        .equalTo(email.toLowerCase())
        .get();
    if (!snap.exists || snap.value == null) return;

    final updates = <String, dynamic>{};
    final pendingConnIds = <String>[];

    for (final child in snap.children) {
      final data = child.value as Map;
      if (data['status'] != ConnectionStatus.pending.name) continue;
      final connId = child.key!;
      updates['connections/$connId/toUid'] = uid;
      updates['connections/$connId/toName'] = displayName;
      updates['connections/$connId/toPhotoUrl'] = photoUrl;
      pendingConnIds.add(connId);
    }

    if (updates.isEmpty) return;
    await _db.ref().update(updates);

    // Add each claimed invite to the new user's pending requests
    for (final connId in pendingConnIds) {
      await _db.ref('userPendingRequests/$uid/$connId').set(true);
    }
  }
}
