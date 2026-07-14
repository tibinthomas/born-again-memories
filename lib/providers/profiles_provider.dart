import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kid_profile.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import 'auth_provider.dart';
import 'profile_ops/attachments_ops.dart';
import 'profile_ops/dev_checklist_ops.dart';
import 'profile_ops/documents_ops.dart';
import 'profile_ops/future_plans_ops.dart';
import 'profile_ops/growth_ops.dart';
import 'profile_ops/links_ops.dart';
import 'profile_ops/milestones_ops.dart';
import 'profile_ops/profile_mutations.dart';
import 'profile_ops/reminders_ops.dart';
import '../utils/profile_theme.dart';
import '../utils/theme_preset.dart';

/// Owns the signed-in user's list of [KidProfile]s. Domain-specific
/// mutators (milestones, reminders, documents, links, growth, future
/// plans, dev checklist, attachments) live in the `profile_ops/` mixins
/// mixed in below — this class keeps only profile-list CRUD and the
/// shared load/state-replace plumbing they build on.
class ProfilesNotifier extends StateNotifier<List<KidProfile>?>
    with
        ProfileMutations,
        MilestonesOps,
        RemindersOps,
        DocumentsOps,
        LinksOps,
        DevChecklistOps,
        GrowthOps,
        FuturePlansOps,
        AttachmentsOps {
  @override
  final String uid;
  @override
  final Ref ref;

  // null = initial load in progress, [] = loaded/empty, [...] = loaded with data
  ProfilesNotifier(this.uid, this.ref) : super(uid.isNotEmpty ? null : <KidProfile>[]) {
    if (uid.isNotEmpty) _load();
  }

  Future<void> _load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.email != null) {
        FirestoreService.saveUserMeta(uid, user!.email!, user.displayName);
      }
      final loadedProfiles = await FirestoreService.loadProfiles(uid);
      final profiles = <KidProfile>[];
      for (final profile in loadedProfiles) {
        final avatarPath = await LocalStorageService.resolveAvatarPath(
          profile.id,
          profile.avatarImagePath,
        );
        profiles.add(
          avatarPath == profile.avatarImagePath
              ? profile
              : profile.copyWith(
                  avatarImagePath: avatarPath,
                  clearAvatar: avatarPath == null,
                ),
        );
      }
      if (mounted) state = profiles;
    } catch (e) {
      debugPrint('ProfilesNotifier._load error: $e');
      if (mounted) state = <KidProfile>[];
    }
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
    setProfile(index, updated);
    await FirestoreService.saveProfile(uid, updated);
  }

  Future<void> deleteProfile(int index) async {
    final list = state ?? <KidProfile>[];
    final profile = list[index];
    state = <KidProfile>[...list]..removeAt(index);
    // Keep the selected index valid now that the list is shorter.
    final remaining = state?.length ?? 0;
    final selected = ref.read(selectedProfileIndexProvider);
    if (selected >= remaining) {
      ref.read(selectedProfileIndexProvider.notifier).state =
          remaining == 0 ? 0 : remaining - 1;
    }
    await FirestoreService.deleteProfile(uid, profile.id);
  }
}

final profilesProvider =
    StateNotifierProvider<ProfilesNotifier, List<KidProfile>?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid ?? '';
  return ProfilesNotifier(uid, ref);
});

final selectedProfileIndexProvider = StateProvider<int>((ref) {
  // Reset to the first profile whenever the signed-in user changes, so a
  // stale index from a previous account can't point past the new list.
  ref.watch(authStateProvider.select((a) => a.value?.uid));
  return 0;
});

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

/// Form state for the "edit profile" sheet, keyed by the [KidProfile] being
/// edited. Holds only the fields that can change through async pickers
/// (avatar/background upload) or dialogs (date/time) — [EditProfileSheet]
/// keeps simple text fields (name, nickname) as local `TextEditingController`s,
/// same split used by [AddProfileFormNotifier]/`AddProfileSheet`.
class EditProfileFormState {
  final DateTime dob;
  final DateTime? timeOfBirth;
  final Gender gender;
  final String themePresetId;
  final String? avatarImagePath;
  final String? backgroundImagePath;
  final bool isUploadingAvatar;
  final bool isUploadingBackground;

  const EditProfileFormState({
    required this.dob,
    this.timeOfBirth,
    required this.gender,
    required this.themePresetId,
    this.avatarImagePath,
    this.backgroundImagePath,
    this.isUploadingAvatar = false,
    this.isUploadingBackground = false,
  });

  EditProfileFormState copyWith({
    DateTime? dob,
    DateTime? timeOfBirth,
    bool clearTimeOfBirth = false,
    Gender? gender,
    String? themePresetId,
    String? avatarImagePath,
    bool clearAvatar = false,
    String? backgroundImagePath,
    bool clearBackground = false,
    bool? isUploadingAvatar,
    bool? isUploadingBackground,
  }) =>
      EditProfileFormState(
        dob: dob ?? this.dob,
        timeOfBirth: clearTimeOfBirth ? null : (timeOfBirth ?? this.timeOfBirth),
        gender: gender ?? this.gender,
        themePresetId: themePresetId ?? this.themePresetId,
        avatarImagePath: clearAvatar ? null : (avatarImagePath ?? this.avatarImagePath),
        backgroundImagePath:
            clearBackground ? null : (backgroundImagePath ?? this.backgroundImagePath),
        isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
        isUploadingBackground: isUploadingBackground ?? this.isUploadingBackground,
      );
}

class EditProfileFormNotifier extends StateNotifier<EditProfileFormState> {
  EditProfileFormNotifier(KidProfile profile)
      : super(EditProfileFormState(
          dob: profile.dateOfBirth,
          timeOfBirth: profile.timeOfBirth,
          gender: profile.gender,
          themePresetId: profile.themePresetId ??
              ThemePreset.defaultIdForGender(profile.gender.name),
          avatarImagePath: profile.avatarImagePath,
          backgroundImagePath: profile.backgroundImagePath,
        ));

  void setDob(DateTime dob) => state = state.copyWith(dob: dob);
  void setTimeOfBirth(DateTime? time) => time == null
      ? state = state.copyWith(clearTimeOfBirth: true)
      : state = state.copyWith(timeOfBirth: time);
  void setGenderAndPreset(Gender gender, String presetId) =>
      state = state.copyWith(gender: gender, themePresetId: presetId);
  void setThemePreset(String id) => state = state.copyWith(themePresetId: id);
  void setAvatarPath(String? path) => path == null
      ? state = state.copyWith(clearAvatar: true)
      : state = state.copyWith(avatarImagePath: path);
  void setBackgroundPath(String? path) => path == null
      ? state = state.copyWith(clearBackground: true)
      : state = state.copyWith(backgroundImagePath: path);
  void setUploadingAvatar(bool value) => state = state.copyWith(isUploadingAvatar: value);
  void setUploadingBackground(bool value) => state = state.copyWith(isUploadingBackground: value);
}

final editProfileFormProvider = StateNotifierProvider.autoDispose
    .family<EditProfileFormNotifier, EditProfileFormState, KidProfile>(
  (ref, profile) => EditProfileFormNotifier(profile),
);
