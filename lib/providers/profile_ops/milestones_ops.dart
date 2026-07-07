import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/kid_profile.dart';
import '../../models/milestone.dart';
import '../../services/drive_service.dart';
import '../../services/firestore_service.dart';
import '../../services/icloud_service.dart';
import '../auth_provider.dart';
import '../sharing_provider.dart';
import 'profile_mutations.dart';

mixin MilestonesOps on StateNotifier<List<KidProfile>?>, ProfileMutations {
  void updateMilestones(int profileIndex, List<Milestone> milestones) =>
      setProfile(profileIndex,
          (state ?? <KidProfile>[])[profileIndex].copyWith(milestones: milestones));

  Future<void> prependMilestone(int profileIndex, Milestone milestone) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    setProfile(profileIndex,
        profile.copyWith(milestones: [milestone, ...profile.milestones]));
    await FirestoreService.saveMilestone(uid, profile.id, milestone);

    // Notify users who have shared access to this account. Fall back to the
    // Firestore list if sharedEmailsProvider hasn't finished its initial load.
    var sharedEmails = ref
        .read(sharedEmailsProvider)
        .map((i) => i.email)
        .toList();
    if (sharedEmails.isEmpty) {
      final doc = await FirestoreService.getUserDoc(uid);
      sharedEmails =
          List<String>.from(doc?['sharedWithEmails'] as List? ?? []);
    }
    if (sharedEmails.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      final senderName = user?.displayName?.isNotEmpty == true
          ? user!.displayName!
          : user?.email ?? 'Someone';
      unawaited(FirestoreService.sendSharedMilestoneNotifications(
        senderName: senderName,
        recipientEmails: sharedEmails,
        milestoneTitle: milestone.title,
      ));
    }
  }

  Future<void> updateMilestone(int profileIndex, Milestone milestone) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];

    // Delete cloud files for any attachments removed during edit.
    final old = profile.milestones.firstWhere(
      (m) => m.id == milestone.id,
      orElse: () => milestone,
    );
    final kept = milestone.attachments.map((a) => a.id).toSet();
    final removed = old.attachments.where((a) => !kept.contains(a.id));
    if (removed.isNotEmpty) {
      final gs = ref.read(authServiceProvider).googleSignIn;
      for (final a in removed) {
        if (a.driveFileId != null) {
          DriveService.deleteFile(googleSignIn: gs, driveFileId: a.driveFileId!);
        }
        if (a.iCloudFileId != null) {
          ICloudService.deleteFile(a.iCloudFileId!);
        }
      }
    }

    final milestones = profile.milestones
        .map((m) => m.id == milestone.id ? milestone : m)
        .toList();
    setProfile(profileIndex, profile.copyWith(milestones: milestones));
    await FirestoreService.saveMilestone(uid, profile.id, milestone);
  }

  Future<void> deleteMilestone(int profileIndex, String milestoneId) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    final milestone =
        profile.milestones.firstWhere((m) => m.id == milestoneId);

    // Delete cloud files for all attachments in the milestone.
    final gs = ref.read(authServiceProvider).googleSignIn;
    for (final a in milestone.attachments) {
      if (a.driveFileId != null) {
        DriveService.deleteFile(googleSignIn: gs, driveFileId: a.driveFileId!);
      }
      if (a.iCloudFileId != null) {
        ICloudService.deleteFile(a.iCloudFileId!);
      }
    }

    final milestones =
        profile.milestones.where((m) => m.id != milestoneId).toList();
    setProfile(profileIndex, profile.copyWith(milestones: milestones));
    await FirestoreService.deleteMilestone(uid, profile.id, milestoneId);
  }

  Future<void> toggleMilestoneFavorite(int profileIndex, String milestoneId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final milestones = profile.milestones
        .map((m) => m.id == milestoneId ? m.copyWith(isFavorite: !m.isFavorite) : m)
        .toList();
    setProfile(profileIndex, profile.copyWith(milestones: milestones));
    final milestone = milestones.firstWhere((m) => m.id == milestoneId);
    await FirestoreService.saveMilestone(uid, profile.id, milestone);
  }
}
