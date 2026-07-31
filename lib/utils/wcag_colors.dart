import 'package:flutter/material.dart';

abstract final class WcagColors {
  static const primaryText = Color(0xFF1A1A2E);
  static const secondaryText = Color(0xFF616161);
  static const controlBorder = Color(0xFF757575);
  static const focusIndicator = Color(0xFF005FCC);

  static double contrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static bool meetsNormalText(Color foreground, Color background) =>
      contrastRatio(foreground, background) >= 4.5;

  static bool meetsLargeTextOrUi(Color foreground, Color background) =>
      contrastRatio(foreground, background) >= 3;
}
