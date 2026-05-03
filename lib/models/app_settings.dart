import 'package:flutter/material.dart';

class AppSettings {
  final String? customIcon;
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
  }) {
    return AppSettings(
      customIcon: customIcon ?? this.customIcon,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}