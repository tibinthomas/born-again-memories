import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../models/attachment.dart';
import '../../../models/milestone.dart';
import '../../../utils/attachment_helper.dart';
import '../../../utils/profile_theme.dart';

// ── Shared small widgets (used inside this file and by content_sheet) ──────────

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

// ── Media section ──────────────────────────────────────────────────────────────

class MediaSection extends StatelessWidget {
  final Milestone milestone;
  final ProfileTheme pTheme;

  const MediaSection({super.key, required this.milestone, required this.pTheme});

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
              itemBuilder: (_, i) => PhotoThumbnail(
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
                child: VideoTile(attachment: v, accent: pTheme.accent),
              )),
        ],

        // Audio
        if (audios.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Voice Memos', pTheme.accent),
          ...audios.map((a) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                child: AudioTile(attachment: a, accent: pTheme.accent),
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

class PhotoThumbnail extends StatelessWidget {
  final Attachment attachment;
  final List<Attachment> allPhotos;
  final int initialIndex;

  const PhotoThumbnail({
    super.key,
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
        builder: (_) => PhotoDialog(
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

class PhotoDialog extends StatefulWidget {
  final List<Attachment> photos;
  final int initialIndex;
  const PhotoDialog({super.key, required this.photos, required this.initialIndex});

  @override
  State<PhotoDialog> createState() => _PhotoDialogState();
}

class _PhotoDialogState extends State<PhotoDialog> {
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
    final size = MediaQuery.of(context).size;
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
              top: MediaQuery.of(context).padding.top + 8,
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

class VideoTile extends StatelessWidget {
  final Attachment attachment;
  final Color accent;

  const VideoTile({super.key, required this.attachment, required this.accent});

  @override
  Widget build(BuildContext context) {
    final exists = !kIsWeb && File(attachment.localPath).existsSync();
    return GestureDetector(
      onTap: exists
          ? () => showDialog(
                context: context,
                barrierColor: Colors.black87,
                builder: (_) => VideoDialog(attachment: attachment),
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

class VideoDialog extends StatefulWidget {
  final Attachment attachment;
  const VideoDialog({super.key, required this.attachment});

  @override
  State<VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<VideoDialog> {
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
    final size = MediaQuery.of(context).size;
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
                      top: MediaQuery.of(context).padding.top + 8,
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
                        bottom: MediaQuery.of(context).padding.bottom + 16,
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

class AudioTile extends StatefulWidget {
  final Attachment attachment;
  final Color accent;

  const AudioTile({super.key, required this.attachment, required this.accent});

  @override
  State<AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends State<AudioTile> {
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
      return;
    }

    if (!widget.attachment.localExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file not available on this device.')),
        );
      }
      return;
    }

    try {
      // The `record` package leaves AVAudioSession in .record category after
      // stopping. Reset it on this player instance before play() so the
      // platform-side AVPlayer can acquire the session. Using the instance
      // method (not AudioPlayer.global) ensures the context is applied to
      // this player's platform object, not just the OS-level category.
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await _player.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ));
      }

      if (_state == PlayerState.completed) {
        await _player.seek(Duration.zero);
      }

      await _player.play(DeviceFileSource(widget.attachment.localPath));
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
