import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/attachment.dart';

class ICloudNotAvailableException implements Exception {}

// Returned when an upload or delete operation fails for a non-availability reason.
class ICloudOperationException implements Exception {
  final String message;
  ICloudOperationException(this.message);
  @override
  String toString() => 'ICloudOperationException: $message';
}

class ICloudService {
  // Must match the iCloud container configured in Xcode entitlements.
  // Update this value to match your app's iCloud container ID.
  static const _containerId = 'iCloud.com.bornagainmemories.app';
  static const _backupRoot = 'BornAgainMemories';

  static Future<bool> isAvailable() async {
    try {
      await ICloudStorage.gather(containerId: _containerId, onUpdate: null);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _relativePath({
    required String profileName,
    required String milestoneId,
    required String fileName,
  }) =>
      '$_backupRoot/$profileName/$milestoneId/$fileName';

  static Future<String> uploadFile({
    required String localPath,
    required String fileName,
    required String profileName,
    required String milestoneId,
    required AttachmentType type,
  }) async {
    final available = await isAvailable();
    if (!available) throw ICloudNotAvailableException();

    final relativePath = _relativePath(
      profileName: profileName,
      milestoneId: milestoneId,
      fileName: fileName,
    );

    try {
      await ICloudStorage.upload(
        containerId: _containerId,
        filePath: localPath,
        destinationRelativePath: relativePath,
        onProgress: null,
      );
      return relativePath;
    } catch (e) {
      if (e is ICloudNotAvailableException) rethrow;
      throw ICloudOperationException(e.toString());
    }
  }

  static Future<void> deleteFile(String relativePath) async {
    try {
      await ICloudStorage.delete(
        containerId: _containerId,
        relativePath: relativePath,
      );
    } catch (_) {}
  }

  /// Downloads a backed-up attachment to a temporary file and returns it.
  static Future<Uint8List> downloadFileBytes(String relativePath) async {
    final tempDirectory = await getTemporaryDirectory();
    final destination = File(
      '${tempDirectory.path}/icloud_${DateTime.now().microsecondsSinceEpoch}',
    );
    final completed = Completer<void>();
    StreamSubscription<double>? progressSubscription;
    var progressAttached = false;

    try {
      await ICloudStorage.download(
        containerId: _containerId,
        relativePath: relativePath,
        destinationFilePath: destination.path,
        onProgress: (stream) {
          progressAttached = true;
          progressSubscription = stream.listen(
            (_) {},
            onDone: () {
              if (!completed.isCompleted) completed.complete();
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!completed.isCompleted) {
                completed.completeError(error, stackTrace);
              }
            },
            cancelOnError: true,
          );
        },
      );
      if (progressAttached) {
        await completed.future.timeout(const Duration(seconds: 30));
      }
      return await destination.readAsBytes();
    } finally {
      await progressSubscription?.cancel();
      if (await destination.exists()) await destination.delete();
    }
  }

  static Future<void> deleteAllBackups() async {
    try {
      final files = await ICloudStorage.gather(
        containerId: _containerId,
        onUpdate: null,
      );
      for (final file in files) {
        if (file.relativePath.startsWith(_backupRoot)) {
          await ICloudStorage.delete(
            containerId: _containerId,
            relativePath: file.relativePath,
          );
        }
      }
    } catch (_) {}
  }
}
