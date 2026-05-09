import 'package:flutter/material.dart';
import '../models/kid_profile.dart';
import 'theme_preset.dart';

class ProfileTheme {
  final Color accent;
  final Color secondary;
  final Color? tertiary;
  final Color soft;
  final Color cardBg;
  final Color timelineDot;
  final String decalEmoji;
  final LinearGradient headerGradient;

  const ProfileTheme({
    required this.accent,
    required this.secondary,
    this.tertiary,
    required this.soft,
    required this.cardBg,
    required this.timelineDot,
    required this.decalEmoji,
    required this.headerGradient,
  });

  // ── Hand-crafted gem pairs for the three base genders ──────────────────────
  // Boy:     sapphire blue  ↔  warm gold      (like a royal signet ring)
  // Girl:    rose quartz    ↔  jade teal      (like a blush opal)
  // Neutral: amber topaz    ↔  soft amethyst  (like alexandrite)
  static ProfileTheme forGender(Gender gender) {
    switch (gender) {
      case Gender.boy:
        const accent = Color(0xFF4A90D9);
        const secondary = Color(0xFFD4A235);
        return ProfileTheme(
          accent: accent,
          secondary: secondary,
          soft: const Color(0xFFE8F4FD),
          cardBg: const Color(0xFFF0F8FF),
          timelineDot: accent,
          decalEmoji: '🚀',
          headerGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
            colors: [Color(0xFF4A90D9), Color(0xFF2F6DB5), Color(0xFF1E5A9C)],
          ),
        );
      case Gender.girl:
        const accent = Color(0xFFE070A8);
        const secondary = Color(0xFF3DBFB0);
        return ProfileTheme(
          accent: accent,
          secondary: secondary,
          soft: const Color(0xFFFDF0F7),
          cardBg: const Color(0xFFFFF5FB),
          timelineDot: accent,
          decalEmoji: '🌸',
          headerGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
            colors: [Color(0xFFE070A8), Color(0xFFCC4F90), Color(0xFFB83A7A)],
          ),
        );
      case Gender.neutral:
        const accent = Color(0xFFFF9F2E);
        const secondary = Color(0xFF8B6FD6);
        return ProfileTheme(
          accent: accent,
          secondary: secondary,
          soft: const Color(0xFFFFF8EE),
          cardBg: const Color(0xFFFFFBF5),
          timelineDot: accent,
          decalEmoji: '⭐',
          headerGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
            colors: [Color(0xFFFF9F2E), Color(0xFFE07A10), Color(0xFFCC6000)],
          ),
        );
    }
  }

  // ── Build a theme from a ThemePreset ──────────────────────────────────────
  static ProfileTheme fromPreset(ThemePreset preset, {String decalEmoji = '⭐'}) {
    final accent = preset.accent;
    final secondary = preset.secondary;
    final tertiary = preset.tertiary;

    final hsl = HSLColor.fromColor(accent);
    final darker = hsl
        .withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0))
        .toColor();

    final headerColors = tertiary != null
        ? [accent, Color.lerp(accent, tertiary, 0.5)!, darker]
        : [accent, darker, darker];

    return ProfileTheme(
      accent: accent,
      secondary: secondary,
      tertiary: tertiary,
      soft: accent.withAlpha(30),
      cardBg: accent.withAlpha(15),
      timelineDot: accent,
      decalEmoji: decalEmoji,
      headerGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.6, 1.0],
        colors: headerColors,
      ),
    );
  }

  // ── Dynamic theme from a profile ──────────────────────────────────────────
  static ProfileTheme forProfile(KidProfile profile) {
    final emoji = switch (profile.gender) {
      Gender.boy => '🚀',
      Gender.girl => '🌸',
      Gender.neutral => '⭐',
    };

    final preset = ThemePreset.findById(profile.themePresetId);
    if (preset != null) {
      return fromPreset(preset, decalEmoji: emoji);
    }

    // Fallback: derive from profile.color via split-complementary hue shift
    final accent = profile.color;
    final hsl = HSLColor.fromColor(accent);
    final darker = hsl
        .withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0))
        .toColor();
    final secHsl = hsl
        .withHue((hsl.hue + 150) % 360)
        .withSaturation((hsl.saturation + 0.08).clamp(0.0, 1.0))
        .withLightness(hsl.lightness.clamp(0.30, 0.65));
    final secondary = secHsl.toColor();

    return ProfileTheme(
      accent: accent,
      secondary: secondary,
      soft: accent.withAlpha(30),
      cardBg: accent.withAlpha(15),
      timelineDot: accent,
      decalEmoji: emoji,
      headerGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.6, 1.0],
        colors: [accent, darker, darker],
      ),
    );
  }
}
