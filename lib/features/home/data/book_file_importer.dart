import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/data/text_book_document.dart';
import 'package:path_provider/path_provider.dart';

/// Keep a private copy: a phone's file picker can return a temporary file or URI.
class BookFileImporter {
  BookFileImporter({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directory;

  Future<LibraryBook> import({
    required String name,
    required Stream<List<int>> bytes,
  }) async {
    final extension = name.split('.').last.toLowerCase();
    if (!const ['txt', 'pdf'].contains(extension)) {
      throw const FormatException('Выберите файл TXT или PDF.');
    }
    final root = await _directory();
    final folder = await Directory('${root.path}/books')
        .create(recursive: true);
    final temporary = File(
      '${folder.path}/import-${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      final sink = temporary.openWrite();
      try {
        await sink.addStream(bytes);
      } finally {
        await sink.close();
      }
      if (await temporary.length() == 0) {
        throw const FormatException('Файл пуст. Выберите другую книгу.');
      }
      final text = extension == 'txt'
          ? await compute(
              TextBookDocument.fromBytes,
              await temporary.readAsBytes(),
            )
          : null;
      final digest = (await sha256.bind(temporary.openRead()).first).toString();
      final destination = File('${folder.path}/$digest.$extension');
      if (!await destination.exists()) await temporary.rename(destination.path);
      final seed = int.parse(digest.substring(0, 8), radix: 16);
      final title = name
          .replaceFirst(RegExp(r'\.(txt|pdf)$', caseSensitive: false), '')
          .replaceAll('_', ' ')
          .trim();
      return LibraryBook(
        id: '$digest.$extension',
        title: title.isEmpty ? 'Без названия' : title,
        author: 'Из вашей библиотеки',
        mood: 'Любое',
        description: 'Ваша книга. Ваш ритм. Продолжайте с той страницы, где остановились.',
        coverStyle: seed % 6,
        coverSeed: seed,
        filePath: destination.path,
        pageCount: text?.pages.length ?? 0,
      );
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
