import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class MirrorSurface extends StatefulWidget {
  const MirrorSurface({
    super.key,
    required this.accent,
    this.selected = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(26)),
    this.showShadow = true,
    required this.child,
  });

  final Color accent;
  final bool selected;
  final BorderRadius borderRadius;
  final bool showShadow;
  final Widget child;

  @override
  State<MirrorSurface> createState() => _MirrorSurfaceState();
}

class _MirrorSurfaceState extends State<MirrorSurface> {
  Alignment _light = const Alignment(-.7, -.8);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final accent = widget.accent;
    final base = colors.surface;
    return LayoutBuilder(
      builder: (context, _) => MouseRegion(
        onHover: reduceMotion
            ? null
            : (event) {
                final bounds = context.findRenderObject()! as RenderBox;
                final position = Alignment(
                  (event.localPosition.dx / bounds.size.width * 2 - 1).clamp(
                    -1,
                    1,
                  ),
                  (event.localPosition.dy / bounds.size.height * 2 - 1).clamp(
                    -1,
                    1,
                  ),
                );
                setState(() => _light = position);
              },
        onExit: (_) => setState(() => _light = const Alignment(-.7, -.8)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: widget.showShadow
                ? [
                    BoxShadow(
                      color: accent.withValues(
                        alpha: widget.selected ? .1 : .04,
                      ),
                      blurRadius: 48,
                      spreadRadius: -8,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: accent.withValues(
                        alpha: widget.selected ? .05 : .02,
                      ),
                      blurRadius: 24,
                      spreadRadius: -10,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0, .3, .42, .48, .56, .8, 1],
                    colors: [
                      Color.alphaBlend(accent.withValues(alpha: .14), base),
                      base.withValues(alpha: .82),
                      Color.alphaBlend(
                        Colors.white.withValues(alpha: dark ? .13 : .7),
                        base,
                      ),
                      Color.alphaBlend(accent.withValues(alpha: .08), base),
                      base.withValues(alpha: .9),
                      Color.alphaBlend(accent.withValues(alpha: .18), base),
                      Color.alphaBlend(
                        Colors.white.withValues(alpha: dark ? .08 : .6),
                        base,
                      ),
                    ],
                  ),
                  borderRadius: widget.borderRadius,
                ),
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedContainer(
                          duration: reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: _light,
                              radius: 1.2,
                              colors: [
                                Colors.white.withValues(
                                  alpha: dark ? .12 : .55,
                                ),
                                Colors.white.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    widget.child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
