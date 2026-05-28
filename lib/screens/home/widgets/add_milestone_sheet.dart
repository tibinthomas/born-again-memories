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
import '../../../models/attachment.dart';
import '../../../models/kid_profile.dart';
import '../../../models/milestone.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/backup_provider.dart';
import '../../../providers/milestone_form_provider.dart';
import '../../../providers/profiles_provider.dart';
import '../../../services/google_photos_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../utils/app_date_picker.dart';
import '../../../utils/attachment_helper.dart';
import '../../../utils/chime.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/milestone_templates.dart';
import '../../../utils/profile_theme.dart';
import '../../google_photos_picker.dart';
import '../../video_recorder_screen.dart';

class AddMilestoneSheet extends ConsumerStatefulWidget {
  final Milestone? initialMilestone;
  const AddMilestoneSheet({super.key, this.initialMilestone});

  @override
  ConsumerState<AddMilestoneSheet> createState() => _AddMilestoneSheetState();
}

class _AddMilestoneSheetState extends ConsumerState<AddMilestoneSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagController = TextEditingController();
  final _picker = ImagePicker();
  final _labelControllers = <String, TextEditingController>{};
  final List<Attachment> _attachments = [];
  final List<String> _tags = [];
  String? _titleError;
  String? _descError;
  Set<String> _existingAttachmentIds = {};
  bool _hasCameras = false;

  MilestoneTemplate? _selectedTemplate;
  String? _selectedCategory;
  bool _showingTemplates = true;

  bool get _isEditing => widget.initialMilestone != null;

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

  static String _extOf(PlatformFile f) {
    if (f.extension != null && f.extension!.isNotEmpty) return f.extension!.toLowerCase();
    final dot = f.name.lastIndexOf('.');
    return dot != -1 ? f.name.substring(dot + 1).toLowerCase() : '';
  }

  Future<void> _pickFromGooglePhotos() async {
    final authService = ref.read(authServiceProvider);
    final gs = authService.googleSignIn;

    final granted = await GooglePhotosService.requestScope(gs);
    if (!granted || !mounted) return;

    final selected = await GooglePhotosPicker.open(context);
    if (selected == null || selected.isEmpty || !mounted) return;

    for (int i = 0; i < selected.length; i++) {
      final item = selected[i];
      try {
        final path = await GooglePhotosService.downloadItem(gs, item);
        if (!mounted) return;
        _addAttachment(Attachment(
          id: '${DateTime.now().microsecondsSinceEpoch}_$i',
          name: item.filename.isNotEmpty
              ? item.filename
              : 'photo.${item.isVideo ? 'mp4' : 'jpg'}',
          localPath: path,
          type: item.isVideo ? AttachmentType.video : AttachmentType.image,
          sizeBytes: 0,
        ));
      } catch (_) {}
    }
  }

  Future<void> _startLiveRecording() async {
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/rec_${DateTime.now().microsecondsSinceEpoch}.m4a';
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
    final stablePath = await LocalStorageService.copyToAppStorage(filePath, 'audio_$id.m4a');
    _addAttachment(Attachment(
      id: id,
      name: 'Voice memo $label',
      localPath: stablePath,
      type: AttachmentType.audio,
      sizeBytes: 0,
    ));
    setState(() {});
  }

  Widget _buildTemplatePicker(ProfileTheme pTheme) {
    final categories = milestoneCategories;
    final activeCat = _selectedCategory ?? categories.first;
    final templates = babyMilestones.where((t) => t.category == activeCat).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D),
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

  Widget _buildForm(BuildContext context, ProfileTheme pTheme) {
    final theme = Theme.of(context);
    final form = ref.watch(addMilestoneFormProvider);

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
            GestureDetector(
              onTap: () async {
                final picked = await showAppDatePicker(
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
              if (_hasCameras)
                _MediaBtn(
                  icon: Icons.videocam_outlined,
                  label: 'Record',
                  color: Colors.red,
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    final path = await VideoRecorderScreen.open(context);
                    if (path != null && mounted) {
                      final file = File(path);
                      final ext = path.split('.').last.toLowerCase();
                      _addAttachment(Attachment(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: 'video_${DateTime.now().millisecondsSinceEpoch}.$ext',
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
                if (kIsWeb) {
                  final files = await _picker.pickMultiImage();
                  if (files.isNotEmpty) await _addXFiles(files);
                } else if (Platform.isIOS || Platform.isAndroid) {
                  final files = await _picker.pickMultipleMedia();
                  if (files.isNotEmpty) await _addXFiles(files);
                } else {
                  final result = await FilePicker.pickFiles(
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
                final result = await FilePicker.pickFiles(
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
        if (!kIsWeb && (Platform.isIOS || Platform.isAndroid) &&
            !ref.read(authServiceProvider).isAppleUser)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: _pickFromGooglePhotos,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_rounded,
                        size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Google Photos',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 128,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _attachments.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
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
                            child: a.webBytes != null ||
                                    (a.type == AttachmentType.image &&
                                        a.localExists)
                                ? attachmentImageWidget(a, width: 90, height: 90)
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

            final docsDir = await getApplicationDocumentsDirectory();
            final saved = <Attachment>[];
            for (final a in _attachments) {
              final labelText = _labelControllers[a.id]?.text.trim();
              final label = labelText?.isEmpty == true ? null : labelText;
              if (_existingAttachmentIds.contains(a.id)) {
                // Already persisted in a previous save — keep as-is.
                saved.add(a.copyWith(label: label));
              } else if (kIsWeb) {
                saved.add(a.copyWith(label: label));
              } else if (a.localPath.startsWith(docsDir.path)) {
                // Already in app persistent storage (e.g. audio copied during
                // live recording). A second copy would strip the extension from
                // names like "Voice memo 10:30 AM" → broken path, no MIME type.
                saved.add(a.copyWith(
                  label: label,
                  backupStatus: BackupStatus.queued,
                ));
              } else {
                try {
                  final src = a.localPath;
                  final dot = src.lastIndexOf('.');
                  final ext = dot != -1 ? src.substring(dot) : ''; // e.g. '.m4a'
                  final filename = '${a.id}$ext';
                  final permanentPath =
                      await LocalStorageService.copyToAppStorage(src, filename);
                  saved.add(Attachment(
                    id: a.id,
                    name: a.name,
                    label: label,
                    type: a.type,
                    sizeBytes: a.sizeBytes,
                    localPath: permanentPath,
                    backupStatus: BackupStatus.queued,
                  ));
                } catch (e) {
                  debugPrint('[AddMilestone] copy failed for "${a.name}": $e');
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
                      color: Colors.primaries[existingCount % Colors.primaries.length]
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
    final profile = profiles.isNotEmpty
        ? profiles[profileIndex.clamp(0, profiles.length - 1)]
        : null;
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

// ── Shared helpers ─────────────────────────────────────────────────────────────

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
