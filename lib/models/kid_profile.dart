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
}
