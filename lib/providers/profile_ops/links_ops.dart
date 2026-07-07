import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/kid_profile.dart';
import '../../models/saved_link.dart';
import '../../services/firestore_service.dart';
import 'profile_mutations.dart';

mixin LinksOps on StateNotifier<List<KidProfile>?>, ProfileMutations {
  Future<void> addLink(int profileIndex, SavedLink link) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    setProfile(profileIndex, profile.copyWith(links: [link, ...profile.links]));
    await FirestoreService.saveLink(uid, profile.id, link);
  }

  Future<void> addLinkToProfiles(List<int> profileIndices, SavedLink link) async {
    for (final profileIndex in profileIndices) {
      final list = state ?? <KidProfile>[];
      final profile = list[profileIndex];
      setProfile(profileIndex, profile.copyWith(links: [link, ...profile.links]));
      await FirestoreService.saveLink(uid, profile.id, link);
    }
  }

  Future<void> updateLink(int profileIndex, SavedLink link) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    final links = profile.links.map((item) => item.id == link.id ? link : item).toList();
    setProfile(profileIndex, profile.copyWith(links: links));
    await FirestoreService.saveLink(uid, profile.id, link);
  }

  Future<void> deleteLink(int profileIndex, String linkId) async {
    final list = state ?? <KidProfile>[];
    final profile = list[profileIndex];
    final links = profile.links.where((item) => item.id != linkId).toList();
    setProfile(profileIndex, profile.copyWith(links: links));
    await FirestoreService.deleteLink(uid, profile.id, linkId);
  }

  Future<void> toggleLinkFavorite(int profileIndex, String linkId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final links = profile.links
        .map((l) => l.id == linkId ? l.copyWith(isFavorite: !l.isFavorite) : l)
        .toList();
    setProfile(profileIndex, profile.copyWith(links: links));
    final link = links.firstWhere((l) => l.id == linkId);
    await FirestoreService.saveLink(uid, profile.id, link);
  }
}
