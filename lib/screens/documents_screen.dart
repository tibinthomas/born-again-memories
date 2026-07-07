import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/baby_document.dart';
import '../models/kid_profile.dart';
import '../providers/profiles_provider.dart';
import '../services/local_storage_service.dart';
import '../utils/profile_theme.dart';
import '../utils/date_formatter.dart';
import '../utils/profile_theme.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

class DocumentsScreen extends ConsumerStatefulWidget {
  final int profileIndex;

  const DocumentsScreen({super.key, required this.profileIndex});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  DocumentCategory? _selectedCategory;
  bool _showFavoritesOnly = false;
  bool _showSearch = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(profilesProvider) ?? [];
    if (profiles.isEmpty || widget.profileIndex >= profiles.length) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profile = profiles[widget.profileIndex];
    final theme = ProfileTheme.forProfile(profile);
    final docs = [...profile.documents]
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    final q = _searchQuery.toLowerCase();
    final filtered = docs.where((d) {
      final matchesSearch = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.notes?.toLowerCase().contains(q) == true;
      final matchesCategory = _selectedCategory == null || d.category == _selectedCategory;
      final matchesFavorite = !_showFavoritesOnly || d.isFavorite;
      return matchesSearch && matchesCategory && matchesFavorite;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: CustomScrollView(
        slivers: [
          _Header(
            profile: profile,
            theme: theme,
            showSearch: _showSearch,
            onSearchToggle: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                  _searchFocus.unfocus();
                } else {
                  Future.delayed(const Duration(milliseconds: 180),
                      () => _searchFocus.requestFocus());
                }
              });
            },
          ),

