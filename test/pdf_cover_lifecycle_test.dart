import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_cover.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

void main() {
  testWidgets('Catalog PDF uses its own title before download', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 140,
            height: 200,
            child: BookCover(
              book: LibraryBook(
                id: 'catalog:new',
                title: 'Новая книга',
                author: 'Автор',
                mood: '',
                description: '',
                coverStyle: 0,
                downloadUrl: 'https://example.com/new.pdf',
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Новая книга'), findsOneWidget);
    expect(find.byType(PdfDocumentViewBuilder), findsNothing);
  });

  testWidgets(
    'PDF cover keeps its document during parent rebuilds and replaces it for a new file',
    (tester) async {
      final root = Directory.systemTemp.createTempSync('myb-cover-lifecycle-');
      final first = File('test/fixtures/colored_book.pdf')
          .copySync('${root.path}/first.pdf');
      final second = first.copySync('${root.path}/second.pdf');
      Pdfrx.pdfiumModulePath = File(
        Platform.environment['PDFIUM_PATH'] ?? '.dart_tool/hooks_runner/shared/pdfium_dart/build/chromium_8125/mac-arm64/libpdfium.dylib',
      ).absolute.path;
      Pdfrx.cacheDirectoryPath = root.path;
      addTearDown(() => root.deleteSync(recursive: true));
      var path = first.path;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Center(
                  child: SizedBox(
                    width: 140,
                    height: 200,
                    child: BookCover(
                      showAuthorAvatar: false,
                      book: LibraryBook(
                        id: path,
                        title: 'PDF',
                        author: '',
                        mood: '',
                        description: '',
                        coverStyle: 0,
                        filePath: path,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      Future<void> waitForCover() async {
        await tester.runAsync(() async {
          for (
            var i = 0;
            i < 150 && find.byType(PdfPageView).evaluate().isEmpty;
            i++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            await tester.pump(const Duration(milliseconds: 16));
          }
        });
        await tester.pumpAndSettle();
        expect(find.byType(PdfPageView), findsOneWidget);
      }

      await waitForCover();
      final document = tester
          .widget<PdfPageView>(find.byType(PdfPageView))
          .document;
      for (var i = 0; i < 12; i++) {
        rebuild(() {});
        await tester.pump();
        await waitForCover();
        expect(
          tester.widget<PdfPageView>(find.byType(PdfPageView)).document,
          same(document),
        );
      }
      rebuild(() => path = second.path);
      await tester.pump();
      await waitForCover();
      expect(
        tester.widget<PdfPageView>(find.byType(PdfPageView)).document,
        isNot(same(document)),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
