import 'dart:io';

import 'package:flutter_app/features/home/data/book_file_importer.dart';
import 'package:flutter_app/features/home/data/book_library.dart';

class BookDownloadService {
  BookDownloadService({
    BookFileImporter? importer,
    HttpClient Function()? clientFactory,
  }) : _importer = importer ?? BookFileImporter(),
       _clientFactory = clientFactory ?? HttpClient.new;

  final BookFileImporter _importer;
  final HttpClient Function() _clientFactory;

  Future<LibraryBook> download(LibraryBook book) async {
    final uri = Uri.tryParse(book.downloadUrl ?? '');
    if (uri == null ||
        !const ['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      throw const FormatException('У книги нет доступной ссылки на файл.');
    }
    final client = _clientFactory()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 20));
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw const FormatException(
          'Не удалось скачать книгу. Попробуйте позже.',
        );
      }
      final extension = uri.path.split('.').last.toLowerCase();
      final format = const ['pdf', 'txt', 'md'].contains(extension)
          ? extension
          : switch (response.headers.contentType?.mimeType) {
              'application/pdf' => 'pdf',
              'text/plain' => 'txt',
              'text/markdown' => 'md',
              _ => throw const FormatException(
                'По ссылке нет файла PDF, TXT или MD.',
              ),
            };
      final imported = await _importer.import(
        name: 'book.$format',
        bytes: _validatedBytes(response, format),
      );
      return LibraryBook(
        id: book.id,
        title: book.title,
        author: book.author,
        genre: book.genre,
        mood: book.mood,
        description: book.description,
        coverStyle: book.coverStyle,
        coverSeed: book.coverSeed,
        downloadUrl: book.downloadUrl,
        filePath: imported.filePath,
        page: book.page,
        pageCount: imported.pageCount,
      );
    } finally {
      client.close(force: true);
    }
  }

  Stream<List<int>> _validatedBytes(
    HttpClientResponse response,
    String format,
  ) async* {
    const limit = 200 * 1024 * 1024;
    if (response.contentLength > limit) {
      throw const FormatException('Файл книги больше 200 МБ.');
    }
    var count = 0;
    var checked = format != 'pdf';
    final prefix = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      count += chunk.length;
      if (count > limit) {
        throw const FormatException('Файл книги больше 200 МБ.');
      }
      if (checked) {
        yield chunk;
      } else {
        prefix.addAll(chunk);
        if (prefix.length >= 1024) {
          _checkPdf(prefix);
          checked = true;
          yield prefix;
        }
      }
    }
    if (!checked) {
      _checkPdf(prefix);
      yield prefix;
    }
  }

  void _checkPdf(List<int> prefix) {
    if (!String.fromCharCodes(prefix.take(1024)).contains('%PDF-')) {
      throw const FormatException(
        'Сайт вернул страницу вместо PDF. Попробуйте другую книгу.',
      );
    }
  }
}
