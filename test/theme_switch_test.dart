import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/presentation/widgets/ambient_background.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_spotlight.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ThemeData bookTheme(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(AmbientBackground)));

  String selectedBook(WidgetTester tester) =>
      tester.widget<BookSpotlight>(find.byType(BookSpotlight)).selectedId;

  for (final width in [320.0, 1440.0]) {
    testWidgets('Themes switch and persist at width $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(bookTheme(tester).brightness, Brightness.light);
      expect(bookTheme(tester).scaffoldBackgroundColor, Colors.white);
      await tester.tap(find.byTooltip('Следующая книга'));
      await tester.pumpAndSettle();
      final selected = selectedBook(tester);

      await tester.tap(find.byTooltip('Тёмная тема'));
      await tester.pumpAndSettle();
      expect(bookTheme(tester).brightness, Brightness.dark);
      expect(selectedBook(tester), selected);
      expect(find.byTooltip('Светлая тема'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString('app_theme'),
        'dark',
      );
      final darkAccent = bookTheme(tester).colorScheme.primary;
      await tester.tap(find.byTooltip('Следующая книга'));
      await tester.pumpAndSettle();
      expect(bookTheme(tester).colorScheme.primary, isNot(darkAccent));
      expect(bookTheme(tester).brightness, Brightness.dark);

      // Recreating the application must restore the saved theme.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(bookTheme(tester).brightness, Brightness.dark);
      await tester.tap(find.byTooltip('Светлая тема'));
      await tester.pumpAndSettle();
      expect(bookTheme(tester).brightness, Brightness.light);
      expect(bookTheme(tester).scaffoldBackgroundColor, Colors.white);
      expect(
        (await SharedPreferences.getInstance()).getString('app_theme'),
        'light',
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Dark theme applies to search and book details', (tester) async {
    SharedPreferences.setMockInitialValues({'app_theme': 'dark'});
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Поиск'));
    await tester.pumpAndSettle();
    expect(bookTheme(tester).brightness, Brightness.dark);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.fillColor!.computeLuminance(), lessThan(.1));
    final tile = find.byKey(const ValueKey('book-tile-master'));
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: tile, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Добавить свою книгу'))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
