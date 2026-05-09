import 'package:flutter/material.dart';
import 'milestone.dart';

enum Gender { boy, girl, neutral }

class KidProfile {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final Color color;
  final Gender gender;
  final String? backgroundImagePath; // device-local only, not synced to cloud
  final List<Milestone> milestones;

  KidProfile({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.color,
    this.gender = Gender.neutral,
    this.backgroundImagePath,
    this.milestones = const [],
  });

  String get ageText {
    final now = DateTime.now();
    final years = now.year - dateOfBirth.year;
    final months = now.month - dateOfBirth.month + years * 12;
    final days = now.difference(dateOfBirth).inDays;

    if (days < 1) return 'Today';
    if (days < 7) return '${days}d old';
    if (days < 30) return '${(days / 7).floor()}w old';
    if (months < 24) return '${months}mo old';
    final yrs = months ~/ 12;
    final mo = months % 12;
    return mo > 0 ? '${yrs}yr ${mo}mo old' : '${yrs}yr old';
  }

  KidProfile copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    Color? color,
    Gender? gender,
    String? backgroundImagePath,
    bool clearBackground = false,
    List<Milestone>? milestones,
  }) =>
      KidProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        color: color ?? this.color,
        gender: gender ?? this.gender,
        backgroundImagePath: clearBackground ? null : (backgroundImagePath ?? this.backgroundImagePath),
        milestones: milestones ?? this.milestones,
      );

  // milestones stored in subcollection; backgroundImagePath is device-local
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'color': color.toARGB32(),
        'gender': gender.name,
      };

  factory KidProfile.fromJson(Map<String, dynamic> j) => KidProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        dateOfBirth: DateTime.parse(j['dateOfBirth'] as String),
        color: Color(j['color'] as int),
        gender: Gender.values.firstWhere(
          (g) => g.name == (j['gender'] as String? ?? 'neutral'),
          orElse: () => Gender.neutral,
        ),
      );
}
