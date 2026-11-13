import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/data/reading_activity.dart';
import 'package:flutter_app/features/home/presentation/widgets/reading_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime.now();
  var activity = const ReadingActivity();
  for (var day = 0; day < 28; day++) {
    for (var page = 1; page <= day % 5; page++) {
      activity = activity.record(
        'reading',
        page,
        DateTime(today.year, today.month, today.day - day),
      );
    }
  }
  const books = [
    LibraryBook(
      id: 'reading',
      title: 'Читаю',
      author: '',
      mood: '',
      description: '',
      coverStyle: 0,
      filePath: '/reading.txt',
      page: 2,
      pageCount: 10,
    ),
    LibraryBook(
      id: 'done',
      title: 'Прочитано',
      author: '',
      mood: '',
      description: '',
      coverStyle: 1,
      filePath: '/done.txt',
      page: 10,
      pageCount: 10,
    ),
    LibraryBook(
      id: 'unopened',
      title: 'Не открыта',
      author: '',
      mood: '',
      description: '',
      coverStyle: 2,
      filePath: '/unopened.pdf',
    ),
  ];

  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('Charts fit width $width, dark $dark, with enlarged text', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1200);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1200),
                textScaler: const TextScaler.linear(2),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ReadingProgressCharts(
                    activity: activity,
                    books: books,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('28 дней'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('activity-bar-3')), findsOneWidget);
        expect(find.byKey(const ValueKey('activity-bar-4')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('activity-bar-3')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('activity-chart-caption')),
              )
              .data,
          contains(' — '),
        );
        final status = find.byKey(const ValueKey('shelf-status-1'));
        await tester.ensureVisible(status);
        await tester.pumpAndSettle();
        await tester.tap(status);
        await tester.pumpAndSettle();
        expect(find.text('Прочитано'), findsOneWidget);
        expect(find.text('Ещё не открыты'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'An empty activity chart displays zero rather than invented data',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: ReadingActivityChart(
              activity: ReadingActivity(),
              compact: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
      expect(find.textContaining('Откройте книгу'), findsOneWidget);
      expect(find.byKey(const ValueKey('activity-bar-6')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
