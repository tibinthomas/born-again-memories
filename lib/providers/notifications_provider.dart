import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import 'auth_provider.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return FirebaseFirestore.instance
      .collection('notifications/$uid/items')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs
          .map((d) => AppNotification.fromMap(d.id, d.data()))
          .toList());
});

final unreadNotificationCountProvider = Provider<int>((ref) =>
    ref.watch(notificationsProvider).value?.where((n) => !n.isRead).length ?? 0);
