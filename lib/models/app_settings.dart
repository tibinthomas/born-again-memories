import 'package:flutter/material.dart';

class AppSettings {
  final String? customIcon; // local path, device-only (not synced)
  final bool soundEnabled;
  final double soundVolume;
  final bool hapticEnabled;
  final bool animationsEnabled;
  final Color themeColor;

  AppSettings({
    this.customIcon,
    this.soundEnabled = true,
    this.soundVolume = 0.7,
    this.hapticEnabled = true,
    this.animationsEnabled = true,
    this.themeColor = Colors.pinkAccent,
  });

  AppSettings copyWith({
    String? customIcon,
    bool? soundEnabled,
    double? soundVolume,
    bool? hapticEnabled,
    bool? animationsEnabled,
    Color? themeColor,
    bool clearCustomIcon = false,
  }) =>
      AppSettings(
        customIcon: clearCustomIcon ? null : customIcon ?? this.customIcon,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        soundVolume: soundVolume ?? this.soundVolume,
        hapticEnabled: hapticEnabled ?? this.hapticEnabled,
        animationsEnabled: animationsEnabled ?? this.animationsEnabled,
        themeColor: themeColor ?? this.themeColor,
      );

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'soundVolume': soundVolume,
        'hapticEnabled': hapticEnabled,
        'animationsEnabled': animationsEnabled,
        'themeColor': themeColor.toARGB32(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        soundEnabled: j['soundEnabled'] as bool? ?? true,
        soundVolume: (j['soundVolume'] as num?)?.toDouble() ?? 0.7,
        hapticEnabled: j['hapticEnabled'] as bool? ?? true,
        animationsEnabled: j['animationsEnabled'] as bool? ?? true,
        themeColor:
            Color(j['themeColor'] as int? ?? Colors.pinkAccent.toARGB32()),
      );
}
