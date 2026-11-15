import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_page_turn.dart';
import 'package:flutter_test/flutter_test.dart';

Finder get curl => find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is PaperCurlPainter,
);

Future<void> mountReader(
  WidgetTester tester,
  BookPageTurnController controller,
  List<int> changes, {
  bool reduceMotion = false,
}) async {
  var page = 0;
  Widget content(int index) => ColoredBox(
    color: index.isEven ? Colors.white : Colors.amber.shade50,
    child: Center(child: Text('Page $index')),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: BookPageTurn(
              controller: controller,
              page: page,
              pageCount: 3,
              onPageChanged: (index) {
                changes.add(index);
                setState(() => page = index);
              },
              previewBuilder: (context, index) => content(index),
              child: content(page),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Desktop page keys turn pages without pointer input', (
    tester,
  ) async {
    final controller = BookPageTurnController();
    final changes = <int>[];
    await mountReader(tester, controller, changes);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(changes, [1]);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(changes, [1, 2]);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(changes, [1, 2, 1]);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  testWidgets('A finger swipe controls the fold before committing the page', (
    tester,
  ) async {
    final controller = BookPageTurnController();
    final changes = <int>[];
    await mountReader(tester, controller, changes);
    final gesture = await tester.startGesture(const Offset(600, 300));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-160, 0));
    await tester.pump(const Duration(milliseconds: 160));
    expect(curl, findsOneWidget);
    final painter =
        tester.widget<CustomPaint>(curl).painter! as PaperCurlPainter;
    expect(painter.progress, inExclusiveRange(0, 1));
    expect(painter.forward, isTrue);
    expect(changes, isEmpty);
    await gesture.moveBy(const Offset(-160, 0));
    await tester.pump();
    final nextPainter =
        tester.widget<CustomPaint>(curl).painter! as PaperCurlPainter;
    expect(nextPainter.progress, greaterThan(painter.progress));
    expect(changes, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, [1]);
    expect(find.text('Page 1'), findsOneWidget);
    expect(curl, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Arrow navigation changes the page without a curl', (
    tester,
  ) async {
    final controller = BookPageTurnController();
    final changes = <int>[];
    await mountReader(tester, controller, changes);
    unawaited(controller.goToPage(1));
    await tester.pumpAndSettle();
    expect(changes, [1]);
    expect(curl, findsNothing);
  });

  testWidgets('A short drag cancels without changing reading progress', (
    tester,
  ) async {
    final controller = BookPageTurnController();
    final changes = <int>[];
    await mountReader(tester, controller, changes);
    final gesture = await tester.startGesture(const Offset(700, 300));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(curl, findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(find.text('Page 0'), findsOneWidget);
    expect(curl, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Swipes turn forward and back and stop at the first page', (
    tester,
  ) async {
    final controller = BookPageTurnController();
    final changes = <int>[];
    await mountReader(tester, controller, changes);
    final reader = find.byType(BookPageTurn);
    await tester.timedDrag(
      reader,
      const Offset(-450, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(changes, [1]);
    await tester.timedDrag(
      reader,
      const Offset(450, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(changes, [1, 0]);
    await tester.timedDrag(
      reader,
      const Offset(450, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(changes, [1, 0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reduced motion changes pages without a fold', (tester) async {
    final controller = BookPageTurnController();
    final changes = <int>[];
    await mountReader(tester, controller, changes, reduceMotion: true);
    unawaited(controller.goToPage(2));
    await tester.pumpAndSettle();
    expect(changes, [2]);
    expect(find.text('Page 2'), findsOneWidget);
    expect(curl, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Closing the reader during a turn releases the animation', (
    tester,
  ) async {
    final controller = BookPageTurnController();
    await mountReader(tester, controller, []);
    final gesture = await tester.startGesture(const Offset(600, 300));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-160, 0));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpWidget(const SizedBox.shrink());
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
