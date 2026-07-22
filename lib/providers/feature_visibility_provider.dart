import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feature_visibility.dart';

const _configAsset = 'assets/config/feature_visibility.json';

final featureVisibilityProvider = FutureProvider<FeatureVisibility>((
  ref,
) async {
  try {
    final source = await rootBundle.loadString(_configAsset);
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      return const FeatureVisibility.allVisible();
    }
    return FeatureVisibility.fromJson(json);
  } catch (_) {
    return const FeatureVisibility.allVisible();
  }
});

/// The single app-facing utility for module visibility. It fails open while
/// loading or if the bundled configuration cannot be read.
bool isModuleEnabled(WidgetRef ref, AppModule module) {
  return ref.watch(featureVisibilityProvider).valueOrNull?.isEnabled(module) ??
      true;
}
