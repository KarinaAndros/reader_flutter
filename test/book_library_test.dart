import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Library restores imported PDFs, reading positions and favorites',
    () async {
      final library = BookLibrary();
      final book = LibraryBook(
        id: 'pdf-1',
        title: 'Моя книга',
        author: 'Автор',
        mood: 'Любое',
        description: '',
        coverStyle: 3,
        filePath: '/books/my-book.pdf',
      ).withProgress(24, 120);
      await library.save([book]);
      await library.saveFavorites({'pdf-1', 'prince'});
      final restored = (await BookLibrary().load()).single;
      expect(restored.filePath, '/books/my-book.pdf');
      expect(restored.title, 'Моя книга');
      expect(restored.page, 24);
      expect(restored.pageCount, 120);
      expect(restored.progress, .2);
      expect(await BookLibrary().loadFavorites(), {'pdf-1', 'prince'});
    },
  );

  test('Malformed library data does not prevent opening the app', () async {
    SharedPreferences.setMockInitialValues({BookLibrary.booksKey: '{broken'});
    expect(await BookLibrary().load(), isEmpty);
  });
}
