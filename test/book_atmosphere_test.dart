import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_atmosphere.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Book accents preserve their hue and stay readable in dark theme', () {
    for (final book in editorialBooks) {
      final atmosphere = BookAtmosphere.forBook(book);
      final darkAccent = atmosphere.accentFor(Brightness.dark);
      expect(
        HSLColor.fromColor(darkAccent).hue,
        closeTo(HSLColor.fromColor(atmosphere.accent).hue, 1),
      );
      for (final background in [
        AppTheme.dark.scaffoldBackgroundColor,
        AppTheme.dark.colorScheme.surface,
      ]) {
        expect(
          (darkAccent.computeLuminance() + .05) /
              (background.computeLuminance() + .05),
          greaterThan(4.5),
        );
      }
    }
  });

  test('Cover colors ignore white margins and dark text', () {
    final pixels = Uint8List.fromList([
      for (var i = 0; i < 100; i++) ...[255, 255, 255, 255],
      for (var i = 0; i < 60; i++) ...[5, 5, 5, 255],
      for (var i = 0; i < 20; i++) ...[60, 45, 180, 255],
      for (var i = 0; i < 5; i++) ...[170, 100, 40, 255],
      for (var i = 0; i < 40; i++) ...[220, 40, 40, 0],
    ]);
    final color = BookAtmosphere.colorFromPixels(pixels)!;
    expect(color, const Color.fromARGB(255, 180, 45, 60));
    final atmosphere = BookAtmosphere.fromColor(color);
    expect(
      HSVColor.fromColor(atmosphere.accent).hue,
      closeTo(HSVColor.fromColor(color).hue, 1),
    );
    expect(
      (AppColors.background.computeLuminance() + .05) /
          (atmosphere.accent.computeLuminance() + .05),
      greaterThan(4.5),
    );
  });

  test('Monochrome covers use the book fallback', () {
    expect(
      BookAtmosphere.colorFromPixels(
        Uint8List.fromList([255, 255, 255, 255, 0, 0, 0, 255]),
      ),
      isNull,
    );
  });
}
