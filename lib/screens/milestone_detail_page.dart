import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../utils/date_formatter.dart';
import '../utils/profile_theme.dart';

// ── Entry point ────────────────────────────────────────────────────────────────

class MilestoneDetailPage extends StatefulWidget {
  final List<Milestone> milestones;
  final int initialIndex;
  final KidProfile profile;

  const MilestoneDetailPage({
    super.key,
    required this.milestones,
    required this.initialIndex,
    required this.profile,
  });

  @override
  State<MilestoneDetailPage> createState() => _MilestoneDetailPageState();
}

class _MilestoneDetailPageState extends State<MilestoneDetailPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late int _currentIndex;

  // Slideshow
  bool _slideshowActive = false;
  bool _musicEnabled = true;
  Timer? _slideshowTimer;
  int _slideshowKey = 0; // incremented to reset progress bar tween

  // Music
  final AudioPlayer _musicPlayer = AudioPlayer();

  // Slideshow content fade
  late final AnimationController _contentFadeCtrl;
  late final Animation<double> _contentFade;

  Milestone get _current => widget.milestones[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _contentFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _contentFade =
        CurvedAnimation(parent: _contentFadeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideshowTimer?.cancel();
    _musicPlayer.dispose();
    _contentFadeCtrl.dispose();
    super.dispose();
  }

  // ── Slideshow control ──────────────────────────────────────────────────────

  Future<void> _startSlideshow() async {
    setState(() {
      _slideshowActive = true;
      _slideshowKey++;
    });
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _contentFadeCtrl.forward(from: 0);
    _scheduleNext();
    if (_musicEnabled) _fadeInMusic();
  }

  Future<void> _stopSlideshow() async {
    _slideshowTimer?.cancel();
    await _fadeOutMusic();
    _contentFadeCtrl.reverse();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) setState(() => _slideshowActive = false);
  }

  void _scheduleNext() {
    _slideshowTimer?.cancel();
    _slideshowTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_slideshowActive) return;
      final next = (_currentIndex + 1) % widget.milestones.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fadeInMusic() async {
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(0);
      // Place your lullaby at assets/music/lullaby.mp3 to enable music
      await _musicPlayer.play(AssetSource('music/lullaby.mp3'));
      for (int i = 1; i <= 10 && mounted && _slideshowActive; i++) {
        await Future.delayed(const Duration(milliseconds: 250));
        await _musicPlayer.setVolume(i * 0.05);
      }
    } catch (_) {
      // Music asset not found — slideshow continues silently
    }
  }

  Future<void> _fadeOutMusic() async {
    try {
      for (int i = 10; i >= 0; i--) {
        await _musicPlayer.setVolume(i * 0.05);
        await Future.delayed(const Duration(milliseconds: 80));
      }
      await _musicPlayer.stop();
    } catch (_) {}
  }

  void _onPageChanged(int i) {
    setState(() {
      _currentIndex = i;
      if (_slideshowActive) {
        _slideshowKey++;
        _scheduleNext();
        _contentFadeCtrl.forward(from: 0);
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pTheme = ProfileTheme.forProfile(widget.profile);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── PageView ───────────────────────────────────────────────────
            PageView.builder(
              controller: _pageController,
              itemCount: widget.milestones.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (_, i) => _MilestoneView(
                milestone: widget.milestones[i],
                profile: widget.profile,
                isSlideshow: _slideshowActive,
                contentFade: _contentFade,
              ),
            ),

            // ── Normal-mode chrome ─────────────────────────────────────────
            if (!_slideshowActive) ...[
              // Top bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      _GlassButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _GlassButton(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Slideshow',
                        onTap: _startSlideshow,
                      ),
                    ],
                  ),
                ),
              ),

              // Page position indicator
              if (widget.milestones.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).size.height * 0.47 + 8,
                  child: Center(
                    child: _PageDots(
                      count: widget.milestones.length,
                      currentIndex: _currentIndex,
                      accent: pTheme.accent,
                    ),
                  ),
                ),
            ],

            // ── Slideshow chrome ───────────────────────────────────────────
            if (_slideshowActive)
              _SlideshowChrome(
                milestone: _current,
                totalCount: widget.milestones.length,
                currentIndex: _currentIndex,
                slideshowKey: _slideshowKey,
                musicEnabled: _musicEnabled,
                contentFade: _contentFade,
                onStop: _stopSlideshow,
                onToggleMusic: () {
                  setState(() => _musicEnabled = !_musicEnabled);
                  if (_musicEnabled) {
                    _fadeInMusic();
                  } else {
                    _musicPlayer.stop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Single milestone view ──────────────────────────────────────────────────────

class _MilestoneView extends StatelessWidget {
  final Milestone milestone;
  final KidProfile profile;
  final bool isSlideshow;
  final Animation<double> contentFade;

  const _MilestoneView({
    required this.milestone,
    required this.profile,
    required this.isSlideshow,
    required this.contentFade,
  });

  @override
  Widget build(BuildContext context) {
    final pTheme = ProfileTheme.forProfile(profile);
    final firstPhoto = !kIsWeb
        ? milestone.attachments
            .where((a) => a.type == AttachmentType.image)
            .where((a) => File(a.localPath).existsSync())
            .firstOrNull
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        _Background(imagePath: firstPhoto?.localPath, gradient: pTheme.headerGradient),

        // Slideshow: just the cinematic overlay with title
        if (isSlideshow)
          _SlideshowContent(
            milestone: milestone,
            pTheme: pTheme,
            fade: contentFade,
          )
        // Normal mode: floating title + draggable content sheet
        else ...[
          _FloatingTitle(milestone: milestone, pTheme: pTheme),
          _ContentSheet(milestone: milestone, profile: profile),
        ],
      ],
    );
  }
}

// ── Background (blurred photo or gradient) ─────────────────────────────────────

class _Background extends StatelessWidget {
  final String? imagePath;
  final LinearGradient gradient;

  const _Background({this.imagePath, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          Image.file(File(imagePath!), fit: BoxFit.cover)
        else
          DecoratedBox(decoration: BoxDecoration(gradient: gradient)),

        // Blur + dark overlay
        if (hasImage)
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: const ColoredBox(color: Colors.transparent),
          ),

        // Dark vignette
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(hasImage ? 80 : 40),
                Colors.black.withAlpha(hasImage ? 180 : 120),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Floating title (normal mode) ──────────────────────────────────────────────

class _FloatingTitle extends StatelessWidget {
  final Milestone milestone;
  final ProfileTheme pTheme;

  const _FloatingTitle({required this.milestone, required this.pTheme});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 64,
      left: 24,
      right: 24,
      child: Column(
        children: [
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  formatDate(milestone.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            milestone.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.3,
              shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Draggable content sheet (normal mode) ──────────────────────────────────────

class _ContentSheet extends StatelessWidget {
  final Milestone milestone;
  final KidProfile profile;

  const _ContentSheet({required this.milestone, required this.profile});

  @override
  Widget build(BuildContext context) {
    final pTheme = ProfileTheme.forProfile(profile);

    return DraggableScrollableSheet(
      initialChildSize: 0.47,
      minChildSize: 0.17,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.17, 0.47, 0.92],
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 24, spreadRadius: 4)],
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Accent bar + title
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient: pTheme.headerGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                milestone.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Date row
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 13, color: pTheme.accent),
                            const SizedBox(width: 6),
                            Text(
                              formatDate(milestone.date),
                              style: TextStyle(
                                color: pTheme.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description
                        if (milestone.description.isNotEmpty)
                          Text(
                            milestone.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF4A4A4A),
                              height: 1.65,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Media section
                  if (milestone.attachments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _MediaSection(
                        milestone: milestone, pTheme: pTheme),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Media section ──────────────────────────────────────────────────────────────

class _MediaSection extends StatelessWidget {
  final Milestone milestone;
  final ProfileTheme pTheme;

  const _MediaSection({required this.milestone, required this.pTheme});

  @override
  Widget build(BuildContext context) {
    final photos = milestone.attachments
        .where((a) => a.type == AttachmentType.image)
        .toList();
    final videos = milestone.attachments
        .where((a) => a.type == AttachmentType.video)
        .toList();
    final audios = milestone.attachments
        .where((a) => a.type == AttachmentType.audio)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photos
        if (photos.isNotEmpty) ...[
          _sectionLabel('Photos', pTheme.accent),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: photos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _PhotoThumbnail(
                attachment: photos[i],
                allPhotos: photos,
                initialIndex: i,
              ),
            ),
          ),
        ],

        // Videos
        if (videos.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Videos', pTheme.accent),
          ...videos.map((v) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: _VideoTile(attachment: v, accent: pTheme.accent),
              )),
        ],

        // Audio
        if (audios.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Voice Memos', pTheme.accent),
          ...audios.map((a) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: _AudioTile(attachment: a, accent: pTheme.accent),
              )),
        ],
      ],
    );
  }
}

Widget _sectionLabel(String text, Color accent) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
                letterSpacing: 0.8),
          ),
        ],
      ),
    );

