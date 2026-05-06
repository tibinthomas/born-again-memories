import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection.dart';
import '../models/milestone.dart';
import '../providers/auth_provider.dart';
import '../providers/connections_provider.dart';
import '../services/sharing_service.dart';
import '../utils/date_formatter.dart';
import 'attachment_preview.dart';
import 'link_preview_card.dart';

class MilestoneCard extends ConsumerWidget {
  final Milestone milestone;
  final String kidName;

  const MilestoneCard({
    super.key,
    required this.milestone,
    this.kidName = '',
  });

  void _share(BuildContext context, WidgetRef ref) {
    final connections = ref.read(myConnectionsProvider).value ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ShareSheet(
        milestone: milestone,
        kidName: kidName,
        connections: connections,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: milestone.color.withAlpha(46),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: milestone.color,
            ),
            child: const Icon(
              Icons.star,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        milestone.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _share(context, ref),
                      icon: const Icon(Icons.share_outlined, size: 20),
                      tooltip: 'Share',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  milestone.description,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatDate(milestone.date),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (milestone.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: milestone.attachments
                        .map((a) => AttachmentPreview(attachment: a))
                        .toList(),
                  ),
                ],
                if (milestone.externalLinks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.link, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Links',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...milestone.externalLinks.map(
                    (link) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: LinkPreviewCard(url: link.url, label: link.label),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Share sheet ────────────────────────────────────────────────────────────────

class _ShareSheet extends ConsumerStatefulWidget {
  final Milestone milestone;
  final String kidName;
  final List<Connection> connections;

  const _ShareSheet({
    required this.milestone,
    required this.kidName,
    required this.connections,
  });

  @override
  ConsumerState<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends ConsumerState<_ShareSheet> {
  bool _sharing = false;
  bool _done = false;

  Future<void> _doShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) return;

    try {
      await SharingService.shareMemory(
        googleSignIn: authService.googleSignIn,
        fromUid: user.uid,
        fromName: user.displayName ?? '',
        fromPhotoUrl: user.photoURL ?? '',
        kidName: widget.kidName,
        milestoneTitle: widget.milestone.title,
        milestoneDescription: widget.milestone.description,
        milestoneDate: widget.milestone.date,
        milestoneColor: widget.milestone.color,
        attachments: widget.milestone.attachments,
        connections: widget.connections,
      );
      if (mounted) setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _sharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Share "${widget.milestone.title}"',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.kidName.isNotEmpty
                ? '${widget.kidName}\'s milestone'
                : 'Your milestone',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (widget.connections.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have no connections yet. Go to the People tab to invite friends.',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Will be shared with ${widget.connections.length} connection${widget.connections.length == 1 ? '' : 's'}:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.connections.map((c) {
                final uid = ref.read(authStateProvider).value?.uid ?? '';
                return Chip(
                  avatar: CircleAvatar(
                    backgroundImage: c.otherPhotoUrl(uid).isNotEmpty
                        ? NetworkImage(c.otherPhotoUrl(uid))
                        : null,
                    child: c.otherPhotoUrl(uid).isEmpty
                        ? Text(c.otherName(uid)[0].toUpperCase())
                        : null,
                  ),
                  label: Text(c.otherName(uid)),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'Images will be made accessible via Google Drive.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: (_sharing || _done) ? null : _doShare,
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Icon(_done ? Icons.check : Icons.share),
              label: Text(_done
                  ? 'Shared!'
                  : _sharing
                      ? 'Sharing…'
                      : 'Share with all connections'),
            ),
          ],
        ],
      ),
    );
  }
}
