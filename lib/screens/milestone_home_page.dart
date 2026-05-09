import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../providers/app_settings_provider.dart';
import '../providers/backup_provider.dart';
import '../providers/milestone_form_provider.dart';
import '../providers/profiles_provider.dart';
import '../services/local_storage_service.dart';
import '../utils/attachment_helper.dart';
import '../utils/chime.dart';
import '../utils/date_formatter.dart';
import '../utils/milestone_templates.dart';
import '../utils/profile_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/milestone_card.dart';
import '../widgets/overview_chip.dart';
import '../utils/memory_sharer.dart';
import 'documents_screen.dart';
import 'milestone_detail_page.dart';
import 'video_recorder_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';

// ── Home page ──────────────────────────────────────────────────────────────────

class MilestoneHomePage extends ConsumerStatefulWidget {
  const MilestoneHomePage({super.key});

  @override
  ConsumerState<MilestoneHomePage> createState() => _MilestoneHomePageState();
}

class _MilestoneHomePageState extends ConsumerState<MilestoneHomePage> {
  String _searchQuery = '';
  int? _selectedYear;
  Set<String> _selectedTags = {};
  bool _showSearch = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showAddProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddProfileSheet(),
    );
  }

  void _showAddMilestoneSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddMilestoneSheet(),
    );
  }

  void _showEditMilestoneSheet(Milestone milestone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddMilestoneSheet(initialMilestone: milestone),
    );
  }

  void _confirmDeleteMilestone(int profileIndex, Milestone milestone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete memory?'),
        content: Text('Delete "${milestone.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(profilesProvider.notifier).deleteMilestone(profileIndex, milestone.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProfileSwitcher(List<KidProfile> profiles, int currentIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ProfileSwitcherSheet(
        profiles: profiles,
        selectedIndex: currentIndex,
        onSelect: (i) {
          ref.read(selectedProfileIndexProvider.notifier).state = i;
          Navigator.pop(context);
          // Reset filters when switching profiles
          setState(() {
            _searchQuery = '';
            _selectedYear = null;
            _selectedTags = {};
            _showSearch = false;
            _searchController.clear();
          });
        },
        onAddProfile: () {
          Navigator.pop(context);
          _showAddProfileSheet();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(backupSyncProvider);

    final profilesAsync = ref.watch(profilesProvider);
    if (profilesAsync == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profiles = profilesAsync;
    if (profiles.isEmpty) {
      return _EmptyProfilesScreen(onAdd: _showAddProfileSheet);
    }

    final selectedIndex = ref.watch(selectedProfileIndexProvider);
    final safeIndex = selectedIndex.clamp(0, profiles.length - 1);
    final currentProfile = profiles[safeIndex];
    final profileTheme = ProfileTheme.forProfile(currentProfile);

    // Filter milestones
    final allMilestones = currentProfile.milestones;
    final availableYears = allMilestones
        .map((m) => m.date.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final allTags = ({for (final m in allMilestones) ...m.tags}).toList()..sort();

    final filtered = allMilestones.where((m) {
      final matchYear = _selectedYear == null || m.date.year == _selectedYear;
      final q = _searchQuery.toLowerCase();
      final matchQuery = q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q) ||
          m.tags.any((t) => t.contains(q));
      final matchTags = _selectedTags.isEmpty || m.tags.any(_selectedTags.contains);
      return matchYear && matchQuery && matchTags;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Column(
        children: [
          // ── Hero header ──────────────────────────────
          _ProfileHeader(
            profile: currentProfile,
            profileTheme: profileTheme,
            milestoneCount: allMilestones.length,
            hasMultipleProfiles: profiles.length > 1,
            profileIndex: safeIndex,
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            onSwitchProfile: () => _showProfileSwitcher(profiles, safeIndex),
          ),

          // ── Milestone list ───────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        '${profileTheme.decalEmoji}  Precious moments',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const Spacer(),
                      if (allMilestones.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            _showSearch ? Icons.search_off : Icons.search,
                            color: _showSearch ? profileTheme.accent : Colors.grey.shade500,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _showSearch = !_showSearch;
                              if (!_showSearch) {
                                _searchQuery = '';
                                _searchController.clear();
                              }
                            });
                            if (_showSearch) _searchFocusNode.requestFocus();
                          },
                          tooltip: _showSearch ? 'Hide search' : 'Search',
                        ),
                      TextButton.icon(
                        onPressed: _showAddMilestoneSheet,
                        icon: Icon(Icons.add_circle, color: profileTheme.accent, size: 20),
                        label: Text(
                          'Add',
                          style: TextStyle(
                              color: profileTheme.accent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // Collapsible search bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  height: _showSearch ? 52 : 0,
                  child: _showSearch
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search memories…',
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: profileTheme.accent, width: 1.5),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Filter chips: years + tags in one scrollable row
                if (allMilestones.isNotEmpty && (availableYears.length > 1 || allTags.isNotEmpty)) ...[
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      children: [
                        if (availableYears.length > 1) ...[
                          _FilterChip(
                            label: 'All years',
                            selected: _selectedYear == null,
                            accent: profileTheme.accent,
                            soft: profileTheme.soft,
                            onTap: () => setState(() => _selectedYear = null),
                          ),
                          ...availableYears.map((y) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _FilterChip(
                                  label: '$y',
                                  selected: _selectedYear == y,
                                  accent: profileTheme.accent,
                                  soft: profileTheme.soft,
                                  onTap: () => setState(
                                      () => _selectedYear = _selectedYear == y ? null : y),
                                ),
                              )),
                          if (allTags.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                        ],
                        ...allTags.map((tag) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _FilterChip(
                                label: '#$tag',
                                selected: _selectedTags.contains(tag),
                                accent: profileTheme.accent,
                                soft: profileTheme.soft,
                                onTap: () => setState(() {
                                  if (_selectedTags.contains(tag)) {
                                    _selectedTags = {..._selectedTags}..remove(tag);
                                  } else {
                                    _selectedTags = {..._selectedTags, tag};
                                  }
                                }),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Milestone list or empty state
                Expanded(
                  child: allMilestones.isEmpty
                      ? EmptyState(theme: Theme.of(context), gender: currentProfile.gender)
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No milestones match your filter.',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _searchQuery = '';
                                      _selectedYear = null;
                                      _selectedTags = {};
                                      _showSearch = false;
                                      _searchController.clear();
                                    }),
                                    child: const Text('Clear filters'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final milestone = filtered[index];
                                return MilestoneCard(
                                  milestone: milestone,
                                  gender: currentProfile.gender,
                                  isFirst: index == 0,
                                  isLast: index == filtered.length - 1,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MilestoneDetailPage(
                                        milestones: filtered,
                                        initialIndex: index,
                                        profile: currentProfile,
                                      ),
                                    ),
                                  ),
                                  onEdit: () => _showEditMilestoneSheet(milestone),
                                  onDelete: () =>
                                      _confirmDeleteMilestone(safeIndex, milestone),
                                  onShare: () => MemorySharer.show(
                                    context,
                                    milestone,
                                    currentProfile.name,
                                    currentProfile.gender,
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMilestoneSheet,
        backgroundColor: profileTheme.accent,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('New memory',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }
}

// ── Filter chip (year + tag) ───────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color soft;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.soft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent : soft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? accent : accent.withAlpha(60)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : accent,
          ),
        ),
      ),
    );
  }
}

// ── Empty profiles screen ──────────────────────────────────────────────────────

class _EmptyProfilesScreen extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyProfilesScreen({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.orange.withAlpha(60), blurRadius: 20, spreadRadius: 4)
                    ],
                  ),
                  child: const Icon(Icons.child_care, size: 52, color: Color(0xFFFFB347)),
                ),
                const SizedBox(height: 28),
                const Text('Start your journey',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
                const SizedBox(height: 10),
                Text(
                  'Add your first little one and begin capturing those priceless moments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.5),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB347),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: const Text('Add first profile',
                      style: TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final KidProfile profile;
  final ProfileTheme profileTheme;
  final int milestoneCount;
  final bool hasMultipleProfiles;
  final int profileIndex;
  final VoidCallback onSettings;
  final VoidCallback onSwitchProfile;

  const _ProfileHeader({
    required this.profile,
    required this.profileTheme,
    required this.milestoneCount,
    required this.hasMultipleProfiles,
    required this.profileIndex,
    required this.onSettings,
    required this.onSwitchProfile,
  });

  @override
  Widget build(BuildContext context) {
    final hasBackground = !kIsWeb &&
        profile.backgroundImagePath != null &&
        profile.backgroundImagePath!.isNotEmpty &&
        File(profile.backgroundImagePath!).existsSync();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: ClipRRect(
        key: ValueKey(profile.id + (profile.backgroundImagePath ?? '')),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: hasBackground ? null : profileTheme.headerGradient,
            image: hasBackground
                ? DecorationImage(
                    image: FileImage(File(profile.backgroundImagePath!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Stack(
            children: [
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(hasBackground ? 100 : 20),
                        Colors.black.withAlpha(hasBackground ? 160 : 50),
                      ],
                    ),
                  ),
                ),
              ),
              // Decorative bubbles
              Positioned(
                right: -30,
                top: 10,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(20),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                top: 60,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(15),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 20),
                  child: Column(
                    children: [
                      // Top action row
                      Row(
                        children: [
                          // Switch profile button (only when multiple profiles)
                          if (hasMultipleProfiles)
                            _SwitchProfileButton(onTap: onSwitchProfile)
                          else
                            const SizedBox(width: 48),
                          const Spacer(),
                          // Documents button
                          _DocumentsButton(profileIndex: profileIndex),
                          // Reminders bell with badge
                          _RemindersButton(
                            profile: profile,
                            profileIndex: profileIndex,
                          ),
                          IconButton(
                            onPressed: onSettings,
                            icon: const Icon(Icons.settings_outlined,
                                color: Colors.white70, size: 22),
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Avatar + name + age
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(30),
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Center(
                          child: Text(profileTheme.decalEmoji,
                              style: const TextStyle(fontSize: 34)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          profile.ageText,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Overview chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OverviewChip(
                            label: 'Milestones',
                            value: milestoneCount.toString(),
                            icon: Icons.flag,
                          ),
                          const SizedBox(width: 12),
                          const OverviewChip(
                            label: 'Memories',
                            value: 'Forever',
                            icon: Icons.cloud,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchProfileButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SwitchProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, color: Colors.white, size: 16),
            SizedBox(width: 5),
            Text('Switch', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Reminders bell button ──────────────────────────────────────────────────────

class _RemindersButton extends StatelessWidget {
  final KidProfile profile;
  final int profileIndex;

  const _RemindersButton({required this.profile, required this.profileIndex});

  @override
  Widget build(BuildContext context) {
    final upcoming = profile.reminders.where((r) => r.isUpcoming).length;
    final overdue = profile.reminders.where((r) => r.isOverdue).length;
    final badgeCount = upcoming + overdue;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RemindersScreen(profileIndex: profileIndex),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(overdue > 0 ? 60 : 35),
              border: Border.all(color: Colors.white.withAlpha(overdue > 0 ? 120 : 60)),
            ),
            child: Icon(
              overdue > 0 ? Icons.alarm_outlined : Icons.notifications_outlined,
              color: overdue > 0 ? Colors.orange.shade200 : Colors.white70,
              size: 20,
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: overdue > 0 ? Colors.orange.shade400 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: overdue > 0 ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Documents button ──────────────────────────────────────────────────────────

class _DocumentsButton extends ConsumerWidget {
  final int profileIndex;

  const _DocumentsButton({required this.profileIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider) ?? [];
    final count = (profiles.isEmpty || profileIndex >= profiles.length)
        ? 0
        : profiles[profileIndex].documents.length;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentsScreen(profileIndex: profileIndex),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(35),
              border: Border.all(color: Colors.white.withAlpha(60)),
            ),
            child: const Icon(Icons.folder_outlined,
                color: Colors.white70, size: 20),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Profile switcher sheet ─────────────────────────────────────────────────────

class _ProfileSwitcherSheet extends StatelessWidget {
  final List<KidProfile> profiles;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddProfile;

  const _ProfileSwitcherSheet({
    required this.profiles,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAddProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 4,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Row(
            children: [
              const Text('Switch profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddProfile,
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Add new'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...profiles.asMap().entries.map((e) {
            final i = e.key;
            final profile = e.value;
            final pTheme = ProfileTheme.forProfile(profile);
            final isSelected = i == selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? pTheme.soft : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? pTheme.accent : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: pTheme.accent.withAlpha(40), blurRadius: 10)]
                        : [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? pTheme.accent : pTheme.soft,
                        ),
                        child: Center(
                          child: Text(pTheme.decalEmoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? pTheme.accent : const Color(0xFF2D2D2D),
                                )),
                            Text(profile.ageText,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: pTheme.accent, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Add-profile sheet ──────────────────────────────────────────────────────────

class _AddProfileSheet extends ConsumerStatefulWidget {
  const _AddProfileSheet();

  @override
  ConsumerState<_AddProfileSheet> createState() => _AddProfileSheetState();
}

class _AddProfileSheetState extends ConsumerState<_AddProfileSheet> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBackground() async {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        ref.read(addProfileFormProvider.notifier).setBackgroundImagePath(file.path);
      }
    } else if (!kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result?.files.first.path != null) {
        ref.read(addProfileFormProvider.notifier)
            .setBackgroundImagePath(result!.files.first.path!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(addProfileFormProvider);
    final pTheme = ProfileTheme.forGender(form.gender);
    final hasBackground = !kIsWeb &&
        form.backgroundImagePath != null &&
        form.backgroundImagePath!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const Text('New little one',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D))),
            const SizedBox(height: 4),
            Text('Tell us about your baby.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 20),

            // Gender selector
            const Text('Gender',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: Gender.values.map((g) {
                final gTheme = ProfileTheme.forGender(g);
                final isSelected = form.gender == g;
                final label = switch (g) {
                  Gender.boy => '🚀 Boy',
                  Gender.girl => '🌸 Girl',
                  Gender.neutral => '⭐ Surprise',
                };
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(addProfileFormProvider.notifier).setGender(g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? gTheme.accent : gTheme.soft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? gTheme.accent : gTheme.accent.withAlpha(60),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isSelected ? Colors.white : gTheme.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: "Baby's name",
                prefixIcon: Icon(Icons.badge_outlined, color: pTheme.accent),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: pTheme.accent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // DOB
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: form.dob,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365 * 10)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  ref.read(addProfileFormProvider.notifier).setDob(picked);
                }
              },
              icon: Icon(Icons.cake_outlined, color: pTheme.accent),
              label: Text('Birthday: ${formatDate(form.dob)}',
                  style: TextStyle(
                      color: pTheme.accent, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: pTheme.accent.withAlpha(120)),
              ),
            ),
            const SizedBox(height: 16),

            // Background image (not on web)
            if (!kIsWeb) ...[
              Row(
                children: [
                  const Text('Background photo',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  if (hasBackground)
                    TextButton(
                      onPressed: () => ref
                          .read(addProfileFormProvider.notifier)
                          .setBackgroundImagePath(null),
                      child: Text('Remove',
                          style:
                              TextStyle(color: Colors.red.shade400, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickBackground,
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: pTheme.soft,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: pTheme.accent.withAlpha(80), width: 1.5),
                    image: hasBackground
                        ? DecorationImage(
                            image:
                                FileImage(File(form.backgroundImagePath!)),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withAlpha(30),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasBackground
                              ? Icons.check_circle
                              : Icons.add_photo_alternate_outlined,
                          color: hasBackground ? Colors.white : pTheme.accent,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasBackground
                              ? 'Photo selected — tap to change'
                              : 'Tap to pick a photo',
                          style: TextStyle(
                            color: hasBackground ? Colors.white : pTheme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Create button
            FilledButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter your baby's name.")),
                  );
                  return;
                }
                ref.read(profilesProvider.notifier).addProfile(
                      name,
                      form.dob,
                      form.color,
                      gender: form.gender,
                      backgroundImagePath: form.backgroundImagePath,
                    );
                ref.read(selectedProfileIndexProvider.notifier).state =
                    (ref.read(profilesProvider)?.length ?? 1) - 1;
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: pTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Create profile',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add-milestone sheet ────────────────────────────────────────────────────────

class _AddMilestoneSheet extends ConsumerStatefulWidget {
  final Milestone? initialMilestone;
  const _AddMilestoneSheet({this.initialMilestone});

  @override
  ConsumerState<_AddMilestoneSheet> createState() => _AddMilestoneSheetState();
}

class _AddMilestoneSheetState extends ConsumerState<_AddMilestoneSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  final _picker = ImagePicker();
  final _labelControllers = <String, TextEditingController>{};
  // Attachments stored in local state so webBytes survive async gaps + autoDispose
  final List<Attachment> _attachments = [];
  final List<String> _tags = [];
  String? _titleError;
  String? _descError;
  Set<String> _existingAttachmentIds = {};
  bool _hasCameras = false;

  // Template state
  MilestoneTemplate? _selectedTemplate;
  String? _selectedCategory;
  bool _showingTemplates = true; // start with template picker for new milestones

  bool get _isEditing => widget.initialMilestone != null;

  @override
  @override
  void initState() {
    super.initState();
    final initial = widget.initialMilestone;
    if (initial != null) {
      _titleController.text = initial.title;
      _descController.text = initial.description;
      _existingAttachmentIds = {for (final a in initial.attachments) a.id};
      _attachments.addAll(initial.attachments);
      for (final a in initial.attachments) {
        _labelControllers[a.id] = TextEditingController(text: a.label ?? '');
      }
      _tags.addAll(initial.tags);
      _showingTemplates = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(addMilestoneFormProvider.notifier).setDate(initial.date);
      });
    }
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      _checkCameras();
    }
  }

  Future<void> _checkCameras() async {
    try {
      final cameras = await availableCameras();
      if (mounted) setState(() => _hasCameras = cameras.isNotEmpty);
    } catch (_) {}
  }

  void _addTag(String raw) {
    final tag = raw.trim().toLowerCase();
    if (tag.isEmpty || _tags.contains(tag) || _tags.length >= 5) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagController.dispose();
    for (final c in _labelControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyTemplate(MilestoneTemplate template) {
    setState(() {
      _selectedTemplate = template;
      _showingTemplates = false;
    });
    _titleController.text = template.title;
    _descController.text = template.description;
    _titleError = null;
    _descError = null;
  }

  void _addAttachment(Attachment a) {
    setState(() {
      _attachments.add(a);
      _labelControllers[a.id] = TextEditingController();
    });
  }

  void _removeAttachment(int index, String id) {
    setState(() {
      _labelControllers[id]?.dispose();
      _labelControllers.remove(id);
      _attachments.removeAt(index);
    });
  }

  Future<void> _addXFiles(List<XFile> files) async {
    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final ext = f.name.contains('.') ? f.name.split('.').last.toLowerCase() : '';
      final bytes = kIsWeb ? await f.readAsBytes() : null;
      _addAttachment(Attachment(
        id: '${DateTime.now().microsecondsSinceEpoch}_$i',
        name: f.name,
        localPath: kIsWeb ? '' : f.path,
        type: getAttachmentTypeFromExtension(ext),
        sizeBytes: kIsWeb ? bytes!.length : 0,
        webBytes: bytes,
      ));
    }
  }

  // Extracts file extension reliably — f.extension is null on web.
  static String _extOf(PlatformFile f) {
    if (f.extension != null && f.extension!.isNotEmpty) return f.extension!.toLowerCase();
    final dot = f.name.lastIndexOf('.');
    return dot != -1 ? f.name.substring(dot + 1).toLowerCase() : '';
  }

  Future<void> _startLiveRecording() async {
    final tempDir = await getTemporaryDirectory();
    final path =
        '${tempDir.path}/rec_${DateTime.now().microsecondsSinceEpoch}.m4a';
    final now = TimeOfDay.now();
    if (!mounted) return;
    final filePath = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RecordingDialog(savePath: path),
    );
    if (filePath == null || !mounted) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final label = now.format(context);
    _addAttachment(Attachment(
      id: id,
      name: 'Voice memo $label',
      localPath: filePath,
      type: AttachmentType.audio,
      sizeBytes: 0,
    ));
    setState(() {});
  }

  // ── Template picker ──────────────────────────────────────────────────────────

  Widget _buildTemplatePicker(ProfileTheme pTheme) {
    final categories = milestoneCategories;
    final activeCat = _selectedCategory ?? categories.first;
    final templates =
        babyMilestones.where((t) => t.category == activeCat).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const Text('Choose a milestone',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Pick a common one or write your own.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 16),

        // Category chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories.map((cat) {
              final isActive = cat == activeCat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? pTheme.accent : pTheme.soft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isActive ? pTheme.accent : pTheme.accent.withAlpha(60)),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : pTheme.accent,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Template grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: templates.map((t) {
            return GestureDetector(
              onTap: () => _applyTemplate(t),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: pTheme.soft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: pTheme.accent.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Text(t.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D2D2D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Custom button
        OutlinedButton.icon(
          onPressed: () => setState(() => _showingTemplates = false),
          icon: Icon(Icons.edit_outlined, color: pTheme.accent, size: 18),
          label: Text('Write a custom milestone',
              style: TextStyle(color: pTheme.accent, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: pTheme.accent.withAlpha(120)),
          ),
        ),
      ],
    );
  }

  // ── Milestone form ───────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context, ProfileTheme pTheme) {
    final theme = Theme.of(context);
    final form = ref.watch(addMilestoneFormProvider); // only used for form.date

    final inputDeco = InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Header row with back button for new milestones
        Row(
          children: [
            if (!_isEditing)
              GestureDetector(
                onTap: () => setState(() => _showingTemplates = true),
                child: Icon(Icons.arrow_back_ios, size: 18, color: pTheme.accent),
              ),
            if (!_isEditing) const SizedBox(width: 6),
            Expanded(
              child: Text(
                _isEditing
                    ? 'Edit memory'
                    : _selectedTemplate != null
                        ? '${_selectedTemplate!.emoji}  ${_selectedTemplate!.title}'
                        : 'Custom milestone',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Date chip
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: form.date,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365 * 10)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  ref.read(addMilestoneFormProvider.notifier).setDate(picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today,
                        size: 13, color: theme.colorScheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      formatDate(form.date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Title
        TextField(
          controller: _titleController,
          maxLength: 100,
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = null);
          },
          decoration: inputDeco.copyWith(
            labelText: 'Milestone title *',
            errorText: _titleError,
            counterText: '',
          ),
        ),
        const SizedBox(height: 10),

        // Description
        TextField(
          controller: _descController,
          maxLines: 3,
          maxLength: 500,
          onChanged: (_) {
            if (_descError != null) setState(() => _descError = null);
          },
          decoration: inputDeco.copyWith(
            labelText: 'Why this moment matters *',
            errorText: _descError,
            counterText: '',
          ),
        ),
        const SizedBox(height: 14),

        // Tags
        _sectionLabel('Tags'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text('#$tag',
                      style: TextStyle(fontSize: 12, color: pTheme.accent)),
                  backgroundColor: pTheme.soft,
                  side: BorderSide(color: pTheme.accent.withAlpha(80)),
                  deleteIconColor: pTheme.accent.withAlpha(160),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  visualDensity: VisualDensity.compact,
                )),
            if (_tags.length < 5)
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _tagController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _addTag,
                  style: const TextStyle(fontSize: 13),
                  decoration: inputDeco.copyWith(
                    hintText: 'Add tag…',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add, size: 16, color: pTheme.accent),
                      onPressed: () => _addTag(_tagController.text),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),

        // Media
        _sectionLabel('Media'),
        const SizedBox(height: 8),
        Row(
          children: [
            if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) ...[
              _MediaBtn(
                icon: Icons.camera_alt_outlined,
                label: 'Photo',
                color: Colors.blue,
                onTap: () async {
                  final f =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (f != null) _addXFiles([f]);
                },
              ),
              const SizedBox(width: 8),
              if (_hasCameras)
                _MediaBtn(
                  icon: Icons.videocam_outlined,
                  label: 'Record',
                  color: Colors.red,
                  onTap: () async {
                    // Dismiss keyboard before going full-screen
                    FocusScope.of(context).unfocus();
                    final path = await VideoRecorderScreen.open(context);
                    if (path != null && mounted) {
                      final file = File(path);
                      final ext = path.split('.').last.toLowerCase();
                      _addAttachment(Attachment(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name:
                            'video_${DateTime.now().millisecondsSinceEpoch}.$ext',
                        localPath: path,
                        type: AttachmentType.video,
                        sizeBytes: await file.length(),
                      ));
                    }
                  },
                )
              else
                _MediaBtn(
                  icon: Icons.videocam_outlined,
                  label: 'Video',
                  color: Colors.red,
                  onTap: () async {
                    final f =
                        await _picker.pickVideo(source: ImageSource.camera);
                    if (f != null) _addXFiles([f]);
                  },
                ),
              const SizedBox(width: 8),
            ],
            _MediaBtn(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              color: Colors.purple,
              onTap: () async {
                if (kIsWeb) {
                  // image_picker on web reliably returns XFile with readable bytes
                  final files = await _picker.pickMultiImage();
                  if (files.isNotEmpty) await _addXFiles(files);
                } else if (Platform.isIOS || Platform.isAndroid) {
                  final files = await _picker.pickMultipleMedia();
                  if (files.isNotEmpty) await _addXFiles(files);
                } else {
                  // Desktop: use file_picker (has real file paths)
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.media,
                  );
                  if (result != null) {
                    for (final f in result.files.where((f) => f.path != null)) {
                      final ext = _extOf(f);
                      _addAttachment(Attachment(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: f.name,
                        localPath: f.path!,
                        type: getAttachmentTypeFromExtension(ext),
                        sizeBytes: f.size,
                      ));
                    }
                  }
                }
              },
            ),
            const SizedBox(width: 8),
            _MediaBtn(
              icon: Icons.audio_file_outlined,
              label: 'Audio',
              color: Colors.orange,
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.custom,
                  allowedExtensions: ['wav', 'mp3', 'm4a', 'aac'],
                  withData: true,
                );
                if (result != null) {
                  for (final f in result.files) {
                    _addAttachment(Attachment(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: f.name,
                      localPath: f.path ?? '',
                      type: AttachmentType.audio,
                      sizeBytes: f.size,
                      webBytes: f.bytes,
                    ));
                  }
                }
                setState(() {});
              },
            ),
            const SizedBox(width: 8),
            _MediaBtn(
              icon: Icons.mic_outlined,
              label: 'Record',
              color: Colors.teal,
              onTap: _startLiveRecording,
            ),
          ],
        ),

        // Attachment strip
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _attachments.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final a = _attachments[i];
                final labelCtrl = _labelControllers[a.id] ??
                    (_labelControllers[a.id] = TextEditingController());
                return SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: a.webBytes != null || (a.type == AttachmentType.image && a.localExists)
                                ? attachmentImageWidget(a,
                                    width: 90, height: 90)
                                : Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          a.type == AttachmentType.video
                                              ? Icons.videocam
                                              : a.type == AttachmentType.image
                                                  ? Icons.image_not_supported_outlined
                                                  : Icons.mic,
                                          size: 28,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Text(
                                            a.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: 3,
                            right: 3,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _removeAttachment(i, a.id)),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: labelCtrl,
                        maxLength: 40,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Add label…',
                          hintStyle: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                          isDense: true,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide:
                                BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                                color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Save button
        _SaveBtn(
          onSave: () async {
            final title = _titleController.text.trim();
            final desc = _descController.text.trim();
            bool valid = true;
            if (title.isEmpty) {
              setState(() => _titleError = 'Title is required');
              valid = false;
            } else if (title.length < 2) {
              setState(
                  () => _titleError = 'Title must be at least 2 characters');
              valid = false;
            }
            if (desc.isEmpty) {
              setState(() =>
                  _descError = 'Please write why this moment matters');
              valid = false;
            } else if (desc.length < 5) {
              setState(() => _descError = 'Description is too short');
              valid = false;
            }
            if (!valid) return false;

            final profileIndex = ref.read(selectedProfileIndexProvider);
            final profile =
                (ref.read(profilesProvider) ?? [])[profileIndex];

            final saved = <Attachment>[];
            for (final a in _attachments) {
              final labelText = _labelControllers[a.id]?.text.trim();
              final label =
                  labelText?.isEmpty == true ? null : labelText;
              if (_existingAttachmentIds.contains(a.id)) {
                saved.add(a.copyWith(label: label));
              } else if (kIsWeb) {
                // On web there is no local filesystem — keep webBytes in-memory
                saved.add(a.copyWith(label: label));
              } else {
                try {
                  final filename =
                      '${a.id}_${a.name.replaceAll(RegExp(r'[^\w.]'), '_')}';
                  final permanentPath = await LocalStorageService
                      .copyToAppStorage(a.localPath, filename);
                  saved.add(Attachment(
                    id: a.id,
                    name: a.name,
                    label: label,
                    type: a.type,
                    sizeBytes: a.sizeBytes,
                    localPath: permanentPath,
                    backupStatus: BackupStatus.queued,
                  ));
                } catch (_) {
                  saved.add(a.copyWith(label: label));
                }
              }
            }

            if (_isEditing) {
              final original = widget.initialMilestone!;
              await ref
                  .read(profilesProvider.notifier)
                  .updateMilestone(
                    profileIndex,
                    Milestone(
                      id: original.id,
                      title: title,
                      description: desc,
                      date: form.date,
                      color: original.color,
                      attachments: saved,
                      tags: List.unmodifiable(_tags),
                    ),
                  );
            } else {
              final existingCount = profile.milestones.length;
              await ref.read(profilesProvider.notifier).prependMilestone(
                    profileIndex,
                    Milestone(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      title: title,
                      description: desc,
                      date: form.date,
                      color: Colors.primaries[
                              existingCount % Colors.primaries.length]
                          .shade300,
                      attachments: saved,
                      tags: List.unmodifiable(_tags),
                    ),
                  );
            }
            ref.read(backupSyncProvider.notifier).syncNow();
            return true;
          },
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileIndex = ref.read(selectedProfileIndexProvider);
    final profiles = ref.read(profilesProvider) ?? [];
    final profile = profiles.isNotEmpty ? profiles[profileIndex.clamp(0, profiles.length - 1)] : null;
    final pTheme = profile != null
        ? ProfileTheme.forProfile(profile)
        : ProfileTheme.forGender(Gender.neutral);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _showingTemplates
              ? _buildTemplatePicker(pTheme)
              : _buildForm(context, pTheme),
        ),
      ),
    );
  }
}

// ── Recording dialog ───────────────────────────────────────────────────────────

class _RecordingDialog extends StatefulWidget {
  final String savePath;
  const _RecordingDialog({required this.savePath});

  @override
  State<_RecordingDialog> createState() => _RecordingDialogState();
}

class _RecordingDialogState extends State<_RecordingDialog> {
  final _recorder = AudioRecorder();
  bool _started = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) Navigator.pop(context, null);
      return;
    }
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: widget.savePath,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    if (mounted) setState(() => _started = true);
  }

  Future<void> _stop() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (mounted) Navigator.pop(context, path);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mins = (_elapsed.inMinutes).toString().padLeft(2, '0');
    final secs = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Recording'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic, size: 48, color: _started ? Colors.red : Colors.grey),
          const SizedBox(height: 12),
          Text(
            '$mins:$secs',
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 4),
          Text(
            _started ? 'Recording…' : 'Starting…',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            _timer?.cancel();
            await _recorder.cancel();
            if (mounted) navigator.pop(null);
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _started ? _stop : null,
          child: const Text('Stop & Save'),
        ),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

Widget _sectionLabel(String text) => Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.9,
      ),
    );

class _MediaBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(50)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveBtn extends ConsumerStatefulWidget {
  final Future<bool> Function() onSave;
  final VoidCallback onDismiss;
  const _SaveBtn({required this.onSave, required this.onDismiss});

  @override
  ConsumerState<_SaveBtn> createState() => _SaveBtnState();
}

class _SaveBtnState extends ConsumerState<_SaveBtn> {
  bool _saving = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton(
      onPressed: (_saving || _saved) ? null : _handleSave,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: theme.colorScheme.primary,
        disabledBackgroundColor: _saved
            ? Colors.green.shade400
            : theme.colorScheme.primary.withAlpha(100),
      ),
      child: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_saved ? Icons.check : Icons.save_outlined,
                    size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _saved ? 'Saved!' : 'Save milestone',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              ],
            ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    final ok = await widget.onSave();
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    setState(() => _saved = true);
    final s = ref.read(appSettingsProvider);
    if (s.hapticEnabled) HapticFeedback.mediumImpact();
    if (s.soundEnabled) unawaited(playChime(volume: s.soundVolume));
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onDismiss();
  }
}
