import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/forum_question.dart';
import '../models/kid_profile.dart';
import '../providers/profiles_provider.dart';
import '../services/firestore_service.dart';
import '../utils/device_performance.dart';
import '../utils/profile_theme.dart';
import '../widgets/gradient_fab.dart';
import 'forum_detail_screen.dart';

final forumQuestionsProvider = StreamProvider<List<ForumQuestion>>(
  (_) => FirestoreService.streamForumQuestions(),
);

class ForumScreen extends ConsumerWidget {
  final int profileIndex;
  const ForumScreen({super.key, required this.profileIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(forumQuestionsProvider);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    color: const Color(0xFF1A1A2E),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Q&A Forum',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                        Text('Ask the parenting community',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF888888))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: questions.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: accent)),
                error: (e, _) {
                  debugPrint('forumQuestionsProvider error: $e');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Error: $e',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.red.shade400, fontSize: 13)),
                    ),
                  );
                },
                data: (list) {
                  if (list.isEmpty) {
                    return _EmptyState(
                        accent: accent,
                        onAsk: () => _showAskSheet(context, accent, uid));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _AnimatedCard(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _QuestionCard(
                          question: list[i],
                          accent: accent,
                          currentUid: uid,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForumDetailScreen(
                                question: list[i],
                                currentUid: uid,
                                accent: accent,
                              ),
                            ),
                          ),
                          onEdit: () =>
                              _showAskSheet(context, accent, uid, editing: list[i]),
                          onDelete: () =>
                              _confirmDelete(context, list[i].id),
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
        icon: Icons.help_outline_rounded,
        label: 'Ask a question',
        onTap: () => _showAskSheet(context, accent, uid),
      ),
    );
  }

  void _showAskSheet(BuildContext context, Color accent, String uid,
      {ForumQuestion? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AskQuestionSheet(
          accent: accent, uid: uid, editing: editing),
    );
  }

  void _confirmDelete(BuildContext context, String questionId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete question?'),
        content: const Text(
            'This will also delete all answers. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirestoreService.deleteForumQuestion(questionId);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Question card ─────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final ForumQuestion question;
  final Color accent;
  final String currentUid;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.accent,
    required this.currentUid,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = question.authorId == currentUid;

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
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(name: question.authorName, photoUrl: question.authorPhotoUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question.authorName,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                        Text(_timeAgo(question.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                  if (isOwner)
                    _OwnerMenu(onEdit: onEdit, onDelete: onDelete),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.help_outline_rounded,
                      size: 16, color: accent.withAlpha(180)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      question.content,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                          height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (question.edited) ...[
                const SizedBox(height: 2),
                Text('edited',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic)),
              ],
              if (question.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: question.tags
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
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 15, color: Colors.grey.shade400),
                  const SizedBox(width: 5),
                  Text(
                    question.answerCount == 1
                        ? '1 answer'
                        : '${question.answerCount} answers',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text('Answer →',
                      style: TextStyle(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w600)),
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
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

// ── Ask / edit question bottom sheet ─────────────────────────────────────────

class _AskQuestionSheet extends StatefulWidget {
  final Color accent;
  final String uid;
  final ForumQuestion? editing;

  const _AskQuestionSheet(
      {required this.accent, required this.uid, this.editing});

  @override
  State<_AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends State<_AskQuestionSheet> {
  late final TextEditingController _ctrl;
  final _tagCtrl = TextEditingController();
  late List<String> _tags;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;
  bool get _canSubmit => _ctrl.text.trim().length >= 10;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.editing?.content ?? '');
    _tags = List<String>.from(widget.editing?.tags ?? []);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag(String raw) {
    final tag = raw.trim().toLowerCase().replaceAll(' ', '-');
    if (tag.isEmpty || _tags.contains(tag) || _tags.length >= 5) return;
    setState(() {
      _tags.add(tag);
      _tagCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (_isEditing) {
        await FirestoreService.updateForumQuestion(
          widget.editing!.copyWith(
            content: _ctrl.text.trim(),
            tags: _tags,
            edited: true,
          ),
        );
      } else {
        final q = ForumQuestion(
          id: 'fq_${DateTime.now().microsecondsSinceEpoch}',
          content: _ctrl.text.trim(),
          authorId: user.uid,
          authorName: user.displayName ?? user.email ?? 'Parent',
          authorPhotoUrl: user.photoURL,
          createdAt: DateTime.now(),
          tags: _tags,
        );
        await FirestoreService.createForumQuestion(q);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isEditing ? 'Edit question' : 'Ask the community',
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 4),
          Text('Text only · be specific · be kind',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            minLines: 3,
            autofocus: true,
            style: const TextStyle(
                fontSize: 15, color: Color(0xFF1A1A2E), height: 1.5),
            decoration: InputDecoration(
              hintText: 'What would you like to ask?',
              hintStyle:
                  TextStyle(fontSize: 15, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          // Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._tags.map((t) => GestureDetector(
                    onTap: () => setState(() => _tags.remove(t)),
                    child: Chip(
                      label: Text('#$t',
                          style: TextStyle(
                              fontSize: 12,
                              color: accent,
                              fontWeight: FontWeight.w600)),
                      deleteIcon:
                          Icon(Icons.close_rounded, size: 14, color: accent),
                      onDeleted: () => setState(() => _tags.remove(t)),
                      backgroundColor: accent.withAlpha(14),
                      side: BorderSide(color: accent.withAlpha(50)),
                      padding: EdgeInsets.zero,
                    ),
                  )),
              if (_tags.length < 5)
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: InputDecoration(
                      hintText: '+ add tag',
                      hintStyle: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                    textInputAction: TextInputAction.done,
                    onSubmitted: _addTag,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_canSubmit && !_saving) ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isEditing ? 'Save changes' : 'Post question',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  const _Avatar({required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      backgroundColor: Colors.primaries[
              name.isNotEmpty ? name.codeUnitAt(0) % Colors.primaries.length : 0]
          .shade200,
      child: photoUrl == null
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white))
          : null,
    );
  }
}

class _OwnerMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _OwnerMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded,
          size: 20, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
      itemBuilder: (_) => const [
        PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 16),
              SizedBox(width: 8),
              Text('Edit'),
            ])),
        PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline_rounded,
                  size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ])),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color accent;
  final VoidCallback onAsk;
  const _EmptyState({required this.accent, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No questions yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              'Be the first to ask the community\na parenting question.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAsk,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.help_outline_rounded,
                  size: 16, color: Colors.white),
              label: const Text('Ask the first question',
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
      Future.delayed(Duration(milliseconds: delay),
          () { if (mounted) _ctrl.forward(); });
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
