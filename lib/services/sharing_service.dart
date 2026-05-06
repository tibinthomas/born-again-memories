import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_notification.dart';
import '../models/attachment.dart';
import '../models/comment.dart';
import '../models/connection.dart';
import '../models/shared_memory.dart';
import 'drive_service.dart';

class SharingService {
  static final _db = FirebaseFirestore.instance;

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
    // Make each backed-up image/video publicly readable via Drive link
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

    final visibleTo = [fromUid, ...sharedWithUids];
    final now = DateTime.now().millisecondsSinceEpoch;

    final ref = _db.collection('shared_memories').doc();
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
      'visibleTo': visibleTo,
      'likedByUids': [],
      'commentCount': 0,
      'createdAt': now,
    });

    // Notify each recipient
    for (final uid in sharedWithUids) {
      await _db.collection('notifications/$uid/items').add({
        'type': NotificationType.sharedMemory.name,
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'memoryId': ref.id,
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
    await _db.doc('shared_memories/$memoryId').update({
      'likedByUids': currentlyLiked
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid]),
    });
    if (!currentlyLiked && ownerUid != uid) {
      await _db.collection('notifications/$ownerUid/items').add({
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

  static Future<void> addComment({
    required String memoryId,
    required String fromUid,
    required String fromName,
    required String? fromPhotoUrl,
    required String text,
    required String ownerUid,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _db.batch();
    final commentRef =
        _db.collection('shared_memories/$memoryId/comments').doc();
    batch.set(commentRef, {
      'fromUid': fromUid,
      'fromName': fromName,
      'fromPhotoUrl': fromPhotoUrl,
      'text': text,
      'createdAt': now,
    });
    batch.update(_db.doc('shared_memories/$memoryId'), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();

    if (ownerUid != fromUid) {
      await _db.collection('notifications/$ownerUid/items').add({
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

  static Stream<List<Comment>> commentsStream(String memoryId) => _db
      .collection('shared_memories/$memoryId/comments')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs
          .map((d) => Comment.fromMap(d.id, d.data()))
          .toList());

  static Stream<List<SharedMemory>> feedStream(String uid) => _db
      .collection('shared_memories')
      .where('visibleTo', arrayContains: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs
          .map((d) => SharedMemory.fromMap(d.id, d.data()))
          .toList());

  static Future<void> markNotificationsRead(String uid) async {
    final snap = await _db
        .collection('notifications/$uid/items')
        .where('isRead', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
