import 'package:flutter/material.dart';

import '../models/blog_post.dart';
import '../services/firestore_service.dart';

class StoryDetailScreen extends StatefulWidget {
  final BlogPost post;
  final String currentUid;
  final Color accent;

  const StoryDetailScreen({
    super.key,
    required this.post,
    required this.currentUid,
    required this.accent,
  });

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  late BlogPost _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  Future<void> _toggleLike() async {
    await FirestoreService.toggleLike(_post.id, widget.currentUid);
    final wasLiked = _post.isLikedBy(widget.currentUid);
    setState(() {
      final updated = wasLiked
          ? (List<String>.from(_post.likedByUids)..remove(widget.currentUid))
          : (List<String>.from(_post.likedByUids)..add(widget.currentUid));
      _post = _post.copyWith(likedByUids: updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    final liked = _post.isLikedBy(widget.currentUid);
    final accent = widget.accent;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: const Color(0xFF1A1A2E),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(liked),
                      color: liked
                          ? Colors.red.shade400
                          : Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                  onPressed: _toggleLike,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author
                  Row(
                    children: [
                      _AuthorAvatar(
                        name: _post.authorName,
                        photoUrl: _post.authorPhotoUrl,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _post.authorName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            _formatDate(_post.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Title
                  Text(
                    _post.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                  ),

                  // Tags
                  if (_post.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _post.tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: accent.withAlpha(18),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#$t',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 20),

                  // Body
                  Text(
                    _post.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade800,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Like button
                  Center(
                    child: GestureDetector(
                      onTap: _toggleLike,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        decoration: BoxDecoration(
                          color: liked
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                key: ValueKey(liked),
                                color: liked
                                    ? Colors.red.shade400
                                    : Colors.grey.shade500,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              liked
                                  ? '${_post.likesCount} likes'
                                  : 'Like this story',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: liked
                                    ? Colors.red.shade400
                                    : Colors.grey.shade600,
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
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _AuthorAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _AuthorAvatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      backgroundColor: Colors.primaries[
              name.isNotEmpty ? name.codeUnitAt(0) % Colors.primaries.length : 0]
          .shade200,
      child: photoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            )
          : null,
    );
  }
}
