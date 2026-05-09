import 'kid_profile.dart';
import 'milestone.dart';

class SharedMilestoneEntry {
  final Milestone milestone;
  final String babyName;
  final Gender babyGender;

  const SharedMilestoneEntry({
    required this.milestone,
    required this.babyName,
    required this.babyGender,
  });
}

class SharedSenderGroup {
  final String uid;
  final String displayName;
  final String email;
  final List<SharedMilestoneEntry> milestones;

  const SharedSenderGroup({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.milestones,
  });
}
