import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class AppInputStyles {
  static InputDecoration search({required String label}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.input,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.label, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.label, width: 1),
      ),
      floatingLabelStyle: TextStyle(color: AppColors.primary),
      labelStyle: TextStyle(color: AppColors.label),
      contentPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 20),
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: 20, right: 3),
        child: Icon(Icons.circle_outlined, color: AppColors.label),
      ),
    );
  }
}
