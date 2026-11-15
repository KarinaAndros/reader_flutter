import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/features/home/presentation/widgets/library_components.dart';

class MacOSLibraryMenu extends StatelessWidget {
  const MacOSLibraryMenu({
    super.key,
    required this.enabled,
    required this.onOpen,
    required this.onSearch,
    required this.onPickBook,
    required this.onSelectSection,
    required this.onToggleTheme,
    required this.onCheckForUpdates,
    required this.child,
  });

  final bool enabled;
  final VoidCallback? onOpen, onToggleTheme;
  final VoidCallback? onCheckForUpdates;
  final VoidCallback onSearch, onPickBook;
  final ValueChanged<int> onSelectSection;
  final Widget child;

  static void _edit(Intent intent) {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context != null) Actions.maybeInvoke(context, intent);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return child;
    return PlatformMenuBar(
      menus: [
        PlatformMenu(
          label: 'MYB',
          menus: [
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.about,
            ),
            PlatformMenuItem(
              label: 'Проверить обновления…',
              onSelected: onCheckForUpdates,
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Переключить тему',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyD,
                    meta: true,
                  ),
                  onSelected: enabled ? onToggleTheme : null,
                ),
              ],
            ),
            const PlatformMenuItemGroup(
              members: [
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.hide,
                ),
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.hideOtherApplications,
                ),
                PlatformProvidedMenuItem(
                  type: PlatformProvidedMenuItemType.showAllApplications,
                ),
              ],
            ),
            const PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.quit,
            ),
          ],
        ),
        PlatformMenu(
          label: 'Файл',
          menus: [
            PlatformMenuItem(
              label: 'Открыть книгу…',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyO,
                meta: true,
              ),
              onSelected: enabled ? onOpen : null,
            ),
            PlatformMenuItem(
              label: 'Подобрать книгу…',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyR,
                meta: true,
                shift: true,
              ),
              onSelected: enabled ? onPickBook : null,
            ),
          ],
        ),
        PlatformMenu(
          label: 'Правка',
          menus: [
            PlatformMenuItem(
              label: 'Вырезать',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyX,
                meta: true,
              ),
              onSelected: () => _edit(
                const CopySelectionTextIntent.cut(
                  SelectionChangedCause.keyboard,
                ),
              ),
            ),
            PlatformMenuItem(
              label: 'Копировать',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyC,
                meta: true,
              ),
              onSelected: () => _edit(CopySelectionTextIntent.copy),
            ),
            PlatformMenuItem(
              label: 'Вставить',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyV,
                meta: true,
              ),
              onSelected: () =>
                  _edit(const PasteTextIntent(SelectionChangedCause.keyboard)),
            ),
            PlatformMenuItem(
              label: 'Выделить всё',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyA,
                meta: true,
              ),
              onSelected: () => _edit(
                const SelectAllTextIntent(SelectionChangedCause.keyboard),
              ),
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Найти книгу…',
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyF,
                    meta: true,
                  ),
                  onSelected: enabled ? onSearch : null,
                ),
              ],
            ),
          ],
        ),
        PlatformMenu(
          label: 'Переход',
          menus: [
            for (var index = 0; index < librarySections.length; index++)
              PlatformMenuItem(
                label: librarySections[index],
                shortcut: SingleActivator(_sectionKeys[index], meta: true),
                onSelected: enabled ? () => onSelectSection(index) : null,
              ),
          ],
        ),
        const PlatformMenu(
          label: 'Окно',
          menus: [
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.minimizeWindow,
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.zoomWindow,
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.toggleFullScreen,
            ),
          ],
        ),
      ],
      child: CallbackShortcuts(
        bindings: enabled
            ? {
                const SingleActivator(LogicalKeyboardKey.keyO, meta: true):
                    ?onOpen,
                const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
                    onSearch,
                const SingleActivator(
                  LogicalKeyboardKey.keyR,
                  meta: true,
                  shift: true,
                ): onPickBook,
                const SingleActivator(LogicalKeyboardKey.keyD, meta: true):
                    ?onToggleTheme,
                for (var index = 0; index < librarySections.length; index++)
                  SingleActivator(_sectionKeys[index], meta: true): () =>
                      onSelectSection(index),
              }
            : {},
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  static const _sectionKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
  ];
}
