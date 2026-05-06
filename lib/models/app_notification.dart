enum NotificationType { connectionRequest, sharedMemory, like, comment }

class AppNotification {
  final String id;
  final NotificationType type;
  final String fromUid;
  final String fromName;
  final String? fromPhotoUrl;
  final String? memoryId;
  final String? connectionId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.fromName,
    this.fromPhotoUrl,
    this.memoryId,
    this.connectionId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'memoryId': memoryId,
        'connectionId': connectionId,
        'isRead': isRead,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory AppNotification.fromMap(String id, Map<Object?, Object?> raw) {
    final j = Map<String, dynamic>.from(raw);
    return AppNotification(
      id: id,
      type: NotificationType.values.firstWhere(
        (e) => e.name == (j['type'] as String?),
        orElse: () => NotificationType.sharedMemory,
      ),
      fromUid: j['fromUid'] as String? ?? '',
      fromName: j['fromName'] as String? ?? '',
      fromPhotoUrl: j['fromPhotoUrl'] as String?,
      memoryId: j['memoryId'] as String?,
      connectionId: j['connectionId'] as String?,
      isRead: j['isRead'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (j['createdAt'] as int?) ?? 0),
    );
  }
}
