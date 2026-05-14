import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kid_profile.dart';
import '../models/share_invite.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/backup_provider.dart';
import '../providers/profiles_provider.dart';
import '../providers/sharing_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/backup_permissions_service.dart';
import '../services/drive_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../utils/chime.dart';
import '../utils/profile_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _testingSound = false;
  bool _shownPermSheet = false;

  // ── Accent from current profile ────────────────────────────────────────────

  ProfileTheme _profileTheme() {
    final profiles = ref.read(profilesProvider) ?? [];
    if (profiles.isEmpty) return ProfileTheme.forGender(Gender.neutral);
    final idx = ref.read(selectedProfileIndexProvider)
        .clamp(0, profiles.length - 1);
    return ProfileTheme.forProfile(profiles[idx]);
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

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

  void _showBackupPermissionsSheet(BuildContext context, Color accent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BackupPermissionsSheet(accent: accent),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final sync = ref.watch(backupSyncProvider);
    final stats = ref.watch(backupStatsProvider);
    final emails = ref.watch(sharedEmailsProvider);
    final profiles = ref.watch(profilesProvider) ?? [];

    final pTheme = _profileTheme();
    final accent = pTheme.accent;
    final secondary = pTheme.secondary;

    ref.listen<BackupSyncState>(backupSyncProvider, (prev, curr) {
      if (!_shownPermSheet &&
          !(prev?.driveAccessGranted ?? false) &&
          curr.driveAccessGranted &&
          !kIsWeb) {
        _shownPermSheet = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showBackupPermissionsSheet(context, accent);
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Minimal header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: const Color(0xFF1A1A2E),
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                children: [
                  // Account
                  _AccountCard(accent: accent, secondary: secondary,
                      onSignOut: () => _confirmSignOut(accent),
                  ),
                  const SizedBox(height: 22),

                  // Share Memories
                  _sectionLabel('Share Memories'),
                  _ShareCard(
                    accent: accent,
                    invites: emails,
                    onAdd: () => _showAddEmailDialog(accent),
                    onRemove: (e) => _confirmRemoveEmail(accent, e),
                    onResend: (e) => ref.read(sharedEmailsProvider.notifier).resend(e),
                  ),
                  const SizedBox(height: 22),

                  // Backup
                  _sectionLabel('Backup'),
                  _BackupCard(
                    accent: accent,
                    sync: sync,
                    stats: stats,
                    onGrantAndSync: () => ref.read(backupSyncProvider.notifier).grantAndSync(),
                    onSyncNow: () => ref.read(backupSyncProvider.notifier).syncNow(),
                  ),
                  const SizedBox(height: 22),

                  // Preferences
                  _sectionLabel('Preferences'),
                  _PreferencesCard(
                    accent: accent,
                    settings: settings,
                    testingSound: _testingSound,
                    onSoundChanged: (v) => ref.read(appSettingsProvider.notifier)
                        .update(settings.copyWith(soundEnabled: v)),
                    onVolumeChanged: (v) => ref.read(appSettingsProvider.notifier)
                        .update(settings.copyWith(soundVolume: v)),
                    onHapticChanged: (v) => ref.read(appSettingsProvider.notifier)
                        .update(settings.copyWith(hapticEnabled: v)),
                    onAnimationsChanged: (v) => ref.read(appSettingsProvider.notifier)
                        .update(settings.copyWith(animationsEnabled: v)),
                    onTestSound: _playTestSound,
                  ),
                  const SizedBox(height: 22),

                  // More (App Icon + Profiles — collapsible)
                  _MoreSection(
                    accent: accent,
                    settings: settings,
                    profiles: profiles,
                    onPickIcon: _pickIcon,
                    onClearIcon: () => ref.read(appSettingsProvider.notifier)
                        .update(settings.copyWith(customIcon: null)),
                    onDeleteProfile: (name, i) =>
                        _confirmDeleteProfile(accent, name, i),
                  ),
                  const SizedBox(height: 22),

                  // Danger zone
                  _DangerCard(
                    onDeleteAccount: () => _confirmDeleteAccount(accent),
                  ),
                  const SizedBox(height: 28),

                  // About
                  _About(accent: accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.2,
          ),
        ),
      );

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _confirmRemoveEmail(Color accent, String email) {
    final ctrl = TextEditingController();
    bool confirmed = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Remove sharing?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'They will no longer be able to see your shared memories.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text(
                'Type the Gmail address to confirm:',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) =>
                    setState(() => confirmed = v.trim().toLowerCase() == email),
                decoration: InputDecoration(
                  hintText: email,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: confirmed
                  ? () {
                      Navigator.pop(ctx);
                      ref.read(sharedEmailsProvider.notifier).remove(email);
                    }
                  : null,
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEmailDialog(Color accent) {
    final ctrl = TextEditingController();
    final existingEmails =
        ref.read(sharedEmailsProvider).map((i) => i.email).toSet();

    // phase: 'form' | 'checking' | 'notFound'
    var phase = 'form';
    String? pendingEmail;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          // ── Not found — invite screen ──────────────────────────────────────
          if (phase == 'notFound') {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Not on the app yet'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pendingEmail!} hasn\'t joined Born Again Memories yet.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can add them now — they\'ll see your memories the moment they sign up with this email.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(sharedEmailsProvider.notifier).add(pendingEmail!);
                  },
                  child: const Text('Add anyway'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(sharedEmailsProvider.notifier).add(pendingEmail!);
                    _shareAppInvite(pendingEmail!);
                  },
                  child: const Text('Add & Invite'),
                ),
              ],
            );
          }

          // ── Email input form ───────────────────────────────────────────────
          final raw = ctrl.text.trim().toLowerCase();
          final String? error = _validateShareEmail(raw, existingEmails);
          final bool canAdd =
              raw.isNotEmpty && error == null && phase == 'form';

          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Share with'),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              onChanged: (_) => setDlgState(() {}),
              decoration: InputDecoration(
                labelText: 'Gmail address',
                hintText: 'example@gmail.com',
                errorText: raw.isEmpty ? null : error,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.red.shade400, width: 1.5),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: canAdd
                    ? () async {
                        setDlgState(() => phase = 'checking');
                        final registered =
                            await FirestoreService.isEmailRegistered(raw);
                        if (!ctx.mounted) return;
                        if (registered) {
                          Navigator.pop(ctx);
                          ref
                              .read(sharedEmailsProvider.notifier)
                              .add(raw);
                        } else {
                          pendingEmail = raw;
                          setDlgState(() => phase = 'notFound');
                        }
                      }
                    : null,
                child: phase == 'checking'
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add'),
              ),
            ],
          );
        },
      ),
    ).then((_) => ctrl.dispose());
  }

  void _shareAppInvite(String toEmail) {
    const playStore =
        'https://play.google.com/store/apps/details?id=com.tibinthomas.born_again_memories';
    const appStore =
        'https://apps.apple.com/app/born-again-memories/id000000000';
    final text =
        'Hey! I\'m using Born Again Memories to capture our little one\'s milestones. 📸👶\n\n'
        'Download the app and I\'ll share our memories with you!\n\n'
        '📱 iOS: $appStore\n'
        '🤖 Android: $playStore';
    SharePlus.instance.share(ShareParams(text: text));
  }

  static String? _validateShareEmail(String email, Set<String> existing) {
    if (email.isEmpty) return null;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';
    if (!email.endsWith('@gmail.com')) return 'Only Gmail addresses are supported';
    if (existing.contains(email)) return 'Already added';
    return null;
  }

  void _confirmDeleteProfile(Color accent, String profileName, int index) {
    final profiles = ref.read(profilesProvider) ?? [];
    final targetProfile = profiles.length > index ? profiles[index] : null;
    final displayName = targetProfile?.nickname ?? profileName;
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
              // Profile list — target highlighted in red
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: profiles.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    final isTarget = i == index;
                    final pTheme = ProfileTheme.forProfile(p);
                    final hasAvatar = p.avatarImagePath != null &&
                        p.avatarImagePath!.isNotEmpty &&
                        !kIsWeb &&
                        File(p.avatarImagePath!).existsSync();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (i > 0)
                          Divider(height: 1, color: Colors.grey.shade200),
                        Container(
                          color: isTarget ? Colors.red.shade50 : null,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isTarget
                                      ? Colors.red.shade100
                                      : pTheme.soft,
                                  image: (!isTarget && hasAvatar)
                                      ? DecorationImage(
                                          image: FileImage(
                                              File(p.avatarImagePath!)),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: (!isTarget && hasAvatar)
                                    ? null
                                    : Center(
                                        child: isTarget
                                            ? Icon(Icons.delete_outline_rounded,
                                                size: 15,
                                                color: Colors.red.shade400)
                                            : Text(pTheme.decalEmoji,
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.nickname ?? p.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isTarget
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isTarget
                                        ? Colors.red.shade600
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              if (isTarget)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Will be deleted',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade500),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'All milestones and memories for $displayName will be permanently removed.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 14),
              Text('Type "$profileName" to confirm:',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => confirmed = v.trim() == profileName),
                decoration: InputDecoration(
                  hintText: profileName,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: confirmed
                  ? () {
                      Navigator.pop(ctx);
                      final currentIndex = ref.read(selectedProfileIndexProvider);
                      ref.read(profilesProvider.notifier).deleteProfile(index);
                      final remaining = ref.read(profilesProvider)?.length ?? 0;
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

  void _confirmSignOut(Color accent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(Color accent) {
    final driveActive =
        ref.read(backupSyncProvider).driveAccessGranted;

    if (driveActive) {
      _showDriveBackupChoiceDialog(accent);
    } else {
      _showFinalDeleteDialog(deleteDriveBackup: false);
    }
  }

  void _showDriveBackupChoiceDialog(Color accent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Your Google Drive backup'),
        content: const Text(
          'You have a Drive backup of your memories. '
          'What would you like to do with it when your account is deleted?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showFinalDeleteDialog(deleteDriveBackup: false);
            },
            child: const Text('Keep backup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showFinalDeleteDialog(deleteDriveBackup: true);
            },
            child: const Text(
              'Delete backup',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteDialog({required bool deleteDriveBackup}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deleteDriveBackup
                    ? 'Your account and Google Drive backup will be deleted. '
                        'Your memories are kept for 28 days in case you change your mind — '
                        'but without the Drive files.'
                    : 'Your account will be scheduled for deletion. '
                        'Your memories are kept for 28 days — sign back in to recover them. '
                        'Your Google Drive backup will be kept.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Type "delete" to confirm',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                autofocus: true,
                onChanged: (_) => setDlgState(() {}),
                decoration: const InputDecoration(
                  hintText: 'delete',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: controller.text.trim().toLowerCase() == 'delete'
                  ? () async {
                      Navigator.pop(ctx);
                      await _reauthAndDelete(
                          deleteDriveBackup: deleteDriveBackup);
                    }
                  : null,
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  Future<void> _reauthAndDelete({bool deleteDriveBackup = false}) async {
    try {
      if (deleteDriveBackup) {
        final gs = ref.read(authServiceProvider).googleSignIn;
        await DriveService.deleteAllBackups(gs);
      }
      await ref
          .read(authServiceProvider)
          .softDeleteAccount(deleteDriveBackup: deleteDriveBackup);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Re-authentication cancelled.')));
    }
  }

  static String _fmtBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return mb >= 100 ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

Widget _divider() =>
    Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100);

// ── Account card ──────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final Color accent;
  final Color secondary;
  final VoidCallback onSignOut;

  const _AccountCard({
    required this.accent,
    required this.secondary,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return _Card(children: [
      // Gradient top strip
      Container(
        height: 4,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, secondary]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              backgroundColor: Color.lerp(Colors.white, accent, 0.15),
              child: user?.photoURL == null
                  ? Icon(Icons.person_rounded, color: accent, size: 26)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Unknown',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onSignOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text(
                  'Sign out',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}

// ── Share card ────────────────────────────────────────────────────────────────

class _ShareCard extends StatelessWidget {
  final Color accent;
  final List<ShareInvite> invites;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onResend;

  const _ShareCard({
    required this.accent,
    required this.invites,
    required this.onAdd,
    required this.onRemove,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(children: [
      if (invites.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text('Not shared with anyone yet.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        )
      else
        ...invites.map((invite) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InviteRow(
                  invite: invite,
                  accent: accent,
                  onRemove: () => onRemove(invite.email),
                  onResend: () => onResend(invite.email),
                ),
                _divider(),
              ],
            )),
      // Add button
      GestureDetector(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18, color: accent),
              const SizedBox(width: 10),
              Text(
                'Add Gmail address',
                style: TextStyle(
                    fontSize: 13, color: accent, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _InviteRow extends StatelessWidget {
  final ShareInvite invite;
  final Color accent;
  final VoidCallback onRemove;
  final VoidCallback onResend;

  const _InviteRow({
    required this.invite,
    required this.accent,
    required this.onRemove,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeBg, badgeIcon, badgeLabel) = switch (invite.status) {
      ShareInviteStatus.active => (
          const Color(0xFF27AE60),
          const Color(0xFFEAF7EF),
          Icons.check_circle_rounded,
          'Active',
        ),
      ShareInviteStatus.pending => (
          const Color(0xFFE67E22),
          const Color(0xFFFEF3E2),
          Icons.schedule_rounded,
          'Pending',
        ),
      ShareInviteStatus.expired => (
          Colors.red.shade400,
          Colors.red.shade50,
          Icons.error_outline_rounded,
          'Expired',
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar initial
              CircleAvatar(
                radius: 16,
                backgroundColor: Color.lerp(Colors.white, accent, 0.14),
                child: Text(
                  invite.email[0].toUpperCase(),
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: accent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.email,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(badgeIcon, size: 11, color: badgeColor),
                              const SizedBox(width: 3),
                              Text(
                                badgeLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: badgeColor),
                              ),
                            ],
                          ),
                        ),
                        if (invite.isActive) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Viewing your memories',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ] else if (invite.isPending) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Waiting for them to sign up',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              if (invite.isExpired)
                GestureDetector(
                  onTap: onResend,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Color.lerp(Colors.white, accent, 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withAlpha(60)),
                    ),
                    child: Text(
                      'Resend',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accent),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.remove_circle_outline_rounded,
                    size: 20, color: Colors.grey.shade400),
              ),
            ],
          ),
          // Expired explanation
          if (invite.isExpired) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 14, color: Colors.red.shade300),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'This invite expired after 30 days. Tap Resend to refresh it.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade400,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Backup card ───────────────────────────────────────────────────────────────

class _BackupCard extends StatelessWidget {
  final Color accent;
  final BackupSyncState sync;
  final BackupStats stats;
  final VoidCallback onGrantAndSync;
  final VoidCallback onSyncNow;

  const _BackupCard({
    required this.accent,
    required this.sync,
    required this.stats,
    required this.onGrantAndSync,
    required this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    String lastSync = 'Never';
    if (sync.lastSyncedAt != null) {
      final d = DateTime.now().difference(sync.lastSyncedAt!);
      if (d.inMinutes < 1) lastSync = 'Just now';
      else if (d.inHours < 1) lastSync = '${d.inMinutes}m ago';
      else if (d.inDays < 1) lastSync = '${d.inHours}h ago';
      else lastSync = '${d.inDays}d ago';
    }

    return _Card(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color.lerp(Colors.white, accent, 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    sync.driveAccessGranted
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_upload_outlined,
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sync.isSyncing
                            ? 'Backing up…'
                            : sync.driveAccessGranted
                                ? (stats.allDone ? 'All backed up' : '${stats.backedUp} of ${stats.total} files')
                                : 'Google Drive',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A2E)),
                      ),
                      if (sync.driveAccessGranted)
                        Text(
                          'Last backup: $lastSync',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
                if (sync.driveAccessGranted)
                  GestureDetector(
                    onTap: sync.isSyncing ? null : onSyncNow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color.lerp(Colors.white, accent, 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent.withAlpha(60)),
                      ),
                      child: sync.isSyncing
                          ? SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: accent))
                          : Text(
                              'Sync',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                            ),
                    ),
                  ),
              ],
            ),
            if (sync.driveAccessGranted && stats.total > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stats.backedUp / stats.total,
                  minHeight: 4,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation(accent),
                ),
              ),
            ],
            if (sync.driveAccessGranted) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 13, color: Colors.amber.shade700),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Files are stored in "⚠️ Born Again Memories — App Data (Do Not Delete)" in your Google Drive. Do not rename or delete this folder — doing so will break backup and may cause data loss.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade800, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
            if (!sync.driveAccessGranted) ...[
              const SizedBox(height: 12),
              Text(
                'Back up photos and videos to Google Drive.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (sync.accessError != null) ...[
                const SizedBox(height: 4),
                Text(sync.accessError!,
                    style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: sync.isRequestingAccess ? null : onGrantAndSync,
                  icon: sync.isRequestingAccess
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload, size: 16),
                  label: Text(sync.isRequestingAccess ? 'Requesting…' : 'Enable Drive Backup'),
                ),
              ),
            ],
            if (sync.driveAccessGranted && sync.quota != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.storage_rounded, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  '${_SettingsScreenState._fmtBytes(sync.quota!.usedBytes)}'
                  '${sync.quota!.limitBytes != null ? ' / ${_SettingsScreenState._fmtBytes(sync.quota!.limitBytes!)}' : ''} used',
                  style: TextStyle(
                    fontSize: 11,
                    color: sync.quota!.isNearlyFull ? Colors.orange : Colors.grey.shade400,
                  ),
                ),
              ]),
            ],
            if (sync.syncError != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline_rounded, size: 13, color: Colors.red.shade500),
                        const SizedBox(width: 5),
                        Text(
                          '${stats.failed > 0 ? "${stats.failed} file${stats.failed == 1 ? "" : "s"} failed — " : ""}Backup error',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      sync.syncError!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (stats.failed > 0) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${stats.failed} failed — tap Sync to retry',
                    style: const TextStyle(fontSize: 11, color: Colors.orange)),
              ]),
            ],
            if (sync.driveAccessGranted && !kIsWeb)
              _BackupPermissionTips(accent: accent),
          ],
        ),
      ),
    ]);
  }
}

