import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_discovery_sheet.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_spotlight.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openPicker(WidgetTester tester) async {
    final entry = find.byKey(const ValueKey('random-book-picker'));
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
  }

  Future<void> choose(
    WidgetTester tester,
    String filterKey,
    String option,
  ) async {
    final field = find.byKey(ValueKey(filterKey));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    final item = find.byKey(ValueKey('${filterKey}option-$option'));
    await tester.scrollUntilVisible(
      item,
      80,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    final menuText = tester.renderObject<RenderParagraph>(item);
    expect(
      menuText.size.height,
      greaterThanOrEqualTo(
        menuText.getMaxIntrinsicHeight(menuText.size.width) - .01,
      ),
    );
    await tester.tap(item);
    await tester.pumpAndSettle();
    final selectedText = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(ValueKey('$filterKey$option')),
        matching: find.text(option),
      ),
    );
    expect(
      selectedText.size.height,
      greaterThanOrEqualTo(
        selectedText.getMaxIntrinsicHeight(selectedText.size.width) - .01,
      ),
    );
  }

  for (final (width, scale) in [(320.0, 1.0), (320.0, 2.0), (1024.0, 1.0)]) {
    testWidgets('Genre and mood pick a matching book at $width / $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await openPicker(tester);
      await choose(tester, 'discovery-genre-', 'Роман');
      await choose(tester, 'discovery-mood-', 'Мечтательное');
      expect(find.text('Подходит книг: 1'), findsOneWidget);
      final pick = find.byKey(const ValueKey('pick-random-book'));
      await tester.ensureVisible(pick);
      await tester.pumpAndSettle();
      await tester.tap(pick);
      await tester.pumpAndSettle();
      expect(
        tester.widget<BookSpotlight>(find.byType(BookSpotlight)).selectedId,
        'dandelion',
      );
      final open = find.byKey(const ValueKey('open-picked-book'));
      await tester.ensureVisible(open);
      await tester.pumpAndSettle();
      await tester.tap(open);
      await tester.pumpAndSettle();
      expect(find.byType(BookDiscoverySheet), findsNothing);
      expect(find.text('Добавить свою книгу'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Empty filter combination can be reset', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await openPicker(tester);
    await choose(tester, 'discovery-genre-', 'Роман');
    await choose(tester, 'discovery-mood-', 'Загадочное');
    expect(find.text('Нет книг с таким сочетанием'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('pick-random-book')))
          .onPressed,
      isNull,
    );
    final reset = find.text('Сбросить фильтры');
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(find.text('Подходит книг: 6'), findsOneWidget);
    expect(find.text('Нет книг с таким сочетанием'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
