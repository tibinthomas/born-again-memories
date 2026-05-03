import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/attachment.dart';
import '../models/external_link.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../utils/attachment_helper.dart';
import '../utils/chime.dart';
import '../utils/date_formatter.dart';
import '../widgets/empty_state.dart';
import '../widgets/milestone_card.dart';
import '../widgets/overview_chip.dart';

class MilestoneHomePage extends StatefulWidget {
  const MilestoneHomePage({super.key});

  @override
  State<MilestoneHomePage> createState() => _MilestoneHomePageState();
}

class _MilestoneHomePageState extends State<MilestoneHomePage> {
  late List<KidProfile> _profiles;
  late int _selectedProfileIndex;

  @override
  void initState() {
    super.initState();
    _profiles = [
      KidProfile(
        id: 'profile_1',
        name: 'Emma',
        dateOfBirth: DateTime.now().subtract(const Duration(days: 45)),
        color: Colors.pinkAccent,
        milestones: [
          Milestone(
            title: 'First smile',
            description: 'A bright morning smile that warmed your heart.',
            date: DateTime.now().subtract(const Duration(days: 16)),
            color: Colors.amber,
          ),
          Milestone(
            title: 'First hold',
            description: 'Baby held your finger for the very first time.',
            date: DateTime.now().subtract(const Duration(days: 10)),
            color: Colors.lightBlue,
          ),
          Milestone(
            title: 'Sleepy cuddle',
            description: 'A calm evening full of soft cuddles and tiny yawns.',
            date: DateTime.now().subtract(const Duration(days: 4)),
            color: Colors.pinkAccent,
          ),
        ],
      ),
    ];
    _selectedProfileIndex = 0;
  }

  KidProfile get _currentProfile => _profiles[_selectedProfileIndex];
  List<Milestone> get _milestones => _currentProfile.milestones;

  void _updateMilestones(List<Milestone> newMilestones) {
    setState(() {
      _profiles[_selectedProfileIndex] = KidProfile(
        id: _currentProfile.id,
        name: _currentProfile.name,
        dateOfBirth: _currentProfile.dateOfBirth,
        color: _currentProfile.color,
        milestones: newMilestones,
      );
    });
  }

  void _addProfile(String name, DateTime dob, Color color) {
    setState(() {
      _profiles.add(KidProfile(
        id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        dateOfBirth: dob,
        color: color,
        milestones: [],
      ));
    });
  }

  void _deleteProfile(int index) {
    setState(() {
      _profiles.removeAt(index);
      if (_selectedProfileIndex >= _profiles.length) {
        _selectedProfileIndex = _profiles.length - 1;
      }
    });
  }

