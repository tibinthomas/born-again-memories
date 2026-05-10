import 'dart:async';
import 'dart:io';
import 'dart:ui';
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
import '../utils/theme_preset.dart';
import '../widgets/empty_state.dart';
import '../widgets/milestone_card.dart';
import '../utils/memory_sharer.dart';
import 'documents_screen.dart';
import 'milestone_detail_page.dart';
import 'saved_links_screen.dart';
import 'shared_feed_screen.dart';
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
  bool _selectAllTags = true;
  bool _showSearch = false;
  bool _showFavoritesOnly = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _listScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _listScrollController.dispose();
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

  void _showEditProfileSheet(BuildContext context, int profileIndex, KidProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final nicknameController = TextEditingController(text: profile.nickname ?? '');
    DateTime selectedDob = profile.dateOfBirth;
    DateTime? selectedTob = profile.timeOfBirth;
    Gender selectedGender = profile.gender;
    String? avatarPath = profile.avatarImagePath;
    String selectedPresetId = profile.themePresetId ??
        ThemePreset.defaultIdForGender(profile.gender.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(context);
          final selectedPreset = ThemePreset.findById(selectedPresetId)!;
          final pTheme = ProfileTheme.fromPreset(selectedPreset);
          final hasAvatar = avatarPath != null &&
              avatarPath!.isNotEmpty &&
              !kIsWeb &&
              File(avatarPath!).existsSync();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('Edit Profile', style: theme.textTheme.titleLarge),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          final savePreset = ThemePreset.findById(selectedPresetId)!;
                          final updated = profile.copyWith(
                            name: nameController.text.trim(),
                            nickname: nicknameController.text.trim().isEmpty ? null : nicknameController.text.trim(),
                            clearNickname: nicknameController.text.trim().isEmpty && profile.nickname != null,
                            dateOfBirth: selectedDob,
                            timeOfBirth: selectedTob,
                            clearTimeOfBirth: selectedTob == null && profile.timeOfBirth != null,
                            color: savePreset.accent,
                            themePresetId: selectedPresetId,
                            gender: selectedGender,
                            avatarImagePath: avatarPath,
                            clearAvatar: avatarPath == null && profile.avatarImagePath != null,
                          );
                          ref.read(profilesProvider.notifier).updateProfile(profileIndex, updated);
                          Navigator.pop(ctx);
                        },
                        child: Text('Save', style: TextStyle(color: pTheme.accent, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            String? pickedPath;
                            if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(source: ImageSource.gallery);
                              pickedPath = file?.path;
                            } else if (!kIsWeb) {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: false,
                              );
                              pickedPath = result?.files.firstOrNull?.path;
                            }
                            if (pickedPath != null) {
                              final permanent = await LocalStorageService.copyAvatarToStorage(
                                pickedPath,
                                'avatar_${profile.id}_${DateTime.now().millisecondsSinceEpoch}',
                              );
                              // Delete previously picked (unsaved) avatar to avoid orphans
                              if (avatarPath != null && avatarPath != profile.avatarImagePath) {
                                LocalStorageService.delete(avatarPath!);
                              }
                              setState(() => avatarPath = permanent);
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: pTheme.soft,
                                  image: hasAvatar
                                      ? DecorationImage(
                                          image: FileImage(File(avatarPath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: hasAvatar
                                    ? null
                                    : Center(
                                        child: Text(
                                          ProfileTheme.forGender(selectedGender).decalEmoji,
                                          style: const TextStyle(fontSize: 36),
                                        ),
                                      ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: pTheme.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasAvatar)
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => avatarPath = null),
                            child: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text('Gender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Row(
                        children: Gender.values.map((g) {
                          final gTheme = ProfileTheme.forGender(g);
                          final isSelected = selectedGender == g;
                          final label = switch (g) {
                            Gender.boy => '🚀 Boy',
                            Gender.girl => '🌸 Girl',
                            Gender.neutral => '⭐ Surprise',
                          };
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  selectedGender = g;
                                  selectedPresetId = ThemePreset.defaultIdForGender(g.name);
                                }),
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
                      TextField(
                        controller: nameController,
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
                      TextField(
                        controller: nicknameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Nickname (optional)',
                          prefixIcon: Icon(Icons.favorite_outline, color: pTheme.accent),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: pTheme.accent, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDob,
                            firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => selectedDob = picked);
                          }
                        },
                        icon: Icon(Icons.cake_outlined, color: pTheme.accent),
                        label: Text('Birthday: ${_formatDate(selectedDob)}',
                            style: TextStyle(color: pTheme.accent, fontWeight: FontWeight.w500)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: pTheme.accent.withAlpha(120)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTob != null
                                ? TimeOfDay.fromDateTime(selectedTob!)
                                : TimeOfDay.now(),
                          );
                          if (picked != null) {
                            final now = DateTime.now();
                            setState(() => selectedTob = DateTime(
                              now.year, now.month, now.day,
                              picked.hour, picked.minute,
                            ));
                          }
                        },
                        icon: Icon(Icons.access_time, color: pTheme.accent),
                        label: Text(
                          selectedTob != null
                              ? 'Birth time: ${selectedTob!.hour.toString().padLeft(2, '0')}:${selectedTob!.minute.toString().padLeft(2, '0')}'
                              : 'Add birth time (optional)',
                          style: TextStyle(color: pTheme.accent, fontWeight: FontWeight.w500),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: pTheme.accent.withAlpha(120)),
                        ),
                      ),
                      if (selectedTob != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: TextButton(
                            onPressed: () => setState(() => selectedTob = null),
                            child: const Text('Remove time', style: TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text('Theme', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                      const SizedBox(height: 10),
                      _ThemePresetPicker(
                        selectedId: selectedPresetId,
                        onSelect: (id) => setState(() => selectedPresetId = id),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
      final matchTags = _selectAllTags || _selectedTags.isEmpty || m.tags.any(_selectedTags.contains);
      final matchFavorite = !_showFavoritesOnly || m.isFavorite;
      return matchYear && matchQuery && matchTags && matchFavorite;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          // ── Hero header ──────────────────────────────
          _ProfileHeader(
            profile: currentProfile,
            profileTheme: profileTheme,
            allProfiles: profiles,
            profileIndex: safeIndex,
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            onSelectProfile: (i) {
              ref.read(selectedProfileIndexProvider.notifier).state = i;
              setState(() {
                _searchQuery = '';
                _selectedYear = null;
                _selectedTags = {};
                _showSearch = false;
                _showFavoritesOnly = false;
                _searchController.clear();
              });
            },
            onSharedFeed: () => SharedFeedScreen.push(context),
            onDocuments: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DocumentsScreen(profileIndex: safeIndex),
              ),
            ),
            onLinks: () => SavedLinksScreen.push(context, safeIndex),
            onEditProfile: () => _showEditProfileSheet(context, safeIndex, currentProfile),
            onAddProfile: _showAddProfileSheet,
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
                      if (allMilestones.isNotEmpty) ...[
                        IconButton(
                          icon: Icon(
                            _showFavoritesOnly ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: _showFavoritesOnly ? const Color(0xFFFBBF24) : Colors.grey.shade400,
                            size: 22,
                          ),
                          onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                          tooltip: _showFavoritesOnly ? 'Show all memories' : 'Show favorites only',
                        ),
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
                                _selectedYear = null;
                                _selectedTags = {};
                                _selectAllTags = true;
                              }
                            });
                            if (_showSearch) _searchFocusNode.requestFocus();
                          },
                          tooltip: _showSearch ? 'Hide search' : 'Search',
                        ),
                      ],
                    ],
                  ),
                ),

                // Collapsible filters
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  height: _showSearch ? 120 : 0,
                  child: _showSearch
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 6,
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
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.arrow_left, size: 18),
                                            onPressed: () {
                                              final options = ['All', ...availableYears.map((y) => '$y')];
                                              final currentIndex = _selectedYear == null ? 0 : options.indexOf('$_selectedYear');
                                              final nextIndex = (currentIndex - 1 + options.length) % options.length;
                                              setState(() {
                                                _selectedYear = nextIndex == 0 ? null : int.parse(options[nextIndex]);
                                              });
                                            },
                                          ),
                                          Expanded(
                                            child: Text(
                                              _selectedYear == null ? 'All years' : '$_selectedYear',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.arrow_right, size: 18),
                                            onPressed: () {
                                              final options = ['All', ...availableYears.map((y) => '$y')];
                                              final currentIndex = _selectedYear == null ? 0 : options.indexOf('$_selectedYear');
                                              final nextIndex = (currentIndex + 1) % options.length;
                                              setState(() {
                                                _selectedYear = nextIndex == 0 ? null : int.parse(options[nextIndex]);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (allTags.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 36,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: _FilterChip(
                                          label: 'All tags',
                                          selected: _selectAllTags,
                                          accent: profileTheme.accent,
                                          soft: profileTheme.soft,
                                          onTap: () => setState(() => _selectAllTags = !_selectAllTags),
                                        ),
                                      ),
                                      if (!_selectAllTags) ...allTags.map((tag) => Padding(
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
                                    ].toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

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
                                    _showFavoritesOnly ? 'No favourite memories yet.' : 'No milestones match your filter.',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() {
                                      _searchQuery = '';
                                      _selectedYear = null;
                                      _selectedTags = {};
                                      _showSearch = false;
                                      _showFavoritesOnly = false;
                                      _searchController.clear();
                                    }),
                                    child: const Text('Clear filters'),
                                  ),
                                ],
                              ),
                            )
                          : AnimatedBuilder(
                              animation: _listScrollController,
                              builder: (context, child) {
                                final offset = _listScrollController.hasClients
                                    ? _listScrollController.offset
                                    : 0.0;
                                final t = (offset / 500).clamp(0.0, 1.0);
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color.lerp(
                                          profileTheme.soft.withAlpha(180),
                                          const Color(0xFFF2F2F7),
                                          t,
                                        )!,
                                        const Color(0xFFF2F2F7),
                                        Color.lerp(
                                          profileTheme.cardBg.withAlpha(160),
                                          const Color(0xFFF2F2F7),
                                          t,
                                        )!,
                                      ],
                                    ),
                                  ),
                                  child: child,
                                );
                              },
                              child: ListView.builder(
                                controller: _listScrollController,
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final milestone = filtered[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: MilestoneCard(
                                      milestone: milestone,
                                      gender: currentProfile.gender,
                                      animIndex: index,
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
                                      onEdit: () =>
                                          _showEditMilestoneSheet(milestone),
                                      onDelete: () => _confirmDeleteMilestone(
                                          safeIndex, milestone),
                                      onFavorite: () => ref
                                          .read(profilesProvider.notifier)
                                          .toggleMilestoneFavorite(
                                              safeIndex, milestone.id),
                                      onShare: () => MemorySharer.show(
                                        context,
                                        milestone,
                                        currentProfile.name,
                                        currentProfile.gender,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: profileTheme.headerGradient,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withAlpha(80), width: 1),
          boxShadow: [
            BoxShadow(
              color: profileTheme.accent.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: _showAddMilestoneSheet,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                  SizedBox(width: 6),
                  Text('New memory',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.2)),
                ],
              ),
            ),
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? accent : accent.withAlpha(40), width: 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: accent.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ],
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
  final List<KidProfile> allProfiles;
  final int profileIndex;
  final VoidCallback onSettings;
  final ValueChanged<int> onSelectProfile;
  final VoidCallback onSharedFeed;
  final VoidCallback onDocuments;
  final VoidCallback onLinks;
  final VoidCallback onEditProfile;
  final VoidCallback onAddProfile;

  const _ProfileHeader({
    required this.profile,
    required this.profileTheme,
    required this.allProfiles,
    required this.profileIndex,
    required this.onSettings,
    required this.onSelectProfile,
    required this.onSharedFeed,
    required this.onDocuments,
    required this.onLinks,
    required this.onEditProfile,
    required this.onAddProfile,
  });

  @override
  Widget build(BuildContext context) {
    final hasBackground = !kIsWeb &&
        profile.backgroundImagePath != null &&
        profile.backgroundImagePath!.isNotEmpty &&
        File(profile.backgroundImagePath!).existsSync();
    final hasAvatar = profile.avatarImagePath != null &&
        profile.avatarImagePath!.isNotEmpty &&
        !kIsWeb &&
        File(profile.avatarImagePath!).existsSync();

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
              Positioned(right: -28, top: -18, child: _Bubble(110, 18)),
              Positioned(right: 60, bottom: -22, child: _Bubble(80, 14)),
              Positioned(left: -22, top: 30, child: _Bubble(70, 12)),
              Positioned(left: 80, bottom: 8, child: _Bubble(28, 22)),
              Positioned(right: 24, top: 48, child: _Bubble(16, 30)),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile info + settings ───────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar only — fixed 68px so name never shifts
                          GestureDetector(
                            onTap: onEditProfile,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withAlpha(30),
                                    border: Border.all(color: Colors.white, width: 2),
                                    image: hasAvatar
                                        ? DecorationImage(
                                            image: FileImage(File(profile.avatarImagePath!)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(40),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: hasAvatar
                                      ? null
                                      : Center(
                                          child: Text(
                                            profileTheme.decalEmoji,
                                            style: const TextStyle(fontSize: 32),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(30),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 11,
                                      color: profileTheme.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Name + age
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile.nickname ?? profile.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (profile.nickname != null &&
                                    profile.nickname!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      profile.name,
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(180),
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(35),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    profile.ageText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Settings inline top-right
                          _HeaderIconBtn(
                            icon: Icons.settings_outlined,
                            onTap: onSettings,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Mini profile switcher (own row, never affects name position) ──
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < allProfiles.length; i++)
                            if (i != profileIndex)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: _MiniProfileAvatar(
                                  profile: allProfiles[i],
                                  onTap: () => onSelectProfile(i),
                                ),
                              ),
                          GestureDetector(
                            onTap: onAddProfile,
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withAlpha(30),
                                    border: Border.all(
                                        color: Colors.white.withAlpha(140), width: 1.5),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Quick-access strip ────────────────────────
                      Row(
                        children: [
                          Expanded(child: _QuickPill(
                            icon: Icons.auto_awesome,
                            label: 'Moments',
                          )),
                          Expanded(child: _QuickPill(
                            icon: Icons.folder_outlined,
                            label: 'Docs',
                            onTap: onDocuments,
                          )),
                          Expanded(child: _QuickPill(
                            icon: Icons.link_outlined,
                            label: 'Links',
                            onTap: onLinks,
                          )),
                          Expanded(child: _QuickPill(
                            icon: Icons.people_outline_rounded,
                            label: 'Feed',
                            onTap: onSharedFeed,
                          )),
                          Expanded(child: _RemindersQuickPill(
                            profile: profile,
                            profileIndex: profileIndex,
                          )),
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

// ── Decorative bubble ─────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final double size;
  final int alpha;
  const _Bubble(this.size, this.alpha);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(alpha),
      ),
    );
  }
}

// ── Minimal header icon button ────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(45),
              border: Border.all(color: Colors.white.withAlpha(70), width: 0.8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Quick-access pill ─────────────────────────────────────────────────────────

class _QuickPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickPill({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(onTap != null ? 45 : 25),
                  border: Border.all(
                    color: Colors.white.withAlpha(onTap != null ? 80 : 45),
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 17),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini profile avatar (switcher) ───────────────────────────────────────────

class _MiniProfileAvatar extends StatelessWidget {
  final KidProfile profile;
  final VoidCallback onTap;
  const _MiniProfileAvatar({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = profile.avatarImagePath != null &&
        profile.avatarImagePath!.isNotEmpty &&
        !kIsWeb &&
        File(profile.avatarImagePath!).existsSync();
    final pTheme = ProfileTheme.forProfile(profile);

    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(35),
              border: Border.all(color: Colors.white.withAlpha(160), width: 1.5),
              image: hasAvatar
                  ? DecorationImage(
                      image: FileImage(File(profile.avatarImagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasAvatar
                ? null
                : Center(
                    child: Text(
                      pTheme.decalEmoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Reminders quick pill ──────────────────────────────────────────────────────

class _RemindersQuickPill extends StatelessWidget {
  final KidProfile profile;
  final int profileIndex;

  const _RemindersQuickPill(
      {required this.profile, required this.profileIndex});

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: overdue > 0
                          ? Colors.orange.withAlpha(60)
                          : Colors.white.withAlpha(45),
                      border: Border.all(
                        color: overdue > 0
                            ? Colors.orange.shade300.withAlpha(180)
                            : Colors.white.withAlpha(80),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      overdue > 0
                          ? Icons.alarm_outlined
                          : Icons.notifications_outlined,
                      color: overdue > 0 ? Colors.orange.shade200 : Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: overdue > 0 ? Colors.orange : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withAlpha(120), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: overdue > 0 ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Remind',
            style: TextStyle(
              color: overdue > 0 ? Colors.orange.shade100 : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
                            Text(profile.nickname ?? profile.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? pTheme.accent : const Color(0xFF2D2D2D),
                                )),
                            if (profile.nickname != null && profile.nickname!.isNotEmpty)
                              Text(profile.name,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade500)),
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
    if (tag.isEmpty || _tags.contains(tag) || _tags.length >= 20) {
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

    // Collect all tags used across every profile (excluding tags already added)
    final profiles = ref.read(profilesProvider);
    final List<String> tagSuggestions;
    if (profiles != null && profiles.isNotEmpty) {
      final all = {
        for (final p in profiles)
          for (final m in p.milestones) ...m.tags
      };
      tagSuggestions = (all.difference(_tags.toSet()).toList())..sort();
    } else {
      tagSuggestions = const [];
    }

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
            if (_tags.length < 20)
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
        // Existing tags as suggestions
        if (tagSuggestions.isNotEmpty && _tags.length < 20) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tagSuggestions
                .map((tag) => GestureDetector(
                      onTap: () => _addTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: pTheme.accent.withAlpha(70), width: 1),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: pTheme.accent.withAlpha(180),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
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

// ── Theme preset picker ───────────────────────────────────────────────────────

class _ThemePresetPicker extends StatefulWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _ThemePresetPicker({required this.selectedId, required this.onSelect});

  @override
  State<_ThemePresetPicker> createState() => _ThemePresetPickerState();
}

class _ThemePresetPickerState extends State<_ThemePresetPicker> {
  late bool _show3Color;

  @override
  void initState() {
    super.initState();
    final preset = ThemePreset.findById(widget.selectedId);
    _show3Color = preset?.isThreeColor ?? false;
  }

  @override
  void didUpdateWidget(covariant _ThemePresetPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      final preset = ThemePreset.findById(widget.selectedId);
      if (preset != null) setState(() => _show3Color = preset.isThreeColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = _show3Color ? ThemePreset.threeColor : ThemePreset.twoColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact inline toggle + scroll row
        Row(
          children: [
            // Pill toggle
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniTab(
                    label: '2-Color',
                    selected: !_show3Color,
                    onTap: () => setState(() => _show3Color = false),
                  ),
                  _MiniTab(
                    label: '3-Color',
                    selected: _show3Color,
                    onTap: () => setState(() => _show3Color = true),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Horizontally scrolling preset chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final preset = presets[i];
              final isSelected = preset.id == widget.selectedId;
              return GestureDetector(
                onTap: () => widget.onSelect(preset.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color.lerp(Colors.white, preset.accent, 0.10)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? preset.accent : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: preset.accent.withAlpha(40), blurRadius: 6, offset: const Offset(0, 2))]
                        : [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 3)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ColorDot(color: preset.accent, size: 11),
                      const SizedBox(width: 3),
                      _ColorDot(color: preset.secondary, size: 11),
                      if (preset.tertiary != null) ...[
                        const SizedBox(width: 3),
                        _ColorDot(color: preset.tertiary!, size: 11),
                      ],
                      const SizedBox(width: 7),
                      Text(
                        preset.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? preset.accent : const Color(0xFF444444),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_rounded, size: 12, color: preset.accent),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF1A1A2E) : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final double size;

  const _ColorDot({required this.color, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
