import 'dart:async';
import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../models/attachment.dart';
import '../models/kid_profile.dart';
import '../models/milestone.dart';
import '../providers/profiles_provider.dart';
import '../services/local_storage_service.dart';
import '../utils/attachment_helper.dart';
import '../utils/date_formatter.dart';
import '../utils/profile_theme.dart';

// ── Entry point ────────────────────────────────────────────────────────────────

class MilestoneDetailPage extends StatefulWidget {
  final List<Milestone> milestones;
  final int initialIndex;
  final KidProfile profile;
  final bool animationsEnabled;

  const MilestoneDetailPage({
    super.key,
    required this.milestones,
    required this.initialIndex,
    required this.profile,
    this.animationsEnabled = true,
  });

  @override
  State<MilestoneDetailPage> createState() => _MilestoneDetailPageState();
}

class _MilestoneDetailPageState extends State<MilestoneDetailPage>
    with TickerProviderStateMixin {
  late int _currentIndex;

  // Slideshow
  bool _slideshowActive = false;
  bool _musicEnabled = true;
  Timer? _slideshowTimer;
  int _slideshowKey = 0;

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
    _contentFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _contentFade =
        CurvedAnimation(parent: _contentFadeCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _musicPlayer.dispose();
    _contentFadeCtrl.dispose();
    super.dispose();
  }

  void _prevMilestone() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _nextMilestone() {
    if (_currentIndex < widget.milestones.length - 1) {
      setState(() => _currentIndex++);
    }
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
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.milestones.length;
        _slideshowKey++;
      });
      _contentFadeCtrl.forward(from: 0);
      _scheduleNext();
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
            // ── Current milestone view (animated swap on index change) ──────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.97, end: 1.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  ),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_currentIndex),
                child: _MilestoneView(
                  milestone: widget.milestones[_currentIndex],
                  profile: widget.profile,
                  isSlideshow: _slideshowActive,
                  contentFade: _contentFade,
                  animationsEnabled: widget.animationsEnabled,
                ),
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
                      if (widget.milestones.length > 1)
                        _GlassButton(
                          icon: Icons.photo_library_outlined,
                          label:
                              '${_currentIndex + 1} / ${widget.milestones.length}',
                          onTap: null,
                        ),
                      if (widget.milestones.length > 1)
                        const SizedBox(width: 8),
                      _GlassButton(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Slideshow',
                        onTap: _startSlideshow,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Left / right navigation arrows ────────────────────────────
              if (widget.milestones.length > 1) ...[
                if (_currentIndex > 0)
                  Positioned(
                    left: 8,
                    top: MediaQuery.paddingOf(context).top + 60,
                    bottom: MediaQuery.sizeOf(context).height * 0.48,
                    child: Center(
                      child: _NavArrow(
                        icon: Icons.chevron_left_rounded,
                        onTap: _prevMilestone,
                      ),
                    ),
                  ),
                if (_currentIndex < widget.milestones.length - 1)
                  Positioned(
                    right: 8,
                    top: MediaQuery.paddingOf(context).top + 60,
                    bottom: MediaQuery.sizeOf(context).height * 0.48,
                    child: Center(
                      child: _NavArrow(
                        icon: Icons.chevron_right_rounded,
                        onTap: _nextMilestone,
                      ),
                    ),
                  ),
                // Dots below arrows
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.sizeOf(context).height * 0.47 + 8,
                  child: Center(
                    child: _PageDots(
                      count: widget.milestones.length,
                      currentIndex: _currentIndex,
                      accent: pTheme.accent,
                    ),
                  ),
                ),
              ],
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
  final bool animationsEnabled;

  const _MilestoneView({
    required this.milestone,
    required this.profile,
    required this.isSlideshow,
    required this.contentFade,
    this.animationsEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final pTheme = ProfileTheme.forProfile(profile);
    final firstPhoto = milestone.attachments
        .where((a) => a.type == AttachmentType.image)
        .where((a) => a.isViewable)
        .firstOrNull;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        _Background(bgAttachment: firstPhoto, gradient: pTheme.headerGradient),

        // Animated bubble layer (sits above bg, below content)
        if (animationsEnabled) _BubbleLayer(pTheme: pTheme, seed: milestone.id),

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
  final Attachment? bgAttachment;
  final LinearGradient gradient;

  const _Background({this.bgAttachment, required this.gradient});

  @override
  Widget build(BuildContext context) {
    final hasImage = bgAttachment != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          attachmentImageWidget(bgAttachment!, fit: BoxFit.cover)
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
      top: MediaQuery.paddingOf(context).top + 58,
      left: 24,
      right: 24,
      child: Column(
        children: [
          // Glowing emoji circle
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(22),
              border: Border.all(color: Colors.white.withAlpha(90), width: 2),
              boxShadow: [
                BoxShadow(
                  color: pTheme.accent.withAlpha(110),
                  blurRadius: 44,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: pTheme.secondary.withAlpha(60),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(pTheme.decalEmoji,
                  style: const TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 14),
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
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
                if (milestone.isFavorite) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded,
                      size: 13, color: Color(0xFFFBBF24)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
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
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 14),
                Shadow(color: Colors.black26, blurRadius: 28),
              ],
            ),
          ),
          // Tags
          if (milestone.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: milestone.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withAlpha(55)),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
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
    final accent = pTheme.accent;
    final secondary = pTheme.secondary;

    return DraggableScrollableSheet(
      initialChildSize: 0.46,
      minChildSize: 0.16,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.16, 0.46, 0.92],
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
                color: accent.withAlpha(50),
                blurRadius: 30,
                spreadRadius: 2),
            const BoxShadow(
                color: Colors.black26, blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Themed gradient header with animated bubbles
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32)),
                    child: Stack(
                      children: [
                        // Gradient background
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.lerp(Colors.white, accent, 0.14)!,
                                  Color.lerp(Colors.white, secondary, 0.10)!,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Floating bubbles
                        Positioned.fill(
                          child: _TitleBubbleLayer(
                              accent: accent, secondary: secondary, seed: milestone.id),
                        ),
                        // Content on top
                        Column(
                          children: [
                            // Drag handle
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: accent.withAlpha(70),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            // Title row
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 16, 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon bubble
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          accent,
                                          Color.lerp(accent, secondary, 0.6)!,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                            color: accent.withAlpha(80),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: const Icon(Icons.auto_awesome,
                                        color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          milestone.title,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1A1A1A),
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                                Icons.calendar_today_outlined,
                                                size: 12,
                                                color: accent),
                                            const SizedBox(width: 4),
                                            Text(
                                              formatDate(milestone.date),
                                              style: TextStyle(
                                                color: accent,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (milestone.isFavorite) ...[
                                              const SizedBox(width: 8),
                                              const Icon(Icons.star_rounded,
                                                  size: 14,
                                                  color: Color(0xFFFBBF24)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],   // closes Stack children
                    ),     // closes Stack
                  ),       // closes ClipRRect

                  // Body content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description card
                        if (milestone.description.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                  Colors.white, accent, 0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                  color: accent.withAlpha(30)),
                            ),
                            child: Text(
                              milestone.description,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF4A4A4A),
                                height: 1.65,
                              ),
                            ),
                          ),

                        // Tags
                        if (milestone.tags.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: milestone.tags
                                .map((tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: accent.withAlpha(18),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: accent.withAlpha(60)),
                                      ),
                                      child: Text(
                                        '#$tag',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Media section
                  if (milestone.attachments.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _MediaSection(milestone: milestone, pTheme: pTheme),
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
    if (!attachment.isViewable) {
      return Container(
        width: 140,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                attachment.name,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => _PhotoDialog(
          photos: allPhotos,
          initialIndex: initialIndex,
        ),
      ),
      child: Hero(
        tag: 'photo_${attachment.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              attachmentImageWidget(attachment, width: 140, height: 200),
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

// ── Photo dialog (inline overlay) ─────────────────────────────────────────────

class _PhotoDialog extends StatefulWidget {
  final List<Attachment> photos;
  final int initialIndex;
  const _PhotoDialog({required this.photos, required this.initialIndex});

  @override
  State<_PhotoDialog> createState() => _PhotoDialogState();
}

class _PhotoDialogState extends State<_PhotoDialog> {
  late int _index;
  late final PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // Photo pages
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final a = widget.photos[i];
                if (!a.isViewable) {
                  return const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54));
                }
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 6,
                  child: Center(
                    child: Hero(
                      tag: 'photo_${a.id}',
                      child: attachmentImageWidget(a, fit: BoxFit.contain),
                    ),
                  ),
                );
              },
            ),

            // Top bar
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _GlassButton(
                      icon: Icons.close,
                      onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  if (widget.photos.length > 1)
                    _GlassButton(
                      icon: Icons.photo_library_outlined,
                      label: '${_index + 1} / ${widget.photos.length}',
                      onTap: null,
                    ),
                ],
              ),
            ),

            // Left / right arrows
            if (widget.photos.length > 1) ...[
              if (_index > 0)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(
                        icon: Icons.chevron_left_rounded,
                        onTap: () {
                          _ctrl.previousPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut);
                        }),
                  ),
                ),
              if (_index < widget.photos.length - 1)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(
                        icon: Icons.chevron_right_rounded,
                        onTap: () {
                          _ctrl.nextPage(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOut);
                        }),
                  ),
                ),
            ],

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

            // Dots
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
          ? () => showDialog(
                context: context,
                barrierColor: Colors.black87,
                builder: (_) => _VideoDialog(attachment: attachment),
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

// ── Video dialog (inline overlay) ─────────────────────────────────────────────

class _VideoDialog extends StatefulWidget {
  final Attachment attachment;
  const _VideoDialog({required this.attachment});

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.file(File(widget.attachment.localPath));
      await ctrl.initialize();
      ctrl.addListener(() { if (mounted) setState(() {}); });
      await ctrl.play();
      if (mounted) setState(() { _ctrl = ctrl; _initialized = true; });
    } catch (_) {}
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3),
          () { if (mounted) setState(() => _showControls = false); });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: GestureDetector(
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

              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Stack(
                  children: [
                    // Gradient bars
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent, Colors.black54],
                            stops: [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Close button
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 8,
                      left: 12,
                      child: _GlassButton(
                          icon: Icons.close,
                          onTap: () => Navigator.pop(context)),
                    ),

                    // Play/pause
                    if (_ctrl != null)
                      Center(
                        child: GestureDetector(
                          onTap: () => _ctrl!.value.isPlaying
                              ? _ctrl!.pause()
                              : _ctrl!.play(),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withAlpha(100), width: 1.5),
                            ),
                            child: Icon(
                              _ctrl!.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),

                    // Progress bar
                    if (_ctrl != null)
                      Positioned(
                        bottom: MediaQuery.paddingOf(context).bottom + 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VideoProgressIndicator(
                              _ctrl!,
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
                                Text(_fmt(_ctrl!.value.position),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(_fmt(_ctrl!.value.duration),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
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

// ── Audio tile ─────────────────────────────────────────────────────────────────

class _AudioTile extends ConsumerStatefulWidget {
  final Attachment attachment;
  final Color accent;

  const _AudioTile({required this.attachment, required this.accent});

  @override
  ConsumerState<_AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends ConsumerState<_AudioTile> {
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

  /// If the file exists at [path] but is outside the app's documents directory
  /// (e.g. still in a temp folder), copy it to persistent storage and update
  /// the attachment record so the path survives app restarts.
  Future<String> _ensurePersistent(String path) async {
    if (path.isEmpty || !File(path).existsSync()) return path;
    final docsDir = await getApplicationDocumentsDirectory();
    if (path.startsWith(docsDir.path)) return path; // already safe
    final stable = await LocalStorageService.copyToAppStorage(
        path, 'audio_${widget.attachment.id}.m4a');
    ref
        .read(profilesProvider.notifier)
        .updateAttachmentLocalPath(widget.attachment.id, stable);
    return stable;
  }

  Future<void> _togglePlayback() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
      return;
    }

    final path = await _ensurePersistent(widget.attachment.localPath);

    if (!File(path).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file not available on this device.')),
        );
      }
      return;
    }

    try {
      // The `record` package leaves AVAudioSession in .record category after
      // stopping. Reset it before play() so the platform audio session is
      // reconfigured for playback on both iOS and Android.
      if (!kIsWeb) {
        if (Platform.isIOS || Platform.isMacOS) {
          await _player.setAudioContext(AudioContext(
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
            ),
          ));
        } else if (Platform.isAndroid) {
          await _player.setAudioContext(AudioContext(
            android: AudioContextAndroid(
              isSpeakerphoneOn: false,
              stayAwake: false,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gain,
            ),
          ));
        }
      }

      if (_state == PlayerState.completed) {
        await _player.seek(Duration.zero);
      }

      await _player.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint('[AudioTile] playback failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play audio. Try again.')),
        );
      }
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
    final exists = widget.attachment.localExists;
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
                    color: !exists
                        ? Colors.grey.withAlpha(40)
                        : isPlaying
                            ? accent
                            : accent.withAlpha(30),
                  ),
                  child: Icon(
                    !exists
                        ? Icons.cloud_off_rounded
                        : isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                    color: !exists ? Colors.grey.shade400 : isPlaying ? Colors.white : accent,
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
                    if (!exists)
                      Text('Not available on this device',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400))
                    else
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

// ── Title header bubble layer ─────────────────────────────────────────────────

class _TitleBubbleLayer extends StatefulWidget {
  final Color accent;
  final Color secondary;
  final String seed;
  const _TitleBubbleLayer(
      {required this.accent, required this.secondary, required this.seed});

  @override
  State<_TitleBubbleLayer> createState() => _TitleBubbleLayerState();
}

class _TitleBubbleLayerState extends State<_TitleBubbleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<double> _phases;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.seed.hashCode ^ 0xABCD);
    _phases = List.generate(5, (_) => rng.nextDouble() * 2 * math.pi);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value * 2 * math.pi;
            double s(double v) => math.sin(v);
            double c(double v) => math.cos(v);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Large accent blob — drifts right-to-left near top
                Positioned(
                  right: -30 + s(t + _phases[0]) * 18,
                  top: -20 + c(t * 0.7 + _phases[0]) * 10,
                  child: _DetailBubble(90, widget.accent, 28),
                ),
                // Medium secondary — bottom-left drift
                Positioned(
                  left: -20 + c(t * 0.8 + _phases[1]) * 14,
                  bottom: -18 + s(t + _phases[1]) * 8,
                  child: _DetailBubble(64, widget.secondary, 22),
                ),
                // Small accent — gentle mid-right float
                Positioned(
                  right: w * 0.28 + s(t * 1.2 + _phases[2]) * 12,
                  top: h * 0.1 + c(t * 0.9 + _phases[2]) * 10,
                  child: _DetailBubble(28, widget.accent, 30),
                ),
                // Tiny secondary — near drag handle
                Positioned(
                  left: w * 0.55 + c(t * 1.3 + _phases[3]) * 10,
                  top: 6 + s(t + _phases[3]) * 6,
                  child: _DetailBubble(16, widget.secondary, 35),
                ),
                // Tiny accent — bottom centre
                Positioned(
                  left: w * 0.42 + s(t * 1.1 + _phases[4]) * 14,
                  bottom: 4 + c(t * 0.8 + _phases[4]) * 6,
                  child: _DetailBubble(20, widget.accent, 25),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Animated bubble layer ─────────────────────────────────────────────────────

class _BubbleLayer extends StatefulWidget {
  final ProfileTheme pTheme;
  final String seed;
  const _BubbleLayer({required this.pTheme, required this.seed});

  @override
  State<_BubbleLayer> createState() => _BubbleLayerState();
}

class _BubbleLayerState extends State<_BubbleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<double> _phases;
  late final List<double> _amps;
  late final List<double> _signs;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.seed.hashCode);
    _phases = List.generate(6, (_) => rng.nextDouble() * 2 * math.pi);
    _amps   = List.generate(6, (_) => 0.7 + rng.nextDouble() * 0.6);
    _signs  = List.generate(6, (_) => rng.nextBool() ? 1.0 : -1.0);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.pTheme.accent;
    final secondary = widget.pTheme.secondary;
    return LayoutBuilder(
      builder: (_, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) {
            final t = _ctrl.value * 2 * math.pi;
            double s(double v) => math.sin(v);
            double c(double v) => math.cos(v);
            return Stack(
              fit: StackFit.expand,
              children: [
                // Large accent — horizontal sweep near top
                Positioned(
                  left: (s(t + _phases[0]) * 0.5 + 0.5) * (w + 130) - 65,
                  top: h * 0.04 + s(t * 2 + _phases[0]) * h * 0.05 * _amps[0],
                  child: _DetailBubble(130, accent, 32),
                ),
                // Large secondary — opposite sweep near bottom
                Positioned(
                  left: (c(_signs[1] * t + _phases[1]) * 0.5 + 0.5) * (w + 100) - 50,
                  top: h * 0.68 + s(t * 3 + _phases[1]) * h * 0.05 * _amps[1],
                  child: _DetailBubble(100, secondary, 28),
                ),
                // Mid secondary — diagonal figure-8
                Positioned(
                  left: (s(_signs[2] * t * 2 + _phases[2]) * 0.5 + 0.5) * w,
                  top: (c(t * 2 + _phases[2]) * 0.5 + 0.5) * h,
                  child: _DetailBubble(55, secondary, 24),
                ),
                // Medium accent — wide circular orbit
                Positioned(
                  left: w * 0.5 + c(_signs[3] * t + _phases[3]) * w * 0.44 * _amps[3],
                  top: h * 0.38 + s(t + _phases[3]) * h * 0.32 * _amps[3],
                  child: _DetailBubble(75, accent, 22),
                ),
                // Small accent — fast small orbit
                Positioned(
                  left: w * 0.3 + c(_signs[4] * t * 3 + _phases[4]) * w * 0.22 * _amps[4],
                  top: h * 0.22 + s(t * 3 + _phases[4]) * h * 0.16 * _amps[4],
                  child: _DetailBubble(32, accent, 20),
                ),
                // Tiny secondary — bottom sweep
                Positioned(
                  left: (s(t * 2 + _phases[5]) * 0.5 + 0.5) * w * 0.75,
                  top: h * 0.82 + s(t * 3 + _phases[5]) * h * 0.06 * _amps[5],
                  child: _DetailBubble(46, secondary, 18),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DetailBubble extends StatelessWidget {
  final double size;
  final Color color;
  final int alpha;
  const _DetailBubble(this.size, this.color, this.alpha);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withAlpha(alpha),
      ),
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

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(70),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
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
