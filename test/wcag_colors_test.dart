import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/utils/theme_preset.dart';
import 'package:my_app/utils/wcag_colors.dart';

void main() {
  test('shared text colors meet WCAG AA on light surfaces', () {
    expect(
      WcagColors.contrastRatio(WcagColors.primaryText, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      WcagColors.contrastRatio(WcagColors.secondaryText, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('control boundaries and focus indicators meet non-text contrast', () {
    expect(
      WcagColors.contrastRatio(WcagColors.controlBorder, Colors.white),
      greaterThanOrEqualTo(3),
    );
    expect(
      WcagColors.contrastRatio(WcagColors.focusIndicator, Colors.white),
      greaterThanOrEqualTo(3),
    );
  });

  test(
    'theme colors used for foreground content meet normal text contrast',
    () {
      for (final preset in ThemePreset.all) {
        expect(
          WcagColors.contrastRatio(preset.accent, Colors.white),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.name} accent',
        );
        expect(
          WcagColors.contrastRatio(preset.secondary, Colors.white),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.name} secondary',
        );
        if (preset.tertiary case final tertiary?) {
          expect(
            WcagColors.contrastRatio(tertiary, Colors.white),
            greaterThanOrEqualTo(4.5),
            reason: '${preset.name} tertiary',
          );
        }
      }
    },
  );
}