  void _showAddProfileSheet() {
    final nameController = TextEditingController();
    DateTime selectedDob = DateTime.now();
    Color selectedColor = Colors.pinkAccent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    controller: nameController,
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
                        initialDate: selectedDob,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setModalState(() => selectedDob = picked);
                    },
                    child: Text('DOB: ${formatDate(selectedDob)}'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Profile color'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: Colors.primaries.take(6).map((color) {
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = color),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: selectedColor == color ? Colors.black : Colors.transparent,
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
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your baby\'s name.')),
                        );
                        return;
                      }
                      _addProfile(name, selectedDob, selectedColor);
                      setState(() => _selectedProfileIndex = _profiles.length - 1);
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
          },
        );
      },
    );
  }

  void _showAddMilestoneSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final linkController = TextEditingController();
    final linkLabelController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final selectedAttachments = <Attachment>[];
    final selectedLinks = <ExternalLink>[];
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) {
          final theme = Theme.of(ctx);

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

          void addXFiles(List<XFile> files) {
            setSt(() {
              for (final f in files) {
                final ext = f.path.split('.').last.toLowerCase();
                selectedAttachments.add(Attachment(
                  name: f.name,
                  path: f.path,
                  type: getAttachmentTypeFromExtension(ext),
                ));
              }
            });
          }

          void addLink() {
            final raw = linkController.text.trim();
            if (raw.isEmpty) return;
            final url = raw.startsWith('http') ? raw : 'https://$raw';
            final lbl = linkLabelController.text.trim();
            setSt(() {
              selectedLinks.add(ExternalLink(url: url, label: lbl.isEmpty ? null : lbl));
              linkController.clear();
              linkLabelController.clear();
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setSt(() => selectedDate = picked);
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
                                formatDate(selectedDate),
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
                    controller: titleController,
                    decoration: inputDeco.copyWith(labelText: 'Milestone name'),
                  ),
                  const SizedBox(height: 10),

                  // Description
                  TextField(
                    controller: descController,
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
                          final f = await picker.pickImage(source: ImageSource.camera);
                          if (f != null) addXFiles([f]);
                        },
                      ),
                      const SizedBox(width: 8),
                      _MediaOptionButton(
                        icon: Icons.videocam,
                        label: 'Video',
                        color: Colors.red,
                        onTap: () async {
                          final f = await picker.pickVideo(source: ImageSource.camera);
                          if (f != null) addXFiles([f]);
                        },
                      ),
                      const SizedBox(width: 8),
                      _MediaOptionButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        color: Colors.purple,
                        onTap: () async {
                          final files = await picker.pickMultipleMedia();
                          if (files.isNotEmpty) addXFiles(files);
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
                            setSt(() {
                              for (final f in result.files.where((f) => f.path != null)) {
                                selectedAttachments.add(Attachment(
                                  name: f.name,
                                  path: f.path!,
                                  type: AttachmentType.audio,
                                ));
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  // Thumbnail strip
                  if (selectedAttachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 84,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedAttachments.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final a = selectedAttachments[i];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: a.type == AttachmentType.image
                                    ? Image.file(File(a.path),
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
                                  onTap: () => setSt(() => selectedAttachments.removeAt(i)),
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
                          controller: linkController,
                          keyboardType: TextInputType.url,
                          decoration: inputDeco.copyWith(
                            labelText: 'Link URL',
                            isDense: true,
                            prefixIcon: const Icon(Icons.link, size: 18),
                          ),
                          onSubmitted: (_) => addLink(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: linkLabelController,
                          decoration: inputDeco.copyWith(labelText: 'Label', isDense: true),
                          onSubmitted: (_) => addLink(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Add link',
                        onPressed: addLink,
                      ),
                    ],
                  ),
                  if (selectedLinks.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: selectedLinks.asMap().entries.map((e) {
                        final lbl = e.value.label?.isNotEmpty == true
                            ? e.value.label!
                            : (Uri.tryParse(e.value.url)?.host ?? e.value.url);
                        return Chip(
                          avatar: const Icon(Icons.link, size: 14),
                          label: Text(lbl, style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setSt(() => selectedLinks.removeAt(e.key)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Save ───────────────────────────────────
                  _SaveButton(
                    onSave: () {
                      final title = titleController.text.trim();
                      final desc = descController.text.trim();
                      if (title.isEmpty || desc.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please add a title and a note.')),
                        );
                        return false;
                      }
                      _updateMilestones([
                        Milestone(
                          title: title,
                          description: desc,
                          date: selectedDate,
                          color: Colors.primaries[
                                  _milestones.length % Colors.primaries.length]
                              .shade300,
                          attachments: List.from(selectedAttachments),
                          externalLinks: List.from(selectedLinks),
                        ),
                        ..._milestones,
                      ]);
                      return true;
                    },
                    onDismiss: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 26,
                            child: Icon(
                              Icons.child_care,
                              color: _currentProfile.color,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentProfile.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Age: ${_currentProfile.ageText}',
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
                      const SizedBox(height: 24),
                      if (_profiles.length > 1) ...[
                        const Text(
                          'Switch profile',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_profiles.length, (index) {
                              final profile = _profiles[index];
                              final isSelected = index == _selectedProfileIndex;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedProfileIndex = index),
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
                            value: _milestones.length.toString(),
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
                            onPressed: _showAddMilestoneSheet,
                            icon: const Icon(Icons.add_circle_outline),
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _milestones.isEmpty
                            ? EmptyState(theme: theme)
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: _milestones.length,
                                itemBuilder: (context, index) {
                                  return MilestoneCard(milestone: _milestones[index]);
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
            onPressed: _showAddProfileSheet,
            mini: true,
            tooltip: 'Add kid profile',
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: _showAddMilestoneSheet,
            icon: const Icon(Icons.add),
            label: const Text('Add milestone'),
          ),
        ],
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

class _SaveButton extends StatefulWidget {
  final bool Function() onSave;
  final VoidCallback onDismiss;

  const _SaveButton({required this.onSave, required this.onDismiss});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _saved = false;

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
        if (_saved) return;
        final ok = widget.onSave();
        if (!ok) return;
        setState(() => _saved = true);
        HapticFeedback.mediumImpact();
        unawaited(playChime());
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
          child: Row(
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
