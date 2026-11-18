import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_spotlight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<LibraryBook> books;
  late String selectedId;
  late StateSetter update;
  final carousel = find.byKey(const ValueKey('spotlight-books'));

  double page(WidgetTester tester) =>
      tester.widget<PageView>(carousel).controller!.page!;

  Future<void> open(WidgetTester tester, {bool reduceMotion = false}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return BookSpotlight(
                  books: books,
                  selectedId: selectedId,
                  onSelected: (book) => setState(() => selectedId = book.id),
                  onOpen: (_) {},
                  onFavorite: (_) {},
                  isFavorite: (_) => false,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipe(WidgetTester tester, int direction) async {
    final width = tester.getSize(carousel).width;
    final fraction = tester
        .widget<PageView>(carousel)
        .controller!
        .viewportFraction;
    await tester.timedDrag(
      carousel,
      Offset(direction * width * fraction * .9, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    books = List.of(editorialBooks);
    selectedId = books.first.id;
  });

  testWidgets('swipes loop smoothly in both directions over multiple cycles', (
    tester,
  ) async {
    await open(tester);
    final initialPage = page(tester);
    await swipe(tester, 1);
    expect(selectedId, books.last.id);
    expect(page(tester), closeTo(initialPage - 1, .01));
    for (var index = 0; index < books.length * 2 + 1; index++) {
      final previous = page(tester);
      await swipe(tester, -1);
      expect(selectedId, books[index % books.length].id);
      expect(page(tester), closeTo(previous + 1, .01));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('recentering preserves selection and allows continued swiping', (
    tester,
  ) async {
    await open(tester);
    tester.widget<PageView>(carousel).controller!.jumpToPage(1);
    await tester.pumpAndSettle();
    expect(selectedId, books[1].id);
    expect(page(tester), greaterThan(1));
    await swipe(tester, 1);
    expect(selectedId, books.first.id);
    await swipe(tester, 1);
    expect(selectedId, books.last.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrows and dots use the nearest copy at the loop boundary', (
    tester,
  ) async {
    await open(tester);
    final initialPage = page(tester);
    await tester.tap(find.byTooltip('Предыдущая книга'));
    await tester.pumpAndSettle();
    expect(selectedId, books.last.id);
    expect(page(tester), closeTo(initialPage - 1, .01));
    await tester.tap(find.byTooltip('Следующая книга'));
    await tester.pumpAndSettle();
    expect(selectedId, books.first.id);
    expect(page(tester), closeTo(initialPage, .01));
    await tester.tap(find.byTooltip('Перейти к книге: ${books.last.title}'));
    await tester.pumpAndSettle();
    expect(page(tester), closeTo(initialPage - 1, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reordering and adding books preserve selection after looping', (
    tester,
  ) async {
    await open(tester);
    await swipe(tester, 1);
    final selected = selectedId;
    update(() => books = books.reversed.toList());
    await tester.pumpAndSettle();
    expect(selectedId, selected);
    expect(page(tester).round() % books.length, 0);
    update(() => books = books.take(3).toList());
    await tester.pumpAndSettle();
    await swipe(tester, 1);
    expect(selectedId, books.last.id);
    update(() => books = [editorialBooks.first, ...books]);
    await tester.pumpAndSettle();
    expect(page(tester).round() % books.length, books.length - 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty and single-book carousels are stable with reduced motion',
    (tester) async {
      books = [books.first];
      await open(tester, reduceMotion: true);
      await swipe(tester, 1);
      expect(page(tester), 0);
      final next = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton && widget.tooltip == 'Следующая книга',
        ),
      );
      expect(next.onPressed, isNull);
      update(() => books = List.of(editorialBooks));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Предыдущая книга'));
      await tester.pumpAndSettle();
      expect(selectedId, books.last.id);
      update(() => books = []);
      await tester.pumpAndSettle();
      expect(carousel, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
