import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen in-app video recorder.
/// Returns the recorded file path via Navigator.pop, or null if cancelled.
class VideoRecorderScreen extends StatefulWidget {
  const VideoRecorderScreen({super.key});

  static Future<String?> open(BuildContext context) => Navigator.push<String?>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const VideoRecorderScreen(),
        ),
      );

  @override
  State<VideoRecorderScreen> createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0;

  bool _initialized = false;
  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  FlashMode _flashMode = FlashMode.off;
  String? _initError;

  static const _maxDuration = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      if (_isRecording) _stopRecording(save: false);
      ctrl.dispose();
      if (mounted) setState(() => _initialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _startController(_cameras[_cameraIndex]);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _initError = 'No cameras found on this device.');
        return;
      }
      // Prefer back camera as default
      final backIdx = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back);
      _cameraIndex = backIdx >= 0 ? backIdx : 0;
      await _startController(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      if (mounted) setState(() => _initError = e.description ?? 'Camera error');
    }
  }

  Future<void> _startController(CameraDescription desc) async {
    final ctrl = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller = ctrl;
    try {
      await ctrl.initialize();
      if (mounted) setState(() { _initialized = true; _initError = null; });
    } on CameraException catch (e) {
      if (mounted) setState(() => _initError = e.description ?? 'Camera init failed');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording(save: true);
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isRecording) return;
    try {
      await ctrl.startVideoRecording();
      setState(() {
        _isRecording = true;
        _elapsed = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed += const Duration(seconds: 1));
        if (_elapsed >= _maxDuration) _stopRecording(save: true);
      });
    } on CameraException catch (e) {
      _showError(e.description ?? 'Could not start recording');
    }
  }

  Future<void> _stopRecording({required bool save}) async {
    _timer?.cancel();
    _timer = null;
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isRecordingVideo) {
      if (mounted) setState(() => _isRecording = false);
      return;
    }
    try {
      final xFile = await ctrl.stopVideoRecording();
      if (mounted) {
        setState(() => _isRecording = false);
        if (save) Navigator.pop(context, xFile.path);
      }
    } on CameraException catch (e) {
      if (mounted) setState(() => _isRecording = false);
      _showError(e.description ?? 'Could not save recording');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _isRecording) return;
    setState(() { _initialized = false; });
    await _controller?.dispose();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startController(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || _isRecording) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _controller!.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Preview ──────────────────────────────────────────────────
          if (_initError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_outlined,
                        color: Colors.white54, size: 64),
                    const SizedBox(height: 16),
                    Text(_initError!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else if (!_initialized)
            const Center(
                child: CircularProgressIndicator(color: Colors.white))
          else
            Center(child: CameraPreview(_controller!)),

          // ── Top bar ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Close
                  _CircleBtn(
                    icon: Icons.close,
                    onTap: () async {
                      final nav = Navigator.of(context);
                      if (_isRecording) await _stopRecording(save: false);
                      if (mounted) nav.pop();
                    },
                  ),
                  const Spacer(),

                  // Recording timer
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle,
                              color: Colors.white, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            _formatElapsed(_elapsed),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Flash (only for back camera, not while recording)
                  if (_initialized &&
                      _cameras.isNotEmpty &&
                      _cameras[_cameraIndex].lensDirection ==
                          CameraLensDirection.back)
                    _CircleBtn(
                      icon: _flashMode == FlashMode.off
                          ? Icons.flash_off_outlined
                          : Icons.flash_on,
                      highlighted: _flashMode != FlashMode.off,
                      onTap: _isRecording ? null : _toggleFlash,
                    )
                  else
                    const SizedBox(width: 44),
                ],
              ),
            ),
          ),

          // ── Bottom controls ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Flip camera
                    if (_cameras.length > 1)
                      _CircleBtn(
                        icon: Icons.flip_camera_ios_outlined,
                        size: 44,
                        onTap: _isRecording ? null : _flipCamera,
                      )
                    else
                      const SizedBox(width: 44),

                    // Record button
                    GestureDetector(
                      onTap: _initialized ? _toggleRecording : null,
                      child: _RecordButton(isRecording: _isRecording),
                    ),

                    // Placeholder (keeps button centered)
                    const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Record button ─────────────────────────────────────────────────────────────

class _RecordButton extends StatelessWidget {
  final bool isRecording;

  const _RecordButton({required this.isRecording});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
          ),
          // Inner indicator — circle idle, rounded square when recording
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: isRecording ? 30 : 56,
            height: isRecording ? 30 : 56,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius:
                  BorderRadius.circular(isRecording ? 8 : 28),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small overlay icon button ─────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool highlighted;

  const _CircleBtn({
    required this.icon,
    this.onTap,
    this.size = 44,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted
              ? Colors.amber.withAlpha(200)
              : Colors.black.withAlpha(100),
          border: Border.all(
              color: Colors.white.withAlpha(highlighted ? 255 : 80), width: 1),
        ),
        child: Icon(icon,
            color: onTap == null
                ? Colors.white30
                : highlighted
                    ? Colors.black
                    : Colors.white,
            size: size * 0.5),
      ),
    );
  }
}
