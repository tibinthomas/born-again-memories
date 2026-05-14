import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/kid_profile.dart';
import '../../../providers/backup_provider.dart';
import '../../../utils/profile_theme.dart';
import '../../reminders_screen.dart';

// ── Profile header ─────────────────────────────────────────────────────────────

class ProfileHeader extends ConsumerWidget {
  final KidProfile profile;
  final ProfileTheme profileTheme;
  final List<KidProfile> allProfiles;
  final int profileIndex;
  final VoidCallback onSettings;
  final ValueChanged<int> onSelectProfile;
  final VoidCallback onSharedFeed;
  final VoidCallback onDocuments;
  final VoidCallback onLinks;
  final VoidCallback onEditProfile;
  final VoidCallback onAddProfile;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.profileTheme,
    required this.allProfiles,
    required this.profileIndex,
    required this.onSettings,
    required this.onSelectProfile,
    required this.onSharedFeed,
    required this.onDocuments,
    required this.onLinks,
    required this.onEditProfile,
    required this.onAddProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(backupSyncProvider);
    final hasBackground = !kIsWeb &&
        profile.backgroundImagePath != null &&
        profile.backgroundImagePath!.isNotEmpty &&
        File(profile.backgroundImagePath!).existsSync();
    final hasAvatar = profile.avatarImagePath != null &&
        profile.avatarImagePath!.isNotEmpty &&
        !kIsWeb &&
        File(profile.avatarImagePath!).existsSync();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: ClipRRect(
        key: ValueKey(profile.id + (profile.backgroundImagePath ?? '')),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: hasBackground ? null : profileTheme.headerGradient,
            image: hasBackground
                ? DecorationImage(
                    image: FileImage(File(profile.backgroundImagePath!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: Stack(
            children: [
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(hasBackground ? 100 : 20),
                        Colors.black.withAlpha(hasBackground ? 160 : 50),
                      ],
                    ),
                  ),
                ),
              ),
              // Decorative bubbles
              Positioned(right: -28, top: -18, child: Bubble(110, 18)),
              Positioned(right: 60, bottom: -22, child: Bubble(80, 14)),
              Positioned(left: -22, top: 30, child: Bubble(70, 12)),
              Positioned(left: 80, bottom: 8, child: Bubble(28, 22)),
              Positioned(right: 24, top: 48, child: Bubble(16, 30)),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile info + settings ───────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar only — fixed 68px so name never shifts
                          GestureDetector(
                            onTap: onEditProfile,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withAlpha(30),
                                    border: Border.all(color: Colors.white, width: 2),
                                    image: hasAvatar
                                        ? DecorationImage(
                                            image: FileImage(File(profile.avatarImagePath!)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(40),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: hasAvatar
                                      ? null
                                      : Center(
                                          child: Text(
                                            profileTheme.decalEmoji,
                                            style: const TextStyle(fontSize: 32),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(30),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 11,
                                      color: profileTheme.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Name + age
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  profile.nickname ?? profile.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (profile.nickname != null &&
                                    profile.nickname!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      profile.name,
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(180),
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(35),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    profile.ageText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Backup status indicator
                          if (sync.driveAccessGranted) ...[
                            BackupHeaderIndicator(sync: sync),
                            const SizedBox(width: 6),
                          ],

                          // Settings inline top-right
                          HeaderIconBtn(
                            icon: Icons.settings_outlined,
                            onTap: onSettings,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Mini profile switcher (own row, never affects name position) ──
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < allProfiles.length; i++)
                            if (i != profileIndex)
                              Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: MiniProfileAvatar(
                                  profile: allProfiles[i],
                                  onTap: () => onSelectProfile(i),
                                ),
                              ),
                          GestureDetector(
                            onTap: onAddProfile,
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withAlpha(30),
                                    border: Border.all(
                                        color: Colors.white.withAlpha(140), width: 1.5),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Quick-access strip ────────────────────────
                      Row(
                        children: [
                          Expanded(child: QuickPill(
                            icon: Icons.auto_awesome,
                            label: 'Moments',
                          )),
                          Expanded(child: QuickPill(
                            icon: Icons.folder_outlined,
                            label: 'Docs',
                            onTap: onDocuments,
                          )),
                          Expanded(child: QuickPill(
                            icon: Icons.link_outlined,
                            label: 'Links',
                            onTap: onLinks,
                          )),
                          Expanded(child: QuickPill(
                            icon: Icons.people_outline_rounded,
                            label: 'Feed',
                            onTap: onSharedFeed,
                          )),
                          Expanded(child: RemindersQuickPill(
                            profile: profile,
                            profileIndex: profileIndex,
                          )),
                        ],
                      ),
                    ],
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

// ── Decorative bubble ─────────────────────────────────────────────────────────

class Bubble extends StatefulWidget {
  final double size;
  final int alpha;
  const Bubble(this.size, this.alpha, {super.key});

  @override
  State<Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<Bubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    final ms = (2200 + widget.size * 12).toInt();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: ms))
      ..repeat(reverse: true);
    // Start at a phase offset derived from size so bubbles are out of sync
    _ctrl.forward(from: (widget.size % 100) / 100);
    final travel = (widget.size * 0.12).clamp(6.0, 20.0);
    _float = Tween<double>(begin: 0, end: -travel).animate(
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
    return AnimatedBuilder(
      animation: _float,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, _float.value),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(widget.alpha),
          ),
        ),
      ),
    );
  }
}

// ── Minimal header icon button ────────────────────────────────────────────────

class HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const HeaderIconBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(45),
              border: Border.all(color: Colors.white.withAlpha(70), width: 0.8),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Backup status indicator (header) ─────────────────────────────────────────

class BackupHeaderIndicator extends StatelessWidget {
  final BackupSyncState sync;
  const BackupHeaderIndicator({super.key, required this.sync});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(45),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(70), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sync.isSyncing)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.cloud_done_outlined,
                  color: Colors.white.withAlpha(200),
                  size: 14,
                ),
              const SizedBox(width: 5),
              Text(
                sync.isSyncing
                    ? (sync.currentUploadName != null ? 'Backing up…' : 'Syncing…')
                    : 'Backed up',
                style: TextStyle(
                  color: Colors.white.withAlpha(220),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick-access pill ─────────────────────────────────────────────────────────

class QuickPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QuickPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(onTap != null ? 45 : 25),
                  border: Border.all(
                    color: Colors.white.withAlpha(onTap != null ? 80 : 45),
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 17),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini profile avatar (switcher) ───────────────────────────────────────────

class MiniProfileAvatar extends StatelessWidget {
  final KidProfile profile;
  final VoidCallback onTap;
  const MiniProfileAvatar({super.key, required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasAvatar = profile.avatarImagePath != null &&
        profile.avatarImagePath!.isNotEmpty &&
        !kIsWeb &&
        File(profile.avatarImagePath!).existsSync();
    final pTheme = ProfileTheme.forProfile(profile);

    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(35),
              border: Border.all(color: Colors.white.withAlpha(160), width: 1.5),
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
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Reminders quick pill ──────────────────────────────────────────────────────

class RemindersQuickPill extends StatelessWidget {
  final KidProfile profile;
  final int profileIndex;

  const RemindersQuickPill(
      {super.key, required this.profile, required this.profileIndex});

  @override
  Widget build(BuildContext context) {
    final upcoming = profile.reminders.where((r) => r.isUpcoming).length;
    final overdue = profile.reminders.where((r) => r.isOverdue).length;
    final badgeCount = upcoming + overdue;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RemindersScreen(profileIndex: profileIndex),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: overdue > 0
                          ? Colors.orange.withAlpha(60)
                          : Colors.white.withAlpha(45),
                      border: Border.all(
                        color: overdue > 0
                            ? Colors.orange.shade300.withAlpha(180)
                            : Colors.white.withAlpha(80),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      overdue > 0
                          ? Icons.alarm_outlined
                          : Icons.notifications_outlined,
                      color: overdue > 0 ? Colors.orange.shade200 : Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: overdue > 0 ? Colors.orange : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withAlpha(120), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        '$badgeCount',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: overdue > 0 ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Remind',
            style: TextStyle(
              color: overdue > 0 ? Colors.orange.shade100 : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
