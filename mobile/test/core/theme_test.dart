import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcafacil_mobile/core/theme/app_colors.dart';
import 'package:orcafacil_mobile/core/theme/app_spacing.dart';

void main() {
  group('AppColors', () {
    test('cores semânticas mantêm os hex esperados (compatibilidade visual)',
        () {
      // Confere que o token equivale ao Colors.X original para garantir
      // que a refatoração não introduziu drift visual.
      expect(AppColors.success.toARGB32(), Colors.green.toARGB32());
      expect(AppColors.danger.toARGB32(), Colors.red.toARGB32());
      expect(AppColors.warning.toARGB32(), Colors.orange.toARGB32());
      expect(AppColors.info.toARGB32(), Colors.teal.toARGB32());
      expect(AppColors.neutral.toARGB32(), Colors.blueGrey.toARGB32());
      expect(AppColors.attention.toARGB32(), Colors.amber.toARGB32());
    });

    test('appLightScheme produz ColorScheme com brightness light', () {
      final scheme = appLightScheme();
      expect(scheme.brightness, Brightness.light);
      expect(scheme.surface, isNotNull);
    });

    test('appDarkScheme produz ColorScheme com brightness dark', () {
      final scheme = appDarkScheme();
      expect(scheme.brightness, Brightness.dark);
      expect(scheme.surface, isNotNull);
      // ColorScheme.fromSeed em dark gera onSurface com contraste alto
      // (Material 3 garante WCAG AA por construção).
      expect(scheme.onSurface, isNotNull);
    });
  });

  group('AppSpacing', () {
    test('escala progressiva 4/8/12/16/24/32', () {
      expect(AppSpacing.xs, 4);
      expect(AppSpacing.sm, 8);
      expect(AppSpacing.md, 12);
      expect(AppSpacing.lg, 16);
      expect(AppSpacing.xl, 24);
      expect(AppSpacing.xxl, 32);
    });
  });
}
