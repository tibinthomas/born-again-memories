import 'dart:io';
import 'package:flutter/foundation.dart';

/// Simple heuristic: Android devices with ≤4 logical CPU cores are treated as
/// low-end and skip GPU-heavy effects (blurs, per-frame animations).
/// iOS and web are always treated as capable.
class DevicePerformance {
  static bool? _isLowEnd;

  static bool get isLowEnd {
    if (_isLowEnd != null) return _isLowEnd!;
    if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
      return _isLowEnd = false;
    }
    try {
      _isLowEnd = Platform.numberOfProcessors <= 4;
    } catch (_) {
      _isLowEnd = false;
    }
    return _isLowEnd!;
  }
}
