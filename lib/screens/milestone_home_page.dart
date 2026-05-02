import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../utils/attachment_helper.dart';
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
            attachments: [],
          ),
          Milestone(
            title: 'First hold',
            description: 'Baby held your finger for the very first time.',
            date: DateTime.now().subtract(const Duration(days: 10)),
            color: Colors.lightBlue,
            attachments: [],
          ),
          Milestone(
            title: 'Sleepy cuddle',
            description: 'A calm evening full of soft cuddles and tiny yawns.',
            date: DateTime.now().subtract(const Duration(days: 4)),
            color: Colors.pinkAccent,
            attachments: [],
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
      _profiles.add(
        KidProfile(
          id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          dateOfBirth: dob,
          color: color,
          milestones: [],
        ),
      );
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                      if (picked != null) {
                        setModalState(() {
                          selectedDob = picked;
                        });
                      }
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
                        onTap: () {
                          setModalState(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: selectedColor == color
                                  ? Colors.black
                                  : Colors.transparent,
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
                          const SnackBar(
                            content: Text('Please enter your baby\'s name.'),
                          ),
                        );
                        return;
                      }
                      _addProfile(name, selectedDob, selectedColor);
                      setState(() {
                        _selectedProfileIndex = _profiles.length - 1;
                      });
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    List<Attachment> selectedAttachments = [];

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
                    'Record a new milestone',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Milestone name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Why this moment matters',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'wav', 'mp3', 'm4a', 'aac'],
                      );
                      if (result != null) {
                        setModalState(() {
                          selectedAttachments = result.files
                              .where((file) => file.path != null)
                              .map(
                                (file) => Attachment(
                                  name: file.name,
                                  path: file.path!,
                                  type: getAttachmentTypeFromExtension(file.extension ?? ''),
                                ),
                              )
                              .toList();
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add photos, videos, or audio'),
                  ),
                  if (selectedAttachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: selectedAttachments
                          .map((attachment) => Container(
                            width: 90,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  attachment.type == AttachmentType.video ? Icons.videocam : Icons.audiotrack,
                                  size: 28,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  attachment.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Text(formatDate(selectedDate)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final description = descriptionController.text.trim();

                      if (title.isEmpty || description.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please add a title and a note.'),
                          ),
                        );
                        return;
                      }

                      final updatedMilestones = [
                        Milestone(
                          title: title,
                          description: description,
                          date: selectedDate,
                          color: Colors.primaries[_milestones.length % Colors.primaries.length].shade300,
                          attachments: selectedAttachments,
                        ),
                        ..._milestones,
                      ];
                      _updateMilestones(updatedMilestones);

                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save milestone'),
                  ),
                ],
              ),
            );
          },
        );
      },
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
                                SizedBox(height: 4),
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
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_profiles.length, (index) {
                              final profile = _profiles[index];
                              final isSelected = index == _selectedProfileIndex;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedProfileIndex = index;
                                  });
                                },
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
                          OverviewChip(label: 'Milestones', value: _milestones.length.toString(), icon: Icons.flag),
                          const SizedBox(width: 12),
                          OverviewChip(label: 'Memories', value: 'Forever', icon: Icons.cloud),
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
                                  final milestone = _milestones[index];
                                  return MilestoneCard(milestone: milestone);
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
