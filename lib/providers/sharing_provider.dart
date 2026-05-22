import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/share_invite.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class SharedEmailsNotifier extends StateNotifier<List<ShareInvite>> {
  final String uid;

  SharedEmailsNotifier(this.uid) : super([]) {
    if (uid.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final data = await FirestoreService.getUserDoc(uid);
    final emails = List<String>.from(data?['sharedWithEmails'] as List? ?? []);
    final metaRaw = data?['inviteMeta'] as Map<String, dynamic>? ?? {};

    final invites = await Future.wait(emails.map((email) async {
      final raw = metaRaw[email];
      final sentAt = raw != null && raw['sentAt'] is Timestamp
          ? (raw['sentAt'] as Timestamp).toDate()
          : DateTime.now().subtract(const Duration(days: 1));

      final isRegistered = await FirestoreService.isEmailRegistered(email);
      final daysSinceSent = DateTime.now().difference(sentAt).inDays;

      final status = isRegistered
          ? ShareInviteStatus.active
          : daysSinceSent > 30
              ? ShareInviteStatus.expired
              : ShareInviteStatus.pending;

      return ShareInvite(email: email, sentAt: sentAt, status: status);
    }));

    if (mounted) state = invites;
  }

  Future<void> add(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || state.any((i) => i.email == e)) return;

    final now = DateTime.now();
    state = [
      ...state,
      ShareInvite(email: e, sentAt: now, status: ShareInviteStatus.pending),
    ];
    await Future.wait([
      FirestoreService.updateUserDoc(uid, {
        'sharedWithEmails': state.map((i) => i.email).toList(),
      }),
      FirestoreService.setInviteSentAt(uid, e),
    ]);

    // Re-check status in the background after adding
    final isRegistered = await FirestoreService.isEmailRegistered(e);
    if (!mounted) return;
    if (isRegistered) {
      state = state.map((i) => i.email == e
          ? i.copyWith(status: ShareInviteStatus.active)
          : i).toList();
    }
  }

  Future<void> remove(String email) async {
    state = state.where((i) => i.email != email).toList();
    await Future.wait([
      FirestoreService.updateUserDoc(uid, {
        'sharedWithEmails': state.map((i) => i.email).toList(),
      }),
      FirestoreService.removeInviteMeta(uid, email),
    ]);
  }

  Future<void> resend(String email) async {
    final now = DateTime.now();
    state = state.map((i) => i.email == email
        ? i.copyWith(status: ShareInviteStatus.pending, sentAt: now)
        : i).toList();
    await FirestoreService.setInviteSentAt(uid, email);

    // Re-check after resend
    final isRegistered = await FirestoreService.isEmailRegistered(email);
    if (!mounted) return;
    if (isRegistered) {
      state = state.map((i) => i.email == email
          ? i.copyWith(status: ShareInviteStatus.active)
          : i).toList();
    }
  }

  Future<void> refresh() => _load();
}

final sharedEmailsProvider =
    StateNotifierProvider<SharedEmailsNotifier, List<ShareInvite>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  return SharedEmailsNotifier(uid);
});

/// Number of users currently sharing their memories with the signed-in user.
final sharedSendersCountProvider = FutureProvider<int>((ref) async {
  final email = ref.watch(authStateProvider).value?.email;
  if (email == null || email.isEmpty) return 0;
  return FirestoreService.countSharedSenders(email);
});
