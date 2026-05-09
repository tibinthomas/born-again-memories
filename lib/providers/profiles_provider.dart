import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import '../utils/profile_theme.dart';

class ProfilesNotifier extends StateNotifier<List<KidProfile>?> {
  final String uid;

  // null = initial load in progress, [] = loaded/empty, [...] = loaded with data
  ProfilesNotifier(this.uid) : super(uid.isNotEmpty ? null : <KidProfile>[]) {
    if (uid.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final profiles = await FirestoreService.loadProfiles(uid);
    if (mounted) state = profiles;
  }

  Future<void> addProfile(
    String name,
    DateTime dob,
    Color color, {
    Gender gender = Gender.neutral,
    String? backgroundImagePath,
  }) async {
    final profile = KidProfile(
      id: 'profile_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      dateOfBirth: dob,
      color: color,
      gender: gender,
      backgroundImagePath: backgroundImagePath,
    );
    state = <KidProfile>[...(state ?? []), profile];
    await FirestoreService.saveProfile(uid, profile);
  }

  Future<void> updateProfile(int index, KidProfile updated) async {
    _setProfile(index, updated);
    await FirestoreService.saveProfile(uid, updated);
  }

  Future<void> deleteProfile(int index) async {
    final list = state ?? <KidProfile>[];
    final profile = list[index];
    state = <KidProfile>[...list]..removeAt(index);
    await FirestoreService.deleteProfile(uid, profile.id);
  }

  void updateMilestones(int profileIndex, List<Milestone> milestones) =>
      _setProfile(profileIndex,
          (state ?? <KidProfile>[])[profileIndex].copyWith(milestones: milestones));

  Future<void> prependMilestone(int profileIndex, Milestone milestone) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    _setProfile(profileIndex,
        profile.copyWith(milestones: [milestone, ...profile.milestones]));
    await FirestoreService.saveMilestone(uid, profile.id, milestone);
  }

  Future<void> updateMilestone(int profileIndex, Milestone milestone) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    final milestones = profile.milestones
        .map((m) => m.id == milestone.id ? milestone : m)
        .toList();
    _setProfile(profileIndex, profile.copyWith(milestones: milestones));
    await FirestoreService.saveMilestone(uid, profile.id, milestone);
  }

  Future<void> deleteMilestone(int profileIndex, String milestoneId) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    final milestones =
        profile.milestones.where((m) => m.id != milestoneId).toList();
    _setProfile(profileIndex, profile.copyWith(milestones: milestones));
    await FirestoreService.deleteMilestone(uid, profile.id, milestoneId);
  }

  void _setProfile(int index, KidProfile profile) {
    final list = <KidProfile>[...(state ?? [])];
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
    state = (state ?? <KidProfile>[]).map((profile) {
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
    StateNotifierProvider<ProfilesNotifier, List<KidProfile>?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  return ProfilesNotifier(uid);
});

final selectedProfileIndexProvider = StateProvider<int>((ref) => 0);

class AddProfileFormState {
  final DateTime dob;
  final Color color;
  final Gender gender;
  final String? backgroundImagePath;

  const AddProfileFormState({
    required this.dob,
    required this.color,
    this.gender = Gender.neutral,
    this.backgroundImagePath,
  });

  AddProfileFormState copyWith({
    DateTime? dob,
    Color? color,
    Gender? gender,
    String? backgroundImagePath,
    bool clearBackground = false,
  }) =>
      AddProfileFormState(
        dob: dob ?? this.dob,
        color: color ?? this.color,
        gender: gender ?? this.gender,
        backgroundImagePath: clearBackground ? null : (backgroundImagePath ?? this.backgroundImagePath),
      );
}

class AddProfileFormNotifier extends StateNotifier<AddProfileFormState> {
  AddProfileFormNotifier()
      : super(AddProfileFormState(dob: DateTime.now(), color: ProfileTheme.forGender(Gender.neutral).accent));

  void setDob(DateTime dob) => state = state.copyWith(dob: dob);
  void setColor(Color color) => state = state.copyWith(color: color);
  void setGender(Gender gender) => state = state.copyWith(
        gender: gender,
        color: ProfileTheme.forGender(gender).accent,
      );
  void setBackgroundImagePath(String? path) => state = path == null
      ? state.copyWith(clearBackground: true)
      : state.copyWith(backgroundImagePath: path);
}

final addProfileFormProvider = StateNotifierProvider.autoDispose<
    AddProfileFormNotifier, AddProfileFormState>(
  (ref) => AddProfileFormNotifier(),
);
