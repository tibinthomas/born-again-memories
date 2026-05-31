import 'package:flutter/material.dart';
import 'custom_spark.dart';

class AppSettings {
  final String? customIcon; // local path, device-only (not synced)
  final bool soundEnabled;
  final double soundVolume;
  final bool hapticEnabled;
  final bool animationsEnabled;
  final Color themeColor;
  // Feature toggles — all default true so existing users see everything
  final bool growthTrackingEnabled;
  final bool checklistEnabled;
  final bool sparksEnabled;
  final bool remindersEnabled;
  final bool documentsEnabled;
  final bool linksEnabled;
  final bool storiesEnabled;
  final bool forumEnabled;
  final bool futurePlansEnabled;
  final List<String> menuOrder;
  // User-defined custom sparks (global across all profiles)
  final List<CustomSpark> customSparks;

  AppSettings({
    this.customIcon,
    this.soundEnabled = true,
    this.soundVolume = 0.7,
    this.hapticEnabled = true,
    this.animationsEnabled = true,
    this.themeColor = Colors.pinkAccent,
    this.growthTrackingEnabled = true,
    this.checklistEnabled = true,
    this.sparksEnabled = true,
    this.remindersEnabled = true,
    this.documentsEnabled = true,
    this.linksEnabled = true,
    this.storiesEnabled = true,
    this.forumEnabled = true,
    this.futurePlansEnabled = true,
    this.menuOrder = const [
      'growth', 'checklist', 'sparks', 'stories', 'forum',
      'documents', 'links', 'feed', 'reminders', 'future_plans',
    ],
    this.customSparks = const [],
  });

  AppSettings copyWith({
    String? customIcon,
    bool? soundEnabled,
    double? soundVolume,
    bool? hapticEnabled,
    bool? animationsEnabled,
    Color? themeColor,
    bool? growthTrackingEnabled,
    bool? checklistEnabled,
    bool? sparksEnabled,
    bool? remindersEnabled,
    bool? documentsEnabled,
    bool? linksEnabled,
    bool? storiesEnabled,
    bool? forumEnabled,
    bool? futurePlansEnabled,
    List<String>? menuOrder,
    List<CustomSpark>? customSparks,
    bool clearCustomIcon = false,
  }) =>
      AppSettings(
        customIcon: clearCustomIcon ? null : customIcon ?? this.customIcon,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        soundVolume: soundVolume ?? this.soundVolume,
        hapticEnabled: hapticEnabled ?? this.hapticEnabled,
        animationsEnabled: animationsEnabled ?? this.animationsEnabled,
        themeColor: themeColor ?? this.themeColor,
        growthTrackingEnabled: growthTrackingEnabled ?? this.growthTrackingEnabled,
        checklistEnabled: checklistEnabled ?? this.checklistEnabled,
        sparksEnabled: sparksEnabled ?? this.sparksEnabled,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        documentsEnabled: documentsEnabled ?? this.documentsEnabled,
        linksEnabled: linksEnabled ?? this.linksEnabled,
        storiesEnabled: storiesEnabled ?? this.storiesEnabled,
        forumEnabled: forumEnabled ?? this.forumEnabled,
        futurePlansEnabled: futurePlansEnabled ?? this.futurePlansEnabled,
        menuOrder: menuOrder ?? this.menuOrder,
        customSparks: customSparks ?? this.customSparks,
      );

  Map<String, dynamic> toJson() => {
        'soundEnabled': soundEnabled,
        'soundVolume': soundVolume,
        'hapticEnabled': hapticEnabled,
        'animationsEnabled': animationsEnabled,
        'themeColor': themeColor.toARGB32(),
        'growthTrackingEnabled': growthTrackingEnabled,
        'checklistEnabled': checklistEnabled,
        'sparksEnabled': sparksEnabled,
        'remindersEnabled': remindersEnabled,
        'documentsEnabled': documentsEnabled,
        'linksEnabled': linksEnabled,
        'storiesEnabled': storiesEnabled,
        'forumEnabled': forumEnabled,
        'futurePlansEnabled': futurePlansEnabled,
        'menuOrder': menuOrder,
        if (customSparks.isNotEmpty)
          'customSparks': customSparks.map((s) => s.toJson()).toList(),
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        soundEnabled: j['soundEnabled'] as bool? ?? true,
        soundVolume: (j['soundVolume'] as num?)?.toDouble() ?? 0.7,
        hapticEnabled: j['hapticEnabled'] as bool? ?? true,
        animationsEnabled: j['animationsEnabled'] as bool? ?? true,
        themeColor:
            Color(j['themeColor'] as int? ?? Colors.pinkAccent.toARGB32()),
        growthTrackingEnabled: j['growthTrackingEnabled'] as bool? ?? true,
        checklistEnabled: j['checklistEnabled'] as bool? ?? true,
        sparksEnabled: j['sparksEnabled'] as bool? ?? true,
        remindersEnabled: j['remindersEnabled'] as bool? ?? true,
        documentsEnabled: j['documentsEnabled'] as bool? ?? true,
        linksEnabled: j['linksEnabled'] as bool? ?? true,
        storiesEnabled: j['storiesEnabled'] as bool? ?? true,
        forumEnabled: j['forumEnabled'] as bool? ?? true,
        futurePlansEnabled: j['futurePlansEnabled'] as bool? ?? true,
        menuOrder: () {
          const def = [
            'growth', 'checklist', 'sparks', 'stories', 'forum',
            'documents', 'links', 'feed', 'reminders', 'future_plans',
          ];
          final stored = (j['menuOrder'] as List<dynamic>?)?.cast<String>() ?? [];
          if (stored.isEmpty) return def;
          // append any keys added in newer versions
          final missing = def.where((k) => !stored.contains(k)).toList();
          return [...stored, ...missing];
        }(),
        customSparks: (j['customSparks'] as List<dynamic>?)
                ?.map((e) => CustomSpark.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );
}
