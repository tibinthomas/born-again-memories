import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/feature_visibility.dart';

void main() {
  test('sub-feature visibility flags are parsed independently', () {
    final visibility = FeatureVisibility.fromJson({
      'googlePhotosImport': false,
      'pdfExport': false,
    });

    expect(visibility.isEnabled(AppModule.googlePhotosImport), isFalse);
    expect(visibility.isEnabled(AppModule.pdfExport), isFalse);
    expect(visibility.isEnabled(AppModule.memories), isTrue);
  });
}
