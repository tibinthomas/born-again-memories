import 'dart:io';
import 'dart:math' show pi, sin, cos;
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/backup_provider.dart';
import '../providers/profiles_provider.dart';
import '../services/drive_service.dart';
import '../services/local_storage_service.dart';
import '../utils/app_date_picker.dart';
import '../utils/chime.dart';
import '../utils/device_performance.dart';
import 'dev_checklist_screen.dart';
import 'growth_screen.dart';
import 'sparks_screen.dart';
import 'pdf_export_sheet.dart';
import '../utils/image_utils.dart';
import '../utils/profile_theme.dart';
import '../utils/theme_preset.dart';
import '../widgets/empty_state.dart';
import '../widgets/milestone_card.dart';
import '../utils/memory_sharer.dart';
import 'documents_screen.dart';
import 'home/widgets/add_milestone_sheet.dart';
import 'home/widgets/add_profile_sheet.dart';
import 'home/widgets/theme_preset_picker.dart';
import 'milestone_detail_page.dart';
import 'saved_links_screen.dart';
import 'shared_feed_screen.dart';
import '../providers/sharing_provider.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';
import 'stories_screen.dart';

// ── Home page ──────────────────────────────────────────────────────────────────

class MilestoneHomePage extends ConsumerStatefulWidget {
  const MilestoneHomePage({super.key});

  @override
  ConsumerState<MilestoneHomePage> createState() => _MilestoneHomePageState();
}

class _MilestoneHomePageState extends ConsumerState<MilestoneHomePage> {
  String _searchQuery = '';
  Set<String> _selectedTags = {};
  Set<int> _selectedAges = {};
  bool _selectAllTags = true;
  bool _showSearch = false;
  bool _showFavoritesOnly = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _listScrollController = ScrollController();
  final _scrollOffset = ValueNotifier<double>(0.0);
  DateTime _lastScrollSample = DateTime(0);