// ── Photo thumbnail ────────────────────────────────────────────────────────────

class _PhotoThumbnail extends StatelessWidget {
  final Attachment attachment;
  final List<Attachment> allPhotos;
  final int initialIndex;

  const _PhotoThumbnail({
    required this.attachment,
    required this.allPhotos,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !File(attachment.localPath).existsSync()) {
      return const SizedBox(width: 140, height: 200);
    }
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _FullScreenPhotoViewer(
            photos: allPhotos,
            initialIndex: initialIndex,
          ),
        ),
      ),
      child: Hero(
        tag: 'photo_${attachment.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.file(
                File(attachment.localPath),
                width: 140,
                height: 200,
                fit: BoxFit.cover,
              ),
              // Label overlay
              if (attachment.label != null && attachment.label!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      attachment.label!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              // Expand icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(100),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.open_in_full,
                      size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Full-screen photo viewer ────────────────────────────────────────────────────

class _FullScreenPhotoViewer extends StatefulWidget {
  final List<Attachment> photos;
  final int initialIndex;

  const _FullScreenPhotoViewer(
      {required this.photos, required this.initialIndex});

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late int _index;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo PageView
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.photos.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final a = widget.photos[i];
              if (kIsWeb || !File(a.localPath).existsSync()) {
                return const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54));
              }
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 6,
                child: Center(
                  child: Hero(
                    tag: 'photo_${a.id}',
                    child: Image.file(File(a.localPath), fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _GlassButton(
                        icon: Icons.close,
                        onTap: () => Navigator.pop(context)),
                    const Spacer(),
                    if (widget.photos.length > 1)
                      _GlassButton(
                        icon: Icons.photo_library_outlined,
                        label:
                            '${_index + 1}/${widget.photos.length}',
                        onTap: null,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Caption
          if (widget.photos[_index].label?.isNotEmpty == true)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Text(
                widget.photos[_index].label!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
            ),

          // Dot indicator
          if (widget.photos.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _PageDots(
                  count: widget.photos.length,
                  currentIndex: _index,
                  accent: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Video tile ──────────────────────────────────────────────────────────────────

class _VideoTile extends StatelessWidget {
  final Attachment attachment;
  final Color accent;

  const _VideoTile({required this.attachment, required this.accent});

  @override
  Widget build(BuildContext context) {
    final exists = !kIsWeb && File(attachment.localPath).existsSync();
    return GestureDetector(
      onTap: exists
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) =>
                      _FullScreenVideoPlayer(attachment: attachment),
                ),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withAlpha(15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(exists ? Icons.play_arrow_rounded : Icons.videocam_off,
                  size: 28, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.label?.isNotEmpty == true
                        ? attachment.label!
                        : attachment.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1A1A1A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exists ? 'Tap to play' : 'File not available',
                    style: TextStyle(
                        fontSize: 12,
                        color: exists ? Colors.grey.shade500 : Colors.red.shade400),
                  ),
                ],
              ),
            ),
            if (exists)
              Icon(Icons.fullscreen_rounded, color: accent.withAlpha(150), size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Full-screen video player ──────────────────────────────────────────────────

class _FullScreenVideoPlayer extends StatefulWidget {
  final Attachment attachment;
  const _FullScreenVideoPlayer({required this.attachment});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.file(File(widget.attachment.localPath));
      await ctrl.initialize();
      ctrl.addListener(() {
        if (mounted) setState(() {});
      });
      await ctrl.play();
      if (mounted) setState(() { _ctrl = ctrl; _initialized = true; });
    } catch (_) {}
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _ctrl?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer =
        Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_initialized && _ctrl != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _ctrl!.value.aspectRatio,
                  child: VideoPlayer(_ctrl!),
                ),
              )
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _VideoControls(ctrl: _ctrl, onClose: () => Navigator.pop(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final VideoPlayerController? ctrl;
  final VoidCallback onClose;

  const _VideoControls({required this.ctrl, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient overlays
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black54],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),

        // Top: close
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.topLeft,
              child: _GlassButton(icon: Icons.close, onTap: onClose),
            ),
          ),
        ),

        // Center: play/pause
        if (ctrl != null)
          Center(
            child: GestureDetector(
              onTap: ctrl!.value.isPlaying ? ctrl!.pause : ctrl!.play,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(100), width: 1.5),
                ),
                child: Icon(
                  ctrl!.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
          ),

        // Bottom: progress
        if (ctrl != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoProgressIndicator(
                      ctrl!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmtDuration(ctrl!.value.position),
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(_fmtDuration(ctrl!.value.duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Audio tile ─────────────────────────────────────────────────────────────────

class _AudioTile extends StatefulWidget {
  final Attachment attachment;
  final Color accent;

  const _AudioTile({required this.attachment, required this.accent});

  @override
  State<_AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<_AudioTile> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else {
      if (_state == PlayerState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play(DeviceFileSource(widget.attachment.localPath));
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _state == PlayerState.playing;
    final accent = widget.accent;
    final progress =
        _duration.inMilliseconds > 0 ? _position.inMilliseconds / _duration.inMilliseconds : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: kIsWeb ? null : _togglePlayback,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlaying ? accent : accent.withAlpha(30),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: isPlaying ? Colors.white : accent,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.attachment.label?.isNotEmpty == true
                          ? widget.attachment.label!
                          : widget.attachment.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF1A1A1A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Waveform-style progress
                    _WaveformBar(progress: progress, accent: accent),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _duration > Duration.zero ? _fmt(_duration) : '--:--',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          if (_duration > Duration.zero) ...[
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 3,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (v) {
                  final ms = (v * _duration.inMilliseconds).toInt();
                  _player.seek(Duration(milliseconds: ms));
                },
                activeColor: accent,
                inactiveColor: accent.withAlpha(40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_position),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                  Text(_fmt(_duration),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Decorative waveform bar widget
class _WaveformBar extends StatelessWidget {
  final double progress;
  final Color accent;

  const _WaveformBar({required this.progress, required this.accent});

  @override
  Widget build(BuildContext context) {
    const bars = 20;
    return SizedBox(
      height: 18,
      child: Row(
        children: List.generate(bars, (i) {
          final filled = i / bars < progress;
          final heights = [0.4, 0.6, 0.9, 0.7, 0.5, 0.8, 1.0, 0.6, 0.4, 0.7,
                          0.9, 0.5, 0.8, 0.6, 1.0, 0.7, 0.4, 0.9, 0.6, 0.5];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FractionallySizedBox(
                heightFactor: heights[i],
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: filled ? accent : accent.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Slideshow cinematic content ────────────────────────────────────────────────

class _SlideshowContent extends StatelessWidget {
  final Milestone milestone;
  final ProfileTheme pTheme;
  final Animation<double> fade;

  const _SlideshowContent(
      {required this.milestone, required this.pTheme, required this.fade});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glow circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(25),
                  border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: pTheme.accent.withAlpha(120),
                        blurRadius: 30,
                        spreadRadius: 8)
                  ],
                ),
                child: Center(
                  child: Text(pTheme.decalEmoji,
                      style: const TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(height: 24),
              // Date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: Text(
                  formatDate(milestone.date),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                milestone.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 16),
                    Shadow(color: Colors.black26, blurRadius: 32),
                  ],
                ),
              ),
              if (milestone.description.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  milestone.description,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Slideshow chrome overlay ───────────────────────────────────────────────────

class _SlideshowChrome extends StatelessWidget {
  final Milestone milestone;
  final int totalCount;
  final int currentIndex;
  final int slideshowKey;
  final bool musicEnabled;
  final Animation<double> contentFade;
  final VoidCallback onStop;
  final VoidCallback onToggleMusic;

  const _SlideshowChrome({
    required this.milestone,
    required this.totalCount,
    required this.currentIndex,
    required this.slideshowKey,
    required this.musicEnabled,
    required this.contentFade,
    required this.onStop,
    required this.onToggleMusic,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Progress bar (resets per slide via key)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(slideshowKey),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 5),
            builder: (_, v, child) => LinearProgressIndicator(
              value: v,
              minHeight: 3,
              backgroundColor: Colors.white.withAlpha(30),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Music toggle
                  _GlassButton(
                    icon: musicEnabled
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                    onTap: onToggleMusic,
                  ),
                  const SizedBox(width: 20),

                  // Stop button
                  GestureDetector(
                    onTap: onStop,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: Colors.white.withAlpha(80), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Stop slideshow',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Position
                  _GlassButton(
                    icon: Icons.photo_library_outlined,
                    label: '${currentIndex + 1}/$totalCount',
                    onTap: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color accent;

  const _PageDots(
      {required this.count, required this.currentIndex, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (count > 12) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${currentIndex + 1} / $count',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? accent : Colors.white.withAlpha(100),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;

  const _GlassButton({required this.icon, this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: label != null ? 12 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(50)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(40), blurRadius: 8, spreadRadius: 1)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
