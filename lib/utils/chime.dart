import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

Future<void> playChime({double volume = 0.7}) async {
  final player = AudioPlayer();
  player.setVolume(volume);
  player.onPlayerComplete.listen((_) => player.dispose());
  await player.play(BytesSource(_buildChimeWav(volume)));
}

Uint8List _buildChimeWav(double volume) {
  const sr = 44100;
  const dur = 0.8;
  final n = (sr * dur).round();
  final out = Uint8List(44 + n * 2);
  final bd = ByteData.sublistView(out);

  out.setRange(0, 4, 'RIFF'.codeUnits);
  bd.setUint32(4, 36 + n * 2, Endian.little);
  out.setRange(8, 12, 'WAVE'.codeUnits);
  out.setRange(12, 16, 'fmt '.codeUnits);
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little); // PCM
  bd.setUint16(22, 1, Endian.little); // mono
  bd.setUint32(24, sr, Endian.little);
  bd.setUint32(28, sr * 2, Endian.little);
  bd.setUint16(32, 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  out.setRange(36, 40, 'data'.codeUnits);
  bd.setUint32(40, n * 2, Endian.little);

  // Bell tone: 880 Hz fundamental + harmonics, exponential decay
  for (var i = 0; i < n; i++) {
    final t = i / sr;
    final attack = (t / 0.012).clamp(0.0, 1.0);
    final decay = exp(-t / 0.22);
    final env = attack * decay;
    final v = sin(2 * pi * 880 * t) * 0.55 +
        sin(2 * pi * 1760 * t) * 0.28 +
        sin(2 * pi * 2640 * t) * 0.12 +
        sin(2 * pi * 3520 * t) * 0.05;
    bd.setInt16(44 + i * 2, (v * env * 29000 * volume).round().clamp(-32768, 32767), Endian.little);
  }
  return out;
}
