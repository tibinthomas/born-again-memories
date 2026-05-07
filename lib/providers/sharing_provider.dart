import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class SharedEmailsNotifier extends StateNotifier<List<String>> {
  final String uid;

  SharedEmailsNotifier(this.uid) : super([]) {
    if (uid.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final data = await FirestoreService.getUserDoc(uid);
    final emails = List<String>.from(data?['sharedWithEmails'] as List? ?? []);
    if (mounted) state = emails;
  }

  Future<void> add(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || state.contains(e)) return;
    state = [...state, e];
    await FirestoreService.updateUserDoc(uid, {'sharedWithEmails': state});
  }

  Future<void> remove(String email) async {
    state = state.where((e) => e != email).toList();
    await FirestoreService.updateUserDoc(uid, {'sharedWithEmails': state});
  }
}

final sharedEmailsProvider =
    StateNotifierProvider<SharedEmailsNotifier, List<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  return SharedEmailsNotifier(uid);
});
