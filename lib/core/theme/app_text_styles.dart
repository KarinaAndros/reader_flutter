import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AppTextStyles {
  static const label = TextStyle(
    fontSize: 11,
    color: AppColors.label,
    fontWeight: FontWeight(600),
    letterSpacing: 2,
  );

  static const title = TextStyle(fontSize: 20);
  static const titleH2 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const titleColor = TextStyle(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.w600);
  static const titleH2Color = TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600);
}
