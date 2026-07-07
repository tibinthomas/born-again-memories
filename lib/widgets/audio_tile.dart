import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../models/attachment.dart';
import '../providers/profiles_provider.dart';
import '../services/local_storage_service.dart';

/// Playback tile for a milestone's audio attachment. Shared by the media
/// grid and the milestone detail page — previously duplicated between the
/// two with slightly different platform-audio-context handling.
class AudioTile extends ConsumerStatefulWidget {
  final Attachment attachment;
  final Color accent;

  const AudioTile({super.key, required this.attachment, required this.accent});

  @override
  ConsumerState<AudioTile> createState() => _AudioTileState();
}

class _AudioTileState extends ConsumerState<AudioTile> {
  final _player = AudioPlayer();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _player.onPlayerStateChanged.listen((s) {
        if (mounted) setState(() => _state = s);
      }),
      _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      }),
      _player.onDurationChanged.listen((d) {
        if (mounted) setState(() => _duration = d);
      }),
    ]);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
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
