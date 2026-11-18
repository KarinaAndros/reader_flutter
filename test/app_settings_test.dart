import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/screens/app_settings_screen.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_atmosphere.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings open from the mobile header and hide macOS updates', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    expect(find.byType(AppSettingsScreen), findsOneWidget);
    expect(find.text('Сбросить кэш'), findsOneWidget);
    expect(find.text('Проверить обновления'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Назад в библиотеку'));
    await tester.pumpAndSettle();
    expect(find.byType(AppSettingsScreen), findsNothing);
  });

  testWidgets(
    'cache reset waits, blocks repeated taps and reports completion or failure',
    (tester) async {
      final operation = Completer<void>();
      var calls = 0;
      var fail = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AppSettingsScreen(
            atmosphere: BookAtmosphere.forBook(editorialBooks.first),
            onClearCache: () async {
              calls++;
              if (fail) throw StateError('cache unavailable');
              await operation.future;
            },
          ),
        ),
      );
      await tester.tap(find.text('Сбросить кэш'));
      await tester.pump();
      await tester.tap(find.text('Сбросить кэш'));
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('Кэш очищен.'), findsNothing);
      operation.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Кэш очищен. Книги и прогресс чтения сохранены.'),
        findsOneWidget,
      );
      fail = true;
      await tester.tap(find.text('Сбросить кэш'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(
        find.text('Не удалось полностью очистить кэш. Попробуйте ещё раз.'),
        findsOneWidget,
      );
      expect(find.textContaining('Кэш очищен.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
