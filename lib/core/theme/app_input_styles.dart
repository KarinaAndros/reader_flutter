import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AppInputStyles {
  static InputDecoration search({required String label}) {
    return InputDecoration(
      hintText: label,
      filled: true,
      fillColor: AppColors.input,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.label),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.label),
    );
  }
}
