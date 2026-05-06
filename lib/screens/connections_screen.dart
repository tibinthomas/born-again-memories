import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../providers/auth_provider.dart';
import '../providers/connections_provider.dart';
import '../services/connection_service.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showInviteDialog() {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite by email'),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              final user =
                  ref.read(authServiceProvider).currentUser;
              if (user == null) return;
              await ConnectionService.sendInvite(
                fromUid: user.uid,
                fromName: user.displayName ?? '',
                fromPhotoUrl: user.photoURL ?? '',
                toEmail: email,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invite sent to $email'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Send invite'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'People',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _showInviteDialog,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Invite'),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: const [
                Tab(text: 'Connections'),
                Tab(text: 'Requests'),
                Tab(text: 'Sent'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ConnectionsTab(),
                  _RequestsTab(),
                  _SentTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Connections tab ─────────────────────────────────────────────────────────

class _ConnectionsTab extends ConsumerWidget {
  const _ConnectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final connections = ref.watch(myConnectionsProvider);

    return connections.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return _empty(context, 'No connections yet',
              'Invite friends using the button above.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _ConnectionTile(conn: list[i], currentUid: uid),
        );
      },
    );
  }
}

class _ConnectionTile extends ConsumerWidget {
  final Connection conn;
  final String currentUid;

  const _ConnectionTile({required this.conn, required this.currentUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = conn.otherName(currentUid);
    final photo = conn.otherPhotoUrl(currentUid);

    return ListTile(
      leading: _Avatar(photoUrl: photo, name: name),
      title: Text(name),
      subtitle: Text(conn.otherEmail(currentUid),
          style: const TextStyle(fontSize: 12)),
      trailing: IconButton(
        icon: const Icon(Icons.person_remove_outlined),
        tooltip: 'Remove connection',
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Remove connection?'),
              content: Text('Remove $name from your connections?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          );
          if (ok == true) await ConnectionService.remove(conn.id);
        },
      ),
    );
  }
}

// ── Received Requests tab ──────────────────────────────────────────────────────

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final requests = ref.watch(receivedRequestsProvider);

    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return _empty(context, 'No pending requests',
              'Connection requests from others will appear here.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final conn = list[i];
            return ListTile(
              leading:
                  _Avatar(photoUrl: conn.fromPhotoUrl, name: conn.fromName),
              title: Text(conn.fromName),
              subtitle: Text('Wants to connect',
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).colorScheme.primary)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    tooltip: 'Accept',
                    onPressed: () => ConnectionService.accept(
                      connectionId: conn.id,
                      toUid: user!.uid,
                      toName: user.displayName ?? '',
                      toPhotoUrl: user.photoURL ?? '',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Decline',
                    onPressed: () => ConnectionService.decline(conn.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Sent Requests tab ──────────────────────────────────────────────────────────

class _SentTab extends ConsumerWidget {
  const _SentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sent = ref.watch(sentRequestsProvider);

    return sent.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return _empty(context, 'No sent invites',
              'Invites you have sent will appear here.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final conn = list[i];
            final name = conn.toName ?? conn.toEmail;
            final photo = conn.toPhotoUrl ?? '';
            return ListTile(
              leading: _Avatar(photoUrl: photo, name: name),
              title: Text(name),
              subtitle: Text(
                conn.toUid == null ? 'Not yet registered' : 'Pending',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              trailing: TextButton(
                onPressed: () => ConnectionService.remove(conn.id),
                child: const Text('Cancel'),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Notifications tab ──────────────────────────────────────────────────────────

// ── Shared helpers ─────────────────────────────────────────────────────────────

Widget _empty(BuildContext context, String title, String subtitle) {
  final theme = Theme.of(context);
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline,
              size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  final String photoUrl;
  final String name;

  const _Avatar({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(photoUrl));
    }
    return CircleAvatar(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
