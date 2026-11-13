import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/author_avatar.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_palette.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.overlay,
    this.showAuthorAvatar = true,
    this.showShadow = true,
  });
  final LibraryBook book;
  final bool showAuthorAvatar;
  final bool showShadow;

  /// Keep cover highlights and ink effects below the opaque author avatar.
  final Widget? overlay;

  static const palettes = BookPalette.editorial;

  @override
  Widget build(BuildContext context) {
    final fallback = _IllustratedCover(book: book);
    return Semantics(
      label: 'Обложка: ${book.title}',
      image: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final avatarSize = (constraints.maxWidth * .26).clamp(12.0, 48.0);
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: showShadow
                      ? const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (book.isPdf)
                      PdfDocumentViewBuilder.file(
                        book.filePath!,
                        loadingBuilder: (_) => fallback,
                        errorBuilder: (_, error, stackTrace) => fallback,
                        builder: (context, document) =>
                            document == null || document.pages.isEmpty
                            ? fallback
                            : ColoredBox(
                                color: Colors.white,
                                child: PdfPageView(
                                  document: document,
                                  pageNumber: 1,
                                  maximumDpi: 100,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      )
                    else
                      fallback,
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x48000000),
                              Color(0x12FFFFFF),
                              Colors.transparent,
                            ],
                            stops: [0, 0.045, 0.12],
                          ),
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (overlay != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: overlay!,
                  ),
                ),
              if (showAuthorAvatar)
                Positioned(
                  top: -avatarSize * .4,
                  right: -avatarSize * .35,
                  child: AuthorAvatar(author: book.author, size: avatarSize),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _IllustratedCover extends StatelessWidget {
  const _IllustratedCover({required this.book});
  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    final palette = BookPalette.forBook(book);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette[0], palette[1]],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: book.isLocal
                    ? _PersonalCoverArt(
                        book.coverSeed ?? book.coverStyle,
                        palette[2],
                      )
                    : _CoverArt(book.coverStyle, palette[2]),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  width * .12,
                  width * .13,
                  width * .1,
                  width * .12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.isLocal
                          ? 'ЛИЧНАЯ БИБЛИОТЕКА'
                          : book.author.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: palette[2],
                        fontSize: width * .051,
                        fontWeight: FontWeight.w600,
                        letterSpacing: width * .007,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: width * .09),
                    Text(
                      book.isLocal
                          ? book.title
                          : switch (book.coverStyle) {
                              0 => 'Маленький\nпринц',
                              1 => 'Мастер и\nМаргарита',
                              3 => 'Норвежский\nлес',
                              4 => 'Вино из\nодуванчиков',
                              5 => 'Старик\nи море',
                              _ => book.title,
                            },
                      maxLines: book.isLocal ? 4 : 3,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: palette[2],
                        fontSize:
                            width *
                            (book.isLocal
                                ? .13
                                : book.coverStyle == 2
                                ? .32
                                : book.coverStyle == 3
                                ? .115
                                : book.coverStyle == 4
                                ? .105
                                : .14),
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w600,
                        height: 1.08,
                        letterSpacing: -width * .003,
                      ),
                    ),
                    const Spacer(),
                    if (book.isLocal)
                      Text(
                        book.isText ? 'TXT' : 'PDF',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: palette[2],
                          fontSize: width * .055,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PersonalCoverArt extends CustomPainter {
  const _PersonalCoverArt(this.seed, this.color);
  final int seed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 290);
    final random = math.Random(seed);
    final paint = Paint()..color = color.withValues(alpha: .18);
    final center = Offset(110 + random.nextDouble() * 45, 206);
    canvas.drawCircle(center, 78, paint);
    paint
      ..color = color.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 6; i++) {
      final radius = 26.0 + i * 12;
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radius * 2,
          height: radius * (seed.isEven ? .65 : 1.6),
        ),
        paint,
      );
    }
    paint
      ..style = PaintingStyle.fill
      ..color = color;
    for (var i = 0; i < 12; i++) {
      canvas.drawCircle(
        Offset(18 + random.nextDouble() * 164, 158 + random.nextDouble() * 92),
        i % 3 == 0 ? 1.8 : .7,
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PersonalCoverArt oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.color != color;
}

class _CoverArt extends CustomPainter {
  const _CoverArt(this.variant, this.color);
  final int variant;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 290);
    final paint = Paint()..color = color;
    switch (variant % 6) {
      case 0:
        final random = math.Random(8);
        for (var i = 0; i < 34; i++) {
          final x = random.nextDouble() * 190 + 5;
          final y = random.nextDouble() * 130 + 130;
          canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.6 : .65, paint);
        }
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1;
        canvas.drawOval(const Rect.fromLTWH(30, 180, 145, 56), paint);
        canvas.save();
        canvas.translate(103, 209);
        canvas.rotate(-.4);
        canvas.drawOval(const Rect.fromLTWH(-95, -12, 190, 24), paint);
        canvas.restore();
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(const Offset(112, 172), 6, paint);
        canvas.drawPath(
          Path()
            ..moveTo(109, 179)
            ..lineTo(103, 201)
            ..lineTo(122, 199)
            ..lineTo(117, 179)
            ..close(),
          paint,
        );
      case 1:
        canvas.drawCircle(const Offset(155, 183), 43, paint);
        paint.color = const Color(0xFF251F2A);
        canvas.drawPath(
          Path()
            ..moveTo(23, 266)
            ..lineTo(29, 215)
            ..lineTo(34, 188)
            ..lineTo(49, 202)
            ..quadraticBezierTo(60, 199, 73, 203)
            ..lineTo(88, 189)
            ..lineTo(91, 220)
            ..quadraticBezierTo(105, 244, 113, 266)
            ..close(),
          paint,
        );
        paint.color = color;
        canvas.drawOval(const Rect.fromLTWH(46, 217, 10, 4), paint);
        canvas.drawOval(const Rect.fromLTWH(70, 217, 10, 4), paint);
      case 2:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        for (var i = 0; i < 9; i++) {
          canvas.drawLine(
            Offset(15, 170 + i * 10),
            Offset(185, 170 + i * 10),
            paint,
          );
        }
        paint.style = PaintingStyle.fill;
        canvas.drawPath(
          Path()
            ..moveTo(25, 208)
            ..quadraticBezierTo(100, 146, 175, 208)
            ..quadraticBezierTo(100, 270, 25, 208),
          paint,
        );
        paint.color = const Color(0xFFE5D8BE);
        canvas.drawCircle(const Offset(100, 208), 25, paint);
        paint.color = const Color(0xFF252829);
        canvas.drawCircle(const Offset(100, 208), 12, paint);
      case 3:
        for (var i = 0; i < 11; i++) {
          paint.color = color.withValues(alpha: .12 + (i % 3) * .1);
          final x = i * 21.0 - 5;
          canvas.drawPath(
            Path()
              ..moveTo(x, 104 + (i % 3) * 22)
              ..lineTo(x - 34, 270)
              ..lineTo(x + 34, 270)
              ..close(),
            paint,
          );
        }
        paint.color = color;
        canvas.drawCircle(const Offset(150, 161), 17, paint);
      case 4:
        paint.strokeWidth = .9;
        for (var flower = 0; flower < 3; flower++) {
          final center = Offset(53 + flower * 55, 191 + (flower % 2) * 27);
          paint.style = PaintingStyle.stroke;
          canvas.drawLine(center, Offset(center.dx - 12, 274), paint);
          for (var petal = 0; petal < 16; petal++) {
            final angle = petal / 16 * math.pi * 2;
            final tip = center + Offset(math.cos(angle), math.sin(angle)) * 26;
            canvas.drawLine(center, tip, paint);
            canvas.drawCircle(tip, 3, paint);
          }
        }
      case 5:
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = .9;
        for (var i = 0; i < 12; i++) {
          final y = 166 + i * 8.0;
          canvas.drawPath(
            Path()
              ..moveTo(-10, y)
              ..cubicTo(45, y - 25, 100, y + 25, 210, y - 3),
            paint,
          );
        }
        paint.style = PaintingStyle.fill;
        canvas.drawPath(
          Path()
            ..moveTo(70, 197)
            ..lineTo(131, 197)
            ..lineTo(120, 208)
            ..lineTo(83, 208)
            ..close(),
          paint,
        );
        paint.strokeWidth = 2;
        canvas.drawLine(const Offset(103, 169), const Offset(103, 197), paint);
        canvas.drawPath(
          Path()
            ..moveTo(106, 170)
            ..lineTo(126, 192)
            ..lineTo(106, 192)
            ..close(),
          paint,
        );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CoverArt oldDelegate) =>
      oldDelegate.variant != variant || oldDelegate.color != color;
}
