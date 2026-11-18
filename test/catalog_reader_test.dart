import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_catalog_repository.dart';
import 'package:flutter_app/features/home/data/book_download_service.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/screens/text_reader_screen.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_spotlight.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Catalog extends BookCatalogRepository {
  _Catalog(this.books);
  final List<LibraryBook> books;
  bool fail = false;
  @override
  Future<List<LibraryBook>?> loadCached() async => null;
  @override
  Future<List<LibraryBook>> load() async {
    if (fail) throw const SocketException('offline');
    return books;
  }
}

class _Downloads extends BookDownloadService {
  _Downloads(this.saved);
  final LibraryBook saved;
  int calls = 0;
  @override
  Future<LibraryBook> download(LibraryBook book) async {
    calls++;
    return saved;
  }
}

Future<void> waitForIo(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 150 && !ready(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 50));
    }
  });
  await tester.pumpAndSettle();
  expect(ready(), isTrue);
}

void main() {
  late Directory directory;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('myb-reader-');
  });
  tearDown(() => directory.delete(recursive: true));

  testWidgets(
    'Catalog downloads open in the reader, deduplicate and reopen offline',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1100);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final file = File('${directory.path}/book.txt')
        ..writeAsStringSync('Текст книги из каталога.\n\n' * 350);
      final remote = BookCatalogRepository.parse([
        {
          'id': 'test',
          'title': 'Книга из базы',
          'author': 'Автор из базы',
          'genre': 'Роман',
          'link': 'https://example.com/book.txt',
        },
      ]).single;
      final saved = LibraryBook(
        id: remote.id,
        title: remote.title,
        author: remote.author,
        mood: remote.mood,
        description: remote.description,
        coverStyle: remote.coverStyle,
        coverSeed: remote.coverSeed,
        genre: remote.genre,
        downloadUrl: remote.downloadUrl,
        filePath: file.path,
      );
      final catalog = _Catalog([remote]);
      final downloads = _Downloads(saved);
      await tester.pumpWidget(MyApp(catalog: catalog, downloads: downloads));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BookSpotlight>(find.byType(BookSpotlight))
            .books
            .single
            .title,
        remote.title,
      );
      final read = find.text('Читать');
      await tester.ensureVisible(read);
      await tester.pumpAndSettle();
      await tester.tap(read);
      await waitForIo(
        tester,
        () => find.byType(SelectableText).evaluate().isNotEmpty,
      );
      expect(find.byType(TextReaderScreen), findsOneWidget);
      expect(downloads.calls, 1);
      await tester.tap(find.byTooltip('Следующая страница'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Назад в библиотеку'));
      await waitForIo(
        tester,
        () => find.byType(BookSpotlight).evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      final restored = (await BookLibrary().load()).single;
      expect(restored.page, 3);
      expect(restored.downloadUrl, remote.downloadUrl);
      expect(
        tester.widget<BookSpotlight>(find.byType(BookSpotlight)).books,
        hasLength(1),
      );
      catalog.fail = true;
      await tester.ensureVisible(find.byKey(const ValueKey('refresh-catalog')));
      await tester.tap(find.byKey(const ValueKey('refresh-catalog')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Читать дальше'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Читать дальше'));
      await waitForIo(
        tester,
        () => find
            .textContaining(RegExp(r'Страниц(?:а 3|ы 3–4) из'))
            .evaluate()
            .isNotEmpty,
      );
      expect(downloads.calls, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('An empty database displays an empty catalog and can refresh', (
    tester,
  ) async {
    final catalog = _Catalog([]);
    await tester.pumpWidget(MyApp(catalog: catalog));
    await tester.pumpAndSettle();
    expect(find.text('В каталоге пока нет книг'), findsOneWidget);
    expect(
      tester.widget<BookSpotlight>(find.byType(BookSpotlight)).books,
      isEmpty,
    );
    catalog.books.addAll(
      BookCatalogRepository.parse([
        {'id': 'new', 'title': 'Новая книга', 'author': 'Автор', 'link': null},
      ]),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('refresh-catalog')));
    await tester.tap(find.byKey(const ValueKey('refresh-catalog')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BookSpotlight>(find.byType(BookSpotlight))
          .books
          .single
          .title,
      'Новая книга',
    );
    expect(tester.takeException(), isNull);
  });
}
