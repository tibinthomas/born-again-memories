import 'package:flutter/material.dart';

class ThemePreset {
  final String id;
  final String name;
  final String emoji;
  final Color accent;
  final Color secondary;
  final Color? tertiary;

  const ThemePreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.accent,
    required this.secondary,
    this.tertiary,
  });

  bool get isThreeColor => tertiary != null;

  static const List<ThemePreset> all = [
    // ── 2-Color ──────────────────────────────────────────────────────────────
    ThemePreset(
      id: 'sapphire_gold',
      name: 'Sapphire & Gold',
      emoji: '💎',
      accent: Color(0xFF4A90D9),
      secondary: Color(0xFFD4A235),
    ),
    ThemePreset(
      id: 'rose_jade',
      name: 'Rose & Jade',
      emoji: '🌸',
      accent: Color(0xFFE070A8),
      secondary: Color(0xFF3DBFB0),
    ),
    ThemePreset(
      id: 'topaz_amethyst',
      name: 'Topaz & Amethyst',
      emoji: '⭐',
      accent: Color(0xFFFF9F2E),
      secondary: Color(0xFF8B6FD6),
    ),
    ThemePreset(
      id: 'emerald_ruby',
      name: 'Emerald & Ruby',
      emoji: '🌿',
      accent: Color(0xFF3CA76A),
      secondary: Color(0xFFD94F6A),
    ),
    ThemePreset(
      id: 'arctic_coral',
      name: 'Arctic & Coral',
      emoji: '❄️',
      accent: Color(0xFF4BBFCC),
      secondary: Color(0xFFFF6B5E),
    ),
    ThemePreset(
      id: 'lavender_peach',
      name: 'Lavender & Peach',
      emoji: '🌙',
      accent: Color(0xFF9B7ED4),
      secondary: Color(0xFFFF8C6E),
    ),
    // ── 3-Color ──────────────────────────────────────────────────────────────
    ThemePreset(
      id: 'aurora',
      name: 'Aurora Borealis',
      emoji: '🌌',
      accent: Color(0xFF3BB8D0),
      secondary: Color(0xFF7B6FD4),
      tertiary: Color(0xFF4AC99B),
    ),
    ThemePreset(
      id: 'sunset_bloom',
      name: 'Sunset Bloom',
      emoji: '🌅',
      accent: Color(0xFFFF7043),
      secondary: Color(0xFFE040A0),
      tertiary: Color(0xFFFFD740),
    ),
    ThemePreset(
      id: 'ocean_depths',
      name: 'Ocean Depths',
      emoji: '🌊',
      accent: Color(0xFF1976D2),
      secondary: Color(0xFF00897B),
      tertiary: Color(0xFF7E57C2),
    ),
    ThemePreset(
      id: 'crystal_garden',
      name: 'Crystal Garden',
      emoji: '🪻',
      accent: Color(0xFF8E24AA),
      secondary: Color(0xFF0097A7),
      tertiary: Color(0xFFD81B60),
    ),
  ];

  static List<ThemePreset> get twoColor =>
      all.where((p) => !p.isThreeColor).toList();

  static List<ThemePreset> get threeColor =>
      all.where((p) => p.isThreeColor).toList();

  static ThemePreset? findById(String? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static String defaultIdForGender(String gender) => switch (gender) {
        'boy' => 'sapphire_gold',
        'girl' => 'rose_jade',
        _ => 'topaz_amethyst',
      };
}
