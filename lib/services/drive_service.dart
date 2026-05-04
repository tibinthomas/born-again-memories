import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../models/attachment.dart';

class DriveQuota {
  final int usedBytes;
  final int? limitBytes; // null = unlimited (G Suite / Workspace)
  const DriveQuota({required this.usedBytes, this.limitBytes});

  double get fraction =>
      limitBytes != null && limitBytes! > 0 ? usedBytes / limitBytes! : 0.0;

  bool get isNearlyFull => fraction > 0.9;
  bool get isFull => fraction >= 1.0;
}

class DriveNotAuthorizedException implements Exception {}

class DriveService {
  static const _appFolderName = 'Born Again Memories';

  static Future<drive.DriveApi> _api(GoogleSignIn gs) async {
    final client = await gs.authenticatedClient();
    if (client == null) throw DriveNotAuthorizedException();
    return drive.DriveApi(client);
  }

  static Future<String> _ensureFolder(
    drive.DriveApi api,
    String name, {
    String? parentId,
  }) async {
    var q =
        "name='$name' and mimeType='application/vnd.google-apps.folder' and trashed=false";
    if (parentId != null) q += " and '$parentId' in parents";
    final list =
        await api.files.list(q: q, spaces: 'drive', $fields: 'files(id)');
    if (list.files?.isNotEmpty == true) return list.files!.first.id!;
    final meta = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = parentId != null ? [parentId] : null;
    final created = await api.files.create(meta, $fields: 'id');
    return created.id!;
  }

  static String _contentType(AttachmentType type) => switch (type) {
        AttachmentType.image => 'image/jpeg',
        AttachmentType.video => 'video/mp4',
        AttachmentType.audio => 'audio/m4a',
        _ => 'application/octet-stream',
      };

  static Future<String> uploadFile({
    required GoogleSignIn googleSignIn,
    required String localPath,
    required String fileName,
    required String profileName,
    required String milestoneId,
    required AttachmentType type,
  }) async {
    final api = await _api(googleSignIn);
    final root = await _ensureFolder(api, _appFolderName);
    final profileFolder =
        await _ensureFolder(api, profileName, parentId: root);
    final msFolder =
        await _ensureFolder(api, milestoneId, parentId: profileFolder);

    final file = File(localPath);
    final meta = drive.File()
      ..name = fileName
      ..parents = [msFolder];

    final result = await api.files.create(
      meta,
      uploadMedia: drive.Media(
        file.openRead(),
        await file.length(),
        contentType: _contentType(type),
      ),
      $fields: 'id',
    );
    return result.id!;
  }

  static Future<void> deleteFile({
    required GoogleSignIn googleSignIn,
    required String driveFileId,
  }) async {
    try {
      final api = await _api(googleSignIn);
      await api.files.delete(driveFileId);
    } catch (_) {}
  }

  static Future<DriveQuota?> getQuota(GoogleSignIn googleSignIn) async {
    try {
      final api = await _api(googleSignIn);
      final about =
          await api.about.get($fields: 'storageQuota');
      final used = int.tryParse(about.storageQuota?.usage ?? '');
      if (used == null) return null;
      final limit = int.tryParse(about.storageQuota?.limit ?? '');
      return DriveQuota(usedBytes: used, limitBytes: limit);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> requestDriveScope(GoogleSignIn googleSignIn) =>
      googleSignIn.requestScopes([drive.DriveApi.driveFileScope]);
}
