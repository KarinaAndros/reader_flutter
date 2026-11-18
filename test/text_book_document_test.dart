import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_app/features/home/data/text_book_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'TXT reads UTF-8 with BOM, UTF-16 in either byte order, Windows-1251',
    () {
      const text = 'Привет, мир! Ёжик и книга.';
      final encodings = [
        utf8.encode(text),
        [0xEF, 0xBB, 0xBF, ...utf8.encode(text)],
        [
          0xFF,
          0xFE,
          for (final c in text.codeUnits) ...[c & 255, c >> 8],
        ],
        [
          0xFE,
          0xFF,
          for (final c in text.codeUnits) ...[c >> 8, c & 255],
        ],
        [
          207,
          240,
          232,
          226,
          229,
          242,
          44,
          32,
          236,
          232,
          240,
          33,
          32,
          168,
          230,
          232,
          234,
          32,
          232,
          32,
          234,
          237,
          232,
          227,
          224,
          46,
        ],
      ];
      for (final bytes in encodings) {
        expect(
          TextBookDocument.fromBytes(Uint8List.fromList(bytes)).pages.join(),
          text,
        );
      }
    },
  );

  test('Pagination preserves paragraphs, all text and emoji at boundaries', () {
    final text = '${'А' * 1799}🌙${'Длинная история.\r\n\r\n' * 400}';
    final document = TextBookDocument.fromBytes(
      Uint8List.fromList(utf8.encode(text)),
    );
    expect(document.pages.length, greaterThan(2));
    expect(document.pages.join(), text.replaceAll('\r\n', '\n'));
    for (final page in document.pages) {
      expect(utf8.decode(utf8.encode(page)), page);
      expect(page.length, lessThanOrEqualTo(1800));
    }
  });

  test('Empty, binary and truncated UTF-16 files have readable errors', () {
    for (final bytes in [
      <int>[],
      [32, 10, 9],
      [0, 1, 2],
      [255, 254, 40],
    ]) {
      expect(
        () => TextBookDocument.fromBytes(Uint8List.fromList(bytes)),
        throwsFormatException,
      );
    }
  });

  test('Markdown pagination preserves fenced code, tables and source text', () {
    const code = '```dart\nvoid main() {\n\n  print("hello");\n}\n```\n\n';
    const table = '| Имя | Значение |\n| --- | --- |\n| Книга | 1 |\n\n';
    final text =
        '# Глава\r\n\r\n${'Абзац **Markdown**.\r\n\r\n' * 110}$code$table';
    final document = TextBookDocument.fromMarkdownBytes(
      Uint8List.fromList(utf8.encode(text)),
    );
    expect(document.pages.length, greaterThan(1));
    expect(document.pages.join(), text.replaceAll('\r\n', '\n'));
    expect(document.pages.where((page) => page.contains(code)), hasLength(1));
    expect(document.pages.where((page) => page.contains(table)), hasLength(1));
    final longCode = '~~~~text\n${'длинный код\n\n' * 250}~~~~\n';
    final longDocument = TextBookDocument.fromMarkdownBytes(
      Uint8List.fromList(utf8.encode(longCode)),
    );
    expect(longDocument.pages, [longCode]);
  });

  test('Markdown reference links survive pagination and ignore fenced definitions', () {
    final text =
        '[ссылка][guide]\n\n${'Абзац.\n\n' * 400}[guide]: https://flutter.dev\n\n```\n[hidden]: https://example.com\n```';
    final document = TextBookDocument.fromMarkdownBytes(
      Uint8List.fromList(utf8.encode(text)),
    );
    expect(document.pages.length, greaterThan(1));
    expect(document.referenceDefinitions, '[guide]: https://flutter.dev');
    expect(document.pages.join(), text);
  });
}
