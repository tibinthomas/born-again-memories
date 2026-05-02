import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BabyMilestonesApp());
}

class BabyMilestonesApp extends StatelessWidget {
  const BabyMilestonesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baby Milestones',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: Colors.grey.shade900,
              displayColor: Colors.grey.shade900,
            ),
      ),
      home: const MilestoneHomePage(),
    );
  }
}

enum AttachmentType { image, video, audio, other }

class Attachment {
  final String name;
  final String path;
  final AttachmentType type;

  Attachment({
    required this.name,
    required this.path,
    required this.type,
  });
}

class Milestone {
  final String title;
  final String description;
  final DateTime date;
  final Color color;
  final List<Attachment> attachments;

  Milestone({
    required this.title,
    required this.description,
    required this.date,
    required this.color,
    this.attachments = const [],
  });
}

class MilestoneHomePage extends StatefulWidget {
  const MilestoneHomePage({super.key});

  @override
  State<MilestoneHomePage> createState() => _MilestoneHomePageState();
}

class _MilestoneHomePageState extends State<MilestoneHomePage> {
  final List<Milestone> _milestones = [
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
  ];

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
                                  type: _attachmentTypeFromExtension(file.extension ?? ''),
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
                          .map((attachment) => _buildAttachmentPreview(attachment))
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
                          child: Text(_formatDate(selectedDate)),
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

                      setState(() {
                        _milestones.insert(
                          0,
                          Milestone(
                            title: title,
                            description: description,
                            date: selectedDate,
                            color: Colors.primaries[_milestones.length % Colors.primaries.length].shade300,
                            attachments: selectedAttachments,
                          ),
                        );
                      });

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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  AttachmentType _attachmentTypeFromExtension(String extension) {
    final value = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(value)) return AttachmentType.image;
    if (['mp4', 'mov'].contains(value)) return AttachmentType.video;
    if (['wav', 'mp3', 'm4a', 'aac'].contains(value)) return AttachmentType.audio;
    return AttachmentType.other;
  }

  Widget _buildAttachmentPreview(Attachment attachment) {
    if (attachment.type == AttachmentType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(attachment.path),
          width: 90,
          height: 90,
          fit: BoxFit.cover,
        ),
      );
    }

    final icon = attachment.type == AttachmentType.video ? Icons.videocam : Icons.audiotrack;
    return Container(
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
          Icon(icon, size: 28, color: Colors.grey.shade700),
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
    );
  }

  Widget _buildMilestoneCard(Milestone milestone) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: milestone.color.withAlpha(46),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: milestone.color,
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  milestone.description,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(milestone.date),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (milestone.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: milestone.attachments
                        .map((attachment) => _buildAttachmentPreview(attachment))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 82,
            color: theme.colorScheme.primary.withAlpha(77),
          ),
          const SizedBox(height: 18),
          const Text(
            'No milestones yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to capture your baby’s first moments.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
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
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 26,
                            child: Icon(
                              Icons.baby_changing_station,
                              color: Colors.pinkAccent,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Baby Milestones',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'A gentle tracker for parents & tiny achievements',
                                  style: TextStyle(
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
                      const Text(
                        'Track every giggle, first step, and sleepy cuddle with a warm, playful space made for parents and little ones.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildOverviewChip('Milestones', _milestones.length.toString(), Icons.flag),
                          const SizedBox(width: 12),
                          _buildOverviewChip('Memories', 'Forever', Icons.cloud),
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
                            ? _buildEmptyState(theme)
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 24),
                                itemCount: _milestones.length,
                                itemBuilder: (context, index) {
                                  final milestone = _milestones[index];
                                  return _buildMilestoneCard(milestone);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMilestoneSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add milestone'),
      ),
    );
  }

  Widget _buildOverviewChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(46),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(77),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
