import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/presentation/screens/book_reader_screen.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_page_turn.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<int> _threePagePdf() {
  String stream(String text) {
    final data = 'BT /F1 24 Tf 40 640 Td ($text) Tj ET';
    return '<< /Length ${data.length} >>\nstream\n$data\nendstream';
  }

  final objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R 5 0 R 8 0 R] /Count 3 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 400 700] /Resources << /Font << /F1 7 0 R >> >> /Contents 4 0 R >>',
    stream('First page'),
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 400 700] /Resources << /Font << /F1 7 0 R >> >> /Contents 6 0 R >>',
    stream('Second page'),
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 400 700] /Resources << /Font << /F1 7 0 R >> >> /Contents 9 0 R >>',
    stream('Last page'),
  ];
  final buffer = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[0];
  for (var index = 0; index < objects.length; index++) {
    offsets.add(buffer.length);
    buffer.write('${index + 1} 0 obj\n${objects[index]}\nendobj\n');
  }
  final xref = buffer.length;
  buffer.write('xref\n0 ${offsets.length}\n0000000000 65535 f \n');
  for (final offset in offsets.skip(1)) {
    buffer.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  buffer.write(
    'trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n',
  );
  return ascii.encode(buffer.toString());
}

Future<void> _pumpIo(WidgetTester tester, bool Function() ready) async {
  await tester.runAsync(() async {
    for (var index = 0; index < 150 && !ready(); index++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 50));
    }
  });
  await tester.pumpAndSettle();
  expect(ready(), isTrue);
}

void main() {
  final native =
      Platform.environment['PDFIUM_PATH'] ??
      '.dart_tool/hooks_runner/shared/pdfium_dart/build/chromium_8125/mac-arm64/libpdfium.dylib';
  testWidgets('PDF pages turn only horizontally and preserve pinch zoom', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    final directory = Directory.systemTemp.createTempSync('pdf-turn-test-');
    final file = File('${directory.path}/book.pdf')
      ..writeAsBytesSync(_threePagePdf());
    Pdfrx.pdfiumModulePath = File(native).absolute.path;
    Pdfrx.cacheDirectoryPath = directory.path;
    SharedPreferences.setMockInitialValues({});
    final progress = <int>[];
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await directory.delete(recursive: true);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: BookReaderScreen(
          filePath: file.path,
          onProgressChanged: (page, count) => progress.add(page),
        ),
      ),
    );
    await _pumpIo(
      tester,
      () => find.text('Страницы 1–2 из 3').evaluate().isNotEmpty,
    );
    final viewerState = tester.state(find.byType(PdfViewer));
    final turn = find.byType(BookPageTurn);
    final rect = tester.getRect(turn);
    await tester.timedDrag(
      turn,
      const Offset(0, -500),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(find.text('Страницы 1–2 из 3'), findsOneWidget);
    expect(progress.every((page) => page == 1), isTrue);
    final forward = await tester.startGesture(rect.center);
    await forward.moveBy(const Offset(-30, 0));
    await tester.pump();
    await forward.moveBy(const Offset(-70, 0));
    await tester.pump(const Duration(milliseconds: 100));
    final curl = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is PaperCurlPainter,
    );
    expect(curl, findsOneWidget);
    final initialFold =
        tester.widget<CustomPaint>(curl).painter! as PaperCurlPainter;
    expect(initialFold.progress, inExclusiveRange(0, 1));
    expect(progress.last, 1);
    await forward.moveBy(const Offset(-60, 0));
    await tester.pump();
    expect(
      (tester.widget<CustomPaint>(curl).painter! as PaperCurlPainter).progress,
      greaterThan(initialFold.progress),
    );
    await forward.up();
    await _pumpIo(
      tester,
      () => find.text('Страница 3 из 3').evaluate().isNotEmpty,
    );
    expect(tester.state(find.byType(PdfViewer)), same(viewerState));
    expect(progress.last, 3);
    final gesture = await tester.startGesture(rect.center);
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(130, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await _pumpIo(
      tester,
      () => find.text('Страницы 1–2 из 3').evaluate().isNotEmpty,
    );
    expect(tester.state(find.byType(PdfViewer)), same(viewerState));
    expect(progress.last, 1);
    final pdf = tester.widget<PdfViewer>(find.byType(PdfViewer)).controller!;
    final initialZoom = pdf.currentZoom;
    final left = await tester.startGesture(
      rect.center - const Offset(40, 0),
      pointer: 7,
    );
    final right = await tester.startGesture(
      rect.center + const Offset(40, 0),
      pointer: 8,
    );
    await tester.pump();
    await left.moveBy(const Offset(-45, 0));
    await right.moveBy(const Offset(45, 0));
    await tester.pump();
    expect(curl, findsNothing);
    await left.up();
    await right.up();
    await _pumpIo(tester, () => pdf.currentZoom > initialZoom * 1.1);
    expect(curl, findsNothing);
    await tester.timedDrag(
      turn,
      const Offset(0, -400),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(find.text('Страницы 1–2 из 3'), findsOneWidget);
    expect(progress.last, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, skip: !File(native).existsSync());
}
