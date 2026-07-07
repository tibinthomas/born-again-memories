import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/baby_document.dart';
import '../../models/kid_profile.dart';
import '../../services/firestore_service.dart';
import 'profile_mutations.dart';

mixin DocumentsOps on StateNotifier<List<KidProfile>?>, ProfileMutations {
  Future<void> addDocument(int profileIndex, BabyDocument doc) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    setProfile(profileIndex,
        profile.copyWith(documents: [...profile.documents, doc]));
    await FirestoreService.saveDocument(uid, profile.id, doc);
  }

  Future<void> addDocumentToProfiles(List<int> profileIndices, BabyDocument doc) async {
    for (final profileIndex in profileIndices) {
      final profile = (state ?? <KidProfile>[])[profileIndex];
      setProfile(profileIndex,
          profile.copyWith(documents: [...profile.documents, doc]));
      await FirestoreService.saveDocument(uid, profile.id, doc);
    }
  }

  Future<void> deleteDocument(int profileIndex, String docId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    setProfile(profileIndex,
        profile.copyWith(
          documents: profile.documents.where((d) => d.id != docId).toList(),
        ));
    await FirestoreService.deleteDocument(uid, profile.id, docId);
  }

  Future<void> toggleDocumentFavorite(int profileIndex, String docId) async {
    final profile = (state ?? <KidProfile>[])[profileIndex];
    final documents = profile.documents
        .map((d) => d.id == docId ? d.copyWith(isFavorite: !d.isFavorite) : d)
        .toList();
    setProfile(profileIndex, profile.copyWith(documents: documents));
    final doc = documents.firstWhere((d) => d.id == docId);
    await FirestoreService.saveDocument(uid, profile.id, doc);
  }
}
