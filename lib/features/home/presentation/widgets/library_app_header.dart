import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/presentation/widgets/app_logo.dart';
import 'package:flutter_app/features/home/presentation/widgets/mirror_surface.dart';

class LibraryAppHeader extends StatelessWidget {
  const LibraryAppHeader({
    super.key,
    required this.desktop,
    this.onToggleTheme,
    this.onCheckForUpdates,
  });

  final bool desktop;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onCheckForUpdates;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    return MirrorSurface(
      accent: colors.primary,
      borderRadius: BorderRadius.zero,
      showShadow: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
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
                if (onCheckForUpdates != null)
                  IconButton(
                    tooltip: 'Проверить обновления',
                    onPressed: onCheckForUpdates,
                    icon: const Icon(Icons.system_update_alt_rounded),
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
        ),
      ),
    );
  }
}
