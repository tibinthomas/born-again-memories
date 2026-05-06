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

  factory SharedMemoryMedia.fromJson(Map<String, dynamic> j) =>
      SharedMemoryMedia(
        driveFileId: j['driveFileId'] as String? ?? '',
        thumbnailUrl: j['thumbnailUrl'] as String? ?? '',
        type: AttachmentType.values.firstWhere(
          (e) => e.name == (j['type'] as String?),
          orElse: () => AttachmentType.other,
        ),
      );
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
  // All UIDs that can see this post — used for arrayContains queries
  final List<String> visibleTo;
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
    required this.visibleTo,
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
        'visibleTo': visibleTo,
        'likedByUids': likedByUids,
        'commentCount': commentCount,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory SharedMemory.fromMap(String id, Map<String, dynamic> j) =>
      SharedMemory(
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
        media: (j['media'] as List? ?? [])
            .whereType<Map>()
            .map((m) =>
                SharedMemoryMedia.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        visibleTo: List<String>.from(j['visibleTo'] as List? ?? []),
        likedByUids: List<String>.from(j['likedByUids'] as List? ?? []),
        commentCount: (j['commentCount'] as num?)?.toInt() ?? 0,
        createdAt: _parseDate(j['createdAt']),
      );

  static DateTime _parseDate(dynamic v) {
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    try { return (v as dynamic).toDate() as DateTime; } catch (_) {}
    return DateTime.now();
  }
}
