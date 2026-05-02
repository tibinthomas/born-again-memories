import 'dart:io';
import 'package:flutter/material.dart';
import '../models/attachment.dart';

class AttachmentPreview extends StatelessWidget {
  final Attachment attachment;

  const AttachmentPreview({
    super.key,
    required this.attachment,
  });

  @override
  Widget build(BuildContext context) {
    if (attachment.type == AttachmentType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(attachment.path),
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      );
    }

    final icon = attachment.type == AttachmentType.video ? Icons.videocam : Icons.audiotrack;
    return Container(
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
}
