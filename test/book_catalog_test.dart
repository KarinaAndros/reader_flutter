import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/features/home/data/book_catalog_repository.dart';
import 'package:flutter_app/features/home/data/book_download_service.dart';
import 'package:flutter_app/features/home/data/book_file_importer.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RealHttpOverrides extends HttpOverrides {}

HttpClient realClient() =>
    HttpOverrides.runWithHttpOverrides(HttpClient.new, _RealHttpOverrides());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late Directory directory;
  late Uri root;
  var failCatalog = false;
  var badPdf = false;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('myb-catalog-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    root = Uri.parse('http://127.0.0.1:${server.port}/');
    failCatalog = false;
    badPdf = false;
    server.listen((request) async {
      switch (request.uri.path) {
        case '/books':
          request.response.statusCode = failCatalog ? 503 : 200;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode([
              {
                'id': 'kashtanka',
                'title': 'Каштанка',
                'author': 'Антон Чехов',
                'genre': 'Рассказ',
                'link': root.resolve('book.pdf?download=1').toString(),
              },
            ]),
          );
        case '/book.pdf':
          request.response.headers.contentType = ContentType(
            'application',
            'pdf',
          );
          request.response.add(
            badPdf
                ? utf8.encode('<html>not a book</html>')
                : await File('test/fixtures/colored_book.pdf').readAsBytes(),
          );
        case '/book.md':
          request.response.headers.contentType = ContentType(
            'text',
            'markdown',
          );
          request.response.add(utf8.encode('# Глава\n\nТекст книги.'));
        default:
          request.response.statusCode = 404;
      }
      await request.response.close();
    });
  });
  tearDown(() async {
    await server.close(force: true);
    await directory.delete(recursive: true);
  });

  BookCatalogRepository catalog() => BookCatalogRepository(
    api: ApiClient(baseUrl: root, clientFactory: realClient),
  );
  BookDownloadService downloader() => BookDownloadService(
    importer: BookFileImporter(directory: () async => directory),
    clientFactory: realClient,
  );

  test(
    'Server catalog decodes UTF-8, recognizes query URLs and survives offline',
    () async {
      final books = await catalog().load();
      final book = books.single;
      expect(book.title, 'Каштанка');
      expect(book.id, 'catalog:kashtanka');
      expect(book.author, 'Антон Чехов');
      expect(book.isLocal, isFalse);
      expect(book.isPdf, isTrue);
      expect(book.canRead, isTrue);
      failCatalog = true;
      await expectLater(catalog().load(), throwsA(isA<HttpException>()));
      final cached = (await catalog().loadCached())!.single;
      expect(cached.downloadUrl, book.downloadUrl);
      expect(cached.title, book.title);
    },
  );

  test('Download retains catalog identity and metadata across progress and restart', () async {
    final book = (await catalog().load()).single;
    final saved = await downloader().download(book);
    expect(saved.id, book.id);
    expect(saved.title, book.title);
    expect(saved.author, book.author);
    expect(saved.genre, book.genre);
    expect(saved.isLocal, isTrue);
    expect(saved.isPdf, isTrue);
    expect(
      await File(saved.filePath!).readAsBytes(),
      await File('test/fixtures/colored_book.pdf').readAsBytes(),
    );
    await BookLibrary().save([saved.withProgress(2, 5)]);
    final restored = (await BookLibrary().load()).single;
    expect(restored.page, 2);
    expect(restored.downloadUrl, book.downloadUrl);
    expect(restored.coverSeed, book.coverSeed);
    final repeated = await downloader().download(book);
    expect(repeated.filePath, saved.filePath);
  });

  test(
    'HTML masquerading as PDF and HTTP errors leave no imported files',
    () async {
      final book = (await catalog().load()).single;
      badPdf = true;
      await expectLater(downloader().download(book), throwsFormatException);
      expect(
        await Directory('${directory.path}/books').list().toList(),
        isEmpty,
      );
      final missing = BookCatalogRepository.parse([
        {
          'id': 'missing',
          'title': 'Нет',
          'author': 'Автор',
          'link': root.resolve('missing.pdf').toString(),
        },
      ]).single;
      await expectLater(downloader().download(missing), throwsFormatException);
      expect(
        await Directory('${directory.path}/books').list().toList(),
        isEmpty,
      );
    },
  );

  test('Markdown downloads use the existing text importer', () async {
    final book = BookCatalogRepository.parse([
      {
        'id': 'md',
        'title': 'Документ',
        'author': 'Автор',
        'link': root.resolve('book.md').toString(),
      },
    ]).single;
    final saved = await downloader().download(book);
    expect(saved.isMarkdown, isTrue);
    expect(saved.pageCount, greaterThan(0));
    expect(await File(saved.filePath!).readAsString(), contains('# Глава'));
  });

  test(
    'Absent and unsafe URLs cannot be downloaded; malformed catalogs fail',
    () {
      for (final link in [
        null,
        '',
        'file:///private/test.pdf',
        'javascript:alert(1)',
      ]) {
        final book = BookCatalogRepository.parse([
          {'id': '1', 'title': 'Книга', 'author': 'Автор', 'link': link},
        ]).single;
        expect(book.canRead, isFalse);
      }
      expect(
        () => BookCatalogRepository.parse({'error': 'bad'}),
        throwsFormatException,
      );
      expect(
        () => BookCatalogRepository.parse([
          {'id': 'x'},
        ]),
        throwsFormatException,
      );
    },
  );
}
