import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings());

  void update(AppSettings newSettings) => state = newSettings;
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
