import 'dart:async';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/kid_profile.dart';
import '../models/saved_link.dart';
import '../providers/profiles_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/profile_theme.dart';

class SavedLinksScreen extends ConsumerStatefulWidget {
  final int profileIndex;

  const SavedLinksScreen({super.key, required this.profileIndex});

  static void push(BuildContext context, int profileIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedLinksScreen(profileIndex: profileIndex),
      ),
    );
  }

  @override
  ConsumerState<SavedLinksScreen> createState() => _SavedLinksScreenState();
}

class _SavedLinksScreenState extends ConsumerState<SavedLinksScreen> {
  String _searchQuery = '';
  String? _selectedTag;
  int? _selectedYear;
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 12;
  int _loadedItemCount = 12;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 180 && !_isLoadingMore) {
      _loadMore();
    }
  }

  void _resetPagination() {
    setState(() {
      _loadedItemCount = _pageSize;
      _isLoadingMore = false;
    });
  }

  void _loadMore() {
    setState(() {
      _isLoadingMore = true;
      _loadedItemCount += _pageSize;
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider) ?? [];
    if (profiles.isEmpty || widget.profileIndex >= profiles.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profile = profiles[widget.profileIndex];
    final theme = ProfileTheme.forProfile(profile);
    final allLinks = profile.links;
    final allTags = ({for (final link in allLinks) ...link.tags}).toList()..sort();
    final allYears = ({for (final link in allLinks) link.dateAdded.year}).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    final filtered = allLinks.where((link) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          link.title.toLowerCase().contains(query) ||
          link.description?.toLowerCase().contains(query) == true ||
          link.url.toLowerCase().contains(query) ||
          link.tags.any((tag) => tag.toLowerCase().contains(query));
      final matchesTag = _selectedTag == null || link.tags.contains(_selectedTag);
      final matchesYear = _selectedYear == null || link.dateAdded.year == _selectedYear;
      return matchesSearch && matchesTag && matchesYear;
    }).toList();

    final visibleLinks = filtered.take(_loadedItemCount).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('${profile.name}\'s Saved Links'),
        backgroundColor: theme.accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAddEditSheet(context, theme, widget.profileIndex),
            icon: const Icon(Icons.add_link_outlined),
            tooltip: 'Save link',
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _resetPagination();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search links…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: theme.accent, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          if (allYears.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  children: [
                    _TagChip(
                      label: 'All years',
                      selected: _selectedYear == null,
                      color: theme.accent,
                      onTap: () => setState(() {
                        _selectedYear = null;
                        _resetPagination();
                      }),
                    ),
                    ...allYears.map((year) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _TagChip(
                            label: '$year',
                            selected: _selectedYear == year,
                            color: theme.accent,
                            onTap: () => setState(() {
                              _selectedYear = _selectedYear == year ? null : year;
                              _resetPagination();
                            }),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          if (allTags.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  children: [
                    _TagChip(
                      label: 'All tags',
                      selected: _selectedTag == null,
                      color: theme.accent,
                      onTap: () => setState(() {
                        _selectedTag = null;
                        _resetPagination();
                      }),
                    ),
                    ...allTags.map((tag) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _TagChip(
                            label: '#$tag',
                            selected: _selectedTag == tag,
                            color: theme.accent,
                            onTap: () => setState(() {
                              _selectedTag = _selectedTag == tag ? null : tag;
                              _resetPagination();
                            }),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          if (allLinks.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(theme: theme, profile: profile),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('No saved links found', style: TextStyle(color: Colors.grey.shade600)),
                    if (_selectedTag != null || _selectedYear != null)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedTag = null;
                          _selectedYear = null;
                          _resetPagination();
                        }),
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.separated(
                itemCount: visibleLinks.length + (visibleLinks.length < filtered.length ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index >= visibleLinks.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    );
                  }
                  final link = visibleLinks[index];
                  return _LinkCard(
                    link: link,
                    theme: theme,
                    profileIndex: widget.profileIndex,
                    onDelete: () => ref.read(profilesProvider.notifier).deleteLink(widget.profileIndex, link.id),
                    onEdit: () => _showAddEditSheet(context, theme, widget.profileIndex, initial: link),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(context, theme, widget.profileIndex),
        backgroundColor: theme.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New link'),
      ),
    );
  }

  Future<void> _showAddEditSheet(
    BuildContext context,
    ProfileTheme theme,
    int profileIndex, {
    SavedLink? initial,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LinkFormSheet(
        profileIndex: profileIndex,
        theme: theme,
        initial: initial,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : color.withAlpha(60)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ProfileTheme theme;
  final KidProfile profile;

  const _EmptyState({required this.theme, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              'Save URLs, Instagram posts, articles and more so you can open them later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: theme.accent),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkCard extends ConsumerWidget {
  final SavedLink link;
  final ProfileTheme theme;
  final int profileIndex;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _LinkCard({
    required this.link,
    required this.theme,
    required this.profileIndex,
    required this.onDelete,
    required this.onEdit,
  });

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openLink(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (link.previewImageUrl != null && link.previewImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  link.previewImageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          link.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete link?'),
                                content: Text('Remove "${link.title}" from saved links?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                  FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ).then((confirmed) {
                              if (confirmed == true) onDelete();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(link.domain, style: TextStyle(color: theme.accent, fontSize: 12)),
                  if (link.previewTitle != null && link.previewTitle!.isNotEmpty && link.previewTitle != link.title) ...[
                    const SizedBox(height: 8),
                    Text(link.previewTitle!, style: TextStyle(fontSize: 14, color: Colors.grey.shade800)),
                  ],
                  if (link.previewDescription != null && link.previewDescription!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(link.previewDescription!, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                  if (link.description != null && link.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(link.description!, style: TextStyle(color: Colors.grey.shade600)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: link.tags
                        .map((tag) => Chip(
                              label: Text('#$tag'),
                              backgroundColor: theme.accent.withAlpha(20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatDate(link.dateAdded),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkFormSheet extends ConsumerStatefulWidget {
  final int profileIndex;
  final ProfileTheme theme;
  final SavedLink? initial;

  const _LinkFormSheet({
    super.key,
    required this.profileIndex,
    required this.theme,
    this.initial,
  });

  @override
  ConsumerState<_LinkFormSheet> createState() => _LinkFormSheetState();
}

class _LinkFormSheetState extends ConsumerState<_LinkFormSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;
  List<String> _tags = [];
  Metadata? _previewData;
  bool _previewLoading = false;
  bool _previewError = false;
  String _previewErrorText = '';
  Timer? _previewDebounce;
  bool _autoFilled = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initial?.url ?? '');
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initial?.description ?? '');
    _tagController = TextEditingController();
    _tags = widget.initial?.tags.toList() ?? [];
    if (_urlController.text.isNotEmpty) {
      _schedulePreviewFetch(_urlController.text);
    }
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags = [..._tags, tag];
      _tagController.clear();
    });
  }

  void _schedulePreviewFetch(String value) {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 500), () {
      _resolvePreviewMetadata(value);
    });
  }

  Future<void> _resolvePreviewMetadata(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _previewLoading = false;
        _previewData = null;
        _previewError = false;
        _previewErrorText = '';
      });
      return;
    }

    if (!AnyLinkPreview.isValidLink(trimmed, protocols: ['http', 'https'])) {
      setState(() {
        _previewLoading = false;
        _previewData = null;
        _previewError = true;
        _previewErrorText = 'Enter a valid web link starting with http:// or https://';
      });
      return;
    }

    setState(() {
      _previewLoading = true;
      _previewError = false;
      _previewErrorText = '';
      _previewData = null;
    });

    try {
      final metadata = await AnyLinkPreview.getMetadata(
        link: trimmed,
        cache: const Duration(hours: 4),
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      );
      if (!mounted) return;
      if (metadata == null || !metadata.hasData) {
        setState(() {
          _previewLoading = false;
          _previewError = true;
          _previewErrorText = 'Unable to fetch preview for this link. Please verify the URL.';
          _previewData = null;
        });
        return;
      }
      setState(() {
        _previewLoading = false;
        _previewError = false;
        _previewErrorText = '';
        _previewData = metadata;
        if (!_autoFilled && widget.initial == null) {
          if (_titleController.text.trim().isEmpty && metadata.title?.isNotEmpty == true) {
            _titleController.text = metadata.title!;
          }
          if (_descriptionController.text.trim().isEmpty && metadata.desc?.isNotEmpty == true) {
            _descriptionController.text = metadata.desc!;
          }
          _autoFilled = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _previewError = true;
        _previewErrorText = 'Unable to fetch preview for this link. Please try a different URL.';
      });
    }
  }

  Widget _buildPreviewSection() {
    if (_previewLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const CircularProgressIndicator(strokeWidth: 2.4),
            const SizedBox(width: 14),
            Expanded(child: Text('Fetching preview...', style: TextStyle(color: Colors.grey.shade700))),
          ],
        ),
      );
    }

    if (_previewError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text(_previewErrorText, style: const TextStyle(color: Colors.red))),
          ],
        ),
      );
    }

    if (_previewData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_previewData!.image != null && _previewData!.image!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                _previewData!.image!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_previewData!.title != null && _previewData!.title!.isNotEmpty)
                  Text(
                    _previewData!.title!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                if (_previewData!.desc != null && _previewData!.desc!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _previewData!.desc!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  Uri.tryParse(_urlController.text.trim())?.host.replaceFirst('www.', '') ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
    final canSave = _urlController.text.trim().isNotEmpty &&
        _titleController.text.trim().isNotEmpty &&
        !_previewLoading &&
        !_previewError &&
        _previewData != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEditing ? 'Edit saved link' : 'Save a new link',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      setState(() {
                        _previewData = null;
                        _previewError = false;
                        _previewErrorText = '';
                      });
                      _schedulePreviewFetch(value);
                    },
                    decoration: inputDecoration.copyWith(
                      labelText: 'Link URL',
                      hintText: 'https://instagram.com/...',
                    ),
                  ),
                  _buildPreviewSection(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _titleController,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Label',
                      hintText: 'Instagram post or article title',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Description',
                      hintText: 'Add your own note or summary',
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tagController,
                    decoration: inputDecoration.copyWith(
                      labelText: 'Add tag',
                      hintText: 'e.g. inspo',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addTag,
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags
                        .map((tag) => Chip(
                              label: Text('#$tag'),
                              onDeleted: () => setState(() => _tags = _tags.where((value) => value != tag).toList()),
                              backgroundColor: widget.theme.accent.withAlpha(20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Saved link tags are separate from memory tags.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: widget.theme.accent,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: canSave
                  ? () {
                      final url = _urlController.text.trim();
                      final title = _titleController.text.trim();
                      final item = SavedLink(
                        id: widget.initial?.id ?? 'link_${DateTime.now().microsecondsSinceEpoch}',
                        url: url,
                        title: title,
                        description: _descriptionController.text.trim().isEmpty
                            ? null
                            : _descriptionController.text.trim(),
                        tags: List.unmodifiable(_tags),
                        dateAdded: widget.initial?.dateAdded ?? DateTime.now(),
                        previewTitle: _previewData?.title,
                        previewDescription: _previewData?.desc,
                        previewImageUrl: _previewData?.image,
                      );
                      if (widget.initial == null) {
                        ref.read(profilesProvider.notifier).addLink(widget.profileIndex, item);
                      } else {
                        ref.read(profilesProvider.notifier).updateLink(widget.profileIndex, item);
                      }
                      Navigator.pop(context);
                    }
                  : null,
              child: Text(isEditing ? 'Save changes' : 'Add link'),
            ),
          ],
        ),
      ),
    );
  }
}
