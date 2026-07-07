import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/blog_post.dart';
import '../models/kid_profile.dart';
import '../providers/profiles_provider.dart';
import '../services/firestore_service.dart';
import '../utils/device_performance.dart';
import '../widgets/gradient_fab.dart';
import '../utils/profile_theme.dart';
import 'story_detail_screen.dart';
import 'write_story_screen.dart';

final blogsProvider = StreamProvider<List<BlogPost>>(
  (_) => FirestoreService.streamBlogs(),
);

class StoriesScreen extends ConsumerWidget {
  final int profileIndex;
  const StoriesScreen({super.key, required this.profileIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogs = ref.watch(blogsProvider);
    final profiles = ref.watch(profilesProvider) ?? [];
    final theme = profiles.isNotEmpty
        ? ProfileTheme.forProfile(
            profiles[profileIndex.clamp(0, profiles.length - 1)])
        : ProfileTheme.forGender(Gender.neutral);
    final accent = theme.accent;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    tooltip: 'Back',
                    color: const Color(0xFF1A1A2E),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Stories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'Tips, tricks & tales from parents',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF888888)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Blog list
            Expanded(
              child: blogs.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: accent)),
                error: (e, _) => Center(
                  child: Text('Could not load stories.',
                      style: TextStyle(color: Colors.grey.shade500)),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return _EmptyState(
                      accent: accent,
                      onWrite: () => _openWrite(context),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _AnimatedCard(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StoryCard(
                          post: list[i],
                          currentUid: uid,
                          accent: accent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StoryDetailScreen(
                                post: list[i],
                                currentUid: uid,
                                accent: accent,
                              ),
                            ),
                          ),
                          onLike: () =>
                              FirestoreService.toggleLike(list[i].id, uid),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GradientFab(
        gradient: theme.headerGradient,
        accent: accent,
        icon: Icons.edit_rounded,
        label: 'Write a story',
        onTap: () => _openWrite(context),
      ),
    );
  }

  void _openWrite(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WriteStoryScreen()),
    );
  }
}

// ── Story card ────────────────────────────────────────────────────────────────

class _StoryCard extends StatelessWidget {
  final BlogPost post;
  final String currentUid;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const _StoryCard({
    required this.post,
    required this.currentUid,
    required this.accent,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final liked = post.isLikedBy(currentUid);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(7),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              Row(
                children: [
                  _AuthorAvatar(
                      name: post.authorName, photoUrl: post.authorPhotoUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E)),
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),

              // Excerpt
              Text(
                post.excerpt,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Tags
              if (post.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: post.tags
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withAlpha(14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('#$t',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: accent,
                                    fontWeight: FontWeight.w600)),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 8),

              // Like + read more
              Row(
                children: [
                  GestureDetector(
                    onTap: onLike,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(liked),
                            size: 20,
                            color: liked
                                ? Colors.red.shade400
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post.likesCount}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: liked
                                  ? Colors.red.shade400
                                  : Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Read more →',
                    style: TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ── Author avatar ─────────────────────────────────────────────────────────────

class _AuthorAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _AuthorAvatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      backgroundColor: Colors.primaries[
              name.isNotEmpty
                  ? name.codeUnitAt(0) % Colors.primaries.length
                  : 0]
          .shade200,
      child: photoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            )
          : null,
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final Color accent;
  final VoidCallback onWrite;
  const _EmptyState({required this.accent, required this.onWrite});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No stories yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share a parenting tip,\ntrick, or story with the community.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onWrite,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: Colors.white),
              label: const Text('Write the first story',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Entry animation wrapper ───────────────────────────────────────────────────

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    if (DevicePerformance.isLowEnd) return;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 560));
    final curved =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _opacity = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut)));
    _scale = Tween(begin: 0.92, end: 1.0).animate(curved);
    _slide = Tween(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(curved);
    final delay = (widget.index * 60).clamp(0, 320);
    if (delay == 0) {
      _ctrl.forward();
    } else {
      Future.delayed(
          Duration(milliseconds: delay), () { if (mounted) _ctrl.forward(); });
    }
  }

  @override
  void dispose() {
    if (!DevicePerformance.isLowEnd) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DevicePerformance.isLowEnd) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
