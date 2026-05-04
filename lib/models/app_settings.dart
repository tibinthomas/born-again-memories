import 'package:flutter/material.dart';

class AppSettings {
  final String? customIcon; // local path, device-only (not synced)
  final bool soundEnabled;
  final double soundVolume;
  final bool hapticEnabled;
  final Color themeColor;

  AppSettings({
    this.customIcon,
    this.soundEnabled = true,
    this.soundVolume = 0.7,
    this.hapticEnabled = true,
    this.themeColor = Colors.pinkAccent,
  });

  AppSettings copyWith({
    String? customIcon,
    bool? soundEnabled,
    double? soundVolume,
    bool? hapticEnabled,
    Color? themeColor,
    bool clearCustomIcon = false,
  }) =>
      AppSettings(
        customIcon: clearCustomIcon ? null : customIcon ?? this.customIcon,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        soundVolume: soundVolume ?? this.soundVolume,
        hapticEnabled: hapticEnabled ?? this.hapticEnabled,
        themeColor: themeColor ?? this.themeColor,
      );

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'soundVolume': soundVolume,
        'hapticEnabled': hapticEnabled,
        'themeColor': themeColor.toARGB32(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        soundEnabled: j['soundEnabled'] as bool? ?? true,
        soundVolume: (j['soundVolume'] as num?)?.toDouble() ?? 0.7,
        hapticEnabled: j['hapticEnabled'] as bool? ?? true,
        themeColor:
            Color(j['themeColor'] as int? ?? Colors.pinkAccent.toARGB32()),
      );
}