  @override
  void initState() {
    super.initState();
    if (!DevicePerformance.isLowEnd) {
      _listScrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    final now = DateTime.now();
    if (now.difference(_lastScrollSample).inMilliseconds >= 50) {
      _lastScrollSample = now;
      _scrollOffset.value = _listScrollController.offset;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _listScrollController.removeListener(_onScroll);
    _listScrollController.dispose();
    _scrollOffset.dispose();
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
      builder: (_) => const AddProfileSheet(),
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
      builder: (_) => const AddMilestoneSheet(),
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
      builder: (_) => AddMilestoneSheet(initialMilestone: milestone),
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

  void _showEditProfileSheet(BuildContext context, int profileIndex, KidProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final nicknameController = TextEditingController(text: profile.nickname ?? '');
    DateTime selectedDob = profile.dateOfBirth;
    DateTime? selectedTob = profile.timeOfBirth;
    Gender selectedGender = profile.gender;
    String? avatarPath = profile.avatarImagePath;
    String? backgroundPath = profile.backgroundImagePath;
    String selectedPresetId = profile.themePresetId ??
        ThemePreset.defaultIdForGender(profile.gender.name);
    bool isUploadingAvatar = false;
    bool isUploadingBackground = false;

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
              (avatarPath!.startsWith('http') ||
                  (!kIsWeb && File(avatarPath!).existsSync()));
          final hasBackground = backgroundPath != null &&
              backgroundPath!.isNotEmpty &&
              (backgroundPath!.startsWith('http') ||
                  (!kIsWeb && File(backgroundPath!).existsSync()));

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
                            backgroundImagePath: backgroundPath,
                            clearBackground: backgroundPath == null && profile.backgroundImagePath != null,
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
                          onTap: isUploadingAvatar ? null : () async {
                            if (kIsWeb) {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: true,
                              );
                              final fileBytes = result?.files.firstOrNull?.bytes;
                              final fileName = result?.files.firstOrNull?.name;
                              if (fileBytes == null || fileName == null) return;
                              setState(() => isUploadingAvatar = true);
                              try {
                                final ext = fileName.contains('.')
                                    ? fileName.split('.').last.toLowerCase()
                                    : 'jpg';
                                final mime = 'image/${ext == 'jpg' ? 'jpeg' : ext}';
                                final authService = ref.read(authServiceProvider);
                                final url = await DriveService.uploadProfileImageBytes(
                                  googleSignIn: authService.googleSignIn,
                                  bytes: fileBytes,
                                  filename:
                                      'avatar_${profile.id}_${DateTime.now().millisecondsSinceEpoch}.$ext',
                                  mimeType: mime,
                                );
                                setState(() {
                                  avatarPath = url;
                                  isUploadingAvatar = false;
                                });
                              } on DriveNotAuthorizedException {
                                setState(() => isUploadingAvatar = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                    content: Text(
                                        'Google Drive access needed. Enable Drive Backup in Settings first.'),
                                  ));
                                }
                              } catch (e) {
                                setState(() => isUploadingAvatar = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text('Upload failed: $e'),
                                  ));
                                }
                              }
                              return;
                            }
                            String? pickedPath;
                            if (Platform.isIOS || Platform.isAndroid) {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(source: ImageSource.gallery);
                              pickedPath = file?.path;
                            } else {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: false,
                              );
                              pickedPath = result?.files.firstOrNull?.path;
                            }
                            if (pickedPath != null) {
                              final croppedPath = await cropImage(
                                pickedPath,
                                isAvatar: true,
                                accent: pTheme.accent,
                              );
                              if (croppedPath == null) return;
                              final permanent = await LocalStorageService.copyAvatarToStorage(
                                croppedPath,
                                'avatar_${profile.id}_${DateTime.now().millisecondsSinceEpoch}',
                              );
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
                                          image: avatarPath!.startsWith('http')
                                              ? NetworkImage(avatarPath!) as ImageProvider
                                              : FileImage(File(avatarPath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: isUploadingAvatar
                                    ? Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: pTheme.accent,
                                          ),
                                        ),
                                      )
                                    : hasAvatar
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
                                  child: isUploadingAvatar
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
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
                      ...[
                        Row(
                          children: [
                            Text('Background photo',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                            const Spacer(),
                            if (hasBackground)
                              TextButton(
                                onPressed: () => setState(() => backgroundPath = null),
                                child: Text('Remove',
                                    style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: isUploadingBackground ? null : () async {
                            if (kIsWeb) {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: true,
                              );
                              final fileBytes = result?.files.firstOrNull?.bytes;
                              final fileName = result?.files.firstOrNull?.name;
                              if (fileBytes == null || fileName == null) return;
                              setState(() => isUploadingBackground = true);
                              try {
                                final ext = fileName.contains('.')
                                    ? fileName.split('.').last.toLowerCase()
                                    : 'jpg';
                                final mime = 'image/${ext == 'jpg' ? 'jpeg' : ext}';
                                final authService = ref.read(authServiceProvider);
                                final url = await DriveService.uploadProfileImageBytes(
                                  googleSignIn: authService.googleSignIn,
                                  bytes: fileBytes,
                                  filename:
                                      'bg_${profile.id}_${DateTime.now().millisecondsSinceEpoch}.$ext',
                                  mimeType: mime,
                                );
                                setState(() {
                                  backgroundPath = url;
                                  isUploadingBackground = false;
                                });
                              } on DriveNotAuthorizedException {
                                setState(() => isUploadingBackground = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                    content: Text(
                                        'Google Drive access needed. Enable Drive Backup in Settings first.'),
                                  ));
                                }
                              } catch (e) {
                                setState(() => isUploadingBackground = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text('Upload failed: $e'),
                                  ));
                                }
                              }
                              return;
                            }
                            String? pickedPath;
                            if (Platform.isIOS || Platform.isAndroid) {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(source: ImageSource.gallery);
                              pickedPath = file?.path;
                            } else {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: false,
                              );
                              pickedPath = result?.files.firstOrNull?.path;
                            }
                            if (pickedPath != null) {
                              final croppedPath = await cropImage(
                                pickedPath,
                                isAvatar: false,
                                accent: pTheme.accent,
                              );
                              if (croppedPath == null) return;
                              final permanent = await LocalStorageService.copyBackgroundToStorage(
                                croppedPath,
                                'bg_${profile.id}_${DateTime.now().millisecondsSinceEpoch}',
                              );
                              if (backgroundPath != null && backgroundPath != profile.backgroundImagePath) {
                                LocalStorageService.delete(backgroundPath!);
                              }
                              setState(() => backgroundPath = permanent);
                            }
                          },
                          child: Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: pTheme.soft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: pTheme.accent.withAlpha(80), width: 1.5),
                              image: hasBackground
                                  ? DecorationImage(
                                      image: backgroundPath!.startsWith('http')
                                          ? NetworkImage(backgroundPath!) as ImageProvider
                                          : FileImage(File(backgroundPath!)),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withAlpha(30),
                                        BlendMode.darken,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: isUploadingBackground
                                  ? SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: pTheme.accent,
                                      ),
                                    )
                                  : Column(
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
                          final picked = await showAppDatePicker(
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
                      ThemePresetPicker(
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

    final settings = ref.watch(appSettingsProvider);
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
    final allTags = ({for (final m in allMilestones) ...m.tags}).toList()..sort();

    int ageAt(Milestone m) {
      final days = m.date.difference(currentProfile.dateOfBirth).inDays;
      return (days / 365.25).floor().clamp(0, 99);
    }

    final availableAges = allMilestones.map(ageAt).toSet().toList()..sort();

    final filtered = allMilestones.where((m) {
      final matchAge = _selectedAges.isEmpty || _selectedAges.contains(ageAt(m));
      final q = _searchQuery.toLowerCase();
      final matchQuery = q.isEmpty ||
          m.title.toLowerCase().contains(q) ||
          m.description.toLowerCase().contains(q) ||
          m.tags.any((t) => t.contains(q));
      final matchTags = _selectAllTags || _selectedTags.isEmpty || m.tags.any(_selectedTags.contains);
      final matchFavorite = !_showFavoritesOnly || m.isFavorite;
      return matchAge && matchQuery && matchTags && matchFavorite;
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
                _selectedAges = {};
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
            onGrowth: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GrowthScreen(profileIndex: safeIndex),
              ),
            ),
            onChecklist: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DevChecklistScreen(profileIndex: safeIndex),
              ),
            ),
            onSparks: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SparksScreen(profileIndex: safeIndex),
              ),
            ),
            onStories: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoriesScreen(profileIndex: safeIndex),
              ),
            ),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
                  child: Row(
                    children: [
                      Text(
                        '${profileTheme.decalEmoji}  Precious moments',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
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
                                _selectedAges = {};
                                _selectedTags = {};
                                _selectAllTags = true;
                              }
                            });
                            if (_showSearch) _searchFocusNode.requestFocus();
                          },
                          tooltip: _showSearch ? 'Hide search' : 'Search',
                        ),
                        IconButton(
                          icon: Icon(Icons.picture_as_pdf_outlined,
                              color: Colors.grey.shade500, size: 22),
                          onPressed: allMilestones.isEmpty ? null : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => PdfExportSheet(
                                  profileIndex: safeIndex),
                            );
                          },
                          tooltip: 'Export memory book',
                        ),
                      ],
                    ],
                  ),
                ),

                // Collapsible filters
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  height: _showSearch ? 84 : 0,
                  child: _showSearch
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Column(
                            children: [
                              // ── Search bar ──────────────────────────────
                              SizedBox(
                                height: 38,
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: (v) => setState(() => _searchQuery = v),
                                  decoration: InputDecoration(
                                    hintText: 'Search memories…',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.close, size: 16),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.zero,
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
                                      borderSide: BorderSide(color: profileTheme.accent, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              // ── Chip row: tags + age ─────────────────────
                              SizedBox(
                                height: 28,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    // Tags
                                    if (allTags.isNotEmpty) ...[
                                      _FilterChip(
                                        label: 'All tags',
                                        selected: _selectAllTags,
                                        accent: profileTheme.accent,
                                        soft: profileTheme.soft,
                                        onTap: () => setState(() {
                                          _selectAllTags = true;
                                          _selectedTags = {};
                                        }),
                                      ),
                                      ...allTags.map((tag) => Padding(
                                            padding: const EdgeInsets.only(left: 6),
                                            child: _FilterChip(
                                              label: '#$tag',
                                              selected: _selectedTags.contains(tag),
                                              accent: profileTheme.accent,
                                              soft: profileTheme.soft,
                                              onTap: () => setState(() {
                                                _selectAllTags = false;
                                                if (_selectedTags.contains(tag)) {
                                                  _selectedTags = {..._selectedTags}..remove(tag);
                                                  if (_selectedTags.isEmpty) _selectAllTags = true;
                                                } else {
                                                  _selectedTags = {..._selectedTags, tag};
                                                }
                                              }),
                                            ),
                                          )),
                                    ],
                                    // Divider between tags and ages
                                    if (allTags.isNotEmpty && availableAges.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Center(
                                          child: Container(
                                            width: 1,
                                            height: 16,
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                    // Age chips (multiselect)
                                    ...availableAges.map((age) => Padding(
                                          padding: EdgeInsets.only(
                                              left: age == availableAges.first && allTags.isEmpty ? 0 : 6),
                                          child: _AgeChip(
                                            age: age,
                                            selected: _selectedAges.contains(age),
                                            accent: profileTheme.accent,
                                            onTap: () => setState(() {
                                              if (_selectedAges.contains(age)) {
                                                _selectedAges = {..._selectedAges}..remove(age);
                                              } else {
                                                _selectedAges = {..._selectedAges, age};
                                              }
                                            }),
                                          ),
                                        )),
                                  ],
                                ),
                              ),
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
                                      _selectedAges = {};
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
                          : ValueListenableBuilder<double>(
                              valueListenable: _scrollOffset,
                              builder: (context, offset, child) {
                                final t = DevicePerformance.isLowEnd
                                    ? 1.0
                                    : (offset / 500).clamp(0.0, 1.0);
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
                                cacheExtent: 800,
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final milestone = filtered[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: MilestoneCard(
                                      milestone: milestone,
                                      profileTheme: profileTheme,
                                      animIndex: index,
                                      animationsEnabled: settings.animationsEnabled,
                                      dateOfBirth: currentProfile.dateOfBirth,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MilestoneDetailPage(
                                            milestones: filtered,
                                            initialIndex: index,
                                            profile: currentProfile,
                                            animationsEnabled: settings.animationsEnabled,
                                          ),
                                        ),
                                      ),
                                      onEdit: () =>
                                          _showEditMilestoneSheet(milestone),
                                      onDelete: () => _confirmDeleteMilestone(
                                          safeIndex, milestone),
                                      onFavorite: () {
                                        ref.read(profilesProvider.notifier)
                                            .toggleMilestoneFavorite(safeIndex, milestone.id);
                                        triggerLightFeedback(ref);
                                      },
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

class _AgeChip extends StatelessWidget {
  final int age;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _AgeChip({
    required this.age,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? accent : Colors.grey.shade300, width: 1),
          boxShadow: selected
              ? [BoxShadow(color: accent.withAlpha(50), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cake_outlined, size: 11,
                color: selected ? Colors.white : accent),
            const SizedBox(width: 4),
            Text(
              '${age}y',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? accent : Colors.grey.shade300, width: 1),
          boxShadow: selected
              ? [BoxShadow(color: accent.withAlpha(50), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
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

class _ProfileHeader extends ConsumerWidget {
  final KidProfile profile;
  final ProfileTheme profileTheme;
  final List<KidProfile> allProfiles;
  final int profileIndex;
  final VoidCallback onSettings;
  final ValueChanged<int> onSelectProfile;
  final VoidCallback onSharedFeed;
  final VoidCallback onDocuments;
  final VoidCallback onLinks;
  final VoidCallback onGrowth;
  final VoidCallback onChecklist;
  final VoidCallback onSparks;
  final VoidCallback onStories;
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
    required this.onGrowth,
    required this.onChecklist,
    required this.onSparks,
    required this.onStories,
    required this.onEditProfile,
    required this.onAddProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(backupSyncProvider);
    final sharedCount = ref.watch(sharedSendersCountProvider).valueOrNull ?? 0;
    final settings = ref.watch(appSettingsProvider);
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
              // Decorative bubbles — skipped on low-end devices
              if (!DevicePerformance.isLowEnd) ...[
                Positioned(right: -28, top: -18, child: _Bubble(110, 18)),
                Positioned(right: 60, bottom: -22, child: _Bubble(80, 14)),
                Positioned(left: -22, top: 30, child: _Bubble(70, 12)),
                Positioned(left: 80, bottom: 8, child: _Bubble(28, 22)),
                Positioned(right: 24, top: 48, child: _Bubble(16, 30)),
              ],
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
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

                          // Backup status indicator
                          if (sync.driveAccessGranted) ...[
                            _BackupHeaderIndicator(sync: sync),
                            const SizedBox(width: 6),
                          ],

                          // Settings button — shows custom icon image when set
                          _SettingsBtn(onTap: onSettings),
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
                          if (settings.growthTrackingEnabled)
                            Expanded(child: _QuickPill(
                              icon: Icons.show_chart_rounded,
                              label: 'Growth',
                              onTap: onGrowth,
                            )),
                          if (settings.checklistEnabled)
                            Expanded(child: _QuickPill(
                              icon: Icons.checklist_rounded,
                              label: 'Checklist',
                              onTap: onChecklist,
                            )),
                          if (settings.sparksEnabled)
                            Expanded(child: _QuickPill(
                              icon: Icons.bolt_rounded,
                              label: 'Sparks',
                              onTap: onSparks,
                            )),
                          Expanded(child: _QuickPill(
                            icon: Icons.article_outlined,
                            label: 'Stories',
                            onTap: onStories,
                          )),
                          if (settings.documentsEnabled)
                            Expanded(child: _QuickPill(
                              icon: Icons.folder_outlined,
                              label: 'Docs',
                              onTap: onDocuments,
                            )),
                          if (settings.linksEnabled)
                            Expanded(child: _QuickPill(
                              icon: Icons.link_outlined,
                              label: 'Links',
                              onTap: onLinks,
                            )),
                          Expanded(child: _QuickPill(
                            icon: Icons.people_outline_rounded,
                            label: 'Feed',
                            onTap: onSharedFeed,
                            showBadge: sharedCount > 0,
                          )),
                          if (settings.remindersEnabled)
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

class _Bubble extends StatefulWidget {
  final double size;
  final int alpha;
  const _Bubble(this.size, this.alpha);

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final ms = (2800 + widget.size * 14).toInt();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: ms))
      ..repeat();
    // Phase-offset so each bubble is out of sync with its neighbours
    _ctrl.forward(from: (widget.size % 100) / 100);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final travel = (widget.size * 0.13).clamp(6.0, 22.0);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value * 2 * pi;
        final dy = sin(t) * travel;
        final dx = cos(t * 0.65) * travel * 0.45;
        final scale = 1.0 + sin(t * 1.4 + 1.0) * 0.07;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(widget.alpha),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Minimal header icon button ────────────────────────────────────────────────

class _SettingsBtn extends ConsumerWidget {
  final VoidCallback onTap;
  const _SettingsBtn({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customIcon = ref.watch(appSettingsProvider).customIcon;
    final hasCustom = !kIsWeb &&
        customIcon != null &&
        customIcon.isNotEmpty &&
        File(customIcon).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Stack(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(45),
                  border: Border.all(color: Colors.white.withAlpha(70), width: 0.8),
                  image: hasCustom
                      ? DecorationImage(
                          image: FileImage(File(customIcon)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasCustom
                    ? null
                    : const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
              ),
              if (hasCustom)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withAlpha(120),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white, size: 9),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Backup status indicator (header) ─────────────────────────────────────────

class _BackupHeaderIndicator extends StatelessWidget {
  final BackupSyncState sync;
  const _BackupHeaderIndicator({required this.sync});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(70), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sync.isSyncing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.cloud_done_outlined,
                  color: Colors.white.withAlpha(200),
                  size: 14,
                ),
              const SizedBox(width: 5),
              Text(
                sync.isSyncing
                    ? (sync.currentUploadName != null ? 'Backing up…' : 'Syncing…')
                    : 'Backed up',
                style: TextStyle(
                  color: Colors.white.withAlpha(220),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
  final bool showBadge;

  const _QuickPill({
    required this.icon,
    required this.label,
    this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(onTap != null ? 55 : 28),
                      border: Border.all(
                        color: Colors.white.withAlpha(onTap != null ? 110 : 50),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(icon,
                        color: Colors.white.withAlpha(onTap != null ? 230 : 140),
                        size: 20),
                  ),
                ),
              ),
              if (showBadge)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(onTap != null ? 230 : 140),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
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
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: overdue > 0
                          ? Colors.orange.withAlpha(70)
                          : Colors.white.withAlpha(55),
                      border: Border.all(
                        color: overdue > 0
                            ? Colors.orange.shade300.withAlpha(200)
                            : Colors.white.withAlpha(110),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      overdue > 0
                          ? Icons.alarm_outlined
                          : Icons.notifications_outlined,
                      color: overdue > 0 ? Colors.orange.shade200 : Colors.white,
                      size: 20,
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
          const SizedBox(height: 6),
          Text(
            'Remind',
            style: TextStyle(
              color: overdue > 0
                  ? Colors.orange.shade100
                  : Colors.white.withAlpha(230),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
