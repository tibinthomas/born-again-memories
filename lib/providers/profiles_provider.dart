import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

class ProfilesNotifier extends StateNotifier<List<KidProfile>> {
  final String uid;

  ProfilesNotifier(this.uid) : super([]) {
    if (uid.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final profiles = await DatabaseService.loadProfiles(uid);
    if (mounted) state = profiles;
  }

  Future<void> addProfile(String name, DateTime dob, Color color) async {
    final profile = KidProfile(
      id: 'profile_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      dateOfBirth: dob,
      color: color,
    );
    state = [...state, profile];
    await DatabaseService.saveProfile(uid, profile);
  }

  Future<void> deleteProfile(int index) async {
    final profile = state[index];
    final list = [...state];
    list.removeAt(index);
    state = list;
    await DatabaseService.deleteProfile(uid, profile.id);
  }

  void updateMilestones(int profileIndex, List<Milestone> milestones) {
    final profile = state[profileIndex];
    _setProfile(profileIndex, profile.copyWith(milestones: milestones));
  }

  Future<void> prependMilestone(int profileIndex, Milestone milestone) async {
    final profile = state[profileIndex];
    _setProfile(
      profileIndex,
      profile.copyWith(milestones: [milestone, ...profile.milestones]),
    );
    await DatabaseService.saveMilestone(uid, profile.id, milestone);
  }

  void _setProfile(int index, KidProfile profile) {
    final list = [...state];
    list[index] = profile;
    state = list;
  }

  void updateAttachmentBackupStatus(
    String profileId,
    String milestoneId,
    String attachmentId,
    String? driveFileId,
    BackupStatus status,
  ) {
    state = state.map((profile) {
      if (profile.id != profileId) return profile;
      return profile.copyWith(
        milestones: profile.milestones.map((ms) {
          if (ms.id != milestoneId) return ms;
          return ms.copyWith(
            attachments: ms.attachments.map((a) {
              if (a.id != attachmentId) return a;
              return a.copyWith(driveFileId: driveFileId, backupStatus: status);
            }).toList(),
          );
        }).toList(),
      );
    }).toList();
  }
}

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, List<KidProfile>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  return ProfilesNotifier(uid);
});

final selectedProfileIndexProvider = StateProvider<int>((ref) => 0);

// ── Add-profile form state ─────────────────────────────────────────────────────

class AddProfileFormState {
  final DateTime dob;
  final Color color;

  const AddProfileFormState({required this.dob, required this.color});

  AddProfileFormState copyWith({DateTime? dob, Color? color}) =>
      AddProfileFormState(dob: dob ?? this.dob, color: color ?? this.color);
}

class AddProfileFormNotifier extends StateNotifier<AddProfileFormState> {
  AddProfileFormNotifier()
      : super(AddProfileFormState(dob: DateTime.now(), color: Colors.pinkAccent));

  void setDob(DateTime dob) => state = state.copyWith(dob: dob);
  void setColor(Color color) => state = state.copyWith(color: color);
}

final addProfileFormProvider = StateNotifierProvider.autoDispose<
    AddProfileFormNotifier, AddProfileFormState>(
  (ref) => AddProfileFormNotifier(),
);
