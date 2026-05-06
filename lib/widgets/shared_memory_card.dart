import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attachment.dart';
import '../models/comment.dart';
import '../models/shared_memory.dart';
import '../providers/auth_provider.dart';
import '../services/sharing_service.dart';
import '../utils/date_formatter.dart';

class SharedMemoryCard extends ConsumerWidget {
  final SharedMemory memory;

  const SharedMemoryCard({super.key, required this.memory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final theme = Theme.of(context);
    final isLiked = memory.isLikedBy(uid);
    final user = ref.read(authServiceProvider).currentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + date
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _Avatar(photoUrl: memory.fromPhotoUrl, name: memory.fromName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        memory.fromUid == uid ? 'You' : memory.fromName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Shared ${memory.kidName}\'s memory',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatDate(memory.createdAt),
                  style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Milestone info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: memory.milestoneColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        memory.milestoneTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                if (memory.milestoneDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    memory.milestoneDescription,
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  formatDate(memory.milestoneDate),
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          // Media thumbnails
          if (memory.media.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: memory.media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final m = memory.media[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _MediaThumbnail(media: m),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Action bar: like + comment
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Row(
              children: [
                _LikeButton(
                  isLiked: isLiked,
                  count: memory.likedByUids.length,
                  onTap: () => SharingService.toggleLike(
                    memoryId: memory.id,
                    uid: uid,
                    fromName: user?.displayName ?? '',
                    fromPhotoUrl: user?.photoURL ?? '',
                    currentlyLiked: isLiked,
                    ownerUid: memory.fromUid,
                  ),
                ),
                _CommentButton(
                  count: memory.commentCount,
                  onTap: () => _showComments(context, ref, uid, user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComments(
      BuildContext context, WidgetRef ref, String uid, dynamic user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CommentsSheet(
        memoryId: memory.id,
        ownerUid: memory.fromUid,
        currentUid: uid,
        currentName: user?.displayName ?? '',
        currentPhotoUrl: user?.photoURL,
      ),
    );
  }
}

// ── Media thumbnail ────────────────────────────────────────────────────────────

class _MediaThumbnail extends StatelessWidget {
  final SharedMemoryMedia media;

  const _MediaThumbnail({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.type == AttachmentType.image) {
      return Image.network(
        media.thumbnailUrl,
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                width: 160,
                height: 160,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
      );
    }
    return _placeholder(
        media.type == AttachmentType.video ? Icons.videocam : Icons.audiotrack);
  }

  Widget _placeholder(IconData icon) => Container(
        width: 160,
        height: 160,
        color: Colors.grey.shade200,
        child: Icon(icon, size: 40, color: Colors.grey.shade500),
      );
}

// ── Like button ────────────────────────────────────────────────────────────────

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;

  const _LikeButton(
      {required this.isLiked, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        size: 20,
        color: isLiked ? Colors.red : null,
      ),
      label: Text('$count'),
    );
  }
}

// ── Comment button ─────────────────────────────────────────────────────────────

class _CommentButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CommentButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.chat_bubble_outline, size: 20),
      label: Text('$count'),
    );
  }
}

// ── Avatar ─────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String photoUrl;
  final String name;

  const _Avatar({required this.photoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
          radius: 18, backgroundImage: NetworkImage(photoUrl));
    }
    return CircleAvatar(
      radius: 18,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// ── Comments sheet ─────────────────────────────────────────────────────────────

class CommentsSheet extends ConsumerStatefulWidget {
  final String memoryId;
  final String ownerUid;
  final String currentUid;
  final String currentName;
  final String? currentPhotoUrl;

  const CommentsSheet({
    super.key,
    required this.memoryId,
    required this.ownerUid,
    required this.currentUid,
    required this.currentName,
    required this.currentPhotoUrl,
  });

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    await SharingService.addComment(
      memoryId: widget.memoryId,
      fromUid: widget.currentUid,
      fromName: widget.currentName,
      fromPhotoUrl: widget.currentPhotoUrl,
      text: text,
      ownerUid: widget.ownerUid,
    );
    _ctrl.clear();
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Comments',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: SharingService.commentsStream(widget.memoryId),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Text('No comments yet',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant)),
                  );
                }
                return ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: comments.length,
                  itemBuilder: (_, i) => _CommentTile(comment: comments[i]),
                );
              },
            ),
          ),
          // Input
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              top: 8,
            ),
            child: Row(
              children: [
                _Avatar(
                    photoUrl: widget.currentPhotoUrl ?? '',
                    name: widget.currentName),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Add a comment…',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
              photoUrl: comment.fromPhotoUrl ?? '',
              name: comment.fromName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.fromName,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(comment.text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
