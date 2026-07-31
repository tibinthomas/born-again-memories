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
      accent: Color(0xFF1565C0),
      secondary: Color(0xFF806000),
    ),
    ThemePreset(
      id: 'rose_jade',
      name: 'Rose & Jade',
      emoji: '🌸',
      accent: Color(0xFFAD1457),
      secondary: Color(0xFF00796B),
    ),
    ThemePreset(
      id: 'topaz_amethyst',
      name: 'Topaz & Amethyst',
      emoji: '⭐',
      accent: Color(0xFFA64B00),
      secondary: Color(0xFF673AB7),
    ),
    ThemePreset(
      id: 'emerald_ruby',
      name: 'Emerald & Ruby',
      emoji: '🌿',
      accent: Color(0xFF2E7D32),
      secondary: Color(0xFFC62828),
    ),
    ThemePreset(
      id: 'arctic_coral',
      name: 'Arctic & Coral',
      emoji: '❄️',
      accent: Color(0xFF007C91),
      secondary: Color(0xFFC53D2D),
    ),
    ThemePreset(
      id: 'lavender_peach',
      name: 'Lavender & Peach',
      emoji: '🌙',
      accent: Color(0xFF5E35B1),
      secondary: Color(0xFFB34700),
    ),
    // ── 3-Color ──────────────────────────────────────────────────────────────
    ThemePreset(
      id: 'aurora',
      name: 'Aurora Borealis',
      emoji: '🌌',
      accent: Color(0xFF007C91),
      secondary: Color(0xFF5E35B1),
      tertiary: Color(0xFF087F5B),
    ),
    ThemePreset(
      id: 'sunset_bloom',
      name: 'Sunset Bloom',
      emoji: '🌅',
      accent: Color(0xFFC43E20),
      secondary: Color(0xFFAD1457),
      tertiary: Color(0xFF765D00),
    ),
    ThemePreset(
      id: 'ocean_depths',
      name: 'Ocean Depths',
      emoji: '🌊',
      accent: Color(0xFF1565C0),
      secondary: Color(0xFF00796B),
      tertiary: Color(0xFF5E35B1),
    ),
    ThemePreset(
      id: 'crystal_garden',
      name: 'Crystal Garden',
      emoji: '🪻',
      accent: Color(0xFF7B1FA2),
      secondary: Color(0xFF007C91),
      tertiary: Color(0xFFAD1457),
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
