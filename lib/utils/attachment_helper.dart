import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attachment.dart';
import '../providers/auth_provider.dart';
import '../providers/profiles_provider.dart';
import '../services/drive_service.dart';
import '../services/icloud_service.dart';
import '../services/local_storage_service.dart';

AttachmentType getAttachmentTypeFromExtension(String extension) {
  final value = extension.toLowerCase();
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(value)) {
    return AttachmentType.image;
  }
  if (['mp4', 'mov', 'avi', 'mkv'].contains(value)) {
    return AttachmentType.video;
  }
  if (['wav', 'mp3', 'm4a', 'aac', 'ogg'].contains(value)) {
    return AttachmentType.audio;
  }
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
  return _PersistentAttachmentImage(
    attachment: a,
    width: width,
    height: height,
    fit: fit,
    placeholder: placeholder,
  );
}

class _PersistentAttachmentImage extends ConsumerStatefulWidget {
  final Attachment attachment;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const _PersistentAttachmentImage({
    required this.attachment,
    this.width,
    this.height,
    required this.fit,
    this.placeholder,
  });

  @override
  ConsumerState<_PersistentAttachmentImage> createState() =>
      _PersistentAttachmentImageState();
}

class _PersistentAttachmentImageState
    extends ConsumerState<_PersistentAttachmentImage> {
  String? _recoveredPath;
  bool _recovering = false;

  Attachment get _attachment => widget.attachment;

  @override
  void initState() {
    super.initState();
    _recoverIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _PersistentAttachmentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.id != _attachment.id ||
        oldWidget.attachment.localPath != _attachment.localPath) {
      _recoveredPath = null;
      _recoverIfNeeded();
    }
  }

  Future<void> _recoverIfNeeded() async {
    if (kIsWeb ||
        _recovering ||
        _attachment.webBytes != null ||
        _attachment.localExists) {
      return;
    }
    _recovering = true;
    try {
      var path = await LocalStorageService.resolveAttachmentPath(
        _attachment.localPath,
      );
      if (path == null) {
        Uint8List? bytes;
        if (_attachment.driveFileId != null) {
          bytes = await DriveService.downloadFileBytes(
            googleSignIn: ref.read(authServiceProvider).googleSignIn,
            driveFileId: _attachment.driveFileId!,
          );
        } else if (_attachment.iCloudFileId != null) {
          bytes = await ICloudService.downloadFileBytes(
            _attachment.iCloudFileId!,
          );
        }
        if (bytes != null) {
          final source = _attachment.name.contains('.')
              ? _attachment.name
              : _attachment.localPath;
          final dot = source.lastIndexOf('.');
          final extension = dot >= 0 ? source.substring(dot) : '.jpg';
          path = await LocalStorageService.saveAttachmentBytes(
            bytes,
            '${_attachment.id}$extension',
          );
        }
      }
      if (path != null) {
        ref
            .read(profilesProvider.notifier)
            .updateAttachmentLocalPath(_attachment.id, path);
        if (mounted) setState(() => _recoveredPath = path);
      }
    } catch (e) {
      debugPrint(
        '[AttachmentImage] Could not recover "${_attachment.name}": $e',
      );
    } finally {
      _recovering = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback =
        widget.placeholder ??
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: const Center(child: Icon(Icons.image, color: Colors.grey)),
        );

    if (_attachment.webBytes != null) {
      return Image.memory(
        _attachment.webBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stack) => fallback,
      );
    }
    final path = _recoveredPath ?? _attachment.localPath;
    if (!kIsWeb && path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
  }
}
