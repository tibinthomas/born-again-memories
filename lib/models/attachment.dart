import 'dart:io';

enum AttachmentType { image, video, audio, other }

enum BackupStatus { queued, uploading, backedUp, failed }

class Attachment {
  final String id;
  final String name;
  final AttachmentType type;
  final int sizeBytes;
  final String localPath;      // permanent device path — always set
  final String? driveFileId;   // set after Drive backup
  final BackupStatus backupStatus;

  Attachment({
    required this.id,
    required this.name,
    required this.type,
    required this.sizeBytes,
    required this.localPath,
    this.driveFileId,
    this.backupStatus = BackupStatus.queued,
  });

  bool get localExists => localPath.isNotEmpty && File(localPath).existsSync();

  Attachment copyWith({
    String? driveFileId,
    BackupStatus? backupStatus,
    bool clearDriveFileId = false,
  }) =>
      Attachment(
        id: id,
        name: name,
        type: type,
        sizeBytes: sizeBytes,
        localPath: localPath,
        driveFileId: clearDriveFileId ? null : driveFileId ?? this.driveFileId,
        backupStatus: backupStatus ?? this.backupStatus,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'sizeBytes': sizeBytes,
        'localPath': localPath,
        'driveFileId': driveFileId,
        'backupStatus': backupStatus.name,
      };

  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
        id: j['id'] as String,
        name: j['name'] as String,
        type: AttachmentType.values.firstWhere((e) => e.name == j['type']),
        sizeBytes: (j['sizeBytes'] as num).toInt(),
        localPath: j['localPath'] as String? ?? '',
        driveFileId: j['driveFileId'] as String?,
        backupStatus: BackupStatus.values.firstWhere(
          (e) => e.name == (j['backupStatus'] as String? ?? 'queued'),
          orElse: () => BackupStatus.queued,
        ),
      );
}
