import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/author_avatar.dart';
import 'package:flutter_app/features/home/presentation/widgets/library_components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hover border stays beneath the author avatar', (tester) async {
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: boundaryKey,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: SizedBox(
                  width: 160,
                  child: BookTile(
                    book: const LibraryBook(
                      id: 'hover',
                      title: 'Книга',
                      author: '',
                      mood: 'Любое',
                      description: '',
                      coverStyle: 0,
                    ),
                    coverHeight: 220,
                    favorite: false,
                    onTap: () {},
                    onFavorite: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<List<int>> avatarPixel() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final avatar = tester.renderObject<RenderBox>(find.byType(AuthorAvatar));
      final size = avatar.size.width;
      // This point is inside the opaque avatar, exactly where the cover's
      // right border passes behind it. Avoid the fallback icon in its center.
      final point = boundary.globalToLocal(
        avatar.localToGlobal(Offset(size * .65 - .75, size * .8)),
      );
      return (await tester.runAsync(() async {
        const ratio = 3.0;
        final image = await boundary.toImage(pixelRatio: ratio);
        try {
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!.buffer.asUint8List();
          final offset =
              ((point.dy * ratio).round() * image.width +
                  (point.dx * ratio).round()) *
              4;
          return data.sublist(offset, offset + 4);
        } finally {
          image.dispose();
        }
      }))!;
    }

    final before = await avatarPixel();
    final mouse = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    final cover = tester.getTopLeft(find.byType(BookTile));
    await mouse.moveTo(cover + const Offset(80, 100));
    await tester.pumpAndSettle();
    expect(
      await avatarPixel(),
      before,
      reason: 'The highlight must not paint across the opaque author avatar',
    );
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