// ── Preferences card ──────────────────────────────────────────────────────────

class _PreferencesCard extends StatelessWidget {
  final Color accent;
  final dynamic settings;
  final bool testingSound;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<bool> onHapticChanged;
  final ValueChanged<bool> onAnimationsChanged;
  final VoidCallback onTestSound;

  const _PreferencesCard({
    required this.accent,
    required this.settings,
    required this.testingSound,
    required this.onSoundChanged,
    required this.onVolumeChanged,
    required this.onHapticChanged,
    required this.onAnimationsChanged,
    required this.onTestSound,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(children: [
      // Sound toggle
      _PrefRow(
        icon: Icons.music_note_rounded,
        accent: accent,
        label: 'Sound effects',
        trailing: Switch.adaptive(
          value: settings.soundEnabled,
          onChanged: onSoundChanged,
          activeColor: accent,
        ),
      ),
      if (settings.soundEnabled) ...[
        _divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
          child: Row(
            children: [
              Icon(Icons.volume_down_rounded, size: 16, color: Colors.grey.shade400),
              Expanded(
                child: Slider(
                  value: settings.soundVolume,
                  min: 0, max: 1, divisions: 10,
                  activeColor: accent,
                  onChanged: onVolumeChanged,
                ),
              ),
              Icon(Icons.volume_up_rounded, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: testingSound ? null : onTestSound,
                child: Icon(
                  testingSound ? Icons.volume_up_rounded : Icons.play_circle_outline_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ],
      _divider(),
      // Haptic toggle
      _PrefRow(
        icon: Icons.vibration_rounded,
        accent: accent,
        label: 'Haptic feedback',
        trailing: Switch.adaptive(
          value: settings.hapticEnabled,
          onChanged: onHapticChanged,
          activeColor: accent,
        ),
      ),
      _divider(),
      // Animations toggle
      _PrefRow(
        icon: Icons.animation_rounded,
        accent: accent,
        label: 'Animations & bubbles',
        trailing: Switch.adaptive(
          value: settings.animationsEnabled,
          onChanged: onAnimationsChanged,
          activeColor: accent,
        ),
      ),
    ]);
  }
}

class _PrefRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String label;
  final Widget trailing;

  const _PrefRow({
    required this.icon,
    required this.accent,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color.lerp(Colors.white, accent, 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E))),
          ),
          trailing,
        ],
      ),
    );
  }
}

