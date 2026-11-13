import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_atmosphere.dart';

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    required this.atmosphere,
  });
  final Widget child;
  final BookAtmosphere atmosphere;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 650);
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                key: const ValueKey('book-ambient-glow'),
                duration: duration,
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(.4, -.85),
                    radius: 1.1,
                    colors: [
                      atmosphere.glow.withValues(alpha: dark ? .48 : .14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-1.05, -.15),
                    radius: 1.1,
                    colors: [
                      atmosphere.secondary.withValues(alpha: dark ? .24 : .07),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
