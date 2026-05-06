enum ConnectionStatus { pending, accepted, declined }

class Connection {
  final String id;
  final String fromUid;
  final String fromName;
  final String fromPhotoUrl;
  final String toEmail;
  final String? toUid;
  final String? toName;
  final String? toPhotoUrl;
  // Both UIDs once the invite is accepted — used for arrayContains queries
  final List<String> members;
  final ConnectionStatus status;
  final DateTime createdAt;

  const Connection({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromPhotoUrl,
    required this.toEmail,
    this.toUid,
    this.toName,
    this.toPhotoUrl,
    this.members = const [],
    required this.status,
    required this.createdAt,
  });

  String otherName(String currentUid) =>
      fromUid == currentUid ? (toName ?? toEmail) : fromName;

  String otherPhotoUrl(String currentUid) =>
      fromUid == currentUid ? (toPhotoUrl ?? '') : fromPhotoUrl;

  String otherEmail(String currentUid) =>
      fromUid == currentUid ? toEmail : '';

  String otherUid(String currentUid) =>
      fromUid == currentUid ? (toUid ?? '') : fromUid;

  Map<String, dynamic> toJson() => {
        'fromUid': fromUid,
        'fromName': fromName,
        'fromPhotoUrl': fromPhotoUrl,
        'toEmail': toEmail,
        'toUid': toUid,
        'toName': toName,
        'toPhotoUrl': toPhotoUrl,
        'members': members,
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Connection.fromMap(String id, Map<String, dynamic> j) => Connection(
        id: id,
        fromUid: j['fromUid'] as String? ?? '',
        fromName: j['fromName'] as String? ?? '',
        fromPhotoUrl: j['fromPhotoUrl'] as String? ?? '',
        toEmail: j['toEmail'] as String? ?? '',
        toUid: j['toUid'] as String?,
        toName: j['toName'] as String?,
        toPhotoUrl: j['toPhotoUrl'] as String?,
        members: List<String>.from(j['members'] as List? ?? []),
        status: ConnectionStatus.values.firstWhere(
          (e) => e.name == (j['status'] as String?),
          orElse: () => ConnectionStatus.pending,
        ),
        createdAt: _parseDate(j['createdAt']),
      );

  static DateTime _parseDate(dynamic v) {
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    try { return (v as dynamic).toDate() as DateTime; } catch (_) {}
    return DateTime.now();
  }
}
