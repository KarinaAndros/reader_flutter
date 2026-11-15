import 'dart:math';

import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/data/random_book_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Both filters must match and incompatible choices return no book', () {
    final picker = RandomBookPicker(random: Random(1));
    expect(
      picker.pick(editorialBooks, genre: 'Роман', mood: 'Мечтательное')?.id,
      'dandelion',
    );
    expect(
      picker.pick(editorialBooks, genre: 'Роман', mood: 'Загадочное'),
      isNull,
    );
    expect(picker.pick(const []), isNull);
  });

  test('Repeated picks avoid the previous book when alternatives exist', () {
    final picker = RandomBookPicker(random: Random(2));
    var previous = picker.pick(editorialBooks, mood: 'Мечтательное')!;
    for (var index = 0; index < 12; index++) {
      final next = picker.pick(
        editorialBooks,
        mood: 'Мечтательное',
        previousId: previous.id,
      )!;
      expect(next.id, isNot(previous.id));
      expect(next.mood, 'Мечтательное');
      previous = next;
    }
    expect(
      picker.pick(editorialBooks, genre: 'Антиутопия', previousId: '1984')?.id,
      '1984',
    );
  });

  test('Duplicate IDs do not increase a book’s chance of being picked', () {
    final picker = RandomBookPicker();
    final books = [...editorialBooks, editorialBooks.first];
    expect(picker.matching(books).length, editorialBooks.length);
  });

  test('Imports without metadata participate only in matching filters', () {
    final picker = RandomBookPicker();
    const book = LibraryBook(
      id: 'local',
      title: 'Мой документ',
      author: 'Из вашей библиотеки',
      mood: 'Любое',
      description: '',
      coverStyle: 0,
      filePath: '/books/document.txt',
    );
    expect(picker.pick([book]), same(book));
    expect(picker.pick([book], genre: 'Роман'), isNull);
    expect(picker.pick([book], mood: 'Спокойное'), isNull);
  });
}
