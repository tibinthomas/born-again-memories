import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

/// Launches the native crop UI after picking. Returns the cropped path, or
/// null if the user cancelled. Passes [sourcePath] through unchanged on web/desktop.
Future<String?> cropImage(
  String sourcePath, {
  required bool isAvatar,
  required Color accent,
}) async {
  if (kIsWeb) return sourcePath;
  if (!Platform.isIOS && !Platform.isAndroid) return sourcePath;
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: isAvatar ? const CropAspectRatio(ratioX: 1, ratioY: 1) : null,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: isAvatar ? 'Crop Profile Photo' : 'Crop Background',
        toolbarColor: accent,
        toolbarWidgetColor: Colors.white,
        lockAspectRatio: isAvatar,
        initAspectRatio: isAvatar
            ? CropAspectRatioPreset.square
            : CropAspectRatioPreset.ratio16x9,
        aspectRatioPresets: isAvatar
            ? [CropAspectRatioPreset.square]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio16x9,
                CropAspectRatioPreset.ratio4x3,
              ],
      ),
      IOSUiSettings(
        title: isAvatar ? 'Crop Profile Photo' : 'Crop Background',
        aspectRatioLockEnabled: isAvatar,
        aspectRatioPresets: isAvatar
            ? [CropAspectRatioPreset.square]
            : [
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio16x9,
                CropAspectRatioPreset.ratio4x3,
              ],
      ),
    ],
  );
  return cropped?.path;
}
