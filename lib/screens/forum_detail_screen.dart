import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/forum_question.dart';
import '../services/firestore_service.dart';

final _answersProvider = StreamProviderFamily<List<ForumAnswer>, String>(
  (_, questionId) => FirestoreService.streamForumAnswers(questionId),
);

class ForumDetailScreen extends ConsumerStatefulWidget {
  final ForumQuestion question;
  final String currentUid;
  final Color accent;

  const ForumDetailScreen({
    super.key,
    required this.question,
    required this.currentUid,
    required this.accent,
  });

  @override
  ConsumerState<ForumDetailScreen> createState() => _ForumDetailScreenState();
}

class _ForumDetailScreenState extends ConsumerState<ForumDetailScreen> {
  final _answerCtrl = TextEditingController();
  bool _submitting = false;
  ForumAnswer? _editingAnswer;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (_editingAnswer != null) {
        await FirestoreService.updateForumAnswer(
          widget.question.id,
          _editingAnswer!.copyWith(content: text, edited: true),
        );
      } else {
        final answer = ForumAnswer(
          id: 'fa_${DateTime.now().microsecondsSinceEpoch}',
          content: text,
          authorId: user.uid,
          authorName: user.displayName ?? user.email ?? 'Parent',
          authorPhotoUrl: user.photoURL,
          createdAt: DateTime.now(),
        );
        await FirestoreService.createForumAnswer(widget.question.id, answer);
      }
      _answerCtrl.clear();
      setState(() => _editingAnswer = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _startEditAnswer(ForumAnswer answer) {
    setState(() {
      _editingAnswer = answer;
      _answerCtrl.text = answer.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingAnswer = null;
      _answerCtrl.clear();
    });
  }

  void _confirmDeleteAnswer(String answerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete answer?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              FirestoreService.deleteForumAnswer(
                  widget.question.id, answerId);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final answers = ref.watch(_answersProvider(widget.question.id));
    final accent = widget.accent;
    final q = widget.question;
    final isQuestionOwner = q.authorId == widget.currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20),
                    color: const Color(0xFF1A1A2E),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: const Text('Question',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  actions: [
                    if (isQuestionOwner)
                      _OwnerMenu(
                        onEdit: () => _showEditQuestionSheet(context),
                        onDelete: () => _confirmDeleteQuestion(context),
                      ),
                  ],
                ),

                // Question card
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Avatar(
                                name: q.authorName,
                                photoUrl: q.authorPhotoUrl),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(q.authorName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A2E))),
                                Text(_formatDate(q.createdAt),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.help_outline_rounded,
                                size: 18,
                                color: accent.withAlpha(180)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                q.content,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E),
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        if (q.edited) ...[
                          const SizedBox(height: 4),
                          Text('edited',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic)),
                        ],
                        if (q.tags.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: q.tags
                                .map((t) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: accent.withAlpha(14),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text('#$t',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: accent,
                                              fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Answers header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: answers.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (list) => Text(
                        list.isEmpty
                            ? 'No answers yet — be the first!'
                            : '${list.length} ${list.length == 1 ? 'Answer' : 'Answers'}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                ),

                // Answers list
                answers.when(
                  loading: () => SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                      padding: const EdgeInsets.all(32),
                      child:
                          CircularProgressIndicator(color: accent),
                    )),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(
                        child: Text('Could not load answers.',
                            style: TextStyle(
                                color: Colors.grey.shade500))),
                  ),
                  data: (list) => SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: _AnswerCard(
                          answer: list[i],
                          accent: accent,
                          currentUid: widget.currentUid,
                          isEditing: _editingAnswer?.id == list[i].id,
                          onEdit: () => _startEditAnswer(list[i]),
                          onDelete: () =>
                              _confirmDeleteAnswer(list[i].id),
                        ),
                      ),
                      childCount: list.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // Answer input bar
          _AnswerInputBar(
            controller: _answerCtrl,
            accent: accent,
            submitting: _submitting,
            isEditing: _editingAnswer != null,
            onSubmit: _submitAnswer,
            onCancelEdit: _cancelEdit,
          ),
        ],
      ),
    );
  }

  void _showEditQuestionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditQuestionSheet(
        question: widget.question,
        accent: widget.accent,
      ),
    );
  }

  void _confirmDeleteQuestion(BuildContext context) {
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
              Navigator.pop(context);
              FirestoreService.deleteForumQuestion(widget.question.id);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Answer card ───────────────────────────────────────────────────────────────

class _AnswerCard extends StatelessWidget {
  final ForumAnswer answer;
  final Color accent;
  final String currentUid;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnswerCard({
    required this.answer,
    required this.accent,
    required this.currentUid,
    required this.isEditing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = answer.authorId == currentUid;

    return Container(
      decoration: BoxDecoration(
        color: isEditing ? accent.withAlpha(12) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isEditing
            ? Border.all(color: accent.withAlpha(80), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(
                  name: answer.authorName, photoUrl: answer.authorPhotoUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(answer.authorName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    Text(_timeAgo(answer.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              if (isOwner)
                _OwnerMenu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer.content,
            style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                height: 1.55),
          ),
          if (answer.edited) ...[
            const SizedBox(height: 4),
            Text('edited',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic)),
          ],
        ],
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

// ── Answer input bar ──────────────────────────────────────────────────────────

class _AnswerInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final bool submitting;
  final bool isEditing;
  final VoidCallback onSubmit;
  final VoidCallback onCancelEdit;

  const _AnswerInputBar({
    required this.controller,
    required this.accent,
    required this.submitting,
    required this.isEditing,
    required this.onSubmit,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 12,
              offset: const Offset(0, -3)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 12, MediaQuery.viewInsetsOf(context).bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isEditing) ...[
            Row(
              children: [
                Icon(Icons.edit_outlined, size: 14, color: accent),
                const SizedBox(width: 6),
                Text('Editing your answer',
                    style: TextStyle(
                        fontSize: 12,
                        color: accent,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: onCancelEdit,
                  child: Text('Cancel',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write your answer…',
                    hintStyle: TextStyle(
                        fontSize: 14, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF2F2F7),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: submitting ? null : onSubmit,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: submitting
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Edit question sheet ───────────────────────────────────────────────────────

class _EditQuestionSheet extends StatefulWidget {
  final ForumQuestion question;
  final Color accent;
  const _EditQuestionSheet(
      {required this.question, required this.accent});

  @override
  State<_EditQuestionSheet> createState() => _EditQuestionSheetState();
}

class _EditQuestionSheetState extends State<_EditQuestionSheet> {
  late final TextEditingController _ctrl;
  late List<String> _tags;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.question.content);
    _tags = List<String>.from(widget.question.tags);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ctrl.text.trim().length < 10) return;
    setState(() => _saving = true);
    try {
      await FirestoreService.updateForumQuestion(
        widget.question.copyWith(
          content: _ctrl.text.trim(),
          tags: _tags,
          edited: true,
        ),
      );
      if (mounted) Navigator.pop(context);
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
          const Text('Edit question',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            maxLines: 5,
            minLines: 3,
            autofocus: true,
            style: const TextStyle(
                fontSize: 15, color: Color(0xFF1A1A2E), height: 1.5),
            decoration: InputDecoration(
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_ctrl.text.trim().length >= 10 && !_saving)
                  ? _save
                  : null,
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
                  : const Text('Save changes',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

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
              name.isNotEmpty
                  ? name.codeUnitAt(0) % Colors.primaries.length
                  : 0]
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
