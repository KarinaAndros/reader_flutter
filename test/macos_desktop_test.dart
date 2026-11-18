import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/app_updates.dart';
import 'package:flutter_app/features/home/presentation/widgets/ambient_background.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_discovery_sheet.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DesktopPicker extends FilePickerPlatform {
  int calls = 0;
  List<String>? extensions;

  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    calls++;
    extensions = allowedExtensions;
    return [];
  }
}

Future<void> _command(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pumpAndSettle();
}

PlatformMenuItem _menuItem(WidgetTester tester, String label) {
  final menu = tester.widget<PlatformMenuBar>(find.byType(PlatformMenuBar));
  return menu.menus
      .expand((menu) => menu.descendants)
      .firstWhere((item) => item.label == label);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.menu, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.menu, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdates.channel, null);
  });

  Future<void> openApp(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 820);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
  }

  testWidgets('macOS search and section shortcuts work with keyboard focus', (
    tester,
  ) async {
    await openApp(tester);
    expect(find.byType(PlatformMenuBar), findsOneWidget);
    expect(_menuItem(tester, 'Открыть книгу…').onSelected, isNotNull);
    await _command(tester, LogicalKeyboardKey.keyF);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), 'оруэлл');
    await tester.pumpAndSettle();
    expect(find.text('1984'), findsWidgets);
    await _command(tester, LogicalKeyboardKey.digit1);
    expect(find.text('Популярные книги для чтения'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('macOS open command uses the file picker', (tester) async {
    final original = FilePickerPlatform.instance;
    final picker = _DesktopPicker();
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = original);
    await openApp(tester);
    await _command(tester, LogicalKeyboardKey.keyO);
    expect(picker.calls, 1);
    expect(picker.extensions, containsAll(['txt', 'pdf', 'md']));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets(
    'macOS settings menu and shortcut expose updates and handle failures',
    (tester) async {
      final calls = <String>[];
      var fail = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AppUpdates.channel, (call) async {
            calls.add(call.method);
            if (fail) throw PlatformException(code: 'update_in_progress');
            return null;
          });
      await openApp(tester);
      expect(find.byTooltip('Проверить обновления'), findsNothing);
      _menuItem(tester, 'Настройки…').onSelected!();
      await tester.pumpAndSettle();
      expect(find.text('Сбросить кэш'), findsOneWidget);
      await tester.tap(find.text('Проверить обновления'));
      await tester.pumpAndSettle();
      expect(calls, ['checkForUpdates']);
      await tester.tap(find.byTooltip('Назад в библиотеку'));
      await tester.pumpAndSettle();
      await _command(tester, LogicalKeyboardKey.comma);
      fail = true;
      await tester.tap(find.text('Проверить обновления'));
      await tester.pumpAndSettle();
      expect(calls, ['checkForUpdates', 'checkForUpdates']);
      expect(find.text('Проверка обновлений уже выполняется.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('macOS menus pause library commands while a dialog is open', (
    tester,
  ) async {
    await openApp(tester);
    await _command(tester, LogicalKeyboardKey.keyR, shift: true);
    expect(find.byType(BookDiscoverySheet), findsOneWidget);
    expect(_menuItem(tester, 'Открыть книгу…').onSelected, isNull);
    await tester.tap(find.byTooltip('Закрыть подбор'));
    await tester.pumpAndSettle();
    expect(_menuItem(tester, 'Открыть книгу…').onSelected, isNotNull);
    await _command(tester, LogicalKeyboardKey.keyD);
    expect(
      Theme.of(tester.element(find.byType(AmbientBackground))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
