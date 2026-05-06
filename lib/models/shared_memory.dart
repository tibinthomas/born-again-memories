import 'package:flutter/material.dart';
import 'attachment.dart';

class SharedMemoryMedia {
  final String driveFileId;
  final String thumbnailUrl;
  final AttachmentType type;

  const SharedMemoryMedia({
    required this.driveFileId,
    required this.thumbnailUrl,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'driveFileId': driveFileId,
        'thumbnailUrl': thumbnailUrl,
        'type': type.name,
      };

  factory SharedMemoryMedia.fromJson(Map<Object?, Object?> raw) {
    final j = Map<String, dynamic>.from(raw);
    return SharedMemoryMedia(
      driveFileId: j['driveFileId'] as String? ?? '',
      thumbnailUrl: j['thumbnailUrl'] as String? ?? '',
      type: AttachmentType.values.firstWhere(
        (e) => e.name == (j['type'] as String?),
        orElse: () => AttachmentType.other,
      ),
    );
  }
}

class SharedMemory {
  final String id;
  final String fromUid;
  final String fromName;
  final String fromPhotoUrl;
  final String kidName;
  final String milestoneTitle;
  final String milestoneDescription;
  final DateTime milestoneDate;
  final Color milestoneColor;
  final List<SharedMemoryMedia> media;
  // Stored as map {uid: true} in RTDB; exposed as list in Dart
  final List<String> likedByUids;
  final int commentCount;
  final DateTime createdAt;

  const SharedMemory({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromPhotoUrl,
    required this.kidName,
    required this.milestoneTitle,
    required this.milestoneDescription,
    required this.milestoneDate,
    required this.milestoneColor,
    this.media = const [],
    this.likedByUids = const [],
    this.commentCount = 0,
    required this.createdAt,
  });

  bool isLikedBy(String uid) => likedByUids.contains(uid);

  Map<String, dynamic> toJson() => {
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'kidName': kidName,
        'milestoneTitle': milestoneTitle,
        'milestoneDescription': milestoneDescription,
        'milestoneDate': milestoneDate.toIso8601String(),
        'milestoneColor': milestoneColor.toARGB32(),
        'media': media.map((m) => m.toJson()).toList(),
        'likedBy': {for (final uid in likedByUids) uid: true},
        'commentCount': commentCount,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory SharedMemory.fromMap(String id, Map<Object?, Object?> raw) {
    final j = Map<String, dynamic>.from(raw);

    // media: stored as List or as RTDB numeric-keyed map
    List<SharedMemoryMedia> parseMedia() {
      final r = j['media'];
      if (r == null) return [];
      final items = r is List ? r : (r as Map).values.toList();
      return items
          .whereType<Map>()
          .map((m) => SharedMemoryMedia.fromJson(m))
          .toList();
    }

    // likedBy: stored as {uid: true} map
    List<String> parseLiked() {
      final r = j['likedBy'];
      if (r == null) return [];
      return (r as Map).keys.cast<String>().toList();
    }

    return SharedMemory(
      id: id,
      fromUid: j['fromUid'] as String? ?? '',
      fromName: j['fromName'] as String? ?? '',
      fromPhotoUrl: j['fromPhotoUrl'] as String? ?? '',
      kidName: j['kidName'] as String? ?? '',
      milestoneTitle: j['milestoneTitle'] as String? ?? '',
      milestoneDescription: j['milestoneDescription'] as String? ?? '',
      milestoneDate: j['milestoneDate'] != null
          ? DateTime.parse(j['milestoneDate'] as String)
          : DateTime.now(),
      milestoneColor: Color(j['milestoneColor'] as int? ?? 0xFF9E9E9E),
      media: parseMedia(),
      likedByUids: parseLiked(),
      commentCount: (j['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (j['createdAt'] as int?) ?? 0),
    );
  }
}
