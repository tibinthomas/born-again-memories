import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/attachment.dart';

AttachmentType getAttachmentTypeFromExtension(String extension) {
  final value = extension.toLowerCase();
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(value)) return AttachmentType.image;
  if (['mp4', 'mov', 'avi', 'mkv'].contains(value)) return AttachmentType.video;
  if (['wav', 'mp3', 'm4a', 'aac', 'ogg'].contains(value)) return AttachmentType.audio;
  return AttachmentType.other;
}

/// Returns an Image widget from an Attachment, working on both web and native.
/// Falls back to [placeholder] (default: grey icon) when no data is available.
Widget attachmentImageWidget(
  Attachment a, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
}) {
  final fallback = placeholder ??
      SizedBox(
        width: width,
        height: height,
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );

  if (a.webBytes != null) {
    return Image.memory(
      a.webBytes!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stack) => fallback,
    );
  }
  if (!kIsWeb && a.localPath.isNotEmpty && File(a.localPath).existsSync()) {
    return Image.file(
      File(a.localPath),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
  return fallback;
}
