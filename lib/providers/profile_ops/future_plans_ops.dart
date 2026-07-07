import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/future_plan.dart';
import '../../models/kid_profile.dart';
import '../../services/firestore_service.dart';
import 'profile_mutations.dart';

mixin FuturePlansOps on StateNotifier<List<KidProfile>?>, ProfileMutations {
  Future<void> addFuturePlan(int profileIndex, FuturePlan plan) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    setProfile(profileIndex,
        profile.copyWith(futurePlans: [plan, ...profile.futurePlans]));
    await FirestoreService.saveFuturePlan(uid, profile.id, plan);
  }

  Future<void> updateFuturePlan(int profileIndex, FuturePlan plan) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final plans = profile.futurePlans
        .map((p) => p.id == plan.id ? plan : p)
        .toList();
    setProfile(profileIndex, profile.copyWith(futurePlans: plans));
    await FirestoreService.saveFuturePlan(uid, profile.id, plan);
  }

  Future<void> deleteFuturePlan(int profileIndex, String planId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    setProfile(profileIndex,
        profile.copyWith(
          futurePlans: profile.futurePlans.where((p) => p.id != planId).toList(),
        ));
    await FirestoreService.deleteFuturePlan(uid, profile.id, planId);
  }
}
