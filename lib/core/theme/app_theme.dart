import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get light => forAccent(AppColors.primary);

  static ThemeData get dark =>
      forAccent(const Color(0xFF94C8E8), brightness: Brightness.dark);

  static ThemeData forAccent(
    Color accent, {
    Brightness brightness = Brightness.light,
  }) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF15191F) : AppColors.background;
    final surface = dark ? const Color(0xFF222932) : AppColors.surface;
    final text = dark ? const Color(0xFFF1F2F6) : AppColors.text;
    final label = dark ? const Color(0xFFABB4C2) : AppColors.label;
    final input = dark ? const Color(0xFF282F39) : AppColors.input;
    final divider = dark ? const Color(0xFF39424E) : AppColors.divider;
    final grey = dark ? const Color(0xFF778597) : AppColors.grey;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: dark ? AppColors.ink : AppColors.white,
      secondary: accent,
      primaryContainer: Color.alphaBlend(accent.withValues(alpha: .1), surface),
      onPrimaryContainer: accent,
      secondaryContainer: Color.alphaBlend(
        accent.withValues(alpha: .1),
        surface,
      ),
      onSecondaryContainer: accent,
      onSecondary: dark ? AppColors.ink : AppColors.white,
      surface: surface,
      onSurface: text,
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFBA1A1A),
      onError: dark ? const Color(0xFF690005) : AppColors.white,
      onSurfaceVariant: label,
      surfaceContainerLowest: background,
      surfaceContainerLow: input,
      surfaceContainer: dark
          ? const Color(0xFF2B333E)
          : const Color(0xFFF1F4F7),
      surfaceContainerHigh: dark
          ? const Color(0xFF333D49)
          : const Color(0xFFEDF1F5),
      surfaceContainerHighest: dark
          ? const Color(0xFF3D4856)
          : const Color(0xFFE7ECF2),
      surfaceTint: Colors.transparent,
      outline: grey,
      outlineVariant: divider,
    );
    final buttonTextStyle = ThemeData(brightness: brightness)
        .textTheme
        .labelLarge!
        .copyWith(fontSize: 14, fontWeight: FontWeight.w600);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: TextTheme(
        displaySmall: TextStyle(
          color: text,
          fontSize: 34,
          height: 1.16,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineSmall: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        bodyLarge: TextStyle(color: text, fontSize: 16, height: 1.45),
        bodyMedium: TextStyle(color: label, fontSize: 14, height: 1.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      dividerTheme: DividerThemeData(color: divider),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: divider,
        thumbColor: accent,
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: accent.withValues(alpha: .15),
        labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 10)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFFE2E7ED) : AppColors.ink,
        contentTextStyle: TextStyle(
          color: dark ? AppColors.ink : AppColors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
