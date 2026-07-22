enum AppModule {
  memories('memories'),
  childProfiles('childProfiles'),
  growthTracking('growthTracking'),
  developmentChecklist('developmentChecklist'),
  memorySparks('memorySparks'),
  stories('stories'),
  parentingForum('parentingForum'),
  reminders('reminders'),
  documentStorage('documentStorage'),
  savedLinks('savedLinks'),
  futurePlans('futurePlans'),
  familySharing('familySharing'),
  backupAndSync('backupAndSync'),
  accountsAndPrivacy('accountsAndPrivacy'),
  personalizationAndAccessibility('personalizationAndAccessibility');

  const AppModule(this.key);
  final String key;
}

/// App-wide module visibility loaded from the bundled JSON configuration.
/// Missing keys deliberately default to true so a bad config cannot hide
/// shipped functionality.
class FeatureVisibility {
  const FeatureVisibility(this._values);

  final Map<AppModule, bool> _values;

  const FeatureVisibility.allVisible() : _values = const {};

  bool isEnabled(AppModule module) => _values[module] ?? true;

  factory FeatureVisibility.fromJson(Map<String, dynamic> json) {
    return FeatureVisibility({
      for (final module in AppModule.values)
        module: json[module.key] is bool ? json[module.key] as bool : true,
    });
  }
}
