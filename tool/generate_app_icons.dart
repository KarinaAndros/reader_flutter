// Regenerate all launcher assets with:
// flutter test tool/generate_app_icons.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _leftPath =
    'M236 324 C326 300 403 331 496 401 L496 716 C405 655 333 627 236 654 Q220 658 220 640 L220 345 Q220 329 236 324 Z';
const _rightPath =
    'M528 401 C621 331 698 300 788 324 Q804 329 804 345 L804 640 Q804 658 788 654 C691 627 619 655 528 716 Z';
const _bookmarkPath = 'M684 316 Q711 312 740 318 L740 438 L712 417 L684 438 Z';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Generate MYB launcher icons', () async {
    final full = await _render();
    final round = await _render(round: true);
    final mac = await _render(mac: true);
    final foreground = await _render(foreground: true);
    try {
      await _save(full, 'assets/branding/app_icon.png', 1024);
      await _text('assets/branding/app_icon.svg', _svg);
      for (final platform in ['ios', 'macos']) {
        final folder = '$platform/Runner/Assets.xcassets/AppIcon.appiconset';
        final metadata = jsonDecode(
          await File('$folder/Contents.json').readAsString(),
        ) as Map;
        for (final entry in metadata['images'] as List) {
          final size =
              (double.parse((entry['size'] as String).split('x').first) *
                      double.parse(
                        (entry['scale'] as String).replaceAll('x', ''),
                      ))
                  .round();
          await _save(
            platform == 'macos' ? mac : full,
            '$folder/${entry['filename']}',
            size,
            alpha: platform == 'macos',
          );
        }
      }
      for (final entry in {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      }.entries) {
        final folder = 'android/app/src/main/res/mipmap-${entry.key}';
        await _save(
          full,
          '$folder/ic_launcher.png',
          (48 * entry.value).round(),
        );
        await _save(
          round,
          '$folder/ic_launcher_round.png',
          (48 * entry.value).round(),
          alpha: true,
        );
        await _save(
          foreground,
          '$folder/ic_launcher_foreground.png',
          (108 * entry.value).round(),
          alpha: true,
        );
      }
      for (final version in [26, 33]) {
        for (final name in ['ic_launcher', 'ic_launcher_round']) {
          await _text(
            'android/app/src/main/res/mipmap-anydpi-v$version/$name.xml',
            '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
${version == 33 ? '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n' : ''}</adaptive-icon>
''',
          );
        }
      }
      await _text(
        'android/app/src/main/res/values/brand.xml',
        '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">MYB</string>
    <color name="ic_launcher_background">#6553D6</color>
</resources>
''',
      );
      await _text(
        'android/app/src/main/res/drawable/ic_launcher_monochrome.xml',
        '''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="1024" android:viewportHeight="1024">
    <group android:pivotX="512" android:pivotY="512" android:scaleX="0.85" android:scaleY="0.85">
        <path android:fillColor="#FFFFFFFF" android:pathData="$_leftPath $_rightPath" />
    </group>
</vector>
''',
      );
      for (final size in [192, 512]) {
        await _save(full, 'web/icons/Icon-$size.png', size);
        await _save(full, 'web/icons/Icon-maskable-$size.png', size);
      }
      await _save(round, 'web/favicon.png', 32, alpha: true);
    } finally {
      full.dispose();
      round.dispose();
      mac.dispose();
      foreground.dispose();
    }
  });
}

