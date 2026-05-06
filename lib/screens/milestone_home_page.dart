import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/attachment.dart';
import '../models/external_link.dart';
import '../models/milestone.dart';
import '../providers/app_settings_provider.dart';
import '../providers/backup_provider.dart';
import '../providers/milestone_form_provider.dart';
import '../providers/profiles_provider.dart';
import '../services/local_storage_service.dart';
import '../utils/attachment_helper.dart';
import '../utils/chime.dart';
import '../utils/date_formatter.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialise backup sync as soon as the home page is shown
    ref.watch(backupSyncProvider);

    final theme = Theme.of(context);
    final profilesAsync = ref.watch(profilesProvider);

    if (profilesAsync == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profiles = profilesAsync;

    if (profiles.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.child_care, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              const Text('No profiles yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Add your first kid profile to get started.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showAddProfileSheet(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Add profile'),
              ),
            ],
          ),
        ),
      );
    }

    final selectedIndex = ref.watch(selectedProfileIndexProvider);
    final safeIndex = selectedIndex.clamp(0, profiles.length - 1);
    final currentProfile = profiles[safeIndex];
    final milestones = currentProfile.milestones;

    final gradient = LinearGradient(
      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                ),
                Positioned(
                  right: -40,
                  top: 20,
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  top: 70,
                  child: Container(
                    height: 90,
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(38),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  radius: 26,
                                  child: Icon(
                                    Icons.child_care,
                                    color: currentProfile.color,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentProfile.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Age: ${currentProfile.ageText}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            ),
                            icon: const Icon(Icons.settings, color: Colors.white70),
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (profiles.length > 1) ...[
                        const Text(
                          'Switch profile',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(profiles.length, (index) {
                              final profile = profiles[index];
                              final isSelected = index == selectedIndex;
                              return GestureDetector(
                                onTap: () => ref
                                    .read(selectedProfileIndexProvider.notifier)
                                    .state = index,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withAlpha(38),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: profile.color,
                                        ),
                                        child: Center(
                                          child: Text(
                                            profile.name[0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        profile.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.grey.shade900
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Row(
                        children: [
                          OverviewChip(
                            label: 'Milestones',
                            value: milestones.length.toString(),
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
              ],
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Your precious moments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showAddMilestoneSheet(context),
                            icon: const Icon(Icons.add_circle_outline),
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: milestones.isEmpty
                            ? EmptyState(theme: theme)
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: milestones.length,
                                itemBuilder: (context, index) {
                                  return MilestoneCard(
                                    milestone: milestones[index],
                                    kidName: currentProfile.name,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _showAddProfileSheet(context),
            mini: true,
            tooltip: 'Add kid profile',
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => _showAddMilestoneSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add milestone'),
          ),
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(addProfileFormProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            height: 4,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const Text(
            'Add a new kid',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Baby\'s name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: form.dob,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                ref.read(addProfileFormProvider.notifier).setDob(picked);
              }
            },
            child: Text('DOB: ${formatDate(form.dob)}'),
          ),
          const SizedBox(height: 12),
          const Text('Profile color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: Colors.primaries.take(6).map((color) {
              return GestureDetector(
                onTap: () => ref.read(addProfileFormProvider.notifier).setColor(color),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: form.color == color ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter your baby\'s name.')),
                );
                return;
              }
              ref.read(profilesProvider.notifier).addProfile(name, form.dob, form.color);
              ref.read(selectedProfileIndexProvider.notifier).state =
                  (ref.read(profilesProvider)?.length ?? 1) - 1;
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Create profile'),
          ),
        ],
      ),
    );
  }
}

// ── Add-milestone sheet ────────────────────────────────────────────────────────

class _AddMilestoneSheet extends ConsumerStatefulWidget {
  const _AddMilestoneSheet();

  @override
  ConsumerState<_AddMilestoneSheet> createState() => _AddMilestoneSheetState();
}

class _AddMilestoneSheetState extends ConsumerState<_AddMilestoneSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _linkController = TextEditingController();
  final _linkLabelController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    _linkLabelController.dispose();
    super.dispose();
  }

  void _addXFiles(List<XFile> files) {
    for (final f in files) {
      final ext = f.path.split('.').last.toLowerCase();
      ref.read(addMilestoneFormProvider.notifier).addAttachment(Attachment(
        id: '${DateTime.now().microsecondsSinceEpoch}_${files.indexOf(f)}',
        name: f.name,
        localPath: f.path,
        type: getAttachmentTypeFromExtension(ext),
        sizeBytes: 0,
      ));
    }
  }

  void _addLink() {
    final raw = _linkController.text.trim();
    if (raw.isEmpty) return;
    final url = raw.startsWith('http') ? raw : 'https://$raw';
    final lbl = _linkLabelController.text.trim();
    ref.read(addMilestoneFormProvider.notifier).addLink(
          ExternalLink(url: url, label: lbl.isEmpty ? null : lbl),
        );
    _linkController.clear();
    _linkLabelController.clear();
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
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                const Expanded(
                  child: Text(
                    'Record a milestone',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: form.date,
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
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

            // Milestone name
            TextField(
              controller: _titleController,
              decoration: inputDeco.copyWith(labelText: 'Milestone name'),
            ),
            const SizedBox(height: 10),

            // Description
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: inputDeco.copyWith(labelText: 'Why this moment matters'),
            ),
            const SizedBox(height: 18),

            // ── Media ──────────────────────────────────
            _sectionLabel('Media'),
            const SizedBox(height: 8),
            Row(
              children: [
                _MediaOptionButton(
                  icon: Icons.camera_alt,
                  label: 'Photo',
                  color: Colors.blue,
                  onTap: () async {
                    final f = await _picker.pickImage(source: ImageSource.camera);
                    if (f != null) _addXFiles([f]);
                  },
                ),
                const SizedBox(width: 8),
                _MediaOptionButton(
                  icon: Icons.videocam,
                  label: 'Video',
                  color: Colors.red,
                  onTap: () async {
                    final f = await _picker.pickVideo(source: ImageSource.camera);
                    if (f != null) _addXFiles([f]);
                  },
                ),
                const SizedBox(width: 8),
                _MediaOptionButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () async {
                    final files = await _picker.pickMultipleMedia();
                    if (files.isNotEmpty) _addXFiles(files);
                  },
                ),
                const SizedBox(width: 8),
                _MediaOptionButton(
                  icon: Icons.audiotrack,
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
                        ref.read(addMilestoneFormProvider.notifier).addAttachment(Attachment(
                          id: DateTime.now().microsecondsSinceEpoch.toString(),
                          name: f.name,
                          localPath: f.path!,
                          type: AttachmentType.audio,
                          sizeBytes: 0,
                        ));
                      }
                    }
                  },
                ),
              ],
            ),

            // Thumbnail strip
            if (form.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: form.attachments.length,
                  separatorBuilder: (context, i) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final a = form.attachments[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: a.type == AttachmentType.image
                              ? Image.file(File(a.localPath),
                                  width: 84, height: 84, fit: BoxFit.cover)
                              : Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        a.type == AttachmentType.video
                                            ? Icons.videocam
                                            : Icons.audiotrack,
                                        size: 26,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          a.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                            onTap: () => ref
                                .read(addMilestoneFormProvider.notifier)
                                .removeAttachment(i),
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
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 18),

            // ── Links ──────────────────────────────────
            _sectionLabel('Links'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _linkController,
                    keyboardType: TextInputType.url,
                    decoration: inputDeco.copyWith(
                      labelText: 'Link URL',
                      isDense: true,
                      prefixIcon: const Icon(Icons.link, size: 18),
                    ),
                    onSubmitted: (_) => _addLink(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _linkLabelController,
                    decoration: inputDeco.copyWith(labelText: 'Label', isDense: true),
                    onSubmitted: (_) => _addLink(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add link',
                  onPressed: _addLink,
                ),
              ],
            ),
            if (form.links.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: form.links.asMap().entries.map((e) {
                  final lbl = e.value.label?.isNotEmpty == true
                      ? e.value.label!
                      : (Uri.tryParse(e.value.url)?.host ?? e.value.url);
                  return Chip(
                    avatar: const Icon(Icons.link, size: 14),
                    label: Text(lbl, style: const TextStyle(fontSize: 12)),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () =>
                        ref.read(addMilestoneFormProvider.notifier).removeLink(e.key),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // ── Save ───────────────────────────────────
            _SaveButton(
              onSave: () async {
                final title = _titleController.text.trim();
                final desc = _descController.text.trim();
                if (title.isEmpty || desc.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add a title and a note.')),
                  );
                  return false;
                }

                final profileIndex = ref.read(selectedProfileIndexProvider);
                final profile = (ref.read(profilesProvider) ?? [])[profileIndex];
                final milestoneId =
                    DateTime.now().microsecondsSinceEpoch.toString();

                // Copy each file to permanent app storage (fast — no network).
                final saved = <Attachment>[];
                for (final a in form.attachments) {
                  try {
                    final filename =
                        '${a.id}_${a.name.replaceAll(RegExp(r'[^\w.]'), '_')}';
                    final permanentPath = await LocalStorageService
                        .copyToAppStorage(a.localPath, filename);
                    saved.add(Attachment(
                      id: a.id,
                      name: a.name,
                      type: a.type,
                      sizeBytes: a.sizeBytes,
                      localPath: permanentPath,
                      backupStatus: BackupStatus.queued,
                    ));
                  } catch (_) {
                    // Keep original path if copy fails (e.g. same drive)
                    saved.add(a);
                  }
                }

                final existingCount = profile.milestones.length;
                await ref.read(profilesProvider.notifier).prependMilestone(
                      profileIndex,
                      Milestone(
                        id: milestoneId,
                        title: title,
                        description: desc,
                        date: form.date,
                        color:
                            Colors.primaries[existingCount % Colors.primaries.length]
                                .shade300,
                        attachments: saved,
                        externalLinks: List.from(form.links),
                      ),
                    );

                // Trigger background Drive backup (non-blocking)
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

// ── Private widgets ────────────────────────────────────────────────────────────

class _MediaOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOptionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(55)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends ConsumerStatefulWidget {
  final Future<bool> Function() onSave;
  final VoidCallback onDismiss;

  const _SaveButton({required this.onSave, required this.onDismiss});

  @override
  ConsumerState<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends ConsumerState<_SaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _saved = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) async {
        await _ctrl.reverse();
        if (_saved || _uploading) return;
        setState(() => _uploading = true);
        final ok = await widget.onSave();
        if (!mounted) return;
        setState(() => _uploading = false);
        if (!ok) return;
        setState(() => _saved = true);
        final settings = ref.read(appSettingsProvider);
        if (settings.hapticEnabled) HapticFeedback.mediumImpact();
        if (settings.soundEnabled) unawaited(playChime(volume: settings.soundVolume));
        await Future.delayed(const Duration(milliseconds: 700));
        widget.onDismiss();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _saved
                  ? [Colors.green.shade400, Colors.teal.shade500]
                  : [Colors.pinkAccent.shade200, Colors.deepPurple.shade400],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: (_saved ? Colors.green : Colors.pinkAccent).withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: _uploading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _saved ? Icons.check_circle_outline : Icons.favorite,
                        color: Colors.white,
                        size: 20,
                        key: ValueKey(_saved),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _saved ? 'Saved!' : 'Save milestone',
                        key: ValueKey(_saved),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
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
