import 'package:flutter/material.dart';

class AppSettings {
  final String? customIcon; // local path, device-only (not synced)
  final bool soundEnabled;
  final double soundVolume;
  final bool hapticEnabled;
  final bool animationsEnabled;
  final Color themeColor;
  // Feature toggles — all default true so existing users see everything
  final bool growthTrackingEnabled;
  final bool checklistEnabled;
  final bool remindersEnabled;
  final bool documentsEnabled;
  final bool linksEnabled;

  AppSettings({
    this.customIcon,
    this.soundEnabled = true,
    this.soundVolume = 0.7,
    this.hapticEnabled = true,
    this.animationsEnabled = true,
    this.themeColor = Colors.pinkAccent,
    this.growthTrackingEnabled = true,
    this.checklistEnabled = true,
    this.remindersEnabled = true,
    this.documentsEnabled = true,
    this.linksEnabled = true,
  });

  AppSettings copyWith({
    String? customIcon,
    bool? soundEnabled,
    double? soundVolume,
    bool? hapticEnabled,
    bool? animationsEnabled,
    Color? themeColor,
    bool? growthTrackingEnabled,
    bool? checklistEnabled,
    bool? remindersEnabled,
    bool? documentsEnabled,
    bool? linksEnabled,
    bool clearCustomIcon = false,
  }) =>
      AppSettings(
        customIcon: clearCustomIcon ? null : customIcon ?? this.customIcon,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        soundVolume: soundVolume ?? this.soundVolume,
        hapticEnabled: hapticEnabled ?? this.hapticEnabled,
        animationsEnabled: animationsEnabled ?? this.animationsEnabled,
        themeColor: themeColor ?? this.themeColor,
        growthTrackingEnabled: growthTrackingEnabled ?? this.growthTrackingEnabled,
        checklistEnabled: checklistEnabled ?? this.checklistEnabled,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        documentsEnabled: documentsEnabled ?? this.documentsEnabled,
        linksEnabled: linksEnabled ?? this.linksEnabled,
      );

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'soundVolume': soundVolume,
        'hapticEnabled': hapticEnabled,
        'animationsEnabled': animationsEnabled,
        'themeColor': themeColor.toARGB32(),
        'growthTrackingEnabled': growthTrackingEnabled,
        'checklistEnabled': checklistEnabled,
        'remindersEnabled': remindersEnabled,
        'documentsEnabled': documentsEnabled,
        'linksEnabled': linksEnabled,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        soundEnabled: j['soundEnabled'] as bool? ?? true,
        soundVolume: (j['soundVolume'] as num?)?.toDouble() ?? 0.7,
        hapticEnabled: j['hapticEnabled'] as bool? ?? true,
        animationsEnabled: j['animationsEnabled'] as bool? ?? true,
        themeColor:
            Color(j['themeColor'] as int? ?? Colors.pinkAccent.toARGB32()),
        growthTrackingEnabled: j['growthTrackingEnabled'] as bool? ?? true,
        checklistEnabled: j['checklistEnabled'] as bool? ?? true,
        remindersEnabled: j['remindersEnabled'] as bool? ?? true,
        documentsEnabled: j['documentsEnabled'] as bool? ?? true,
        linksEnabled: j['linksEnabled'] as bool? ?? true,
      );
}
