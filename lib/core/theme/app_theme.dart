import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      scaffoldBackgroundColor: AppColors.background,
    );
  }
}
