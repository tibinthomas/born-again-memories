import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/google_photos_service.dart';

class GooglePhotosPicker extends ConsumerStatefulWidget {
  const GooglePhotosPicker({super.key});

  static Future<List<GooglePhotoItem>?> open(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).push<List<GooglePhotoItem>>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const GooglePhotosPicker(),
        ),
      );

  @override
  ConsumerState<GooglePhotosPicker> createState() => _GooglePhotosPickerState();
}

class _GooglePhotosPickerState extends ConsumerState<GooglePhotosPicker> {
  final List<GooglePhotoItem> _items = [];
  final Set<String> _selectedIds = {};
  final ScrollController _scrollController = ScrollController();

  List<GooglePhotoAlbum> _albums = [];
  String? _selectedAlbumId;
  String? _nextPageToken;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gs = ref.read(authServiceProvider).googleSignIn;
      final (items: items, nextPageToken: token) =
          await GooglePhotosService.listMediaItems(gs, albumId: _selectedAlbumId);
      final albums = _albums.isEmpty
          ? await GooglePhotosService.listAlbums(gs)
          : _albums;
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _nextPageToken = token;
        _albums = albums;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextPageToken == null) return;
    setState(() => _loadingMore = true);
    try {
      final gs = ref.read(authServiceProvider).googleSignIn;
      final (items: more, nextPageToken: token) =
          await GooglePhotosService.listMediaItems(
        gs,
        pageToken: _nextPageToken,
        albumId: _selectedAlbumId,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(more);
        _nextPageToken = token;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _selectAlbum(String? albumId) {
    setState(() {
      _selectedAlbumId = albumId;
      _items.clear();
      _nextPageToken = null;
    });
    _load();
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _done() {
    final selected = _items.where((i) => _selectedIds.contains(i.id)).toList();
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _selectedIds.length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.photo_library_rounded, size: 20),
            const SizedBox(width: 8),
            const Text('Google Photos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: count == 0 ? null : _done,
            child: Text(
              count == 0 ? 'Add' : 'Add ($count)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: count == 0 ? null : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_albums.isNotEmpty) _buildAlbumBar(theme),
          Expanded(child: _buildGrid(theme)),
        ],
      ),
    );
  }

  Widget _buildAlbumBar(ThemeData theme) {
    return Container(
      height: 44,
      color: theme.colorScheme.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _AlbumChip(
            label: 'All Photos',
            isSelected: _selectedAlbumId == null,
            theme: theme,
            onTap: () => _selectAlbum(null),
          ),
          ..._albums.map((a) => _AlbumChip(
                label: a.title,
                isSelected: _selectedAlbumId == a.id,
                theme: theme,
                onTap: () => _selectAlbum(a.id),
              )),
        ],
      ),
    );
  }

  Widget _buildGrid(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 52, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Could not load photos',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure you granted access to Google Photos.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text('No photos found',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _items.length + (_loadingMore ? 3 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return Container(color: Colors.grey.shade200);
        }
        final item = _items[index];
        final selected = _selectedIds.contains(item.id);
        return GestureDetector(
          onTap: () => _toggle(item.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item.thumbnailUrl,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(color: Colors.grey.shade200),
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.grey.shade400),
                ),
              ),
              if (item.isVideo)
                const Positioned(
                  bottom: 4,
                  left: 4,
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 22,
                      shadows: [Shadow(blurRadius: 4)]),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                color: selected
                    ? theme.colorScheme.primary.withAlpha(60)
                    : Colors.transparent,
              ),
              Positioned(
                top: 5,
                right: 5,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 120),
                  child: selected
                      ? CircleAvatar(
                          key: const ValueKey(true),
                          radius: 12,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(Icons.check,
                              size: 14, color: Colors.white),
                        )
                      : Container(
                          key: const ValueKey(false),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                            color: Colors.black26,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlbumChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _AlbumChip({
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
