import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

String spreadLabel(int page, int count) {
  final left = (page - 1) ~/ 2 * 2 + 1;
  return left < count
      ? 'Страницы $left–${left + 1} из $count'
      : 'Страница $left из $count';
}

class BookSpread extends StatelessWidget {
  const BookSpread({super.key, required this.left, required this.right});
  final Widget left, right;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(child: left),
          Expanded(child: right),
        ],
      ),
      Center(
        child: IgnorePointer(
          child: Container(
            width: 14,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0x24000000),
                  Color(0x09000000),
                  Colors.transparent,
                ],
                stops: [0, .48, .55, 1],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class BookPageTurnController {
  _BookPageTurnState? _state;

  Future<void> goToPage(int page) async => _state?._goToPage(page);
}

/// Keeps the live reader interactive; only the turning sheet is a snapshot.
class BookPageTurn extends StatefulWidget {
  const BookPageTurn({
    super.key,
    required this.controller,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    required this.previewBuilder,
    required this.child,
    this.onTurnStart,
    this.paperColor,
    this.sheetBounds,
    this.overlayGestures = false,
    this.spread = false,
  });

  final BookPageTurnController controller;
  final int page, pageCount;
  final FutureOr<void> Function(int page) onPageChanged;
  final IndexedWidgetBuilder previewBuilder;
  final VoidCallback? onTurnStart;
  final Color? paperColor;
  final Rect Function()? sheetBounds;
  final bool overlayGestures, spread;
  final Widget child;

  @override
  State<BookPageTurn> createState() => _BookPageTurnState();
}

class _BookPageTurnState extends State<BookPageTurn>
    with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  late final _animation = AnimationController(vsync: this);
  ui.Image? _snapshot;
  Rect? _sheetBounds;
  int? _target;
  bool _preparing = false;
  bool _programmatic = false;
  bool _committing = false;
  bool _forward = true;
  double _dragDistance = 0;
  double? _endVelocity;
  double _fingerY = .7;
  Size _size = Size.zero;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(covariant BookPageTurn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void dispose() {
    widget.controller._state = null;
    _animation.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  Future<bool> _prepare(int target) async {
    if (_preparing ||
        _target != null ||
        target == widget.page ||
        target < 0 ||
        target >= widget.pageCount ||
        _size.isEmpty) {
      return false;
    }
    _preparing = true;
    _forward = target > widget.page;
    widget.onTurnStart?.call();
    ui.Image? snapshot;
    if (!_reduceMotion) {
      // Clear selection handles and paint the live page before capturing it.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return false;
      final boundary =
          _boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null && !boundary.debugNeedsPaint) {
        try {
          final ratio = math.min(
            MediaQuery.devicePixelRatioOf(context),
            1600 / math.max(_size.width, _size.height),
          );
          _sheetBounds = widget.sheetBounds?.call().intersect(
            Offset.zero & _size,
          );
          snapshot = boundary.toImageSync(pixelRatio: ratio);
        } on FlutterError {
          // A reader can still change pages when its surface cannot be captured.
        }
      }
    }
    if (!mounted) {
      snapshot?.dispose();
      return false;
    }
    setState(() {
      _snapshot = snapshot;
      _target = target;
      _preparing = false;
    });
    return true;
  }

  Future<void> _goToPage(int page) async {
    if (_programmatic || _preparing || _target != null) return;
    if (widget.pageCount == 0) return;
    final target = page.clamp(0, widget.pageCount - 1);
    if (target == widget.page) return;
    if (widget.spread && !_reduceMotion && (target - widget.page).abs() == 1) {
      _programmatic = true;
      try {
        if (await _prepare(target)) await _finish(true);
      } finally {
        _programmatic = false;
      }
      return;
    }
    _programmatic = true;
    try {
      widget.onTurnStart?.call();
      await widget.onPageChanged(target);
    } finally {
      if (mounted) _programmatic = false;
    }
  }

  void _reset() {
    final snapshot = _snapshot;
    setState(() {
      _snapshot = null;
      _target = null;
      _programmatic = false;
      _committing = false;
      _endVelocity = null;
      _dragDistance = 0;
      _animation.value = 0;
    });
    if (snapshot != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => snapshot.dispose());
    }
  }

  Future<void> _finish(bool commit) async {
    if (!mounted || _target == null || _committing) return;
    _committing = true;
    try {
      if (_snapshot != null && !_reduceMotion) {
        final remaining = commit ? 1 - _animation.value : _animation.value;
        await _animation
            .animateTo(
              commit ? 1 : 0,
              duration: Duration(
                milliseconds: (560 * remaining).round().clamp(120, 560),
              ),
              curve: Curves.easeInOutCubic,
            )
            .orCancel;
      }
      if (!mounted) return;
      if (commit) {
        await widget.onPageChanged(_target!);
        await WidgetsBinding.instance.endOfFrame;
      }
      if (mounted) _reset();
    } on TickerCanceled {
      // The reader was closed during the turn.
    }
  }

  void _dragStart(DragStartDetails details) {
    if (_programmatic || _preparing || _target != null) return;
    _dragDistance = 0;
    _endVelocity = null;
    _fingerY = (details.localPosition.dy / _size.height).clamp(0, 1);
  }

  Future<void> _dragUpdate(DragUpdateDetails details) async {
    if (_programmatic || _committing) return;
    _dragDistance += details.delta.dx;
    _fingerY = (details.localPosition.dy / _size.height).clamp(0, 1);
    if (_target == null && !_preparing && _dragDistance.abs() >= 2) {
      final target = widget.page + (_dragDistance < 0 ? 1 : -1);
      if (!await _prepare(target) || !mounted) return;
    }
    if (_target == null) return;
    _animation.value = ((_forward ? -1 : 1) * _dragDistance / _size.width)
        .clamp(0, 1);
    final velocity = _endVelocity;
    if (velocity != null) _dragEnd(velocity);
  }

  void _dragEnd(double velocity) {
    if (_programmatic || _committing) return;
    if (_preparing) {
      _endVelocity = velocity;
      return;
    }
    if (_target == null) return;
    final directedVelocity = velocity * (_forward ? -1 : 1);
    final commit =
        directedVelocity > 650 ||
        (directedVelocity >= -300 && _animation.value > .28);
    unawaited(_finish(commit));
  }

  Widget _gestures(Widget child) => RawGestureDetector(
    behavior: HitTestBehavior.translucent,
    gestures: {
      _PageSwipeRecognizer:
          GestureRecognizerFactoryWithHandlers<_PageSwipeRecognizer>(
            _PageSwipeRecognizer.new,
            (recognizer) {
              recognizer
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = _dragStart
                ..onUpdate = _dragUpdate
                ..onEnd = (details) {
                  _dragEnd(details.velocity.pixelsPerSecond.dx);
                }
                ..onCancel = () {
                  _dragEnd(_forward ? 1000 : -1000);
                };
            },
          ),
    },
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final paper =
        widget.paperColor ?? Theme.of(context).scaffoldBackgroundColor;
    final view = LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        final snapshot = _snapshot;
        final target = _target;
        final pages = ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                key: _boundaryKey,
                child: IgnorePointer(
                  ignoring: _preparing || target != null,
                  child: ColoredBox(color: paper, child: widget.child),
                ),
              ),
              if (snapshot != null && target != null) ...[
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: paper,
                      child: widget.previewBuilder(context, target),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, _) => CustomPaint(
                        painter: PaperCurlPainter(
                          image: snapshot,
                          bounds: _sheetBounds,
                          spread: widget.spread,
                          progress: _animation.value,
                          forward: _forward,
                          fingerY: _fingerY,
                          paperColor: paper,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
        if (!widget.overlayGestures) return _gestures(pages);
        return Stack(
          fit: StackFit.expand,
          children: [
            pages,
            Positioned.fill(child: _gestures(const SizedBox.expand())),
          ],
        );
      },
    );
    final desktop =
        !kIsWeb &&
        const {
          TargetPlatform.macOS,
          TargetPlatform.windows,
          TargetPlatform.linux,
        }.contains(defaultTargetPlatform);
    if (!desktop) return view;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final keyboard = HardwareKeyboard.instance;
        if (keyboard.isMetaPressed ||
            keyboard.isControlPressed ||
            keyboard.isAltPressed ||
            keyboard.isShiftPressed) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowRight ||
            key == LogicalKeyboardKey.pageDown) {
          unawaited(_goToPage(widget.page + 1));
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.pageUp) {
          unawaited(_goToPage(widget.page - 1));
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.escape &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: view,
    );
  }
}