// ── More section (collapsible) ────────────────────────────────────────────────

class _MoreSection extends StatefulWidget {
  final Color accent;
  final dynamic settings;
  final List<KidProfile> profiles;
  final VoidCallback onPickIcon;
  final VoidCallback onClearIcon;
  final void Function(String name, int index) onDeleteProfile;

  const _MoreSection({
    required this.accent,
    required this.settings,
    required this.profiles,
    required this.onPickIcon,
    required this.onClearIcon,
    required this.onDeleteProfile,
  });

  @override
  State<_MoreSection> createState() => _MoreSectionState();
}

class _MoreSectionState extends State<_MoreSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle button
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Text(
                  'More options',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),

        // Expandable content
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: _expanded
              ? _Card(children: [
                  // App icon
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color.lerp(Colors.white, widget.accent, 0.12),
                            borderRadius: BorderRadius.circular(10),
                            image: widget.settings.customIcon != null && !kIsWeb
                                ? DecorationImage(
                                    image: FileImage(File(widget.settings.customIcon!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: widget.settings.customIcon == null
                              ? Icon(Icons.child_care_rounded,
                                  size: 20, color: widget.accent)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.settings.customIcon != null
                                ? 'Custom app icon'
                                : 'App icon',
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF1A1A2E)),
                          ),
                        ),
                        if (widget.settings.customIcon != null)
                          GestureDetector(
                            onTap: widget.onClearIcon,
                            child: Icon(Icons.close_rounded,
                                size: 18, color: Colors.grey.shade400),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onPickIcon,
                          child: Text(
                            'Change',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: widget.accent),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profiles list (delete only)
                  if (widget.profiles.isNotEmpty) ...[
                    _divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Text('Profiles',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade400,
                              letterSpacing: 0.3)),
                    ),
                    ...widget.profiles.asMap().entries.map((entry) {
                      final i = entry.key;
                      final p = entry.value;
                      final pTheme = ProfileTheme.forProfile(p);
                      final hasAvatar = p.avatarImagePath != null &&
                          p.avatarImagePath!.isNotEmpty &&
                          !kIsWeb &&
                          File(p.avatarImagePath!).existsSync();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: pTheme.soft,
                                    image: hasAvatar
                                        ? DecorationImage(
                                            image: FileImage(File(p.avatarImagePath!)),
                                            fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: hasAvatar
                                      ? null
                                      : Center(
                                          child: Text(pTheme.decalEmoji,
                                              style: const TextStyle(fontSize: 14))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(p.nickname ?? p.name,
                                      style: const TextStyle(
                                          fontSize: 13, color: Color(0xFF1A1A2E))),
                                ),
                                GestureDetector(
                                  onTap: () => widget.onDeleteProfile(p.name, i),
                                  child: Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Colors.red.shade300),
                                ),
                              ],
                            ),
                          ),
                          if (i < widget.profiles.length - 1) _divider(),
                        ],
                      );
                    }),
                    const SizedBox(height: 6),
                  ],
                ])
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Danger card ───────────────────────────────────────────────────────────────

