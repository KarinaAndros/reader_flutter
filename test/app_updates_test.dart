import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_app/core/app_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'installation waits for progress saving and reports save failures',
    (tester) async {
      final updates = AppUpdates();
      final saving = Completer<void>();
      updates.prepareBeforeInstall(() => saving.future);
      addTearDown(() => updates.prepareBeforeInstall(null));
      const codec = StandardMethodCodec();
      Object? response;
      var replied = false;
      Future<void> request() =>
          tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            AppUpdates.channel.name,
            codec.encodeMethodCall(const MethodCall('prepareForUpdate')),
            (data) {
              replied = true;
              try {
                response = codec.decodeEnvelope(data!);
              } catch (error) {
                response = error;
              }
            },
          );
      unawaited(request());
      await tester.pump();
      expect(replied, isFalse);
      saving.complete();
      await tester.pump();
      expect(replied, isTrue);
      expect(response, isNull);

      updates.prepareBeforeInstall(() async => throw StateError('save failed'));
      await request();
      expect(response, isA<PlatformException>());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
