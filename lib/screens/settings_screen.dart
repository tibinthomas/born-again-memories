import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kid_profile.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/backup_provider.dart';
import '../providers/profiles_provider.dart';
import '../providers/sharing_provider.dart';
import '../utils/chime.dart';
import '../utils/profile_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _testingSound = false;

  Future<void> _pickIcon() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
      ref.read(appSettingsProvider.notifier).update(
            ref.read(appSettingsProvider).copyWith(customIcon: result.files.first.path),
          );
    }
  }

  void _playTestSound() async {
    final settings = ref.read(appSettingsProvider);
    if (!settings.soundEnabled || _testingSound) return;
    setState(() => _testingSound = true);
    HapticFeedback.mediumImpact();
    await playChime();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _testingSound = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final sync = ref.watch(backupSyncProvider);
    final stats = ref.watch(backupStatsProvider);
    final emails = ref.watch(sharedEmailsProvider);
    final profiles = ref.watch(profilesProvider) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── App Icon ──────────────────────────────────────────────
          _label('App Icon'),
          _card([
            _iconRow(theme, settings),
          ]),

          // ── Appearance ────────────────────────────────────────────
          _label('Appearance'),
          _card([
            _colorPicker(theme, settings),
          ]),

          // ── Sound & Haptics ───────────────────────────────────────
          _label('Sound & Haptics'),
          _card([
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('Sound effects'),
              value: settings.soundEnabled,
              onChanged: (v) => ref.read(appSettingsProvider.notifier)
                  .update(settings.copyWith(soundEnabled: v)),
            ),
            if (settings.soundEnabled) ...[
              _divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.volume_down, size: 18, color: Colors.grey),
                    Expanded(
                      child: Slider(
                        value: settings.soundVolume,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        onChanged: (v) => ref.read(appSettingsProvider.notifier)
                            .update(settings.copyWith(soundVolume: v)),
                      ),
                    ),
                    const Icon(Icons.volume_up, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _testingSound ? null : _playTestSound,
                      child: Icon(
                        _testingSound ? Icons.volume_up : Icons.play_circle_outline,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
            _divider(),
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text('Haptic feedback'),
              value: settings.hapticEnabled,
              onChanged: (v) => ref.read(appSettingsProvider.notifier)
                  .update(settings.copyWith(hapticEnabled: v)),
            ),
          ]),

          // ── Drive Backup ──────────────────────────────────────────
          _label('Drive Backup'),
          _card([_backupContent(theme, sync, stats)]),

          // ── Share Memories With ───────────────────────────────────
          _label('Share Memories With'),
          _card([_sharingContent(theme, emails)]),

          // ── Profiles ──────────────────────────────────────────────
          _label('Profiles'),
          _card([_profilesContent(theme, profiles)]),

          // ── Account ───────────────────────────────────────────────
          _label('Account'),
          _card([_accountContent(theme)]),

          // ── About (bottom) ────────────────────────────────────────
          const SizedBox(height: 8),
          _aboutContent(theme),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 0, 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );

  Widget _divider() => Divider(height: 1, thickness: 1, color: Colors.grey.shade200);

  // ── Icon picker ────────────────────────────────────────────────────────────

  Widget _iconRow(ThemeData theme, settings) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                image: settings.customIcon != null && !kIsWeb
                    ? DecorationImage(
                        image: FileImage(File(settings.customIcon!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: settings.customIcon == null
                  ? Icon(Icons.child_care, size: 26, color: theme.colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                settings.customIcon != null ? 'Custom icon set' : 'Default icon',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            if (settings.customIcon != null)
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Remove',
                onPressed: () => ref.read(appSettingsProvider.notifier)
                    .update(settings.copyWith(customIcon: null)),
              ),
            TextButton(onPressed: _pickIcon, child: const Text('Change')),
          ],
        ),
      );

  // ── Color picker ───────────────────────────────────────────────────────────

  Widget _colorPicker(ThemeData theme, settings) => Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Colors.primaries.map((color) {
            final selected = settings.themeColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => ref.read(appSettingsProvider.notifier)
                  .update(settings.copyWith(themeColor: color)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? Colors.black : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: color.withAlpha(120), blurRadius: 6)]
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }).toList(),
        ),
      );

  // ── Backup ─────────────────────────────────────────────────────────────────

  Widget _backupContent(ThemeData theme, BackupSyncState sync, BackupStats stats) {
    String lastSync = 'Never';
    if (sync.lastSyncedAt != null) {
      final d = DateTime.now().difference(sync.lastSyncedAt!);
      if (d.inMinutes < 1) {
        lastSync = 'Just now';
      } else if (d.inHours < 1) {
        lastSync = '${d.inMinutes}m ago';
      } else if (d.inDays < 1) {
        lastSync = '${d.inHours}h ago';
      } else {
        lastSync = '${d.inDays}d ago';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_done_outlined,
                  color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sync.isSyncing
                      ? 'Backing up${sync.currentUploadName != null ? ': ${sync.currentUploadName}' : '…'}'
                      : stats.allDone
                          ? 'All files backed up'
                          : '${stats.backedUp} of ${stats.total} backed up',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (sync.isSyncing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (stats.total > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.backedUp / stats.total,
                minHeight: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ],
          if (stats.failed > 0) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.warning_amber, size: 13, color: Colors.orange),
              const SizedBox(width: 4),
              Text('${stats.failed} failed — tap Sync to retry',
                  style: const TextStyle(fontSize: 12, color: Colors.orange)),
            ]),
          ],
          const SizedBox(height: 10),
          if (!sync.driveAccessGranted) ...[
            Text(
              'Back up your media to Google Drive.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (sync.accessError != null) ...[
              const SizedBox(height: 4),
              Text(sync.accessError!,
                  style: const TextStyle(fontSize: 12, color: Colors.red)),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: sync.isRequestingAccess
                    ? null
                    : () => ref.read(backupSyncProvider.notifier).grantAndSync(),
                icon: sync.isRequestingAccess
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload, size: 16),
                label: Text(sync.isRequestingAccess
                    ? 'Requesting…'
                    : 'Enable Drive Backup'),
              ),
            ),
          ] else ...[
            if (sync.quota != null) ...[
              Row(children: [
                const Icon(Icons.storage, size: 13, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  'Drive: ${_fmtBytes(sync.quota!.usedBytes)}'
                  '${sync.quota!.limitBytes != null ? ' / ${_fmtBytes(sync.quota!.limitBytes!)}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: sync.quota!.isNearlyFull ? Colors.orange : Colors.grey.shade600,
                  ),
                ),
              ]),
              if (sync.quota!.limitBytes != null) ...[
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: sync.quota!.fraction.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                        sync.quota!.isNearlyFull ? Colors.orange : Colors.blue),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
            Row(children: [
              Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text('Last backup: $lastSync',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const Spacer(),
              TextButton.icon(
                onPressed: sync.isSyncing
                    ? null
                    : () => ref.read(backupSyncProvider.notifier).syncNow(),
                icon: const Icon(Icons.sync, size: 15),
                label: const Text('Sync Now'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  static String _fmtBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return mb >= 100 ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ── Sharing ────────────────────────────────────────────────────────────────

  Widget _sharingContent(ThemeData theme, List<String> emails) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (emails.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text('No one added yet.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            )
          else
            ...emails.map((email) => Column(
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const Icon(Icons.person_outline, size: 20),
                      title: Text(email, style: const TextStyle(fontSize: 13)),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            size: 20, color: Colors.red),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            ref.read(sharedEmailsProvider.notifier).remove(email),
                      ),
                    ),
                    _divider(),
                  ],
                )),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(Icons.add_circle_outline,
                size: 20, color: theme.colorScheme.primary),
            title: Text('Add Gmail address',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500)),
            onTap: () => _showAddEmailDialog(theme),
          ),
        ],
      );

  void _showAddEmailDialog(ThemeData theme) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Gmail address'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Gmail address',
            hintText: 'example@gmail.com',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final email = ctrl.text.trim().toLowerCase();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              ref.read(sharedEmailsProvider.notifier).add(email);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Profiles ───────────────────────────────────────────────────────────────

  Widget _profilesContent(ThemeData theme, profiles) {
    if (profiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No profiles yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < profiles.length; i++) ...[
          if (i > 0) _divider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildProfileAvatar(profiles[i]),
            title: Text(profiles[i].nickname ?? profiles[i].name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
              profiles[i].nickname != null && profiles[i].nickname!.isNotEmpty
                  ? '${profiles[i].name} • ${profiles[i].ageText}'
                  : profiles[i].ageText,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary, size: 20),
                  tooltip: 'Edit profile',
                  onPressed: () => _showEditProfileDialog(theme, i, profiles[i]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Delete profile',
                  onPressed: () => _confirmDeleteProfile(theme, profiles[i].name, i),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileAvatar(KidProfile profile) {
    final pTheme = ProfileTheme.forProfile(profile);
    final hasAvatar = profile.avatarImagePath != null &&
        profile.avatarImagePath!.isNotEmpty &&
        !kIsWeb &&
        File(profile.avatarImagePath!).existsSync();

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pTheme.soft,
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
                style: const TextStyle(fontSize: 18),
              ),
            ),
    );
  }

  void _showEditProfileDialog(ThemeData theme, int index, KidProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final nicknameController = TextEditingController(text: profile.nickname ?? '');
    DateTime selectedDob = profile.dateOfBirth;
    DateTime? selectedTob = profile.timeOfBirth;
    Color selectedColor = profile.color;
    Gender selectedGender = profile.gender;
    String? avatarPath = profile.avatarImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final pTheme = ProfileTheme.forGender(selectedGender);
          final hasAvatar = avatarPath != null &&
              avatarPath!.isNotEmpty &&
              !kIsWeb &&
              File(avatarPath!).existsSync();

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
                          final updated = profile.copyWith(
                            name: nameController.text.trim(),
                            nickname: nicknameController.text.trim().isEmpty ? null : nicknameController.text.trim(),
                            clearNickname: nicknameController.text.trim().isEmpty && profile.nickname != null,
                            dateOfBirth: selectedDob,
                            timeOfBirth: selectedTob,
                            clearTimeOfBirth: selectedTob == null && profile.timeOfBirth != null,
                            color: selectedColor,
                            gender: selectedGender,
                            avatarImagePath: avatarPath,
                            clearAvatar: avatarPath == null && profile.avatarImagePath != null,
                          );
                          ref.read(profilesProvider.notifier).updateProfile(index, updated);
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
                          onTap: () async {
                            if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(source: ImageSource.gallery);
                              if (file != null) {
                                setState(() => avatarPath = file.path);
                              }
                            } else if (!kIsWeb) {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: false,
                              );
                              if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
                                setState(() => avatarPath = result.files.first.path);
                              }
                            } else {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                allowMultiple: false,
                              );
                              if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
                                setState(() => avatarPath = result.files.first.path);
                              }
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
                                          image: FileImage(File(avatarPath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: hasAvatar
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
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
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
                                  selectedColor = gTheme.accent;
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
                          final picked = await showDatePicker(
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
                      Text('Theme Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: Colors.primaries.map((color) {
                          final selected = selectedColor.toARGB32() == color.toARGB32();
                          return GestureDetector(
                            onTap: () => setState(() => selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? Colors.black : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: selected
                                    ? [BoxShadow(color: color.withAlpha(120), blurRadius: 6)]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
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

  void _confirmDeleteProfile(ThemeData theme, String profileName, int index) {
    final ctrl = TextEditingController();
    bool confirmed = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete profile?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                  children: [
                    const TextSpan(text: 'This will permanently delete '),
                    TextSpan(
                      text: profileName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const TextSpan(text: ' and all their milestones. This cannot be undone.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Type the name to confirm:',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                onChanged: (v) => setState(() => confirmed = v.trim() == profileName),
                decoration: InputDecoration(
                  hintText: profileName,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: confirmed
                  ? () {
                      Navigator.pop(ctx);
                      final currentIndex = ref.read(selectedProfileIndexProvider);
                      ref.read(profilesProvider.notifier).deleteProfile(index);
                      // Adjust selection if deleted profile was selected
                      final remaining = (ref.read(profilesProvider)?.length ?? 0);
                      if (remaining > 0) {
                        ref.read(selectedProfileIndexProvider.notifier).state =
                            currentIndex.clamp(0, remaining - 1);
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete permanently'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Account ────────────────────────────────────────────────────────────────

  Widget _accountContent(ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          leading: CircleAvatar(
            radius: 20,
            backgroundImage:
                user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: user?.photoURL == null
                ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
                : null,
          ),
          title: Text(user?.displayName ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(user?.email ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
        _divider(),
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.logout, color: Colors.red, size: 20),
          title: const Text('Sign out',
              style: TextStyle(color: Colors.red, fontSize: 14)),
          onTap: () => _confirmSignOut(theme),
        ),
        _divider(),
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
          title: const Text('Delete account',
              style: TextStyle(color: Colors.red, fontSize: 14)),
          onTap: () => _confirmDeleteAccount(theme),
        ),
      ],
    );
  }

  void _confirmSignOut(ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
            },
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(ThemeData theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and all data. '
          'You will be asked to sign in again to confirm.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _reauthAndDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _reauthAndDelete() async {
    try {
      await ref.read(authServiceProvider).reauthenticateAndDelete();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'user-mismatch' => 'Account mismatch.',
        'user-not-found' => 'Account not found.',
        'invalid-credential' => 'Re-authentication failed. Try again.',
        _ => e.message ?? 'Something went wrong.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Re-authentication cancelled.')));
    }
  }

  // ── About (pinned to bottom) ───────────────────────────────────────────────

  Widget _aboutContent(ThemeData theme) => Center(
        child: Column(
          children: [
            const Icon(Icons.child_care, size: 32, color: Colors.pinkAccent),
            const SizedBox(height: 6),
            const Text('Born Again Memories',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text('Version 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text(
              'Capture and cherish your child\'s precious moments.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
}
