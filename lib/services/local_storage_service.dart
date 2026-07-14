import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static Future<String> copyToAppStorage(
      String sourcePath, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${dir.path}/attachments');
    await attachmentsDir.create(recursive: true);
    final dest = File('${attachmentsDir.path}/$filename');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  static Future<String> saveAttachmentBytes(
    Uint8List bytes,
    String filename,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory('${dir.path}/attachments');
    await attachmentsDir.create(recursive: true);
    final dest = File('${attachmentsDir.path}/$filename');
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }

  static Future<String?> resolveAttachmentPath(String storedPath) async {
    if (storedPath.isEmpty || storedPath.startsWith('http')) return null;
    if (await File(storedPath).exists()) return storedPath;
    final filename = storedPath.replaceAll('\\', '/').split('/').last;
    if (filename.isEmpty) return null;
    final dir = await getApplicationDocumentsDirectory();
    final relocated = File('${dir.path}/attachments/$filename');
    return await relocated.exists() ? relocated.path : null;
  }

  static Future<String> copyDocumentToStorage(
      String sourcePath, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${dir.path}/documents');
    await docsDir.create(recursive: true);
    final dest = File('${docsDir.path}/$filename');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  static Future<String> copyAvatarToStorage(
      String sourcePath, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory('${dir.path}/avatars');
    await avatarsDir.create(recursive: true);
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
    final dest = File('${avatarsDir.path}/$filename.$ext');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  /// Resolves a persisted avatar after an app-container path change and also
  /// recovers avatars saved before their local path was serialized.
  static Future<String?> resolveAvatarPath(
    String profileId,
    String? storedPath,
  ) async {
    if (storedPath?.startsWith('http') == true) return storedPath;
    if (storedPath != null && await File(storedPath).exists()) return storedPath;

    final dir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory('${dir.path}/avatars');
    if (!await avatarsDir.exists()) return null;

    if (storedPath != null && storedPath.isNotEmpty) {
      final filename = storedPath.replaceAll('\\', '/').split('/').last;
      final relocated = File('${avatarsDir.path}/$filename');
      if (await relocated.exists()) return relocated.path;
    }

    final candidates = await avatarsDir
        .list()
        .where((entity) => entity is File)
        .cast<File>()
        .where((file) => file.path
            .replaceAll('\\', '/')
            .split('/')
            .last
            .startsWith('avatar_${profileId}_'))
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return candidates.first.path;
  }

  static Future<String> copyBackgroundToStorage(
      String sourcePath, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final bgDir = Directory('${dir.path}/backgrounds');
    await bgDir.create(recursive: true);
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'jpg';
    final dest = File('${bgDir.path}/$filename.$ext');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  static Future<void> delete(String filePath) async {
    try {
      final f = File(filePath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  static Future<String> saveCustomIcon(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final iconsDir = Directory('${dir.path}/icons');
    await iconsDir.create(recursive: true);
    final dest = File('${iconsDir.path}/custom_app_icon');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  static Future<String?> getCustomIconPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/icons/custom_app_icon');
    return await f.exists() ? f.path : null;
  }

  static Future<void> deleteCustomIcon() async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/icons/custom_app_icon');
    if (await f.exists()) await f.delete();
  }
}
