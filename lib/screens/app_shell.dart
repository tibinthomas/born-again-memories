import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connections_provider.dart';
import '../providers/notifications_provider.dart';
import 'connections_screen.dart';
import 'milestone_home_page.dart';
import 'shared_feed_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(pendingRequestsCountProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final peopleBadge = pendingCount + unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          MilestoneHomePage(),
          SharedFeedScreen(),
          ConnectionsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Shared',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: peopleBadge > 0,
              label: Text('$peopleBadge'),
              child: const Icon(Icons.people_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: peopleBadge > 0,
              label: Text('$peopleBadge'),
              child: const Icon(Icons.people),
            ),
            label: 'People',
          ),
        ],
      ),
    );
  }
}
