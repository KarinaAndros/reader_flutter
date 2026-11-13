import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_palette.dart';

@immutable
class BookAtmosphere {
  const BookAtmosphere({
    required this.accent,
    required this.glow,
    required this.secondary,
  });
  final Color accent;
  final Color glow;
  final Color secondary;

  Color accentFor(Brightness brightness) => brightness == Brightness.dark
      ? HSLColor.fromColor(accent).withLightness(.76).toColor()
      : accent;

  factory BookAtmosphere.fromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    var readableAccent = HSLColor.fromColor(color)
        .withSaturation(hsv.saturation.clamp(.48, .68))
        .withLightness(.34);
    // Keep colored text readable on white and on subtly tinted surfaces.
    while (1.05 / (readableAccent.toColor().computeLuminance() + .05) < 5.5) {
      readableAccent = readableAccent.withLightness(
        readableAccent.lightness - .01,
      );
    }
    return BookAtmosphere(
      accent: readableAccent.toColor(),
      glow: hsv
          .withSaturation(hsv.saturation.clamp(.35, .7))
          .withValue(.62)
          .toColor(),
      secondary: hsv
          .withHue((hsv.hue + 28) % 360)
          .withSaturation(.38)
          .withValue(.48)
          .toColor(),
    );
  }

  factory BookAtmosphere.forBook(LibraryBook book) => BookAtmosphere.fromColor(
    book.coverSeed != null
        ? BookPalette.forBook(book)[1]
        : const [
            Color(0xFF629AB9),
            Color(0xFFB64D61),
            Color(0xFFBB743E),
            Color(0xFF5D9A7C),
            Color(0xFFD6A14F),
            Color(0xFF4299B3),
          ][book.coverStyle % 6],
  );

  /// Quantized dominant color from a small BGRA render. Ignore the white page
  /// margin and black text so a cover's illustration determines the atmosphere.
  static Color? colorFromPixels(Uint8List pixels) {
    final buckets = <int, _ColorBucket>{};
    for (var i = 0; i + 3 < pixels.length; i += 4) {
      if (pixels[i + 3] < 128) continue;
      final r = pixels[i + 2], g = pixels[i + 1], b = pixels[i];
      final hsv = HSVColor.fromColor(Color.fromARGB(255, r, g, b));
      if (hsv.value < .12 || hsv.saturation < .12) continue;
      final key = ((r >> 5) << 6) | ((g >> 5) << 3) | (b >> 5);
      final bucket = buckets.putIfAbsent(key, _ColorBucket.new);
      bucket.add(r, g, b, hsv.saturation);
    }
    if (buckets.isEmpty) return null;
    final winner = buckets.values.reduce((a, b) => a.weight > b.weight ? a : b);
    return Color.fromARGB(
      255,
      winner.red ~/ winner.count,
      winner.green ~/ winner.count,
      winner.blue ~/ winner.count,
    );
  }
}

class _ColorBucket {
  int red = 0, green = 0, blue = 0, count = 0;
  double weight = 0;
  void add(int r, int g, int b, double saturation) {
    red += r;
    green += g;
    blue += b;
    count++;
    weight += .5 + saturation;
  }
}

class BookAtmosphereResolver {
  final _cache = <String, Future<BookAtmosphere>>{};

  Future<BookAtmosphere> resolve(LibraryBook book) =>
      _cache.putIfAbsent(book.id, () async {
        final fallback = BookAtmosphere.forBook(book);
        if (!book.isPdf) return fallback;
        PdfDocument? document;
        PdfImage? image;
        try {
          await pdfrxFlutterInitialize();
          document = await PdfDocument.openFile(book.filePath!);
          if (document.pages.isEmpty) return fallback;
          final page = document.pages.first;
          const width = 48.0;
          final height = width * page.height / page.width;
          image = await page.render(
            width: width.toInt(),
            height: height.round(),
            fullWidth: width,
            fullHeight: height,
          );
          final color = image == null
              ? null
              : BookAtmosphere.colorFromPixels(image.pixels);
          return color == null ? fallback : BookAtmosphere.fromColor(color);
        } catch (_) {
          return fallback;
        } finally {
          image?.dispose();
          await document?.dispose();
        }
      });
}
