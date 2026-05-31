import 'package:flutter/material.dart';
import 'baby_document.dart';
import 'future_plan.dart';
import 'growth_entry.dart';
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
  final String? themePresetId;
  final List<Milestone> milestones;
  final List<Reminder> reminders;
  final List<BabyDocument> documents;
  final List<SavedLink> links;
  final List<GrowthEntry> growthEntries;
  final List<FuturePlan> futurePlans;
  // IDs of CDC developmental milestones the parent has marked as achieved.
  final Set<String> checkedMilestones;
  // CDC milestone ID → app milestone ID (memory created from that checklist item).
  final Map<String, String> devMilestoneLinks;

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
    this.themePresetId,
    this.milestones = const [],
    this.reminders = const [],
    this.documents = const [],
    this.links = const [],
    this.growthEntries = const [],
    this.futurePlans = const [],
    this.checkedMilestones = const {},
    this.devMilestoneLinks = const {},
  });

  String get ageText {
    final now = DateTime.now();
    final totalDays = now.difference(dateOfBirth).inDays;

    if (totalDays < 1) return 'Today';
    if (totalDays < 7) return '${totalDays}d old';
    if (totalDays < 30) return '${(totalDays / 7).floor()}w old';

    int y = now.year - dateOfBirth.year;
    int m = now.month - dateOfBirth.month;
    int d = now.day - dateOfBirth.day;
    if (d < 0) {
      m -= 1;
      d += DateTime(now.year, now.month, 0).day;
    }
    if (m < 0) {
      y -= 1;
      m += 12;
    }

    final totalMonths = y * 12 + m;
    if (totalMonths < 24) {
      return d > 0 ? '${totalMonths}mo ${d}d old' : '${totalMonths}mo old';
    }
    final parts = ['${y}yr'];
    if (m > 0) parts.add('${m}mo');
    if (d > 0) parts.add('${d}d');
    return '${parts.join(' ')} old';
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
    String? themePresetId,
    bool clearThemePreset = false,
    List<Milestone>? milestones,
    List<Reminder>? reminders,
    List<BabyDocument>? documents,
    List<SavedLink>? links,
    List<GrowthEntry>? growthEntries,
    List<FuturePlan>? futurePlans,
    Set<String>? checkedMilestones,
    Map<String, String>? devMilestoneLinks,
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
        themePresetId: clearThemePreset ? null : (themePresetId ?? this.themePresetId),
        milestones: milestones ?? this.milestones,
        reminders: reminders ?? this.reminders,
        documents: documents ?? this.documents,
        links: links ?? this.links,
        growthEntries: growthEntries ?? this.growthEntries,
        futurePlans: futurePlans ?? this.futurePlans,
        checkedMilestones: checkedMilestones ?? this.checkedMilestones,
        devMilestoneLinks: devMilestoneLinks ?? this.devMilestoneLinks,
      );

  // milestones + reminders stored in subcollections; backgroundImagePath is device-local.
  // When running on web the paths are Drive thumbnail URLs — those are synced to Firestore.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'timeOfBirth': timeOfBirth?.toIso8601String(),
        'color': color.toARGB32(),
        'gender': gender.name,
        if (themePresetId != null) 'themePresetId': themePresetId,
        if (avatarImagePath != null && avatarImagePath!.startsWith('http'))
          'avatarUrl': avatarImagePath,
        if (backgroundImagePath != null && backgroundImagePath!.startsWith('http'))
          'backgroundUrl': backgroundImagePath,
        if (checkedMilestones.isNotEmpty)
          'checkedMilestones': checkedMilestones.toList(),
        if (devMilestoneLinks.isNotEmpty)
          'devMilestoneLinks': devMilestoneLinks,
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
        themePresetId: j['themePresetId'] as String?,
        avatarImagePath: j['avatarUrl'] as String?,
        backgroundImagePath: j['backgroundUrl'] as String?,
        checkedMilestones: (j['checkedMilestones'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toSet() ??
            {},
        devMilestoneLinks: (j['devMilestoneLinks'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
      );
}
