import 'dart:async';
import 'dart:io';
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
import '../utils/profile_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/milestone_card.dart';
import '../widgets/overview_chip.dart';
import 'settings_screen.dart';

class MilestoneHomePage extends ConsumerWidget {
  const MilestoneHomePage({super.key});

  void _showAddProfileSheet(BuildContext context) {
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

  void _showAddMilestoneSheet(BuildContext context) {
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

  void _showEditMilestoneSheet(BuildContext context, Milestone milestone) {
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

  void _confirmDeleteMilestone(
      BuildContext context, WidgetRef ref, int profileIndex, Milestone milestone) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(backupSyncProvider);

    final profilesAsync = ref.watch(profilesProvider);
    if (profilesAsync == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profiles = profilesAsync;
    if (profiles.isEmpty) {
      return _EmptyProfilesScreen(onAdd: () => _showAddProfileSheet(context));
    }

    final selectedIndex = ref.watch(selectedProfileIndexProvider);
    final safeIndex = selectedIndex.clamp(0, profiles.length - 1);
    final currentProfile = profiles[safeIndex];
    final milestones = currentProfile.milestones;
    final profileTheme = ProfileTheme.forProfile(currentProfile);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Column(
        children: [
          // ── Hero header ──────────────────────────────
          _ProfileHeader(
            profile: currentProfile,
            profileTheme: profileTheme,
            milestoneCount: milestones.length,
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            onAddProfile: () => _showAddProfileSheet(context),
          ),

          // ── Profile switcher ─────────────────────────
          if (profiles.length > 1)
            _ProfileSwitcher(
              profiles: profiles,
              selectedIndex: safeIndex,
              onSelect: (i) =>
                  ref.read(selectedProfileIndexProvider.notifier).state = i,
            ),

          // ── Milestones list ──────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFFAF8F5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 4),
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
                        TextButton.icon(
                          onPressed: () => _showAddMilestoneSheet(context),
                          icon: Icon(Icons.add_circle, color: profileTheme.accent, size: 20),
                          label: Text(
                            'Add',
                            style: TextStyle(color: profileTheme.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: milestones.isEmpty
                        ? EmptyState(theme: Theme.of(context), gender: currentProfile.gender)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                            itemCount: milestones.length,
                            itemBuilder: (context, index) {
                              final milestone = milestones[index];
                              return MilestoneCard(
                                milestone: milestone,
                                gender: currentProfile.gender,
                                isFirst: index == 0,
                                isLast: index == milestones.length - 1,
                                onEdit: () => _showEditMilestoneSheet(context, milestone),
                                onDelete: () => _confirmDeleteMilestone(
                                    context, ref, safeIndex, milestone),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMilestoneSheet(context),
        backgroundColor: profileTheme.accent,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('New memory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        elevation: 4,
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
                    boxShadow: [BoxShadow(color: Colors.orange.withAlpha(60), blurRadius: 20, spreadRadius: 4)],
                  ),
                  child: const Icon(Icons.child_care, size: 52, color: Color(0xFFFFB347)),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Start your journey',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
                ),
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
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
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
  final VoidCallback onSettings;
  final VoidCallback onAddProfile;

  const _ProfileHeader({
    required this.profile,
    required this.profileTheme,
    required this.milestoneCount,
    required this.onSettings,
    required this.onAddProfile,
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
              // Gradient overlay for legibility
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
              // Content — determines the height of the whole header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: onAddProfile,
                            icon: const Icon(Icons.person_add_outlined, color: Colors.white70, size: 22),
                            tooltip: 'Add profile',
                          ),
                          IconButton(
                            onPressed: onSettings,
                            icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Profile info — centered
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(30),
                                border: Border.all(color: Colors.white, width: 2.5),
                              ),
                              child: Center(
                                child: Text(
                                  profileTheme.decalEmoji,
                                  style: const TextStyle(fontSize: 32),
                                ),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                profile.ageText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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

// ── Profile switcher ───────────────────────────────────────────────────────────

class _ProfileSwitcher extends StatelessWidget {
  final List<KidProfile> profiles;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _ProfileSwitcher({
    required this.profiles,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: profiles.length,
        separatorBuilder: (_, _i) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final profile = profiles[i];
          final isSelected = i == selectedIndex;
          final pTheme = ProfileTheme.forProfile(profile);
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? pTheme.accent : pTheme.soft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? pTheme.accent : pTheme.accent.withAlpha(60),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pTheme.decalEmoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? Colors.white : pTheme.accent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
            // Drag handle
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

            const Text(
              'New little one',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
            ),
            const SizedBox(height: 4),
            Text(
              'Tell us about your baby.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),

            // Gender selector
            const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                      onTap: () => ref.read(addProfileFormProvider.notifier).setGender(g),
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
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  ref.read(addProfileFormProvider.notifier).setDob(picked);
                }
              },
              icon: Icon(Icons.cake_outlined, color: pTheme.accent),
              label: Text(
                'Birthday: ${formatDate(form.dob)}',
                style: TextStyle(color: pTheme.accent, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: pTheme.accent.withAlpha(120)),
              ),
            ),
            const SizedBox(height: 16),

            // Background image picker (not on web)
            if (!kIsWeb) ...[
              Row(
                children: [
                  const Text('Background photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  if (hasBackground)
                    TextButton(
                      onPressed: () => ref.read(addProfileFormProvider.notifier)
                          .setBackgroundImagePath(null),
                      child: Text('Remove', style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
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
                    border: Border.all(color: pTheme.accent.withAlpha(80), width: 1.5),
                    image: hasBackground
                        ? DecorationImage(
                            image: FileImage(File(form.backgroundImagePath!)),
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
                          hasBackground ? Icons.check_circle : Icons.add_photo_alternate_outlined,
                          color: hasBackground ? Colors.white : pTheme.accent,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasBackground ? 'Photo selected — tap to change' : 'Tap to pick a photo',
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
                    const SnackBar(content: Text("Please enter your baby's name.")),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Create profile',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
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
  final _picker = ImagePicker();
  final _labelControllers = <String, TextEditingController>{};
  String? _titleError;
  String? _descError;
  Set<String> _existingAttachmentIds = {};

  bool get _isEditing => widget.initialMilestone != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMilestone;
    if (initial == null) return;
    _titleController.text = initial.title;
    _descController.text = initial.description;
    _existingAttachmentIds = {for (final a in initial.attachments) a.id};
    for (final a in initial.attachments) {
      _labelControllers[a.id] = TextEditingController(text: a.label ?? '');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(addMilestoneFormProvider.notifier).initialize(initial.date, initial.attachments);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    for (final c in _labelControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addAttachment(Attachment a) {
    _labelControllers[a.id] = TextEditingController();
    ref.read(addMilestoneFormProvider.notifier).addAttachment(a);
  }

  void _removeAttachment(int index, String id) {
    _labelControllers[id]?.dispose();
    _labelControllers.remove(id);
    ref.read(addMilestoneFormProvider.notifier).removeAttachment(index);
  }

  void _addXFiles(List<XFile> files) {
    for (final f in files) {
      final ext = f.path.split('.').last.toLowerCase();
      _addAttachment(Attachment(
        id: '${DateTime.now().microsecondsSinceEpoch}_${files.indexOf(f)}',
        name: f.name,
        localPath: f.path,
        type: getAttachmentTypeFromExtension(ext),
        sizeBytes: 0,
      ));
    }
  }

  Future<void> _startLiveRecording() async {
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/rec_${DateTime.now().microsecondsSinceEpoch}.m4a';
    final now = TimeOfDay.now();
    final filePath = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RecordingDialog(savePath: path),
    );
    if (filePath == null || !mounted) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    // ignore: use_build_context_synchronously
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final form = ref.watch(addMilestoneFormProvider);

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

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
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

            // Title + date chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Edit memory' : 'Record a milestone',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: form.date,
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      ref.read(addMilestoneFormProvider.notifier).setDate(picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today, size: 13, color: theme.colorScheme.primary),
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

            // Milestone title
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
            const SizedBox(height: 18),

            // Media buttons
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
                      final f = await _picker.pickImage(source: ImageSource.camera);
                      if (f != null) _addXFiles([f]);
                    },
                  ),
                  const SizedBox(width: 8),
                  _MediaBtn(
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    color: Colors.red,
                    onTap: () async {
                      final f = await _picker.pickVideo(source: ImageSource.camera);
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
                    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
                      final files = await _picker.pickMultipleMedia();
                      if (files.isNotEmpty) _addXFiles(files);
                    } else {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.media,
                      );
                      if (result != null) {
                        for (final f in result.files.where((f) => f.path != null)) {
                          final ext = f.extension?.toLowerCase() ?? '';
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
                    setState(() {});
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
                    );
                    if (result != null) {
                      for (final f in result.files.where((f) => f.path != null)) {
                        _addAttachment(Attachment(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          name: f.name,
                          localPath: f.path!,
                          type: AttachmentType.audio,
                          sizeBytes: 0,
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
            if (form.attachments.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: form.attachments.length,
                  separatorBuilder: (_, _i) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final a = form.attachments[i];
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
                                child: a.type == AttachmentType.image && !kIsWeb
                                    ? Image.file(File(a.localPath),
                                        width: 90, height: 90, fit: BoxFit.cover)
                                    : Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              a.type == AttachmentType.video
                                                  ? Icons.videocam
                                                  : Icons.mic,
                                              size: 28,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(height: 4),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 4),
                                              child: Text(
                                                a.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(fontSize: 9),
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
                                  onTap: () => setState(() => _removeAttachment(i, a.id)),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
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
                              hintStyle:
                                  TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              isDense: true,
                              counterText: '',
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: theme.colorScheme.primary),
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
                  setState(() => _titleError = 'Title must be at least 2 characters');
                  valid = false;
                }
                if (desc.isEmpty) {
                  setState(() => _descError = 'Please write why this moment matters');
                  valid = false;
                } else if (desc.length < 5) {
                  setState(() => _descError = 'Description is too short');
                  valid = false;
                }
                if (!valid) return false;

                final profileIndex = ref.read(selectedProfileIndexProvider);
                final profile = (ref.read(profilesProvider) ?? [])[profileIndex];

                final saved = <Attachment>[];
                for (final a in form.attachments) {
                  final labelText = _labelControllers[a.id]?.text.trim();
                  final label = labelText?.isEmpty == true ? null : labelText;
                  if (_existingAttachmentIds.contains(a.id)) {
                    saved.add(a.copyWith(label: label));
                  } else {
                    try {
                      final filename =
                          '${a.id}_${a.name.replaceAll(RegExp(r'[^\w.]'), '_')}';
                      final permanentPath =
                          await LocalStorageService.copyToAppStorage(a.localPath, filename);
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
                  await ref.read(profilesProvider.notifier).updateMilestone(
                        profileIndex,
                        Milestone(
                          id: original.id,
                          title: title,
                          description: desc,
                          date: form.date,
                          color: original.color,
                          attachments: saved,
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
                          color: Colors.primaries[existingCount % Colors.primaries.length].shade300,
                          attachments: saved,
                        ),
                      );
                }
                ref.read(backupSyncProvider.notifier).syncNow();
                return true;
              },
              onDismiss: () => Navigator.of(context).pop(),
            ),
          ],
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
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 2),
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
            _timer?.cancel();
            await _recorder.cancel();
            if (mounted) Navigator.pop(context, null);
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
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
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_saved ? Icons.check : Icons.save_outlined, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  _saved ? 'Saved!' : 'Save milestone',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
