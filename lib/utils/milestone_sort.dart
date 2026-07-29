import '../models/milestone.dart';

List<Milestone> milestonesNewestFirst(Iterable<Milestone> milestones) {
  return milestones.toList()..sort((a, b) => b.date.compareTo(a.date));
}
