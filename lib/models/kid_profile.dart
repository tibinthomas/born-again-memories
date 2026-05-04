import 'package:flutter/material.dart';
import 'milestone.dart';

class KidProfile {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final Color color;
  final List<Milestone> milestones;

  KidProfile({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.color,
    this.milestones = const [],
  });

  String get ageText {
    final age = DateTime.now().difference(dateOfBirth);
    if (age.inDays < 1) return 'Today';
    if (age.inDays < 7) return '${age.inDays}d';
    if (age.inDays < 30) return '${(age.inDays / 7).ceil()}w';
    if (age.inDays < 365) return '${(age.inDays / 30).ceil()}m';
    return '${(age.inDays / 365).ceil()}y';
  }

  KidProfile copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    Color? color,
    List<Milestone>? milestones,
  }) =>
      KidProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        color: color ?? this.color,
        milestones: milestones ?? this.milestones,
      );

  // milestones are stored in a subcollection, not embedded
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'color': color.toARGB32(),
      };

  factory KidProfile.fromJson(Map<String, dynamic> j) => KidProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        dateOfBirth: DateTime.parse(j['dateOfBirth'] as String),
        color: Color(j['color'] as int),
      );
}
