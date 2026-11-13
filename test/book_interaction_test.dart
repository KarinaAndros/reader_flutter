import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/presentation/widgets/ambient_background.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_spotlight.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openApp(
    WidgetTester tester, {
    double width = 1440,
    bool browse = false,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 1000);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    if (browse) {
      await tester.tap(
        width >= 900 ? find.byTooltip('Поиск') : find.text('Поиск'),
      );
      await tester.pumpAndSettle();
    }
  }

  Color accent(WidgetTester tester) => tester
      .widget<AmbientBackground>(find.byType(AmbientBackground))
      .atmosphere
      .accent;

  testWidgets(
    'Hover previews a cover palette and leaving restores the selection',
    (tester) async {
      await openApp(tester, browse: true);
      final original = accent(tester);
      final tile = find.byKey(const ValueKey('book-tile-master'));
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(1, 1));
      await mouse.moveTo(tester.getCenter(tile));
      await tester.pumpAndSettle();
      final hovered = accent(tester);
      expect(hovered, isNot(original));
      expect(Theme.of(tester.element(tile)).colorScheme.primary, hovered);
      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(accent(tester), original);
      await mouse.removePointer();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Selecting a cover keeps its colors after closing book details', (
    tester,
  ) async {
    await openApp(tester, browse: true);
    final original = accent(tester);
    final tile = find.byKey(const ValueKey('book-tile-master'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: tile, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Добавить свою книгу'), findsOneWidget);
    final selected = accent(tester);
    expect(selected, isNot(original));
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(accent(tester), selected);
    await tester.tap(find.byTooltip('Главная'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<BookSpotlight>(find.byType(BookSpotlight)).selectedId,
      'master',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Swiping the spotlight changes the book and ambient color', (
    tester,
  ) async {
    await openApp(tester, width: 390);
    final original = accent(tester);
    await tester.timedDrag(
      find.byKey(const ValueKey('spotlight-books')),
      const Offset(-120, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<BookSpotlight>(find.byType(BookSpotlight)).selectedId,
      'master',
    );
    expect(accent(tester), isNot(original));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Changing window width preserves the selected book and palette', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.byTooltip('Следующая книга'));
    await tester.pumpAndSettle();
    final selected = accent(tester);
    for (final width in [390.0, 1024.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<BookSpotlight>(find.byType(BookSpotlight)).selectedId,
        'master',
      );
      expect(accent(tester), selected);
      expect(
        tester
            .widget<PageView>(find.byKey(const ValueKey('spotlight-books')))
            .controller!
            .page,
        closeTo(1, .01),
      );
    }
  });
}
