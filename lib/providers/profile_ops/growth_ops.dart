import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/growth_entry.dart';
import '../../models/kid_profile.dart';
import '../../services/firestore_service.dart';
import 'profile_mutations.dart';

mixin GrowthOps on StateNotifier<List<KidProfile>?>, ProfileMutations {
  Future<void> addGrowthEntry(int profileIndex, GrowthEntry entry) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    setProfile(profileIndex,
        profile.copyWith(growthEntries: [entry, ...profile.growthEntries]));
    await FirestoreService.saveGrowthEntry(uid, profile.id, entry);
  }

  Future<void> updateGrowthEntry(int profileIndex, GrowthEntry entry) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final entries = profile.growthEntries
        .map((e) => e.id == entry.id ? entry : e)
        .toList();
    setProfile(profileIndex, profile.copyWith(growthEntries: entries));
    await FirestoreService.saveGrowthEntry(uid, profile.id, entry);
  }

  Future<void> deleteGrowthEntry(int profileIndex, String entryId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    setProfile(profileIndex,
        profile.copyWith(
          growthEntries: profile.growthEntries.where((e) => e.id != entryId).toList(),
        ));
    await FirestoreService.deleteGrowthEntry(uid, profile.id, entryId);
  }
}