class _DangerCard extends StatelessWidget {
  final VoidCallback onDeleteAccount;

  const _DangerCard({required this.onDeleteAccount});

  @override
  Widget build(BuildContext context) {
    return _Card(children: [
      GestureDetector(
        onTap: onDeleteAccount,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.delete_forever_rounded, size: 18, color: Colors.red.shade400),
              const SizedBox(width: 12),
              Text(
                'Delete account',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

// ── About ─────────────────────────────────────────────────────────────────────

class _About extends StatelessWidget {
  final Color accent;
  const _About({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(Colors.white, accent, 0.12),
            ),
            child: Icon(Icons.child_care_rounded, size: 22, color: accent),
          ),
          const SizedBox(height: 8),
          const Text('Born Again Memories',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 2),
          Text('Version 1.0.0',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          const SizedBox(height: 4),
          Text(
            'Cherish every precious moment.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ── Backup permission tips (inline in backup card) ────────────────────────────

class _BackupPermissionTips extends StatefulWidget {
  final Color accent;
  const _BackupPermissionTips({required this.accent});

  @override
  State<_BackupPermissionTips> createState() => _BackupPermissionTipsState();
}

class _BackupPermissionTipsState extends State<_BackupPermissionTips> {
  BackupPermissionsStatus? _status;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final s = await BackupPermissionsService.check();
    if (mounted) setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (s == null || (!s.needsAction && s.backgroundRefresh)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 0.5),
        const SizedBox(height: 10),
        if (!s.notifications)
          _PermTipRow(
            icon: Icons.notifications_off_outlined,
            label: 'Allow notifications for backup alerts',
            actionLabel: 'Allow',
            accent: widget.accent,
            onAction: () async {
              await BackupPermissionsService.requestNotifications();
              _check();
            },
          ),
        if (!kIsWeb && Platform.isAndroid && !s.batteryExempt) ...[
          if (!s.notifications) const SizedBox(height: 6),
          _PermTipRow(
            icon: Icons.battery_saver_outlined,
            label: 'Exempt app from battery optimization',
            actionLabel: 'Exempt',
            accent: widget.accent,
            onAction: () async {
              await BackupPermissionsService.requestBatteryExemption();
              _check();
            },
          ),
        ],
        if (!kIsWeb && Platform.isIOS && !s.backgroundRefresh) ...[
          if (!s.notifications) const SizedBox(height: 6),
          _PermTipRow(
            icon: Icons.refresh_rounded,
            label: 'Enable Background App Refresh for reliable sync',
            actionLabel: 'Settings',
            accent: widget.accent,
            onAction: () => BackupPermissionsService.goToSettings(),
          ),
        ],
      ],
    );
  }
}

// ── Backup permissions bottom sheet (shown once after Drive grant) ────────────

class _BackupPermissionsSheet extends StatefulWidget {
  final Color accent;
  const _BackupPermissionsSheet({required this.accent});

  @override
  State<_BackupPermissionsSheet> createState() => _BackupPermissionsSheetState();
}

class _BackupPermissionsSheetState extends State<_BackupPermissionsSheet> {
  BackupPermissionsStatus? _status;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final s = await BackupPermissionsService.check();
    if (mounted) setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final accent = widget.accent;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.cloud_done_outlined, color: accent, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Optimize backup reliability',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'A few quick steps help ensure your files upload without interruption.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.4),
          ),
          const SizedBox(height: 20),
          if (s == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            _PermSheetRow(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Get alerted when uploads complete or fail.',
              granted: s.notifications,
              actionLabel: 'Allow',
              accent: accent,
              onAction: () async {
                await BackupPermissionsService.requestNotifications();
                _check();
              },
            ),
            if (!kIsWeb && Platform.isAndroid) ...[
              const SizedBox(height: 12),
              _PermSheetRow(
                icon: Icons.battery_saver_outlined,
                title: 'Battery optimization',
                subtitle: 'Prevent the system from pausing uploads in the background.',
                granted: s.batteryExempt,
                actionLabel: 'Exempt',
                accent: accent,
                onAction: () async {
                  await BackupPermissionsService.requestBatteryExemption();
                  _check();
                },
              ),
            ],
            if (!kIsWeb && Platform.isIOS) ...[
              const SizedBox(height: 12),
              _PermSheetRow(
                icon: Icons.refresh_rounded,
                title: 'Background App Refresh',
                subtitle: 'Allow the app to sync when you reopen it.',
                granted: s.backgroundRefresh,
                actionLabel: 'Settings',
                accent: accent,
                onAction: () => BackupPermissionsService.goToSettings(),
              ),
            ],
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared permission row widgets ─────────────────────────────────────────────

class _PermTipRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String actionLabel;
  final Color accent;
  final VoidCallback onAction;

  const _PermTipRow({
    required this.icon,
    required this.label,
    required this.actionLabel,
    required this.accent,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.amber.shade700),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.amber.shade800, height: 1.3),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withAlpha(60)),
            ),
            child: Text(
              actionLabel,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: accent),
            ),
          ),
        ),
      ],
    );
  }
}

class _PermSheetRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final String actionLabel;
  final Color accent;
  final VoidCallback onAction;

  const _PermSheetRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.actionLabel,
    required this.accent,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: granted ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted ? Colors.green.shade100 : Colors.amber.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            granted ? Icons.check_circle_outline : icon,
            size: 20,
            color: granted ? Colors.green.shade600 : Colors.amber.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3)),
              ],
            ),
          ),
          if (!granted) ...[
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(actionLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.white)),
            ),
          ],
        ],
      ),
    );
  }
}
