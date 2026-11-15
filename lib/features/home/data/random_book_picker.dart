import 'dart:math';

import 'package:flutter_app/features/home/data/book_library.dart';

class RandomBookPicker {
  RandomBookPicker({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<LibraryBook> matching(
    Iterable<LibraryBook> books, {
    String genre = '',
    String mood = '',
  }) {
    final seen = <String>{};
    return books.where((book) {
      return (genre.isEmpty || book.genre == genre) &&
          (mood.isEmpty || book.mood == mood) &&
          seen.add(book.id);
    }).toList();
  }

  LibraryBook? pick(
    Iterable<LibraryBook> books, {
    String genre = '',
    String mood = '',
    String? previousId,
  }) {
    final matches = matching(books, genre: genre, mood: mood);
    final choices = matches.length > 1
        ? matches.where((book) => book.id != previousId).toList()
        : matches;
    return choices.isEmpty ? null : choices[_random.nextInt(choices.length)];
  }
}
