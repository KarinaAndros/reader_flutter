import 'dart:convert';
import 'dart:io';

import 'package:flutter_app/features/home/data/book_file_importer.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_atmosphere.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late BookFileImporter importer;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('reader-import-test-');
    importer = BookFileImporter(directory: () async => directory);
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'Removal deletes only the private copy and tolerates a missing file',
    () async {
      final source = File('${directory.path}/original.txt')
        ..writeAsStringSync('Сохранить оригинал');
      final book = await importer.import(
        name: 'original.txt',
        bytes: source.openRead(),
      );
      await importer.removeCopy(source.path);
      await importer.removeCopy(book.filePath!);
      await importer.removeCopy(book.filePath!);
      expect(await File(book.filePath!).exists(), isFalse);
      expect(await source.exists(), isTrue);
    },
  );

  test(
    'TXT is copied, deduplicated and keeps its cover and reading position',
    () async {
      final source = await File('${directory.path}/source.TXT')
          .writeAsString('Новая книга. ' * 500);
      final first = await importer.import(
        name: 'Новая_книга.TXT',
        bytes: source.openRead(),
      );
      final second = await importer.import(
        name: 'Другое имя.txt',
        bytes: source.openRead(),
      );
      expect(first.id, second.id);
      expect(first.filePath, second.filePath);
      expect(first.title, 'Новая книга');
      expect(first.isText, isTrue);
      expect(first.isPdf, isFalse);
      expect(first.pageCount, greaterThan(1));
      expect(first.coverSeed, isNotNull);
      final color = BookAtmosphere.forBook(first).accent;
      await source.delete();
      expect(await File(first.filePath!).readAsString(), 'Новая книга. ' * 500);
      await BookLibrary().save([first.withProgress(2, first.pageCount)]);
      final restored = (await BookLibrary().load()).single;
      expect(restored.page, 2);
      expect(restored.isText, isTrue);
      expect(restored.coverSeed, first.coverSeed);
      expect(BookAtmosphere.forBook(restored).accent, color);
      final other = await importer.import(
        name: 'Другая.txt',
        bytes: Stream.value(utf8.encode('Другая история')),
      );
      expect(BookPalette.forBook(other), isNot(BookPalette.forBook(first)));
      expect(
        (await Directory(
          '${directory.path}/books',
        ).list().toList()).where((file) => file.path.endsWith('.tmp')),
        isEmpty,
      );
    },
  );

  test(
    'PDF keeps its bytes and receives a persistent fallback cover',
    () async {
      final bytes = await File('test/fixtures/colored_book.pdf').readAsBytes();
      final book = await importer.import(
        name: 'Цветная_книга.PDF',
        bytes: Stream.value(bytes),
      );
      expect(book.isPdf, isTrue);
      expect(book.isText, isFalse);
      expect(book.coverSeed, isNotNull);
      expect(await File(book.filePath!).readAsBytes(), bytes);
    },
  );

  test(
    'Markdown imports case-insensitively, deduplicates and restores progress',
    () async {
      final content =
          '# Документ\n\n${'Параграф **жирным** и `код`.\n\n' * 140}';
      final book = await importer.import(
        name: 'Мои_заметки.MD',
        bytes: Stream.value(utf8.encode(content)),
      );
      final duplicate = await importer.import(
        name: 'Копия.md',
        bytes: Stream.value(utf8.encode(content)),
      );
      expect(book.id, duplicate.id);
      expect(book.title, 'Мои заметки');
      expect(book.isMarkdown, isTrue);
      expect(book.isText, isTrue);
      expect(book.isPdf, isFalse);
      expect(book.formatLabel, 'MD');
      expect(book.pageCount, greaterThan(1));
      expect(await File(book.filePath!).readAsString(), content);
      await BookLibrary().save([book.withProgress(2, book.pageCount)]);
      final restored = (await BookLibrary().load()).single;
      expect(restored.isMarkdown, isTrue);
      expect(restored.page, 2);
      await expectLater(
        importer.import(name: 'binary.md', bytes: Stream.value([0, 1, 2])),
        throwsFormatException,
      );
    },
  );

  test(
    'Cancelled streams, empty and unsupported files leave no temporary copies',
    () async {
      await expectLater(
        importer.import(name: 'bad.epub', bytes: const Stream.empty()),
        throwsFormatException,
      );
      await expectLater(
        importer.import(name: 'empty.txt', bytes: const Stream.empty()),
        throwsFormatException,
      );
      await expectLater(
        importer.import(
          name: 'broken.txt',
          bytes: Stream.error(const FileSystemException('broken')),
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        await Directory('${directory.path}/books').list().toList(),
        isEmpty,
      );
    },
  );
}