/// Gives one-finger swipes priority while leaving pinch gestures to the PDF viewer.
class _PageSwipeRecognizer extends HorizontalDragGestureRecognizer {
  int _pointerCount = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _pointerCount++;
    super.addAllowedPointer(event);
    if (_pointerCount > 1) resolve(GestureDisposition.rejected);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _pointerCount = 0;
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerPanZoomUpdateEvent && (event.scale - 1).abs() > .02) {
      resolve(GestureDisposition.rejected);
      return;
    }
    super.handleEvent(event);
  }
}

/// Curves the turning edge and draws the reverse of the sheet over the next page.
class PaperCurlPainter extends CustomPainter {
  const PaperCurlPainter({
    this.bounds,
    this.spread = false,
    required this.image,
    required this.progress,
    required this.forward,
    required this.fingerY,
    required this.paperColor,
  });

  final bool spread;
  final Rect? bounds;
  final ui.Image image;
  final double progress, fingerY;
  final bool forward;
  final Color paperColor;

  void _drawImage(Canvas canvas, Size size, Rect source, {double opacity = 1}) {
    canvas.save();
    if (!forward) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size viewport) {
    final sheet = bounds ?? Offset.zero & viewport;
    final size = sheet.size;
    if (progress >= 1 || size.isEmpty || viewport.isEmpty) return;
    final source = Rect.fromLTRB(
      sheet.left / viewport.width * image.width,
      sheet.top / viewport.height * image.height,
      sheet.right / viewport.width * image.width,
      sheet.bottom / viewport.height * image.height,
    );
    canvas.save();
    canvas.clipRect(sheet);
    canvas.translate(sheet.left, sheet.top);
    if (!forward) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    final lift = math.sin(math.pi * progress);
    final hinge = size.width * (1 - progress * (spread ? .5 : 1));
    final radius = math.min(size.width * .035, 18.0) * lift;
    final skew = (fingerY - .5) * math.min(size.width * .05, 24.0) * lift;
    final top = hinge + skew;
    final bottom = hinge - skew;
    final edgeTop = 2 * top - size.width;
    final edgeBottom = 2 * bottom - size.width;
    final front = Path()
      ..moveTo(0, 0)
      ..lineTo(top, 0)
      ..quadraticBezierTo(
        hinge + radius * .5,
        size.height * .5,
        bottom,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.save();
    canvas.clipPath(front);
    _drawImage(canvas, size, source);
    canvas.restore();
    if (progress > 0) {
      final back = Path()
        ..moveTo(edgeTop, 0)
        ..lineTo(top, 0)
        ..quadraticBezierTo(
          hinge + radius * 1.8,
          size.height * .5,
          bottom,
          size.height,
        )
        ..lineTo(edgeBottom, size.height)
        ..quadraticBezierTo(
          2 * hinge - size.width - radius * .15,
          size.height * .5,
          edgeTop,
          0,
        )
        ..close();
      canvas.drawShadow(
        back,
        Colors.black.withValues(alpha: .18 * lift),
        3 * lift,
        false,
      );
      canvas.drawPath(back, Paint()..color = paperColor.withAlpha(255));
      canvas.save();
      canvas.clipPath(back);
      canvas.translate(2 * hinge, 0);
      canvas.scale(-1, 1);
      _drawImage(canvas, size, source, opacity: .04);
      canvas.restore();
      final dark = paperColor.computeLuminance() < .4;
      canvas.drawPath(
        back,
        Paint()
          ..shader =
              LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: .06),
                  Colors.white.withValues(alpha: dark ? .08 : .35),
                  Colors.black.withValues(alpha: dark ? .3 : .18),
                  Colors.white.withValues(alpha: dark ? .12 : .55),
                ],
                stops: const [0, .6, .9, 1],
              ).createShader(
                Rect.fromLTRB(
                  math.min(edgeTop, edgeBottom),
                  0,
                  hinge + radius,
                  size.height,
                ),
              ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PaperCurlPainter oldDelegate) =>
      bounds != oldDelegate.bounds ||
      spread != oldDelegate.spread ||
      image != oldDelegate.image ||
      progress != oldDelegate.progress ||
      forward != oldDelegate.forward ||
      fingerY != oldDelegate.fingerY ||
      paperColor != oldDelegate.paperColor;
}
