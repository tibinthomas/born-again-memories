import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/kid_profile.dart';
import '../../models/milestone.dart';
import '../../services/firestore_service.dart';
import 'profile_mutations.dart';

mixin DevChecklistOps on StateNotifier<List<KidProfile>?>, ProfileMutations {
  Future<void> toggleDevMilestone(int profileIndex, String milestoneId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final checked = Set<String>.from(profile.checkedMilestones);
    if (checked.contains(milestoneId)) {
      checked.remove(milestoneId);
    } else {
      checked.add(milestoneId);
    }
    final updatedProfile = profile.copyWith(checkedMilestones: checked);
    setProfile(profileIndex, updatedProfile);
    await FirestoreService.saveProfile(uid, updatedProfile);
  }

  /// Creates a milestone memory from a CDC checklist item, marks it done,
  /// and stores the link so the checklist can show the 📸 badge.
  Future<void> addMilestoneFromChecklist(
    int profileIndex,
    String cdcMilestoneId,
    Milestone milestone,
  ) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final checked = Set<String>.from(profile.checkedMilestones)
      ..add(cdcMilestoneId);
    final links = Map<String, String>.from(profile.devMilestoneLinks)
      ..[cdcMilestoneId] = milestone.id;
    final updatedProfile = profile.copyWith(
      milestones: [milestone, ...profile.milestones],
      checkedMilestones: checked,
      devMilestoneLinks: links,
    );
    setProfile(profileIndex, updatedProfile);
    await Future.wait([
      FirestoreService.saveMilestone(uid, profile.id, milestone),
      FirestoreService.saveProfile(uid, updatedProfile),
    ]);
  }
}