          // Search bar (hidden by default)
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _showSearch
                  ? Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search name or notes…',
                            hintStyle: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: Colors.grey.shade400, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
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
                              borderSide:
                                  BorderSide(color: theme.accent, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Category filter
          if (docs.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  children: [
                    _CategoryChip(
                      label: 'All',
                      selected: _selectedCategory == null && !_showFavoritesOnly,
                      color: theme.accent,
                      onTap: () => setState(() {
                        _selectedCategory = null;
                        _showFavoritesOnly = false;
                      }),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _CategoryChip(
                        label: '★ Favourites',
                        selected: _showFavoritesOnly,
                        color: const Color(0xFFFBBF24),
                        onTap: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                      ),
                    ),
                    ...DocumentCategory.values.map((cat) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _CategoryChip(
                            label: '${cat.emoji} ${cat.label}',
                            selected: _selectedCategory == cat,
                            color: cat.color,
                            onTap: () => setState(() =>
                                _selectedCategory =
                                    _selectedCategory == cat ? null : cat),
                          ),
                        )),
                  ],
                ),
              ),
            ),

          if (docs.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(theme: theme, kidName: profile.name),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_list_off,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      _showFavoritesOnly
                          ? 'No favourite documents yet'
                          : 'No ${_selectedCategory?.label ?? ''} documents yet',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedCategory = null;
                        _showFavoritesOnly = false;
                      }),
                      child: const Text('Show all'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (ctx, i) => _DocumentCard(
                  doc: filtered[i],
                  theme: theme,
                  profileIndex: widget.profileIndex,
                ),
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
            onTap: () => _showAddSheet(context, theme, widget.profileIndex),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file_outlined, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Add Document',
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

  static void _showAddSheet(
      BuildContext context, ProfileTheme theme, int profileIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DocumentSheet(profileIndex: profileIndex, theme: theme),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final KidProfile profile;
  final ProfileTheme theme;
  final bool showSearch;
  final VoidCallback onSearchToggle;

  const _Header({
    required this.profile,
    required this.theme,
    required this.showSearch,
    required this.onSearchToggle,
  });

  @override
  Widget build(BuildContext context) {
    final count = profile.documents.length;
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 52,
      backgroundColor: theme.accent,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: Icon(
            showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            color: Colors.white,
          ),
          onPressed: onSearchToggle,
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
                  '${profile.name}\'s Documents',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count document${count == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : color.withAlpha(50), width: 1),
          boxShadow: [
            BoxShadow(
              color: selected ? color.withAlpha(50) : Colors.black.withAlpha(8),
              blurRadius: selected ? 8 : 3,
              offset: const Offset(0, 2),
            ),
          ],
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

// ── Document card ─────────────────────────────────────────────────────────────

class _DocumentCard extends ConsumerWidget {
  final BabyDocument doc;
  final ProfileTheme theme;
  final int profileIndex;

  const _DocumentCard({
    required this.doc,
    required this.theme,
    required this.profileIndex,
  });

  Color get _catColor => doc.category.color;

  Future<void> _open(BuildContext context) async {
    if (kIsWeb) {
      if (doc.webBytes != null && doc.isImage) {
        _showImageViewer(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('File viewing is not supported on web after reload.')),
      );
      return;
    }

    if (doc.localPath.isEmpty || !File(doc.localPath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'File not found on this device. It may have been added on another device.')),
      );
      return;
    }

    if (doc.isImage) {
      _showImageViewer(context);
      return;
    }

    try {
      final uri = Uri.file(doc.localPath);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'No app found to open ${doc.name}. File is saved at: ${doc.localPath}')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open ${doc.name}.')),
        );
      }
    }
  }

  void _showImageViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(doc.name,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          body: InteractiveViewer(
            child: Center(
              child: doc.webBytes != null
                  ? Image.memory(doc.webBytes!, fit: BoxFit.contain)
                  : Image.file(File(doc.localPath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileExists =
        !kIsWeb && doc.localPath.isNotEmpty && File(doc.localPath).existsSync();
    final isAvailable = kIsWeb ? (doc.webBytes != null) : fileExists;

    return Dismissible(
      key: ValueKey(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete document?'),
          content: Text('Remove "${doc.name}"? The local file will also be deleted.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        // Delete local file
        if (!kIsWeb && doc.localPath.isNotEmpty) {
          LocalStorageService.delete(doc.localPath);
        }
        ref
            .read(profilesProvider.notifier)
            .deleteDocument(profileIndex, doc.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
              SnackBar(content: Text('"${doc.name}" deleted')));
      },
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _catColor.withAlpha(22), width: 1),
            boxShadow: [
              BoxShadow(
                color: _catColor.withAlpha(18),
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
          child: Stack(
            children: [
              // Left rail
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                width: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: ColoredBox(color: _catColor),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File type icon
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _catColor.withAlpha(30),
                            _catColor.withAlpha(18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _catColor.withAlpha(50), width: 0.8),
                      ),
                      child: Icon(doc.typeIcon, color: _catColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _catColor.withAlpha(18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${doc.category.emoji} ${doc.category.label}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _catColor,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                doc.formattedSize,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 11, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                formatDate(doc.dateAdded),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500),
                              ),
                              if (!isAvailable) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.cloud_off_outlined,
                                    size: 11, color: Colors.orange.shade400),
                                const SizedBox(width: 3),
                                Text(
                                  'Not on this device',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade400),
                                ),
                              ],
                            ],
                          ),
                          if (doc.notes != null && doc.notes!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              doc.notes!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Favorite + open arrow column
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => ref
                              .read(profilesProvider.notifier)
                              .toggleDocumentFavorite(profileIndex, doc.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 22,
                            color: doc.isFavorite
                                ? const Color(0xFFFBBF24)
                                : _catColor.withAlpha(120),
                          ),
                        ),
                        if (isAvailable) ...[
                          const SizedBox(height: 8),
                          Icon(Icons.open_in_new_outlined,
                              size: 18, color: _catColor.withAlpha(180)),
                        ],
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ProfileTheme theme;
  final String kidName;

  const _EmptyState({required this.theme, required this.kidName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.soft,
                boxShadow: [
                  BoxShadow(
                      color: theme.accent.withAlpha(40),
                      blurRadius: 24,
                      spreadRadius: 4)
                ],
              ),
              child: const Center(
                  child: Text('🗂️', style: TextStyle(fontSize: 42))),
            ),
            const SizedBox(height: 24),
            Text(
              'No documents yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800),
            ),
            const SizedBox(height: 10),
            Text(
              'Store ${kidName.split(' ').first}\'s birth certificate,\nvaccination records, insurance cards\nand more — all in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey.shade500, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add document sheet ────────────────────────────────────────────────────────

class _DocumentSheet extends ConsumerStatefulWidget {
  final int profileIndex;
  final ProfileTheme theme;

  const _DocumentSheet({required this.profileIndex, required this.theme});

  @override
  ConsumerState<_DocumentSheet> createState() => _DocumentSheetState();
}

class _DocumentSheetState extends ConsumerState<_DocumentSheet> {
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DocumentCategory _category = DocumentCategory.other;
  PlatformFile? _pickedFile;
  bool _saving = false;
  String? _error;
  List<int> _selectedProfileIndices = [];

  @override
  void initState() {
    super.initState();
    _selectedProfileIndices = [widget.profileIndex]; // Default to current profile
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _pickedFile = file;
      _error = null;
      if (_nameCtrl.text.isEmpty) {
        final dot = file.name.lastIndexOf('.');
        _nameCtrl.text =
            dot > 0 ? file.name.substring(0, dot) : file.name;
      }
      // Auto-detect category from filename keywords
      final lower = file.name.toLowerCase();
      if (lower.contains('vaccine') || lower.contains('vaccination') || lower.contains('immuniz')) {
        _category = DocumentCategory.vaccination;
      } else if (lower.contains('insurance')) {
        _category = DocumentCategory.insurance;
      } else if (lower.contains('birth') || lower.contains('certificate') || lower.contains('passport')) {
        _category = DocumentCategory.legal;
      } else if (lower.contains('school') || lower.contains('daycare') || lower.contains('edu')) {
        _category = DocumentCategory.education;
      } else if (lower.contains('medical') || lower.contains('hospital') || lower.contains('report')) {
        _category = DocumentCategory.medical;
      }
    });
  }

  String _guessMimeType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    return switch (ext) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'doc' || 'docx' => 'application/msword',
      'xls' || 'xlsx' => 'application/vnd.ms-excel',
      'txt' => 'text/plain',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'wav' => 'audio/wav',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _save() async {
    if (_pickedFile == null) {
      setState(() => _error = 'Please select a file first');
      return;
    }
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    setState(() { _saving = true; _error = null; });

    String localPath = '';
    Uint8List? webBytes;

    if (kIsWeb) {
      webBytes = _pickedFile!.bytes;
    } else if (_pickedFile!.path != null) {
      try {
        final safeFilename =
            '${DateTime.now().microsecondsSinceEpoch}_${_pickedFile!.name.replaceAll(RegExp(r'[^\w.]'), '_')}';
        localPath = await LocalStorageService.copyDocumentToStorage(
          _pickedFile!.path!,
          safeFilename,
        );
      } catch (_) {
        localPath = _pickedFile!.path!;
      }
    }

    final doc = BabyDocument(
      id: 'doc_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      category: _category,
      dateAdded: DateTime.now(),
      localPath: localPath,
      mimeType: _guessMimeType(_pickedFile!.name),
      sizeBytes: _pickedFile!.size,
      webBytes: webBytes,
    );

    if (_selectedProfileIndices.length == 1) {
      await ref.read(profilesProvider.notifier).addDocument(_selectedProfileIndices.first, doc);
    } else {
      await ref.read(profilesProvider.notifier).addDocumentToProfiles(_selectedProfileIndices, doc);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pTheme = widget.theme;
    final inputDeco = InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: pTheme.accent, width: 1.5)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 18),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: pTheme.soft),
                  child: Icon(Icons.upload_file_outlined,
                      color: pTheme.accent, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Add Document',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937))),
              ],
            ),
            const SizedBox(height: 22),

            // Profile selection
            _label('Add to Profiles'),
            const SizedBox(height: 8),
            _ProfileSelector(
              selectedIndices: _selectedProfileIndices,
              onSelectionChanged: (indices) => setState(() => _selectedProfileIndices = indices),
              theme: pTheme,
            ),
            const SizedBox(height: 18),

            // File picker
            GestureDetector(
              onTap: _pickedFile == null ? _pickFile : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _pickedFile != null
                      ? pTheme.accent.withAlpha(12)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pickedFile != null
                        ? pTheme.accent.withAlpha(120)
                        : Colors.grey.shade200,
                    width: _pickedFile != null ? 1.5 : 1,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: _pickedFile == null
                    ? Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 36, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to select a file',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600)),
                          const SizedBox(height: 4),
                          Text('PDF, images, Word, or any file',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade400)),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            BabyDocument(
                              id: '',
                              name: _pickedFile!.name,
                              category: _category,
                              dateAdded: DateTime.now(),
                              localPath: '',
                              mimeType: '',
                              sizeBytes: 0,
                            ).typeIcon,
                            color: pTheme.accent,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFile!.name,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: pTheme.accent),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatBytes(_pickedFile!.size),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _pickFile,
                            child: Text('Change',
                                style: TextStyle(
                                    color: pTheme.accent, fontSize: 12)),
                          ),
                        ],
                      ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 18),

            // Name
            _label('Name'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: inputDeco.copyWith(hintText: 'e.g. Vaccination Record 2024'),
            ),
            const SizedBox(height: 18),

            // Category
            _label('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DocumentCategory.values.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? cat.color : cat.color.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? cat.color : cat.color.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sel ? Colors.white : cat.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Notes
            _label('Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: inputDeco.copyWith(
                  hintText: 'e.g. 6-month checkup, Dr. Smith'),
            ),
            const SizedBox(height: 28),

            // Save
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: pTheme.accent,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Document',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700),
      );

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Profile selector ──────────────────────────────────────────────────────────

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
        // All profiles option
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
        // Individual profiles
        ...profiles.asMap().entries.map((entry) {
          final index = entry.key;
          final profile = entry.value;
          final selected = selectedIndices.contains(index);
          return GestureDetector(
            onTap: () {
              final newSelection = List<int>.from(selectedIndices);
              if (selected) {
                newSelection.remove(index);
                if (newSelection.isEmpty) newSelection.add(index); // Keep at least one
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
