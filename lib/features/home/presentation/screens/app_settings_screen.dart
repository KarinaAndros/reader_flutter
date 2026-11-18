import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/features/home/presentation/widgets/ambient_background.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_atmosphere.dart';
import 'package:flutter_app/features/home/presentation/widgets/mirror_surface.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({
    super.key,
    required this.atmosphere,
    required this.onClearCache,
    this.onCheckForUpdates,
  });

  final BookAtmosphere atmosphere;
  final Future<void> Function() onClearCache;
  final Future<void> Function()? onCheckForUpdates;

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _clearing = false;
  bool _checking = false;
  String? _cacheMessage;
  String? _updateMessage;

  Future<void> _clearCache() async {
    if (_clearing) return;
    setState(() {
      _clearing = true;
      _cacheMessage = null;
    });
    var message = 'Кэш очищен. Книги и прогресс чтения сохранены.';
    try {
      await widget.onClearCache();
    } catch (_) {
      message = 'Не удалось полностью очистить кэш. Попробуйте ещё раз.';
    }
    if (!mounted) return;
    setState(() {
      _clearing = false;
      _cacheMessage = message;
    });
  }

  Future<void> _checkForUpdates() async {
    if (_checking || widget.onCheckForUpdates == null) return;
    setState(() {
      _checking = true;
      _updateMessage = null;
    });
    String? message;
    try {
      await widget.onCheckForUpdates!();
    } on PlatformException catch (error) {
      message = error.code == 'update_in_progress'
          ? 'Проверка обновлений уже выполняется.'
          : 'Не удалось запустить обновление. Попробуйте открыть MYB снова.';
    } on MissingPluginException {
      message = 'Обновления доступны в установленной версии MYB для macOS.';
    } catch (_) {
      message = 'Не удалось проверить обновления. Попробуйте ещё раз.';
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      _updateMessage = message;
    });
  }

  Widget _option({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool busy,
    required VoidCallback onTap,
    String? message,
  }) => MirrorSurface(
    accent: Theme.of(context).colorScheme.primary,
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(subtitle),
            trailing: busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right_rounded),
            enabled: !busy,
            onTap: busy ? null : onTap,
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Semantics(liveRegion: true, child: Text(message)),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Настройки'),
      leading: IconButton(
        tooltip: 'Назад в библиотеку',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: MirrorSurface(
        accent: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.zero,
        showShadow: false,
        child: const SizedBox.expand(),
      ),
    ),
    body: AmbientBackground(
      atmosphere: widget.atmosphere,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.onCheckForUpdates != null) ...[
                    _option(
                      icon: Icons.system_update_alt_rounded,
                      title: 'Проверить обновления',
                      subtitle: 'Новые версии MYB для macOS',
                      busy: _checking,
                      onTap: _checkForUpdates,
                      message: _updateMessage,
                    ),
                    const SizedBox(height: 20),
                  ],
                  _option(
                    icon: Icons.cleaning_services_outlined,
                    title: 'Сбросить кэш',
                    subtitle: 'Временные PDF-файлы и изображения. Книги, цитаты и прогресс сохранятся.',
                    busy: _clearing,
                    onTap: _clearCache,
                    message: _cacheMessage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
