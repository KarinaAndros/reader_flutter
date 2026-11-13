import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/data/quote_repository.dart';
import 'package:flutter_app/features/home/data/reading_activity.dart';
import 'package:flutter_app/features/home/presentation/screens/book_reader_screen.dart';
import 'package:flutter_app/features/home/presentation/screens/text_reader_screen.dart';
import 'package:flutter_app/features/home/presentation/widgets/ambient_background.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_cover.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_spotlight.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdfrx/pdfrx.dart';

final class _PhoneFile extends PlatformFile {
  _PhoneFile(this.file, this.name);
  final File file;
  @override
  final String name;
  // Exercise a phone content URI, which has no directly usable filesystem path.
  @override
  Uri get uri => Uri.parse('content://phone/books/$name');
  @override
  Stream<Uint8List> readAsByteStream() =>
      file.openRead().map(Uint8List.fromList);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Picker extends FilePickerPlatform {
  PlatformFile? file;
  List<String>? extensions;
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    extensions = allowedExtensions;
    return file == null ? [] : [file!];
  }
}

Future<void> pumpIo(WidgetTester tester, bool Function() ready) async {
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
  final pdfiumPath = Platform.environment['PDFIUM_PATH'];
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late _Picker picker;
  late FilePickerPlatform originalPicker;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('reader-ui-test-');
    originalPicker = FilePickerPlatform.instance;
    picker = _Picker();
    if (pdfiumPath != null) {
      Pdfrx.pdfiumModulePath = pdfiumPath;
      Pdfrx.cacheDirectoryPath = directory.path;
    }
    FilePickerPlatform.instance = picker;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
  });
  tearDown(() async {
    FilePickerPlatform.instance = originalPicker;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    await directory.delete(recursive: true);
  });

  testWidgets(
    'Phone TXT imports, saves a quote and resumes from the saved page',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 900);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final file = File('${directory.path}/Моя_история.TXT')
        ..writeAsStringSync('Однажды началась новая история.\n\n' * 180);
      picker.file = _PhoneFile(file, 'Моя_история.TXT');
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Открыть TXT или PDF'));
      await pumpIo(
        tester,
        () => find.byType(SelectableText).evaluate().isNotEmpty,
      );
      expect(picker.extensions, containsAll(['txt', 'pdf']));
      expect(find.byType(TextReaderScreen), findsOneWidget);
      expect(find.byType(BookReaderScreen), findsNothing);
      await tester.longPressAt(
        tester.getTopLeft(find.byType(SelectableText).first) +
            const Offset(40, 15),
      );
      await tester.pumpAndSettle();
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText).first,
      );
      editable.userUpdateTextEditingValue(
        editable.textEditingValue.copyWith(
          selection: const TextSelection(baseOffset: 0, extentOffset: 7),
        ),
        SelectionChangedCause.longPress,
      );
      editable.showToolbar();
      await tester.pumpAndSettle();
      if (find.text('Сохранить цитату').evaluate().isEmpty &&
          find.byTooltip('More').evaluate().isNotEmpty) {
        await tester.tap(find.byTooltip('More'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Сохранить цитату'));
      await tester.pumpAndSettle();
      expect((await QuoteRepository().loadAll()).single.text, 'Однажды');
      await tester.tap(find.byTooltip('Следующая страница'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Страница 2 из'), findsOneWidget);
      await tester.tap(find.byTooltip('Назад в библиотеку'));
      await pumpIo(
        tester,
        () =>
            find.byType(BookSpotlight).evaluate().isNotEmpty &&
            tester
                    .widget<BookSpotlight>(find.byType(BookSpotlight))
                    .books
                    .first
                    .page ==
                2,
      );
      final saved = (await BookLibrary().load()).single;
      expect(saved.page, 2);
      expect(saved.coverSeed, isNotNull);
      expect(
        (await ReadingActivityRepository().load()).series(1).single.pages,
        2,
      );
      expect(saved.filePath, isNot(file.path));
      expect(find.byType(BookCover), findsWidgets);
      expect(find.text('TXT'), findsWidgets);
      final atmosphere = tester
          .widget<AmbientBackground>(find.byType(AmbientBackground))
          .atmosphere;
      await tester.runAsync(() => file.delete());
      await tester.tap(find.text('Читать дальше').first);
      await pumpIo(
        tester,
        () =>
            find.byType(TextReaderScreen).evaluate().isNotEmpty &&
            find.textContaining('Страница 2 из').evaluate().isNotEmpty,
      );
      await tester.tap(find.byTooltip('Назад в библиотеку'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AmbientBackground>(find.byType(AmbientBackground))
            .atmosphere
            .accent,
        atmosphere.accent,
      );
      expect(
        (await ReadingActivityRepository().load()).series(1).single.pages,
        2,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Phone PDF opens with a first-page cover and extracted color',
    (tester) async {
      picker.file = _PhoneFile(
        File('test/fixtures/colored_book.pdf'),
        'Цветная.pdf',
      );
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Открыть TXT или PDF'));
      await pumpIo(
        tester,
        () => find.text('Страница 1 из 1').evaluate().isNotEmpty,
      );
      expect(find.byType(BookReaderScreen), findsOneWidget);
      final book = (await BookLibrary().load()).single;
      expect(book.isPdf, isTrue);
      await tester.tap(find.byTooltip('Назад в библиотеку'));
      await tester.pumpAndSettle();
      final atmosphere = tester
          .widget<AmbientBackground>(find.byType(AmbientBackground))
          .atmosphere;
      final hue = HSLColor.fromColor(atmosphere.accent).hue;
      expect(
        hue > 340 || hue < 10,
        isTrue,
        reason: 'The fixture has a red PDF cover',
      );
      expect(find.byType(BookCover), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    // Widget tests need an explicit native library, unlike installed apps.
    skip: pdfiumPath == null,
  );
}
