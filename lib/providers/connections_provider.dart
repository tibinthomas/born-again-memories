import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../services/connection_service.dart';
import 'auth_provider.dart';

final myConnectionsProvider = StreamProvider<List<Connection>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ConnectionService.myConnectionsStream(uid);
});

final receivedRequestsProvider = StreamProvider<List<Connection>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ConnectionService.receivedRequestsStream(uid);
});

final sentRequestsProvider = StreamProvider<List<Connection>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value([]);
  return ConnectionService.sentRequestsStream(uid);
});

final pendingRequestsCountProvider = Provider<int>((ref) {
  return ref.watch(receivedRequestsProvider).value?.length ?? 0;
});
