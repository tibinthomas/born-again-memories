import 'dart:io';
import 'package:flutter/foundation.dart';

enum AttachmentType { image, video, audio, other }

enum BackupStatus { queued, uploading, backedUp, failed }

class Attachment {
  final String id;
  final String name;
  final String? label;
  final AttachmentType type;
  final int sizeBytes;
  final String localPath;
  final String? driveFileId;
  final String? iCloudFileId;
  final BackupStatus backupStatus;
  // In-memory bytes for web (not serialized — only lives within the session)
  final Uint8List? webBytes;

  Attachment({
    required this.id,
    required this.name,
    this.label,
    required this.type,
    required this.sizeBytes,
    required this.localPath,
    this.driveFileId,
    this.iCloudFileId,
    this.backupStatus = BackupStatus.queued,
    this.webBytes,
  });

  bool get localExists =>
      !kIsWeb && localPath.isNotEmpty && File(localPath).existsSync();

  bool get isViewable => webBytes != null || localExists;

  Attachment copyWith({
    String? localPath,
    String? label,
    String? driveFileId,
    String? iCloudFileId,
    BackupStatus? backupStatus,
    bool clearDriveFileId = false,
    bool clearICloudFileId = false,
    bool clearLabel = false,
  }) =>
      Attachment(
        id: id,
        name: name,
        label: clearLabel ? null : label ?? this.label,
        type: type,
        sizeBytes: sizeBytes,
        localPath: localPath ?? this.localPath,
        driveFileId: clearDriveFileId ? null : driveFileId ?? this.driveFileId,
        iCloudFileId: clearICloudFileId ? null : iCloudFileId ?? this.iCloudFileId,
        backupStatus: backupStatus ?? this.backupStatus,
        webBytes: webBytes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': label,
        'type': type.name,
        'sizeBytes': sizeBytes,
        'localPath': localPath,
        'driveFileId': driveFileId,
        'iCloudFileId': iCloudFileId,
        'backupStatus': backupStatus.name,
        // webBytes intentionally excluded — too large for Firestore
      };

  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
        id: j['id'] as String,
        name: j['name'] as String,
        label: j['label'] as String?,
        type: AttachmentType.values.firstWhere((e) => e.name == j['type'],
            orElse: () => AttachmentType.other),
        sizeBytes: (j['sizeBytes'] as num).toInt(),
        localPath: j['localPath'] as String? ?? '',
        driveFileId: j['driveFileId'] as String?,
        iCloudFileId: j['iCloudFileId'] as String?,
        backupStatus: BackupStatus.values.firstWhere(
          (e) => e.name == (j['backupStatus'] as String? ?? 'queued'),
          orElse: () => BackupStatus.queued,
        ),
      );
}
