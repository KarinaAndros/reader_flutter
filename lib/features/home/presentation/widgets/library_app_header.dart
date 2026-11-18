import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/presentation/widgets/app_logo.dart';
import 'package:flutter_app/features/home/presentation/widgets/mirror_surface.dart';

class LibraryAppHeader extends StatelessWidget {
  const LibraryAppHeader({
    super.key,
    required this.desktop,
    this.onToggleTheme,
    this.onOpenSettings,
  });

  final bool desktop;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return MirrorSurface(
      accent: colors.primary,
      borderRadius: BorderRadius.zero,
      showShadow: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: desktop ? 36 : 20,
          vertical: 16,
        ),
        child: Row(
          children: [
            const AppLogo(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MYB',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  if (desktop)
                    Text(
                      'Ваша личная библиотека',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Настройки',
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
            IconButton.filledTonal(
              key: const ValueKey('theme-toggle'),
              tooltip: dark ? 'Светлая тема' : 'Тёмная тема',
              onPressed: onToggleTheme,
              icon: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
