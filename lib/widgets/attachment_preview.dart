import 'dart:io';
import 'package:flutter/material.dart';
import '../models/attachment.dart';

class AttachmentPreview extends StatelessWidget {
  final Attachment attachment;

  const AttachmentPreview({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (attachment.type == AttachmentType.image && attachment.localExists) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(attachment.localPath),
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      );
    } else {
      final icon = switch (attachment.type) {
        AttachmentType.video => Icons.videocam,
        AttachmentType.audio => Icons.audiotrack,
        AttachmentType.image => Icons.broken_image,
        _ => Icons.attach_file,
      };
      content = Container(
        width: 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: Colors.grey.shade700),
            const SizedBox(height: 8),
            Text(
              attachment.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        content,
        Positioned(
          bottom: 4,
          right: 4,
          child: _BackupBadge(status: attachment.backupStatus),
        ),
      ],
    );
  }
}

class _BackupBadge extends StatelessWidget {
  final BackupStatus status;
  const _BackupBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      BackupStatus.backedUp => (Icons.cloud_done, Colors.green),
      BackupStatus.uploading => (Icons.cloud_upload, Colors.blue),
      BackupStatus.failed => (Icons.cloud_off, Colors.red),
      BackupStatus.queued => (Icons.cloud_queue, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
