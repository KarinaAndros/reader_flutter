import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/home/presentation/screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  LicenseRegistry.addLicense(() async* {
    final credits = await rootBundle.loadString(
      'assets/images/AUTHOR_PORTRAITS_LICENSES.txt',
    );
    yield LicenseEntryWithLineBreaks(['Author portraits'], credits);
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _themeKey = 'app_theme';
  ThemeMode _themeMode = ThemeMode.light;
  bool _changedByUser = false;

  @override
  void initState() {
    super.initState();
    _restoreTheme();
  }

  Future<void> _restoreTheme() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted || _changedByUser) return;
      setState(() {
        _themeMode = preferences.getString(_themeKey) == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light;
      });
    } catch (_) {
      // Keep the default when local settings cannot be read.
    }
  }

  Future<void> _toggleTheme() async {
    setState(() {
      _changedByUser = true;
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
    final value = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_themeKey, value);
    } catch (_) {
      // Switching themes still works if the device cannot save the preference.
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MYB',
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: _themeMode,
    themeAnimationDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 650),
    home: HomeScreen(onToggleTheme: _toggleTheme),
    builder: (context, child) {
      final theme = Theme.of(context);
      final dark = theme.brightness == Brightness.dark;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: theme.brightness,
          systemNavigationBarColor: theme.scaffoldBackgroundColor,
          systemNavigationBarIconBrightness: dark
              ? Brightness.light
              : Brightness.dark,
        ),
        child: child!,
      );
    },
    debugShowCheckedModeBanner: false,
  );
}
