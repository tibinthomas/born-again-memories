class Comment {
  final String id;
  final String fromUid;
  final String fromName;
  final String? fromPhotoUrl;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.fromUid,
    required this.fromName,
    this.fromPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromMap(String id, Map<Object?, Object?> raw) {
    final j = Map<String, dynamic>.from(raw);
    return Comment(
      id: id,
      fromUid: j['fromUid'] as String? ?? '',
      fromName: j['fromName'] as String? ?? '',
      fromPhotoUrl: j['fromPhotoUrl'] as String?,
      text: j['text'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (j['createdAt'] as int?) ?? 0),
    );
  }
}
