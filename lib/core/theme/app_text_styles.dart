import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AppTextStyles {
  static const label = TextStyle(
    fontSize: 10,
    color: AppColors.label,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
  );

  static const title = TextStyle(
    fontSize: 20,
    color: AppColors.text,
    fontWeight: FontWeight.w600,
  );
  static const titleH2 = TextStyle(
    fontSize: 15,
    color: AppColors.text,
    fontWeight: FontWeight.w600,
  );
  static const titleColor = TextStyle(
    fontSize: 22,
    color: AppColors.primary,
    fontWeight: FontWeight.w700,
  );
  static const titleH2Color = TextStyle(
    fontSize: 15,
    color: AppColors.primary,
    fontWeight: FontWeight.w700,
  );
}
