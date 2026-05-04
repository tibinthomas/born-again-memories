import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
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
