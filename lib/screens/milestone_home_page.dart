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
  final _picker = ImagePicker();
  // label controller per attachment id
  final _labelControllers = <String, TextEditingController>{};
  String? _titleError;
  String? _descError;

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
    final path =
        '${tempDir.path}/rec_${DateTime.now().microsecondsSinceEpoch}.m4a';
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
              onChanged: (_) { if (_titleError != null) setState(() => _titleError = null); },
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
              onChanged: (_) { if (_descError != null) setState(() => _descError = null); },
              decoration: inputDeco.copyWith(
                labelText: 'Why this moment matters *',
                errorText: _descError,
                counterText: '',
              ),
            ),
            const SizedBox(height: 18),

            // ── Media ──────────────────────────────────
            _sectionLabel('Media'),
            const SizedBox(height: 8),
            Row(
              children: [
                // Camera-only features: hidden on desktop
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

            // Attachment strip with labels
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
                                  onTap: () {
                                    setState(() => _removeAttachment(i, a.id));
                                  },
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
                              hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                              isDense: true,
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                                borderSide: BorderSide(color: theme.colorScheme.primary),
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

            // ── Save ───────────────────────────────────
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
                final milestoneId = DateTime.now().microsecondsSinceEpoch.toString();

                final saved = <Attachment>[];
                for (final a in form.attachments) {
                  final labelText = _labelControllers[a.id]?.text.trim();
                  try {
                    final filename =
                        '${a.id}_${a.name.replaceAll(RegExp(r'[^\w.]'), '_')}';
                    final permanentPath =
                        await LocalStorageService.copyToAppStorage(a.localPath, filename);
                    saved.add(Attachment(
                      id: a.id,
                      name: a.name,
                      label: labelText?.isEmpty == true ? null : labelText,
                      type: a.type,
                      sizeBytes: a.sizeBytes,
                      localPath: permanentPath,
                      backupStatus: BackupStatus.queued,
                    ));
                  } catch (_) {
                    saved.add(a.copyWith(label: labelText?.isEmpty == true ? null : labelText));
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
                        color: Colors.primaries[existingCount % Colors.primaries.length].shade300,
                        attachments: saved,
                      ),
                    );
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
                Icon(_saved ? Icons.check : Icons.save_outlined,
                    size: 18, color: Colors.white),
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
