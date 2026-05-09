import 'package:flutter/material.dart';
import 'baby_document.dart';
import 'milestone.dart';
import 'reminder.dart';
import 'saved_link.dart';

enum Gender { boy, girl, neutral }

class KidProfile {
  final String id;
  final String name;
  final String? nickname;
  final DateTime dateOfBirth;
  final DateTime? timeOfBirth;
  final Color color;
  final Gender gender;
  final String? avatarImagePath; // device-local only, not synced to cloud
  final String? backgroundImagePath; // device-local only, not synced to cloud
  final List<Milestone> milestones;
  final List<Reminder> reminders;
  final List<BabyDocument> documents;
  final List<SavedLink> links;

  KidProfile({
    required this.id,
    required this.name,
    this.nickname,
    required this.dateOfBirth,
    this.timeOfBirth,
    required this.color,
    this.gender = Gender.neutral,
    this.avatarImagePath,
    this.backgroundImagePath,
    this.milestones = const [],
    this.reminders = const [],
    this.documents = const [],
    this.links = const [],
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
    String? nickname,
    bool clearNickname = false,
    DateTime? dateOfBirth,
    DateTime? timeOfBirth,
    bool clearTimeOfBirth = false,
    Color? color,
    Gender? gender,
    String? avatarImagePath,
    bool clearAvatar = false,
    String? backgroundImagePath,
    bool clearBackground = false,
    List<Milestone>? milestones,
    List<Reminder>? reminders,
    List<BabyDocument>? documents,
    List<SavedLink>? links,
  }) =>
      KidProfile(
        id: id ?? this.id,
        name: name ?? this.name,
        nickname: clearNickname ? null : (nickname ?? this.nickname),
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        timeOfBirth: clearTimeOfBirth ? null : (timeOfBirth ?? this.timeOfBirth),
        color: color ?? this.color,
        gender: gender ?? this.gender,
        avatarImagePath: clearAvatar ? null : (avatarImagePath ?? this.avatarImagePath),
        backgroundImagePath:
            clearBackground ? null : (backgroundImagePath ?? this.backgroundImagePath),
        milestones: milestones ?? this.milestones,
        reminders: reminders ?? this.reminders,
        documents: documents ?? this.documents,
        links: links ?? this.links,
      );

  // milestones + reminders stored in subcollections; backgroundImagePath is device-local
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'timeOfBirth': timeOfBirth?.toIso8601String(),
        'color': color.toARGB32(),
        'gender': gender.name,
      };

  factory KidProfile.fromJson(Map<String, dynamic> j) => KidProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        nickname: j['nickname'] as String?,
        dateOfBirth: DateTime.parse(j['dateOfBirth'] as String),
        timeOfBirth: j['timeOfBirth'] != null ? DateTime.parse(j['timeOfBirth'] as String) : null,
        color: Color(j['color'] as int),
        gender: Gender.values.firstWhere(
          (g) => g.name == (j['gender'] as String? ?? 'neutral'),
          orElse: () => Gender.neutral,
        ),
      );
}