Future<ui.Image> _render({
  bool round = false,
  bool mac = false,
  bool foreground = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const bounds = ui.Rect.fromLTWH(0, 0, 1024, 1024);
  if (mac) {
    final backplate = ui.RRect.fromRectAndRadius(
      const ui.Rect.fromLTWH(64, 64, 896, 896),
      const ui.Radius.circular(200),
    );
    canvas.drawShadow(
      ui.Path()..addRRect(backplate),
      const ui.Color(0x33000000),
      18,
      true,
    );
    canvas.clipRRect(backplate);
    canvas.translate(64, 64);
    canvas.scale(.875);
  } else if (round) {
    canvas.clipPath(ui.Path()..addOval(bounds));
  }
  if (!foreground) {
    canvas.drawRect(
      bounds,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          const ui.Offset(40, 0),
          const ui.Offset(900, 1024),
          const [
            ui.Color(0xFF8B7DF0),
            ui.Color(0xFF6553D6),
            ui.Color(0xFF44318C),
          ],
          [0, .48, 1],
        ),
    );
  } else {
    canvas.translate(512, 512);
    canvas.scale(.85);
    canvas.translate(-512, -512);
  }
  final left = ui.Path()
    ..moveTo(236, 324)
    ..cubicTo(326, 300, 403, 331, 496, 401)
    ..lineTo(496, 716)
    ..cubicTo(405, 655, 333, 627, 236, 654)
    ..quadraticBezierTo(220, 658, 220, 640)
    ..lineTo(220, 345)
    ..quadraticBezierTo(220, 329, 236, 324)
    ..close();
  final right = ui.Path()
    ..moveTo(528, 401)
    ..cubicTo(621, 331, 698, 300, 788, 324)
    ..quadraticBezierTo(804, 329, 804, 345)
    ..lineTo(804, 640)
    ..quadraticBezierTo(804, 658, 788, 654)
    ..cubicTo(691, 627, 619, 655, 528, 716)
    ..close();
  final shadow = ui.Path()
    ..addPath(left, const ui.Offset(0, 22))
    ..addPath(right, const ui.Offset(0, 22));
  canvas.drawShadow(shadow, const ui.Color(0x661B104C), 14, false);
  canvas.drawPath(shadow, ui.Paint()..color = const ui.Color(0xFFBDB0F0));
  canvas.drawPath(
    left,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(230, 320),
        const ui.Offset(496, 716),
        const [ui.Color(0xFFFFFDFA), ui.Color(0xFFE4DDFB)],
      ),
  );
  canvas.drawPath(
    right,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(528, 370),
        const ui.Offset(804, 700),
        const [ui.Color(0xFFFFFFFF), ui.Color(0xFFF2EFFF)],
      ),
  );
  final bookmark = ui.Path()
    ..moveTo(684, 316)
    ..quadraticBezierTo(711, 312, 740, 318)
    ..lineTo(740, 438)
    ..lineTo(712, 417)
    ..lineTo(684, 438)
    ..close();
  canvas.drawPath(bookmark, ui.Paint()..color = const ui.Color(0xFF77D6BC));
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(1024, 1024);
  } finally {
    picture.dispose();
  }
}

Future<void> _save(
  ui.Image source,
  String path,
  int size, {
  bool alpha = false,
}) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    source,
    const ui.Rect.fromLTWH(0, 0, 1024, 1024),
    ui.Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  try {
    final rgba = (await image.toByteData(
      format: ui.ImageByteFormat.rawStraightRgba,
    ))!.buffer.asUint8List();
    final rows = BytesBuilder();
    for (var y = 0; y < size; y++) {
      rows.addByte(0);
      for (var x = 0; x < size; x++) {
        final index = (y * size + x) * 4;
        rows.add(rgba.sublist(index, index + (alpha ? 4 : 3)));
      }
    }
    final header = ByteData(13)
      ..setUint32(0, size)
      ..setUint32(4, size)
      ..setUint8(8, 8)
      ..setUint8(9, alpha ? 6 : 2);
    final png = BytesBuilder()
      ..add([137, 80, 78, 71, 13, 10, 26, 10])
      ..add(_chunk('IHDR', header.buffer.asUint8List()))
      ..add(_chunk('IDAT', ZLibEncoder().convert(rows.takeBytes())))
      ..add(_chunk('IEND', []));
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(png.takeBytes());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

List<int> _chunk(String name, List<int> data) {
  final content = [...ascii.encode(name), ...data];
  var crc = 0xFFFFFFFF;
  for (final byte in content) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xEDB88320 : 0);
    }
  }
  final length = ByteData(4)..setUint32(0, data.length);
  final checksum = ByteData(4)..setUint32(0, crc ^ 0xFFFFFFFF);
  return [
    ...length.buffer.asUint8List(),
    ...content,
    ...checksum.buffer.asUint8List(),
  ];
}

Future<void> _text(String path, String content) async {
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}

const _svg =
    '''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="bg" x2=".85" y2="1"><stop stop-color="#8B7DF0"/><stop offset=".48" stop-color="#6553D6"/><stop offset="1" stop-color="#44318C"/></linearGradient>
    <linearGradient id="left" x2="1" y2="1"><stop stop-color="#FFFDFA"/><stop offset="1" stop-color="#E4DDFB"/></linearGradient>
    <linearGradient id="right" x2="1" y2="1"><stop stop-color="#FFF"/><stop offset="1" stop-color="#F2EFFF"/></linearGradient>
  </defs>
  <rect width="1024" height="1024" fill="url(#bg)"/>
  <path d="$_leftPath $_rightPath" transform="translate(0 22)" fill="#BDB0F0"/>
  <path d="$_leftPath" fill="url(#left)"/>
  <path d="$_rightPath" fill="url(#right)"/>
  <path d="$_bookmarkPath" fill="#77D6BC"/>
</svg>
''';
