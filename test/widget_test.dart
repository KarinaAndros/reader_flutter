import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [320.0, 390.0, 1024.0, 1440.0]) {
    testWidgets('Book shelves fit a $width pixel viewport', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('Популярные книги для чтения'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Открыть TXT или PDF'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Открыть TXT или PDF').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Shelves support enlarged system text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() async {
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.view.devicePixelRatio = 1;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await BookLibrary().save([
      const LibraryBook(
        id: 'large-text-book',
        title: 'Длинное название книги для проверки полки',
        author: 'Из вашей библиотеки',
        mood: '',
        description: '',
        coverStyle: 0,
        filePath: '/books/large-text.txt',
        page: 12,
        pageCount: 100,
      ),
    ]);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Ваш ритм'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search finds authors and favorites appear in the library', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'оруэлл');
    await tester.pumpAndSettle();
    expect(find.text('1984'), findsWidgets);
    expect(find.text('Маленький принц'), findsNothing);
    final favorite = find.byTooltip('В избранное: 1984');
    await tester.ensureVisible(favorite);
    await tester.pumpAndSettle();
    await tester.tap(favorite);
    await tester.pumpAndSettle();
    expect(await BookLibrary().loadFavorites(), contains('1984'));
    await tester.enterText(find.byType(TextField), '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.tap(find.text('Библиотека').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Избранное'));
    await tester.pumpAndSettle();
    expect(find.text('1984'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'нет такой книги');
    await tester.pumpAndSettle();
    expect(find.text('История пока не нашлась'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home shows imported history empty state without editorial shelf',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(find.text('Недавно открытые'), findsOneWidget);
      expect(
        find.text('Книги, которые вы открывали с устройства'),
        findsNothing,
      );
      expect(find.text('Здесь появятся ваши книги'), findsOneWidget);
      expect(find.text('Открыть TXT или PDF'), findsOneWidget);
      expect(find.text('Выберите свою историю'), findsNothing);
      expect(find.text('Ваша цель на год'), findsNothing);
      expect(find.text('Ваш ритм'), findsOneWidget);
      expect(
        find.textContaining(RegExp('между строк', caseSensitive: false)),
        findsNothing,
      );
      expect(find.byType(ListView), findsNothing);
      await tester.ensureVisible(find.text('Подробнее'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подробнее'));
      await tester.pumpAndSettle();
      expect(find.text('Ваша цель на год'), findsOneWidget);
      expect(find.text('Активность чтения'), findsOneWidget);
      expect(find.text('Книжная полка'), findsOneWidget);
      await tester.tap(find.byTooltip('Цитаты'));
      await tester.pumpAndSettle();
      expect(find.text('Слова, которые останутся'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
