import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shared_memory.dart';
import '../services/sharing_service.dart';
import 'auth_provider.dart';

final sharedFeedProvider = StreamProvider<List<SharedMemory>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return SharingService.feedStream(uid);
});
