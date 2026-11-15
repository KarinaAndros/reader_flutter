import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = HSLColor.fromColor(Theme.of(context).colorScheme.primary);
    final background = primary
        .withLightness(primary.lightness.clamp(.25, .48))
        .toColor();
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .29),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(background, Colors.white, .24)!,
              background,
              Color.lerp(background, Colors.black, .3)!,
            ],
            stops: const [0, .48, 1],
          ),
        ),
        child: SizedBox.square(
          dimension: size,
          child: const CustomPaint(painter: _BookLogoPainter()),
        ),
      ),
    );
  }
}

class _BookLogoPainter extends CustomPainter {
  const _BookLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024, size.height / 1024);
    final left = Path()
      ..moveTo(236, 324)
      ..cubicTo(326, 300, 403, 331, 496, 401)
      ..lineTo(496, 716)
      ..cubicTo(405, 655, 333, 627, 236, 654)
      ..quadraticBezierTo(220, 658, 220, 640)
      ..lineTo(220, 345)
      ..quadraticBezierTo(220, 329, 236, 324)
      ..close();
    final right = Path()
      ..moveTo(528, 401)
      ..cubicTo(621, 331, 698, 300, 788, 324)
      ..quadraticBezierTo(804, 329, 804, 345)
      ..lineTo(804, 640)
      ..quadraticBezierTo(804, 658, 788, 654)
      ..cubicTo(691, 627, 619, 655, 528, 716)
      ..close();
    final pages = Path()
      ..addPath(left, const Offset(0, 22))
      ..addPath(right, const Offset(0, 22));
    canvas.drawShadow(pages, const Color(0x66000000), 14, false);
    canvas.drawPath(pages, Paint()..color = const Color(0xFFD4D8DD));
    canvas.drawPath(
      left,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(230, 320),
          const Offset(496, 716),
          const [Color(0xFFFFFDFA), Color(0xFFE8EBF0)],
        ),
    );
    canvas.drawPath(
      right,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(528, 370),
          const Offset(804, 700),
          const [Colors.white, Color(0xFFF2F4F7)],
        ),
    );
    final bookmark = Path()
      ..moveTo(684, 316)
      ..quadraticBezierTo(711, 312, 740, 318)
      ..lineTo(740, 438)
      ..lineTo(712, 417)
      ..lineTo(684, 438)
      ..close();
    canvas.drawPath(bookmark, Paint()..color = const Color(0xFF77D6BC));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BookLogoPainter oldDelegate) => false;
}
