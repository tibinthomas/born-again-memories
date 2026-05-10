import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../utils/date_formatter.dart';
import '../utils/profile_theme.dart';
import '../widgets/milestone_card.dart';

class SharedFeedScreen extends ConsumerStatefulWidget {
  const SharedFeedScreen({super.key});

  static Future<void> push(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SharedFeedScreen()),
      );

  @override
  ConsumerState<SharedFeedScreen> createState() => _SharedFeedScreenState();
}

class _SharedFeedScreenState extends ConsumerState<SharedFeedScreen> {
  bool _loading = true;
  List<_FeedEntry> _entries = [];
  List<_Sender> _senders = [];
  String? _selectedUid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = ref.read(authStateProvider).value;
      if (user?.email == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final groups = await FirestoreService.loadSharedFeed(user!.email!);
      final entries = <_FeedEntry>[];
      final senders = <_Sender>[];
      for (final g in groups) {
        senders.add(_Sender(uid: g.uid, name: g.displayName));
        for (final e in g.milestones) {
          entries.add(_FeedEntry(
            milestone: e.milestone,
            babyName: e.babyName,
            babyGender: e.babyGender,
            senderName: g.displayName,
            senderUid: g.uid,
          ));
        }
      }
      entries.sort((a, b) => b.milestone.date.compareTo(a.milestone.date));
      if (mounted) {
        setState(() {
          _entries = entries;
          _senders = senders;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedUid == null
        ? _entries
        : _entries.where((e) => e.senderUid == _selectedUid).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Shared with me',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _load)
              : _entries.isEmpty
                  ? const _EmptyState()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Sender filter chips ──────────────────────
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            children: [
                              _SenderChip(
                                label: 'All',
                                avatar: null,
                                selected: _selectedUid == null,
                                onTap: () =>
                                    setState(() => _selectedUid = null),
                              ),
                              ..._senders.map((s) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _SenderChip(
                                      label: s.name,
                                      avatar: s.name.isNotEmpty
                                          ? s.name[0].toUpperCase()
                                          : '?',
                                      selected: _selectedUid == s.uid,
                                      onTap: () => setState(() =>
                                          _selectedUid = _selectedUid == s.uid
                                              ? null
                                              : s.uid),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),

                        // ── Feed ─────────────────────────────────────
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No memories from this person yet.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 8, 20, 40),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final entry = filtered[index];
                                    return _FeedItem(
                                      entry: entry,
                                      animIndex: index,
                                      showSender: _selectedUid == null,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _FeedEntry {
  final Milestone milestone;
  final String babyName;
  final Gender babyGender;
  final String senderName;
  final String senderUid;

  const _FeedEntry({
    required this.milestone,
    required this.babyName,
    required this.babyGender,
    required this.senderName,
    required this.senderUid,
  });
}

class _Sender {
  final String uid;
  final String name;
  const _Sender({required this.uid, required this.name});
}

// ── Feed item ─────────────────────────────────────────────────────────────────

class _FeedItem extends StatelessWidget {
  final _FeedEntry entry;
  final int animIndex;
  final bool showSender;

  const _FeedItem({
    required this.entry,
    required this.animIndex,
    required this.showSender,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ProfileTheme.forGender(entry.babyGender);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sender + baby badge
        Padding(
          padding: const EdgeInsets.only(left: 44, bottom: 4),
          child: Row(
            children: [
              if (showSender) ...[
                Icon(Icons.person_outline_rounded,
                    size: 13, color: theme.accent.withAlpha(180)),
                const SizedBox(width: 4),
                Text(
                  entry.senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.accent.withAlpha(200),
                  ),
                ),
                Text(
                  '  ·  ',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
              Icon(Icons.child_care_rounded,
                  size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                entry.babyName,
                style:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(width: 6),
              Text(
                formatDate(entry.milestone.date),
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        MilestoneCard(
          milestone: entry.milestone,
          profileTheme: ProfileTheme.forGender(entry.babyGender),
          animIndex: animIndex,
        ),
      ],
    );
  }
}

// ── Sender filter chip ────────────────────────────────────────────────────────

class _SenderChip extends StatelessWidget {
  final String label;
  final String? avatar;
  final bool selected;
  final VoidCallback onTap;

  const _SenderChip({
    required this.label,
    required this.avatar,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5B9BD5);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? accent : Colors.grey.shade300, width: 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: accent.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withAlpha(60)
                      : accent.withAlpha(30),
                ),
                child: Center(
                  child: Text(
                    avatar!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade50,
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 40, color: Colors.blue.shade200),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nothing shared yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D2D2D)),
            ),
            const SizedBox(height: 8),
            Text(
              'When someone shares their memories\nwith your email, they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Could not load shared memories',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(error,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
