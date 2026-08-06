import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ugc_safety_service.dart';

final blockedUserIdsProvider = StreamProvider<Set<String>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(const <String>{});
  return UgcSafetyService.blockedUserIds(uid);
});
