import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupPermissionsStatus {
  final bool notifications;
  final bool backgroundRefresh; // iOS: Background App Refresh is enabled

  const BackupPermissionsStatus({
    this.notifications = true,
    this.backgroundRefresh = true,
  });

  bool get needsAction => !notifications;
}

class BackupPermissionsService {
  static Future<BackupPermissionsStatus> check() async {
    if (kIsWeb) return const BackupPermissionsStatus();

    final notif = await Permission.notification.status;
    final bgRefresh = Platform.isIOS
        ? (await Permission.backgroundRefresh.status).isGranted
        : true;

    return BackupPermissionsStatus(
      notifications: notif.isGranted,
      backgroundRefresh: bgRefresh,
    );
  }

  static Future<bool> requestNotifications() async {
    if (kIsWeb) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<void> goToSettings() => openAppSettings();
}
