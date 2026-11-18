import 'dart:io';

import 'package:flutter_app/core/app_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('myb-cache-test-');
    SharedPreferences.setMockInitialValues({
      'reader_library_v1': 'books and progress',
      'reader_quotes_v1': 'quotes',
      'reader_daily_activity_v1': 'activity',
      'app_theme': 'dark',
    });
  });
  tearDown(() => root.deleteSync(recursive: true));

  test(
    'clearing cache preserves books, preferences and other temporary data',
    () async {
      final book = File('${root.path}/books/book.pdf')
        ..createSync(recursive: true)
        ..writeAsStringSync('my book');
      final temporary = File('${root.path}/active-import.tmp')
        ..writeAsStringSync('import');
      final font = File('${root.path}/pdfrx.fonts/font.ttf')
        ..createSync(recursive: true)
        ..writeAsStringSync('active font');
      final cached = File('${root.path}/pdfrx.cache/aa/bb/cached.pdf')
        ..createSync(recursive: true)
        ..writeAsStringSync('regenerable');
      Link('${root.path}/pdfrx.cache/book-link').createSync(book.path);
      final preferences = await SharedPreferences.getInstance();
      final before = {
        for (final key in preferences.getKeys()) key: preferences.get(key),
      };

      await AppCache(directory: () async => root).clear();
      expect(cached.existsSync(), isFalse);
      expect(book.readAsStringSync(), 'my book');
      expect(temporary.readAsStringSync(), 'import');
      expect(font.readAsStringSync(), 'active font');
      expect({
        for (final key in preferences.getKeys()) key: preferences.get(key),
      }, before);
      await AppCache(directory: () async => root).clear();
      expect(root.existsSync(), isTrue);
    },
  );

  test(
    'a cache-directory symlink cannot delete a document directory',
    () async {
      final book = File('${root.path}/documents/book.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync('preserved');
      Link('${root.path}/pdfrx.cache').createSync(book.parent.path);
      await AppCache(directory: () async => root).clear();
      expect(book.readAsStringSync(), 'preserved');
    },
  );
}
