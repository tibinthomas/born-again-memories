import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/blog_post.dart';
import '../providers/profiles_provider.dart';
import '../services/firestore_service.dart';
import '../utils/profile_theme.dart';

class WriteStoryScreen extends ConsumerStatefulWidget {
  final BlogPost? editing;
  const WriteStoryScreen({super.key, this.editing});

  @override
  ConsumerState<WriteStoryScreen> createState() => _WriteStoryScreenState();
}

class _WriteStoryScreenState extends ConsumerState<WriteStoryScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  final TextEditingController _tagCtrl = TextEditingController();
  late List<String> _tags;
  bool _saving = false;

  bool get _isEditing => widget.editing != null;

  static const _suggestedTags = [
    'sleep', 'feeding', 'toddler', 'newborn', 'tips',
    'tricks', 'health', 'play', 'milestones', 'parenting',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _bodyCtrl = TextEditingController(text: e?.content ?? '');
    _tags = List<String>.from(e?.tags ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Color get _accent {
    final profiles = ref.read(profilesProvider) ?? [];
    if (profiles.isEmpty) return Colors.pinkAccent;
    return ProfileTheme.forProfile(profiles.first).accent;
  }

  static const _maxWords = 1200;

  int get _wordCount {
    final text = _bodyCtrl.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  bool get _overLimit => _wordCount > _maxWords;

  bool get _canPublish =>
      _titleCtrl.text.trim().isNotEmpty &&
      _bodyCtrl.text.trim().isNotEmpty &&
      !_overLimit;

  void _addTag(String raw) {
    final tag = raw.trim().toLowerCase().replaceAll(' ', '-');
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagCtrl.clear();
    });
  }

  Future<void> _publish() async {
    if (!_canPublish) return;
    if (_overLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Story is too long. Max $_maxWords words (currently $_wordCount).'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (_isEditing) {
        final updated = widget.editing!.copyWith(
          title: _titleCtrl.text.trim(),
          content: _bodyCtrl.text.trim(),
          tags: _tags,
        );
        await FirestoreService.updateBlog(updated);
      } else {
        final post = BlogPost(
          id: 'blog_${DateTime.now().microsecondsSinceEpoch}',
          title: _titleCtrl.text.trim(),
          content: _bodyCtrl.text.trim(),
          authorId: user.uid,
          authorName: user.displayName ?? user.email ?? 'Parent',
          authorPhotoUrl: user.photoURL,
          createdAt: DateTime.now(),
          tags: _tags,
        );
        await FirestoreService.createBlog(post);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Story updated!' : 'Story published! Thanks for sharing.',
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } catch (e, st) {
      debugPrint('Publish error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
          color: const Color(0xFF1A1A2E),
        ),
        title: Text(
          _isEditing ? 'Edit story' : 'Write a story',
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: (_canPublish && !_saving) ? _publish : null,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isEditing ? 'Update' : 'Publish',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.viewInsetsOf(context).bottom + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextField(
                controller: _titleCtrl,
                maxLength: 120,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    height: 1.3),
                decoration: InputDecoration(
                  hintText: 'Story title…',
                  hintStyle: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade300),
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 8),

              // Body field
              TextField(
                controller: _bodyCtrl,
                maxLines: null,
                minLines: 12,
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                    height: 1.65),
                decoration: InputDecoration(
                  hintText:
                      'Share a tip, trick, or story about raising your little one…',
                  hintStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade400,
                      height: 1.65),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              ),
              // Word count indicator
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_wordCount / $_maxWords words',
                  style: TextStyle(
                    fontSize: 11,
                    color: _overLimit
                        ? Colors.red.shade400
                        : Colors.grey.shade400,
                    fontWeight: _overLimit
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (_overLimit)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Over the $_maxWords-word limit — please shorten your story.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.red.shade400),
                  ),
                ),
              const SizedBox(height: 16),

              // Tags section
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tag_rounded,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text('Tags',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _tags
                            .map((t) => GestureDetector(
                                  onTap: () => setState(() => _tags.remove(t)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Color.lerp(Colors.white, accent, 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: accent.withAlpha(60)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('#$t',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: accent,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.close_rounded,
                                            size: 12, color: accent),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tagCtrl,
                      decoration: InputDecoration(
                        hintText: 'Add a tag and press Enter',
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 4),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: _addTag,
                    ),
                    // Suggested tags
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _suggestedTags
                          .where((t) => !_tags.contains(t))
                          .map((t) => GestureDetector(
                                onTap: () => _addTag(t),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '+ $t',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tags help other parents discover your story.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
