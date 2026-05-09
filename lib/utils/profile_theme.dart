import 'package:flutter/material.dart';
import '../models/kid_profile.dart';

class ProfileTheme {
  final Color accent;
  final Color soft;
  final Color cardBg;
  final Color timelineDot;
  final String decalEmoji;
  final LinearGradient headerGradient;

  const ProfileTheme({
    required this.accent,
    required this.soft,
    required this.cardBg,
    required this.timelineDot,
    required this.decalEmoji,
    required this.headerGradient,
  });

  static ProfileTheme forGender(Gender gender) {
    switch (gender) {
      case Gender.boy:
        return ProfileTheme(
          accent: const Color(0xFF5B9BD5),
          soft: const Color(0xFFE8F4FD),
          cardBg: const Color(0xFFF0F8FF),
          timelineDot: const Color(0xFF5B9BD5),
          decalEmoji: '🚀',
          headerGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B9BD5), Color(0xFF3A7FC1)],
          ),
        );
      case Gender.girl:
        return ProfileTheme(
          accent: const Color(0xFFE891B8),
          soft: const Color(0xFFFDF0F7),
          cardBg: const Color(0xFFFFF5FB),
          timelineDot: const Color(0xFFE891B8),
          decalEmoji: '🌸',
          headerGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE891B8), Color(0xFFD4679F)],
          ),
        );
      case Gender.neutral:
        return ProfileTheme(
          accent: const Color(0xFFFFB347),
          soft: const Color(0xFFFFF8EE),
          cardBg: const Color(0xFFFFFBF5),
          timelineDot: const Color(0xFFFFB347),
          decalEmoji: '⭐',
          headerGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB347), Color(0xFFFF8C00)],
          ),
        );
    }
  }

  static ProfileTheme forProfile(KidProfile profile) => forGender(profile.gender);
}
