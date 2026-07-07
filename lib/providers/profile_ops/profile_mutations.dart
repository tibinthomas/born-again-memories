import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kid_profile.dart';

/// Shared plumbing for the per-domain `ProfilesNotifier` mixins:
/// access to [uid]/[ref] and the single-index state-replace helper they
/// all build on.
mixin ProfileMutations on StateNotifier<List<KidProfile>?> {
  String get uid;
  Ref get ref;

  void setProfile(int index, KidProfile profile) {
    final list = <KidProfile>[...(state ?? [])];
    list[index] = profile;
    state = list;
  }
}
