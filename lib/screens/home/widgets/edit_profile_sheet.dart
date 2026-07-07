import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/kid_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profiles_provider.dart';
import '../../../services/drive_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../utils/app_date_picker.dart';
import '../../../utils/image_utils.dart';
import '../../../utils/profile_theme.dart';
import '../../../utils/theme_preset.dart';
import 'theme_preset_picker.dart';

/// Edit-profile bottom sheet. Avatar/background picking, cropping, and
/// Drive upload orchestration live here (as async methods on this widget's
/// state) while the picked values themselves live in [editProfileFormProvider]
/// — same split [AddProfileSheet] uses for its background picker.
class EditProfileSheet extends ConsumerStatefulWidget {
  final int profileIndex;
  final KidProfile profile;

  const EditProfileSheet({
    super.key,
    required this.profileIndex,
    required this.profile,
  });

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final _nameController = TextEditingController(text: widget.profile.name);
  late final _nicknameController =
      TextEditingController(text: widget.profile.nickname ?? '');

  KidProfile get _profile => widget.profile;
  EditProfileFormNotifier get _form =>
      ref.read(editProfileFormProvider(_profile).notifier);

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(Color accent) async {
    if (kIsWeb) {
      final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
      final fileBytes = result?.files.firstOrNull?.bytes;
      final fileName = result?.files.firstOrNull?.name;
      if (fileBytes == null || fileName == null) return;
      _form.setUploadingAvatar(true);
      try {
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
        final mime = 'image/${ext == 'jpg' ? 'jpeg' : ext}';
        final authService = ref.read(authServiceProvider);
        final url = await DriveService.uploadProfileImageBytes(
          googleSignIn: authService.googleSignIn,
          bytes: fileBytes,
          filename: 'avatar_${_profile.id}_${DateTime.now().millisecondsSinceEpoch}.$ext',
          mimeType: mime,
        );
        _form
          ..setAvatarPath(url)
          ..setUploadingAvatar(false);
      } on DriveNotAuthorizedException {
        _form.setUploadingAvatar(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Google Drive access needed. Enable Drive Backup in Settings first.'),
          ));
        }
      } catch (e) {
        _form.setUploadingAvatar(false);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
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
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: false);
      pickedPath = result?.files.firstOrNull?.path;
    }
    if (pickedPath != null) {
      final croppedPath = await cropImage(pickedPath, isAvatar: true, accent: accent);
      if (croppedPath == null) return;
      final permanent = await LocalStorageService.copyAvatarToStorage(
        croppedPath,
        'avatar_${_profile.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      final current = ref.read(editProfileFormProvider(_profile)).avatarImagePath;
      if (current != null && current != _profile.avatarImagePath) {
        LocalStorageService.delete(current);
      }
      _form.setAvatarPath(permanent);
    }
  }

  Future<void> _pickBackground(Color accent) async {
    if (kIsWeb) {
      final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
      final fileBytes = result?.files.firstOrNull?.bytes;
      final fileName = result?.files.firstOrNull?.name;
      if (fileBytes == null || fileName == null) return;
      _form.setUploadingBackground(true);
      try {
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
        final mime = 'image/${ext == 'jpg' ? 'jpeg' : ext}';
        final authService = ref.read(authServiceProvider);
        final url = await DriveService.uploadProfileImageBytes(
          googleSignIn: authService.googleSignIn,
          bytes: fileBytes,
          filename: 'bg_${_profile.id}_${DateTime.now().millisecondsSinceEpoch}.$ext',
          mimeType: mime,
        );
        _form
          ..setBackgroundPath(url)
          ..setUploadingBackground(false);
      } on DriveNotAuthorizedException {
        _form.setUploadingBackground(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Google Drive access needed. Enable Drive Backup in Settings first.'),
          ));
        }
      } catch (e) {
        _form.setUploadingBackground(false);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
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
      final result = await FilePicker.pickFiles(type: FileType.image, allowMultiple: false);
      pickedPath = result?.files.firstOrNull?.path;
    }
    if (pickedPath != null) {
      final croppedPath = await cropImage(pickedPath, isAvatar: false, accent: accent);
      if (croppedPath == null) return;
      final permanent = await LocalStorageService.copyBackgroundToStorage(
        croppedPath,
        'bg_${_profile.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      final current = ref.read(editProfileFormProvider(_profile)).backgroundImagePath;
      if (current != null && current != _profile.backgroundImagePath) {
        LocalStorageService.delete(current);
      }
      _form.setBackgroundPath(permanent);
    }
  }

  void _save(BuildContext ctx) {
    final form = ref.read(editProfileFormProvider(_profile));
    final savePreset = ThemePreset.findById(form.themePresetId)!;
    final updated = _profile.copyWith(
      name: _nameController.text.trim(),
      nickname: _nicknameController.text.trim().isEmpty ? null : _nicknameController.text.trim(),
      clearNickname:
          _nicknameController.text.trim().isEmpty && _profile.nickname != null,
      dateOfBirth: form.dob,
      timeOfBirth: form.timeOfBirth,
      clearTimeOfBirth: form.timeOfBirth == null && _profile.timeOfBirth != null,
      color: savePreset.accent,
      themePresetId: form.themePresetId,
      gender: form.gender,
      avatarImagePath: form.avatarImagePath,
      clearAvatar: form.avatarImagePath == null && _profile.avatarImagePath != null,
      backgroundImagePath: form.backgroundImagePath,
      clearBackground:
          form.backgroundImagePath == null && _profile.backgroundImagePath != null,
    );
    ref.read(profilesProvider.notifier).updateProfile(widget.profileIndex, updated);
    Navigator.pop(ctx);
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(editProfileFormProvider(_profile));
    final theme = Theme.of(context);
    final selectedPreset = ThemePreset.findById(form.themePresetId)!;
    final pTheme = ProfileTheme.fromPreset(selectedPreset);
    final avatarPath = form.avatarImagePath;
    final backgroundPath = form.backgroundImagePath;
    final hasAvatar = avatarPath != null &&
        avatarPath.isNotEmpty &&
        (avatarPath.startsWith('http') || (!kIsWeb && File(avatarPath).existsSync()));
    final hasBackground = backgroundPath != null &&
        backgroundPath.isNotEmpty &&
        (backgroundPath.startsWith('http') || (!kIsWeb && File(backgroundPath).existsSync()));

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.85,
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
                  onPressed: () => _save(context),
                  child: Text('Save',
                      style: TextStyle(color: pTheme.accent, fontWeight: FontWeight.w600)),
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
                    onTap: form.isUploadingAvatar ? null : () => _pickAvatar(pTheme.accent),
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
                                    image: avatarPath.startsWith('http')
                                        ? NetworkImage(avatarPath) as ImageProvider
                                        : FileImage(File(avatarPath)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: form.isUploadingAvatar
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
                                        ProfileTheme.forGender(form.gender).decalEmoji,
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
                            child: form.isUploadingAvatar
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
                      onPressed: () => _form.setAvatarPath(null),
                      child: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Background photo',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                    const Spacer(),
                    if (hasBackground)
                      TextButton(
                        onPressed: () => _form.setBackgroundPath(null),
                        child: Text('Remove',
                            style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: form.isUploadingBackground ? null : () => _pickBackground(pTheme.accent),
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: pTheme.soft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: pTheme.accent.withAlpha(80), width: 1.5),
                      image: hasBackground
                          ? DecorationImage(
                              image: backgroundPath.startsWith('http')
                                  ? NetworkImage(backgroundPath) as ImageProvider
                                  : FileImage(File(backgroundPath)),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withAlpha(30),
                                BlendMode.darken,
                              ),
                            )
                          : null,
                    ),
                    child: Center(
                      child: form.isUploadingBackground
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
                Text('Gender',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
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
                          onTap: () => _form.setGenderAndPreset(
                              g, ThemePreset.defaultIdForGender(g.name)),
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
                TextField(
                  controller: _nicknameController,
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
                      context: context,
                      initialDate: form.dob,
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) _form.setDob(picked);
                  },
                  icon: Icon(Icons.cake_outlined, color: pTheme.accent),
                  label: Text('Birthday: ${_formatDate(form.dob)}',
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
                      context: context,
                      initialTime: form.timeOfBirth != null
                          ? TimeOfDay.fromDateTime(form.timeOfBirth!)
                          : TimeOfDay.now(),
                    );
                    if (picked != null) {
                      final now = DateTime.now();
                      _form.setTimeOfBirth(
                          DateTime(now.year, now.month, now.day, picked.hour, picked.minute));
                    }
                  },
                  icon: Icon(Icons.access_time, color: pTheme.accent),
                  label: Text(
                    form.timeOfBirth != null
                        ? 'Birth time: ${form.timeOfBirth!.hour.toString().padLeft(2, '0')}:${form.timeOfBirth!.minute.toString().padLeft(2, '0')}'
                        : 'Add birth time (optional)',
                    style: TextStyle(color: pTheme.accent, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: pTheme.accent.withAlpha(120)),
                  ),
                ),
                if (form.timeOfBirth != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: () => _form.setTimeOfBirth(null),
                      child: const Text('Remove time',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Theme',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                const SizedBox(height: 10),
                ThemePresetPicker(
                  selectedId: form.themePresetId,
                  onSelect: (id) => _form.setThemePreset(id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
