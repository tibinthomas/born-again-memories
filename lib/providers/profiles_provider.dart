import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attachment.dart';
import '../models/baby_document.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../models/reminder.dart';
import '../models/saved_link.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';
import '../utils/profile_theme.dart';

class ProfilesNotifier extends StateNotifier<List<KidProfile>?> {
  final String uid;

  // null = initial load in progress, [] = loaded/empty, [...] = loaded with data
  ProfilesNotifier(this.uid) : super(uid.isNotEmpty ? null : <KidProfile>[]) {
    if (uid.isNotEmpty) _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      FirestoreService.saveUserMeta(uid, user!.email!, user.displayName);
    }
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

  // ── Reminders ────────────────────────────────────────────────────────────

  Future<void> addReminder(int profileIndex, Reminder reminder) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final updated = profile.copyWith(reminders: [...profile.reminders, reminder]);
    _setProfile(profileIndex, updated);
    await FirestoreService.saveReminder(uid, profile.id, reminder);
    await NotificationService.scheduleReminder(reminder, profile.name);
  }

  Future<void> addReminderToProfiles(List<int> profileIndices, Reminder reminder) async {
    for (final profileIndex in profileIndices) {
      final profile = (state ?? <KidProfile>[])[profileIndex];
      final updated = profile.copyWith(reminders: [...profile.reminders, reminder]);
      _setProfile(profileIndex, updated);
      await FirestoreService.saveReminder(uid, profile.id, reminder);
      await NotificationService.scheduleReminder(reminder, profile.name);
    }
  }

  Future<void> updateReminder(int profileIndex, Reminder reminder) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final reminders = profile.reminders
        .map((r) => r.id == reminder.id ? reminder : r)
        .toList();
    _setProfile(profileIndex, profile.copyWith(reminders: reminders));
    await FirestoreService.saveReminder(uid, profile.id, reminder);
    await NotificationService.cancelReminder(reminder.id);
    await NotificationService.scheduleReminder(reminder, profile.name);
  }

  Future<void> deleteReminder(int profileIndex, String reminderId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final reminders = profile.reminders.where((r) => r.id != reminderId).toList();
    _setProfile(profileIndex, profile.copyWith(reminders: reminders));
    await FirestoreService.deleteReminder(uid, profile.id, reminderId);
    await NotificationService.cancelReminder(reminderId);
  }

  Future<void> markReminderDone(int profileIndex, String reminderId, bool done) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final reminders = profile.reminders
        .map((r) => r.id == reminderId ? r.copyWith(isDone: done) : r)
        .toList();
    _setProfile(profileIndex, profile.copyWith(reminders: reminders));
    final reminder = reminders.firstWhere((r) => r.id == reminderId);
    await FirestoreService.saveReminder(uid, profile.id, reminder);
    if (done) {
      await NotificationService.cancelReminder(reminderId);
    } else {
      await NotificationService.scheduleReminder(reminder, profile.name);
    }
  }

  Future<void> muteReminder(int profileIndex, String reminderId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final reminders = profile.reminders
        .map((r) => r.id == reminderId ? r.copyWith(isMuted: true) : r)
        .toList();
    _setProfile(profileIndex, profile.copyWith(reminders: reminders));
    final reminder = reminders.firstWhere((r) => r.id == reminderId);
    await FirestoreService.saveReminder(uid, profile.id, reminder);
    await NotificationService.cancelReminder(reminderId);
  }

  Future<void> unmuteReminder(int profileIndex, String reminderId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final reminders = profile.reminders
        .map((r) => r.id == reminderId ? r.copyWith(isMuted: false) : r)
        .toList();
    _setProfile(profileIndex, profile.copyWith(reminders: reminders));
    final reminder = reminders.firstWhere((r) => r.id == reminderId);
    await FirestoreService.saveReminder(uid, profile.id, reminder);
    await NotificationService.scheduleReminder(reminder, profile.name);
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  Future<void> addDocument(int profileIndex, BabyDocument doc) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    _setProfile(profileIndex,
        profile.copyWith(documents: [...profile.documents, doc]));
    await FirestoreService.saveDocument(uid, profile.id, doc);
  }

  Future<void> addDocumentToProfiles(List<int> profileIndices, BabyDocument doc) async {
    for (final profileIndex in profileIndices) {
      final profile = (state ?? <KidProfile>[])[profileIndex];
      _setProfile(profileIndex,
          profile.copyWith(documents: [...profile.documents, doc]));
      await FirestoreService.saveDocument(uid, profile.id, doc);
    }
  }

  Future<void> deleteDocument(int profileIndex, String docId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    _setProfile(profileIndex,
        profile.copyWith(
          documents: profile.documents.where((d) => d.id != docId).toList(),
        ));
    await FirestoreService.deleteDocument(uid, profile.id, docId);
  }

  // ── Saved links ─────────────────────────────────────────────────────────────

  Future<void> addLink(int profileIndex, SavedLink link) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    _setProfile(profileIndex, profile.copyWith(links: [link, ...profile.links]));
    await FirestoreService.saveLink(uid, profile.id, link);
  }

  Future<void> addLinkToProfiles(List<int> profileIndices, SavedLink link) async {
    for (final profileIndex in profileIndices) {
      final list = state ?? <KidProfile>[];
      final profile = list[profileIndex];
      _setProfile(profileIndex, profile.copyWith(links: [link, ...profile.links]));
      await FirestoreService.saveLink(uid, profile.id, link);
    }
  }

  Future<void> updateLink(int profileIndex, SavedLink link) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    final links = profile.links.map((item) => item.id == link.id ? link : item).toList();
    _setProfile(profileIndex, profile.copyWith(links: links));
    await FirestoreService.saveLink(uid, profile.id, link);
  }

  Future<void> deleteLink(int profileIndex, String linkId) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    final links = profile.links.where((item) => item.id != linkId).toList();
    _setProfile(profileIndex, profile.copyWith(links: links));
    await FirestoreService.deleteLink(uid, profile.id, linkId);
  }

  Future<void> toggleMilestoneFavorite(int profileIndex, String milestoneId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final milestones = profile.milestones
        .map((m) => m.id == milestoneId ? m.copyWith(isFavorite: !m.isFavorite) : m)
        .toList();
    _setProfile(profileIndex, profile.copyWith(milestones: milestones));
    final milestone = milestones.firstWhere((m) => m.id == milestoneId);
    await FirestoreService.saveMilestone(uid, profile.id, milestone);
  }

  Future<void> toggleLinkFavorite(int profileIndex, String linkId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final links = profile.links
        .map((l) => l.id == linkId ? l.copyWith(isFavorite: !l.isFavorite) : l)
        .toList();
    _setProfile(profileIndex, profile.copyWith(links: links));
    final link = links.firstWhere((l) => l.id == linkId);
    await FirestoreService.saveLink(uid, profile.id, link);
  }

  Future<void> toggleDocumentFavorite(int profileIndex, String docId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final documents = profile.documents
        .map((d) => d.id == docId ? d.copyWith(isFavorite: !d.isFavorite) : d)
        .toList();
    _setProfile(profileIndex, profile.copyWith(documents: documents));
    final doc = documents.firstWhere((d) => d.id == docId);
    await FirestoreService.saveDocument(uid, profile.id, doc);
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
