import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/kid_profile.dart';
import '../../../providers/profiles_provider.dart';
import '../../../utils/app_date_picker.dart';
import '../../../utils/date_formatter.dart';
import '../../../utils/image_utils.dart';
import '../../../utils/profile_theme.dart';

class AddProfileSheet extends ConsumerStatefulWidget {
  const AddProfileSheet({super.key});

  @override
  ConsumerState<AddProfileSheet> createState() => _AddProfileSheetState();
}

class _AddProfileSheetState extends ConsumerState<AddProfileSheet> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBackground() async {
    String? pickedPath;
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      pickedPath = file?.path;
    } else if (!kIsWeb) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      pickedPath = result?.files.first.path;
    }
    if (pickedPath != null) {
      final form = ref.read(addProfileFormProvider);
      final accent = ProfileTheme.forGender(form.gender).accent;
      final croppedPath = await cropImage(pickedPath, isAvatar: false, accent: accent);
      if (croppedPath == null) return;
      ref.read(addProfileFormProvider.notifier).setBackgroundImagePath(croppedPath);
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

            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showAppDatePicker(
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
              label: Text('Birthday: ${formatDate(form.dob)}',
                  style: TextStyle(color: pTheme.accent, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: pTheme.accent.withAlpha(120)),
              ),
            ),
            const SizedBox(height: 16),

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
                          style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
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
              child: const Text('Create profile',
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
