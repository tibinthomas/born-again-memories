import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/backup_provider.dart';
import '../utils/chime.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionHeader('App Icon'),
          const SizedBox(height: 12),
          _iconPickerTile(theme, settings),
          const SizedBox(height: 32),

          _sectionHeader('Sound'),
          const SizedBox(height: 12),
          _soundTile(theme, settings),
          const SizedBox(height: 32),

          _sectionHeader('Appearance'),
          const SizedBox(height: 12),
          _appearanceTile(theme, settings),
          const SizedBox(height: 32),

          _sectionHeader('Haptics'),
          const SizedBox(height: 12),
          _hapticsTile(theme, settings),
          const SizedBox(height: 32),

          _sectionHeader('About'),
          const SizedBox(height: 12),
          _aboutTile(theme),
          const SizedBox(height: 32),

          _sectionHeader('Drive Backup'),
          const SizedBox(height: 12),
          _backupTile(theme),
          const SizedBox(height: 32),

          _sectionHeader('Account'),
          const SizedBox(height: 12),
          _accountTile(theme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.0,
        ),
      );

  Widget _iconPickerTile(ThemeData theme, settings) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                    image: settings.customIcon != null
                        ? DecorationImage(
                            image: FileImage(File(settings.customIcon!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: settings.customIcon == null
                      ? Icon(Icons.child_care, size: 28, color: theme.colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.customIcon != null ? 'Custom icon set' : 'Default icon',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to change app icon',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _pickIcon,
                  icon: const Icon(Icons.image),
                  tooltip: 'Choose icon',
                ),
                if (settings.customIcon != null)
                  IconButton(
                    onPressed: () => ref.read(appSettingsProvider.notifier).update(
                          settings.copyWith(customIcon: null),
                        ),
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove',
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _soundTile(ThemeData theme, settings) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sound effects'),
              subtitle: Text(settings.soundEnabled ? 'On' : 'Off'),
              value: settings.soundEnabled,
              onChanged: (v) => ref.read(appSettingsProvider.notifier).update(
                    settings.copyWith(soundEnabled: v),
                  ),
            ),
            if (settings.soundEnabled) ...[
              const Divider(),
              Row(
                children: [
                  const Text('Volume'),
                  const Spacer(),
                  Text('${(settings.soundVolume * 100).round()}%'),
                ],
              ),
              Slider(
                value: settings.soundVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (v) => ref.read(appSettingsProvider.notifier).update(
                      settings.copyWith(soundVolume: v),
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _testingSound ? null : _playTestSound,
                  icon: Icon(_testingSound ? Icons.volume_up : Icons.play_arrow),
                  label: Text(_testingSound ? 'Playing...' : 'Test sound'),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _appearanceTile(ThemeData theme, settings) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Theme color'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: Colors.primaries.map((color) {
                final isSelected = settings.themeColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () => ref.read(appSettingsProvider.notifier).update(
                        settings.copyWith(themeColor: color),
                      ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withAlpha(128), blurRadius: 8)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _hapticsTile(ThemeData theme, settings) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Haptic feedback'),
          subtitle: Text(settings.hapticEnabled ? 'On' : 'Off'),
          value: settings.hapticEnabled,
          onChanged: (v) => ref.read(appSettingsProvider.notifier).update(
                settings.copyWith(hapticEnabled: v),
              ),
        ),
      );

  Widget _backupTile(ThemeData theme) {
    final sync = ref.watch(backupSyncProvider);
    final stats = ref.watch(backupStatsProvider);

    String lastSyncText = 'Never';
    if (sync.lastSyncedAt != null) {
      final diff = DateTime.now().difference(sync.lastSyncedAt!);
      if (diff.inMinutes < 1) {
        lastSyncText = 'Just now';
      } else if (diff.inHours < 1) {
        lastSyncText = '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        lastSyncText = '${diff.inHours}h ago';
      } else {
        lastSyncText = '${diff.inDays}d ago';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sync.quota?.isNearlyFull == true
              ? Colors.orange.shade300
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.cloud_done_outlined,
                  color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sync.isSyncing
                      ? 'Backing up${sync.currentUploadName != null ? ': ${sync.currentUploadName}' : '…'}'
                      : stats.allDone
                          ? 'All files backed up'
                          : '${stats.backedUp} of ${stats.total} files backed up',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              if (sync.isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),

          // Attachment progress bar
          if (stats.total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.total > 0 ? stats.backedUp / stats.total : 0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ],

          // Failed warning
          if (stats.failed > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                '${stats.failed} file${stats.failed > 1 ? 's' : ''} failed — tap Sync to retry',
                style:
                    const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ]),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Drive quota
          if (!sync.driveAccessGranted) ...[
            const Text(
              'Back up your photos, videos and audio to your own Google Drive.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (sync.accessError != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(sync.accessError!,
                      style: const TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ]),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: sync.isRequestingAccess
                    ? null
                    : () => ref.read(backupSyncProvider.notifier).grantAndSync(),
                icon: sync.isRequestingAccess
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload, size: 18),
                label: Text(sync.isRequestingAccess
                    ? 'Requesting access…'
                    : 'Enable Drive Backup'),
              ),
            ),
          ] else ...[
            if (sync.quota != null) ...[
              Row(
                children: [
                  const Icon(Icons.storage, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Google Drive: ${_fmtBytes(sync.quota!.usedBytes)}'
                    '${sync.quota!.limitBytes != null ? ' of ${_fmtBytes(sync.quota!.limitBytes!)}' : ' used'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: sync.quota!.isNearlyFull
                          ? Colors.orange
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (sync.quota!.limitBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: sync.quota!.fraction.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      sync.quota!.isNearlyFull ? Colors.orange : Colors.blue,
                    ),
                  ),
                ),
              if (sync.quota!.isNearlyFull) ...[
                const SizedBox(height: 6),
                const Text(
                  'Your Google Drive is almost full. Free up space to continue backups.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.schedule, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Last backup: $lastSyncText',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: sync.isSyncing
                      ? null
                      : () => ref
                          .read(backupSyncProvider.notifier)
                          .syncNow(),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync Now'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return mb >= 100
          ? '${mb.round()} MB'
          : '${mb.toStringAsFixed(1)} MB';
    }
    final gb = bytes / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(1)} GB';
  }

  Widget _accountTile(ThemeData theme) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: user?.photoURL != null
                    ? NetworkImage(user!.photoURL!)
                    : null,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: user?.photoURL == null
                    ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(theme),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _confirmDeleteAccount(theme),
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Delete account', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
          'This will permanently delete your account and all associated data. '
          'You will be asked to sign in again to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
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
        'user-mismatch' => 'Account mismatch. Please sign in with the correct Google account.',
        'user-not-found' => 'Account not found.',
        'invalid-credential' => 'Re-authentication failed. Please try again.',
        _ => e.message ?? 'Something went wrong. Please try again.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Re-authentication cancelled.')),
      );
    }
  }

  Widget _aboutTile(ThemeData theme) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.child_care, size: 28, color: Colors.pinkAccent),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Born Again Memories',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Capture and cherish your child\'s precious moments.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
}
