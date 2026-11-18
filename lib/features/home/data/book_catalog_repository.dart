import 'dart:convert';

import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookCatalogRepository {
  BookCatalogRepository({ApiClient? api}) : _api = api ?? ApiClient();

  static const cacheKey = 'reader_catalog_v1';
  final ApiClient _api;

  Future<List<LibraryBook>> load() async {
    final books = parse(await _api.getJson('books'));
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        cacheKey,
        jsonEncode(books.map((book) => book.toJson()).toList()),
      );
    } catch (_) {
      // The online catalog is usable even when its offline cache cannot be saved.
    }
    return books;
  }

  Future<List<LibraryBook>?> loadCached() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(cacheKey);
      if (raw == null) return null;
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) => LibraryBook.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static List<LibraryBook> parse(Object? response) {
    if (response is! List) {
      throw const FormatException('Сервер вернул некорректный каталог.');
    }
    final ids = <String>{};
    return response.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Некорректная книга в каталоге.');
      }
      String requiredText(String key) {
        final value = item[key];
        if (value is! String || value.trim().isEmpty) {
          throw FormatException('Не заполнено поле $key.');
        }
        return value.trim();
      }

      final id = requiredText('id');
      if (!ids.add(id)) {
        throw const FormatException('В каталоге повторяется ID книги.');
      }
      final link = item['link'];
      if (link != null && link is! String) {
        throw const FormatException('Некорректная ссылка на книгу.');
      }
      final uri = Uri.tryParse((link as String? ?? '').trim());
      final validLink =
          uri != null &&
          const ['http', 'https'].contains(uri.scheme) &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty;
      // A stable palette does not change when the server reorders the catalog.
      final seed = id.codeUnits.fold(
        0,
        (value, unit) => (value * 31 + unit) & 0x7fffffff,
      );
      return LibraryBook(
        id: 'catalog:$id',
        title: requiredText('title'),
        author: requiredText('author'),
        genre: item['genre'] as String? ?? '',
        mood: 'Любое',
        description: validLink
            ? 'Откройте книгу — сохраним её на устройстве для чтения без интернета.'
            : 'Файл этой книги пока недоступен.',
        coverStyle: seed % 6,
        coverSeed: seed,
        downloadUrl: validLink ? uri.toString() : null,
      );
    }).toList();
  }
}
