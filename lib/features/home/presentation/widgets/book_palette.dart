import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';

class BookPalette {
  static const editorial = [
    [Color(0xFF163B59), Color(0xFF8CB7CE), Color(0xFFF4DFA2)],
    [Color(0xFF541F2E), Color(0xFFB64D51), Color(0xFFF8D7AD)],
    [Color(0xFFE5D8BE), Color(0xFFC1AC87), Color(0xFF9E302C)],
    [Color(0xFF193E37), Color(0xFF5D8070), Color(0xFFE8D9AF)],
    [Color(0xFFC7863F), Color(0xFFF1CB7F), Color(0xFF442F28)],
    [Color(0xFF1B4C69), Color(0xFF71ACBE), Color(0xFFF2E5C7)],
  ];

  static List<Color> forBook(LibraryBook book) {
    final seed = book.coverSeed;
    if (seed == null) return editorial[book.coverStyle % editorial.length];
    final hue = (seed % 360).toDouble();
    return [
      HSLColor.fromAHSL(1, hue, .5, .19).toColor(),
      HSLColor.fromAHSL(1, (hue + 18) % 360, .54, .38).toColor(),
      const Color(0xFFF6EFDF),
    ];
  }
}
