import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import 'auth_provider.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);

  return FirebaseDatabase.instance
      .ref('notifications/$uid')
      .orderByChild('createdAt')
      .limitToLast(50)
      .onValue
      .map((event) {
    if (!event.snapshot.exists || event.snapshot.value == null) return [];
    final notifs = event.snapshot.children
        .map((c) => AppNotification.fromMap(
            c.key!, c.value as Map<Object?, Object?>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifs;
  });
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).value
          ?.where((n) => !n.isRead)
          .length ??
      0;
});
