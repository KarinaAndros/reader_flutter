import 'package:flutter/material.dart';

class AppInputStyles {
  static InputDecoration search(
    BuildContext context, {
    required String label,
    Color? accent,
  }) {
    return InputDecoration(
      hintText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: accent ?? Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      prefixIcon: Icon(
        Icons.search_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
