import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/growth_measurement_validator.dart';

void main() {
  group('growth measurement validation', () {
    test('allows an empty optional measurement', () {
      expect(
        validateGrowthMeasurement('', label: 'Weight', min: 0.5, max: 100),
        isNull,
      );
    });

    test('rejects zero, negative, invalid, and unrealistic values', () {
      for (final value in ['0', '-1']) {
        expect(
          validateGrowthMeasurement(value, label: 'Weight', min: 0.5, max: 100),
          contains('above zero'),
        );
      }

      expect(
        validateGrowthMeasurement('abc', label: 'Weight', min: 0.5, max: 100),
        'Enter a valid number',
      );
      expect(
        validateGrowthMeasurement('250', label: 'Weight', min: 0.5, max: 100),
        contains('0.5–100'),
      );
    });

    test('accepts a value inside the configured range', () {
      expect(
        validateGrowthMeasurement('7.5', label: 'Weight', min: 0.5, max: 100),
        isNull,
      );
    });
  });
}
