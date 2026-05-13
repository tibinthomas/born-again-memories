import 'dart:async';
import 'dart:ui';

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
  bool _showFavoritesOnly = false;
  bool _showSearch = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
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
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty || _selectedTag != null || _showFavoritesOnly;

  void _clearAllFilters() {
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchQuery = '';
      _selectedTag = null;
      _showFavoritesOnly = false;
      _showSearch = false;
      _resetPagination();
    });
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

    final filtered = allLinks.where((link) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          link.title.toLowerCase().contains(query) ||
          link.description?.toLowerCase().contains(query) == true;
      final matchesTag = _selectedTag == null || link.tags.contains(_selectedTag);
      final matchesFavorite = !_showFavoritesOnly || link.isFavorite;
      return matchesSearch && matchesTag && matchesFavorite;
    }).toList();

    final visibleLinks = filtered.take(_loadedItemCount).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 52,
            backgroundColor: theme.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      _searchQuery = '';
                      _searchFocus.unfocus();
                      _resetPagination();
                    } else {
                      Future.delayed(const Duration(milliseconds: 180),
                          () => _searchFocus.requestFocus());
                    }
                  });
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: BoxDecoration(gradient: theme.headerGradient),
              ),
            ),
            title: Row(
              children: [
                Text('${theme.decalEmoji} ', style: const TextStyle(fontSize: 18)),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${profile.name}\'s Links',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${profile.links.length} link${profile.links.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search bar (hidden by default) ──────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: _showSearch
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 38,
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocus,
                                    onChanged: (value) => setState(() {
                                      _searchQuery = value;
                                      _resetPagination();
                                    }),
                                    decoration: InputDecoration(
                                      hintText: 'Search title or note…',
                                      hintStyle: TextStyle(
                                          color: Colors.grey.shade400, fontSize: 13),
                                      prefixIcon: Icon(Icons.search_rounded,
                                          color: Colors.grey.shade400, size: 18),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? GestureDetector(
                                              onTap: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchQuery = '';
                                                  _resetPagination();
                                                });
                                              },
                                              child: Icon(Icons.cancel_rounded,
                                                  color: Colors.grey.shade400, size: 16),
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: const Color(0xFFEFEFF4),
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: theme.accent, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                                if (allLinks.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 32,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        _TagChip(
                                          label: 'Favourites',
                                          icon: Icons.star_rounded,
                                          selected: _showFavoritesOnly,
                                          color: const Color(0xFFF59E0B),
                                          onTap: () => setState(() {
                                            _showFavoritesOnly = !_showFavoritesOnly;
                                            _resetPagination();
                                          }),
                                        ),
                                        if (allTags.isNotEmpty) ...[
                                          const _FilterDivider(),
                                          ...allTags.map((tag) => Padding(
                                                padding:
                                                    const EdgeInsets.only(right: 8),
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
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Active filter bar: count + clear ────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _hasActiveFilters
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.filter_list_rounded, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(
                                  '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _clearAllFilters,
                                  child: Row(
                                    children: [
                                      Text(
                                        'Clear all',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(Icons.close_rounded, size: 13, color: theme.accent),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(height: 10),
                  ),
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
                    if (_hasActiveFilters)
                      TextButton(
                        onPressed: _clearAllFilters,
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
                    onFavorite: () => ref.read(profilesProvider.notifier).toggleLinkFavorite(widget.profileIndex, link.id),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: theme.headerGradient,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withAlpha(80), width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.accent.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          child: InkWell(
            borderRadius: BorderRadius.circular(32),
            onTap: () => _showAddEditSheet(context, theme, widget.profileIndex),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_link_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('New link',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
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
  final IconData? icon;

  const _TagChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : color.withAlpha(50),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? color.withAlpha(50)
                  : Colors.black.withAlpha(8),
              blurRadius: selected ? 8 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12,
                  color: selected ? Colors.white : color.withAlpha(180)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDivider extends StatelessWidget {
  const _FilterDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Center(
        child: Container(
          width: 1,
          height: 16,
          color: Colors.grey.shade300,
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
  final VoidCallback onFavorite;

  const _LinkCard({
    required this.link,
    required this.theme,
    required this.profileIndex,
    required this.onDelete,
    required this.onEdit,
    required this.onFavorite,
  });

  Future<void> _openLink(BuildContext context, {bool external = false}) async {
    final uri = Uri.tryParse(link.url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL.')),
      );
      return;
    }

    final mode = external ? LaunchMode.externalApplication : LaunchMode.inAppBrowserView;
    final launched = await launchUrl(uri, mode: mode);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = link.previewImageUrl != null && link.previewImageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.accent.withAlpha(18), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openLink(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Preview image ─────────────────────────────────────────
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  link.previewImageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: domain + star + menu ─────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Favicon-style domain pill
                      Expanded(
                        child: Text(
                          link.domain,
                          style: TextStyle(
                            color: theme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _FavButton(
                        isFavorite: link.isFavorite,
                        accent: theme.accent,
                        onTap: onFavorite,
                      ),
                      const SizedBox(width: 2),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_horiz_rounded,
                            size: 20, color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'open_external',
                            child: Row(children: [
                              Icon(Icons.open_in_browser_outlined, size: 16),
                              SizedBox(width: 10),
                              Text('Open in browser'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'open_external') {
                            _openLink(context, external: true);
                          } else if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete link?'),
                                content: Text(
                                    'Remove "${link.title}" from saved links?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel')),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
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

                  const SizedBox(height: 6),

                  // ── Title ─────────────────────────────────────────────
                  Text(
                    link.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // ── Description ───────────────────────────────────────
                  if ((link.previewDescription ?? link.description) != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      link.previewDescription ?? link.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4),
                    ),
                  ],

                  // ── Footer: tags + date ───────────────────────────────
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (link.tags.isNotEmpty) ...[
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 0,
                            children: link.tags
                                .take(3)
                                .map((tag) => Text(
                                      '#$tag',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.accent.withAlpha(180),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ] else
                        const Spacer(),
                      Text(
                        formatDate(link.dateAdded),
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}

class _FavButton extends StatelessWidget {
  final bool isFavorite;
  final Color accent;
  final VoidCallback onTap;

  const _FavButton({
    required this.isFavorite,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFavorite
              ? const Color(0xFFFBBF24).withAlpha(22)
              : Colors.grey.shade100,
        ),
        child: Icon(
          isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 18,
          color: isFavorite ? const Color(0xFFFBBF24) : Colors.grey.shade400,
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
  List<int> _selectedProfileIndices = [];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initial?.url ?? '');
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descriptionController = TextEditingController(text: widget.initial?.description ?? '');
    _tagController = TextEditingController();
    _tags = widget.initial?.tags.toList() ?? [];
    _selectedProfileIndices = [widget.profileIndex]; // Default to current profile
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
            if (!isEditing) ...[
              _ProfileSelector(
                selectedIndices: _selectedProfileIndices,
                onSelectionChanged: (indices) => setState(() => _selectedProfileIndices = indices),
                theme: widget.theme,
              ),
              const SizedBox(height: 12),
            ],
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
                        if (_selectedProfileIndices.length == 1) {
                          ref.read(profilesProvider.notifier).addLink(_selectedProfileIndices.first, item);
                        } else {
                          ref.read(profilesProvider.notifier).addLinkToProfiles(_selectedProfileIndices, item);
                        }
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

class _ProfileSelector extends ConsumerWidget {
  final List<int> selectedIndices;
  final ValueChanged<List<int>> onSelectionChanged;
  final ProfileTheme theme;

  const _ProfileSelector({
    required this.selectedIndices,
    required this.onSelectionChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider) ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        GestureDetector(
          onTap: () {
            final allIndices = List.generate(profiles.length, (i) => i);
            onSelectionChanged(allIndices);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selectedIndices.length == profiles.length ? theme.accent : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selectedIndices.length == profiles.length ? theme.accent : Colors.grey.shade200,
              ),
            ),
            child: Text(
              'All Profiles',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selectedIndices.length == profiles.length ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        ),
        ...profiles.asMap().entries.map((entry) {
          final index = entry.key;
          final profile = entry.value;
          final selected = selectedIndices.contains(index);
          return GestureDetector(
            onTap: () {
              final newSelection = List<int>.from(selectedIndices);
              if (selected) {
                newSelection.remove(index);
                if (newSelection.isEmpty) newSelection.add(index);
              } else {
                newSelection.add(index);
              }
              onSelectionChanged(newSelection);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? ProfileTheme.forProfile(profile).accent : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? ProfileTheme.forProfile(profile).accent : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ProfileTheme.forProfile(profile).decalEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
