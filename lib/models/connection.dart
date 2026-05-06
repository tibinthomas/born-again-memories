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
        'status': status.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory Connection.fromMap(String id, Map<Object?, Object?> raw) {
    final j = Map<String, dynamic>.from(raw);
    return Connection(
      id: id,
      fromUid: j['fromUid'] as String? ?? '',
      fromName: j['fromName'] as String? ?? '',
      fromPhotoUrl: j['fromPhotoUrl'] as String? ?? '',
      toEmail: j['toEmail'] as String? ?? '',
      toUid: j['toUid'] as String?,
      toName: j['toName'] as String?,
      toPhotoUrl: j['toPhotoUrl'] as String?,
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == (j['status'] as String?),
        orElse: () => ConnectionStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (j['createdAt'] as int?) ?? 0),
    );
  }
}
