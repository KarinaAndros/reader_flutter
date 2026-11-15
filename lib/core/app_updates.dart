import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sparkle owns the download, signature verification, installation and relaunch.
class AppUpdates {
  static const channel = MethodChannel('myb/app_updates');

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> check() => channel.invokeMethod<void>('checkForUpdates');

  void prepareBeforeInstall(Future<void> Function()? save) {
    if (!supported) return;
    channel.setMethodCallHandler(
      save == null
          ? null
          : (call) async {
              if (call.method != 'prepareForUpdate') {
                throw MissingPluginException();
              }
              await save();
            },
    );
  }
}
