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

  factory Comment.fromMap(String id, Map<String, dynamic> j) => Comment(
        id: id,
        fromUid: j['fromUid'] as String? ?? '',
        fromName: j['fromName'] as String? ?? '',
        fromPhotoUrl: j['fromPhotoUrl'] as String?,
        text: j['text'] as String? ?? '',
        createdAt: _parseDate(j['createdAt']),
      );

  static DateTime _parseDate(dynamic v) {
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    try { return (v as dynamic).toDate() as DateTime; } catch (_) {}
    return DateTime.now();
  }
}
