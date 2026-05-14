import 'package:icloud_storage/icloud_storage.dart';
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
