import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final String uid;

  AppSettingsNotifier(this.uid) : super(AppSettings()) {
    if (uid.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final settings = await FirestoreService.loadSettings(uid);
    if (mounted) state = settings;
  }

  Future<void> update(AppSettings newSettings) async {
    state = newSettings;
    if (uid.isNotEmpty) {
      await FirestoreService.saveSettings(uid, newSettings);
    }
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  return AppSettingsNotifier(uid);
});
