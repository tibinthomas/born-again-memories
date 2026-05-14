import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class BackupPermissionsStatus {
  final bool notifications;
  final bool batteryExempt;    // Android: exempted from battery optimization
  final bool backgroundRefresh; // iOS: Background App Refresh is enabled

  const BackupPermissionsStatus({
    this.notifications = true,
    this.batteryExempt = true,
    this.backgroundRefresh = true,
  });

  bool get needsAction => !notifications || (Platform.isAndroid && !batteryExempt);
}

class BackupPermissionsService {
  static Future<BackupPermissionsStatus> check() async {
    if (kIsWeb) return const BackupPermissionsStatus();

    final notif = await Permission.notification.status;
    final batteryExempt = Platform.isAndroid
        ? await Permission.ignoreBatteryOptimizations.isGranted
        : true;
    final bgRefresh = Platform.isIOS
        ? (await Permission.backgroundRefresh.status).isGranted
        : true;

    return BackupPermissionsStatus(
      notifications: notif.isGranted,
      batteryExempt: batteryExempt,
      backgroundRefresh: bgRefresh,
    );
  }

  static Future<bool> requestNotifications() async {
    if (kIsWeb) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Android only — opens system dialog to exempt the app from battery optimization.
  static Future<bool> requestBatteryExemption() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  static Future<void> goToSettings() => openAppSettings();
}
