import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_notification.dart';
import '../models/attachment.dart';
import '../models/comment.dart';
import '../models/connection.dart';
import '../models/shared_memory.dart';
import 'drive_service.dart';

class SharingService {
  static final _db = FirebaseDatabase.instance;

  static Future<void> shareMemory({
    required GoogleSignIn googleSignIn,
    required String fromUid,
    required String fromName,
    required String fromPhotoUrl,
    required String kidName,
    required String milestoneTitle,
    required String milestoneDescription,
    required DateTime milestoneDate,
    required Color milestoneColor,
    required List<Attachment> attachments,
    required List<Connection> connections,
  }) async {
    final media = <Map<String, dynamic>>[];
    for (final a in attachments) {
      if (a.driveFileId == null) continue;
      if (a.type != AttachmentType.image && a.type != AttachmentType.video) {
        continue;
      }
      try {
        final url =
            await DriveService.makeShareable(googleSignIn, a.driveFileId!);
        media.add(SharedMemoryMedia(
          driveFileId: a.driveFileId!,
          thumbnailUrl: url,
          type: a.type,
        ).toJson());
      } catch (_) {}
    }

    final sharedWithUids = connections
        .map((c) => c.otherUid(fromUid))
        .where((uid) => uid.isNotEmpty)
        .toList();

    final now = DateTime.now().millisecondsSinceEpoch;
    final ref = _db.ref('sharedMemories').push();
    final memoryId = ref.key!;

    await ref.set({
      'fromUid': fromUid,
      'fromName': fromName,
      'fromPhotoUrl': fromPhotoUrl,
      'kidName': kidName,
      'milestoneTitle': milestoneTitle,
      'milestoneDescription': milestoneDescription,
      'milestoneDate': milestoneDate.toIso8601String(),
      'milestoneColor': milestoneColor.toARGB32(),
      'media': media,
      'likedBy': {},
      'commentCount': 0,
      'createdAt': now,
    });

    // Fan-out: add to sender's feed + each recipient's feed
    final feedEntry = {'createdAt': now};
    final feedUpdates = <String, dynamic>{
      'userFeed/$fromUid/$memoryId': feedEntry,
    };
    for (final uid in sharedWithUids) {
      feedUpdates['userFeed/$uid/$memoryId'] = feedEntry;
    }
    await _db.ref().update(feedUpdates);

    // Notify each recipient
    for (final uid in sharedWithUids) {
      await _db.ref('notifications/$uid').push().set({
        'type': NotificationType.sharedMemory.name,
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'memoryId': memoryId,
        'isRead': false,
        'createdAt': now,
      });
    }
  }

  static Future<void> toggleLike({
    required String memoryId,
    required String uid,
    required String fromName,
    required String fromPhotoUrl,
    required bool currentlyLiked,
    required String ownerUid,
  }) async {
    final likeRef = _db.ref('sharedMemories/$memoryId/likedBy/$uid');
    if (currentlyLiked) {
      await likeRef.remove();
    } else {
      await likeRef.set(true);
      if (ownerUid != uid) {
        await _db.ref('notifications/$ownerUid').push().set({
          'type': NotificationType.like.name,
          'fromUid': uid,
          'fromName': fromName,
          'fromPhotoUrl': fromPhotoUrl,
          'memoryId': memoryId,
          'isRead': false,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
  }

  static Future<void> addComment({
    required String memoryId,
    required String fromUid,
    required String fromName,
    required String? fromPhotoUrl,
    required String text,
    required String ownerUid,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.ref('comments/$memoryId').push().set({
      'fromUid': fromUid,
      'fromName': fromName,
      'fromPhotoUrl': fromPhotoUrl,
      'text': text,
      'createdAt': now,
    });
    // Atomic increment
    await _db
        .ref('sharedMemories/$memoryId/commentCount')
        .set(ServerValue.increment(1));

    if (ownerUid != fromUid) {
      await _db.ref('notifications/$ownerUid').push().set({
        'type': NotificationType.comment.name,
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'memoryId': memoryId,
        'isRead': false,
        'createdAt': now,
      });
    }
  }

  static Stream<List<Comment>> commentsStream(String memoryId) =>
      _db
          .ref('comments/$memoryId')
          .orderByChild('createdAt')
          .onValue
          .map((event) {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          return [];
        }
        return event.snapshot.children
            .map((c) => Comment.fromMap(c.key!, c.value as Map<Object?, Object?>))
            .toList();
      });

  // Feed: sorted by createdAt desc via userFeed fan-out index
  static Stream<List<SharedMemory>> feedStream(String uid) =>
      _db
          .ref('userFeed/$uid')
          .orderByChild('createdAt')
          .limitToLast(50)
          .onValue
          .asyncMap((event) async {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          return [];
        }
        // children are in ascending order — reverse for newest-first
        final memoryIds =
            event.snapshot.children.map((c) => c.key!).toList().reversed;
        final snaps = await Future.wait(
            memoryIds.map((id) => _db.ref('sharedMemories/$id').get()));
        return snaps
            .where((s) => s.exists && s.value != null)
            .map((s) => SharedMemory.fromMap(
                s.key!, s.value as Map<Object?, Object?>))
            .toList();
      });

  static Future<void> markNotificationsRead(String uid) async {
    final snap = await _db.ref('notifications/$uid').get();
    if (!snap.exists || snap.value == null) return;
    final updates = <String, dynamic>{};
    for (final child in snap.children) {
      if (child.value is Map &&
          (child.value as Map)['isRead'] == false) {
        updates['notifications/$uid/${child.key}/isRead'] = true;
      }
    }
    if (updates.isNotEmpty) await _db.ref().update(updates);
  }
}
