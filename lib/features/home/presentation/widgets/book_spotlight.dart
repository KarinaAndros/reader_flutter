import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_atmosphere.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_cover.dart';
import 'package:flutter_app/features/home/presentation/widgets/mirror_surface.dart';

class BookSpotlight extends StatelessWidget {
  const BookSpotlight({
    super.key,
    this.horizontalPadding = 0,
    this.atmospheres = const {},
    required this.books,
    required this.selectedId,
    required this.onSelected,
    required this.onOpen,
    required this.onFavorite,
    required this.isFavorite,
  });
  final double horizontalPadding;
  final List<LibraryBook> books;
  final Map<String, BookAtmosphere> atmospheres;
  final String selectedId;
  final ValueChanged<LibraryBook> onSelected, onOpen, onFavorite;
  final bool Function(LibraryBook) isFavorite;

  int get _selectedIndex =>
      math.max(0, books.indexWhere((book) => book.id == selectedId));

  void _step(int delta) {
    if (books.length < 2) return;
    onSelected(books[(_selectedIndex + delta) % books.length]);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (books.isEmpty) return const SizedBox.shrink();
      final wide = constraints.maxWidth >= 720;
      final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
        1.0,
        3.0,
      );
      final slideWidth = wide
          ? (constraints.maxWidth * .28).clamp(264.0, 332.0)
          : (constraints.maxWidth - 124).clamp(208.0, 280.0);
      final slideHeight = wide
          ? 560 + (textScale - 1) * 360
          : 424 + (textScale - 1) * 280;
      final accent = Theme.of(context).colorScheme.primary;
      final dotCount = math.min(books.length, 7);
      final firstDot = (_selectedIndex - 3).clamp(0, books.length - dotCount);
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
        },
        child: Focus(
          child: Column(
            children: [
              _BookSlideCarousel(
                width: constraints.maxWidth,
                slideWidth: slideWidth,
                slideHeight: slideHeight,
                gap: wide ? 128 : 88,
                wide: wide,
                books: books,
                atmospheres: atmospheres,
                selectedId: selectedId,
                onSelected: onSelected,
                onOpen: onOpen,
                onFavorite: onFavorite,
                isFavorite: isFavorite,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Предыдущая книга',
                          onPressed: books.length > 1 ? () => _step(-1) : null,
                          icon: const Icon(Icons.arrow_back_rounded, size: 19),
                        ),
                        Expanded(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              for (
                                var index = firstDot;
                                index < firstDot + dotCount;
                                index++
                              )
                                Semantics(
                                  selected: index == _selectedIndex,
                                  child: Tooltip(
                                    message:
                                        'Перейти к книге: ${books[index].title}',
                                    child: InkResponse(
                                      onTap: () => onSelected(books[index]),
                                      radius: 18,
                                      child: SizedBox(
                                        width: 24,
                                        height: 36,
                                        child: Center(
                                          child: AnimatedContainer(
                                            duration:
                                                MediaQuery.disableAnimationsOf(
                                                  context,
                                                )
                                                ? Duration.zero
                                                : const Duration(
                                                    milliseconds: 220,
                                                  ),
                                            width: index == _selectedIndex
                                                ? 20
                                                : 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: index == _selectedIndex
                                                  ? accent
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .outline
                                                        .withValues(alpha: .5),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Следующая книга',
                          onPressed: books.length > 1 ? () => _step(1) : null,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BookSlideCarousel extends StatefulWidget {
  const _BookSlideCarousel({
    required this.width,
    required this.slideWidth,
    required this.slideHeight,
    required this.gap,
    required this.atmospheres,
    required this.wide,
    required this.books,
    required this.selectedId,
    required this.onSelected,
    required this.onOpen,
    required this.onFavorite,
    required this.isFavorite,
  });
  final double width, slideWidth, slideHeight, gap;
  final bool wide;
  final List<LibraryBook> books;
  final Map<String, BookAtmosphere> atmospheres;
  final String selectedId;
  final ValueChanged<LibraryBook> onSelected, onOpen, onFavorite;
  final bool Function(LibraryBook) isFavorite;

  @override
  State<_BookSlideCarousel> createState() => _BookSlideCarouselState();
}

class _BookSlideCarouselState extends State<_BookSlideCarousel> {
  static const _middlePage = 100000;
  late PageController _controller;
  late int _index;
  final _slideHeights = <String, double>{};

  void _recordHeight(String bookId, Size size) {
    if (!mounted || _slideHeights[bookId] == size.height) return;
    setState(() => _slideHeights[bookId] = size.height);
  }

  int get _selectedIndex => math.max(
    0,
    widget.books.indexWhere((book) => book.id == widget.selectedId),
  );
  double get _viewportFraction =>
      ((widget.slideWidth + widget.gap) / widget.width).clamp(.01, 1.0);

  int _centerPage(int selected) => widget.books.length == 1
      ? 0
      : _middlePage - _middlePage % widget.books.length + selected;

  PageController _createController() => PageController(
    initialPage: _index,
    keepPage: false,
    viewportFraction: _viewportFraction,
  );

  int _nearestPage(int selected) {
    if (widget.books.length == 1) return 0;
    final page = _controller.hasClients
        ? _controller.page ?? _index.toDouble()
        : _index.toDouble();
    return ((page - selected) / widget.books.length).round() *
            widget.books.length +
        selected;
  }

  bool _sameBooks(List<LibraryBook> previous) {
    if (previous.length != widget.books.length) return false;
    for (var index = 0; index < previous.length; index++) {
      if (previous[index].id != widget.books[index].id) return false;
    }
    return true;
  }

  bool _onScrollEnd(ScrollEndNotification notification) {
    if (notification.depth != 0 || !_controller.hasClients) return false;
    // Recenter only at rest and far from the working range. The identical
    // neighboring books make this jump invisible, including after many loops.
    if ((_index - _middlePage).abs() > _middlePage ~/ 2 &&
        widget.books.length > 1) {
      final controller = _controller;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            controller != _controller ||
            !controller.hasClients ||
            controller.position.isScrollingNotifier.value) {
          return;
        }
        controller.jumpToPage(_centerPage(_index % widget.books.length));
      });
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _index = _centerPage(_selectedIndex);
    _controller = _createController();
  }

  @override
  void didUpdateWidget(covariant _BookSlideCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slideWidth != widget.slideWidth ||
        oldWidget.slideHeight != widget.slideHeight) {
      _slideHeights.clear();
    }
    final next = _selectedIndex;
    if (oldWidget.width != widget.width ||
        oldWidget.slideWidth != widget.slideWidth ||
        oldWidget.gap != widget.gap ||
        !_sameBooks(oldWidget.books)) {
      final previous = _controller;
      _index = _centerPage(next);
      _controller = _createController();
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      return;
    }
    if (_index % widget.books.length == next) return;
    final target = _nearestPage(next);
    _index = target;
    final controller = _controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || controller != _controller || !controller.hasClients) {
        return;
      }
      if (MediaQuery.disableAnimationsOf(context)) {
        controller.jumpToPage(target);
      } else {
        controller.animateToPage(
          target,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carousel = SizedBox(
      height: (_slideHeights[widget.selectedId] ?? widget.slideHeight) + 52,
      child: NotificationListener<ScrollEndNotification>(
        key: ObjectKey(_controller),
        onNotification: _onScrollEnd,
        child: PageView.builder(
          key: const ValueKey('spotlight-books'),
          clipBehavior: Clip.none,
          controller: _controller,
          itemCount: widget.books.length == 1 ? 1 : null,
          physics: widget.books.length == 1
              ? const NeverScrollableScrollPhysics()
              : null,
          onPageChanged: (index) {
            setState(() => _index = index);
            final book = widget.books[index % widget.books.length];
            if (book.id != widget.selectedId) widget.onSelected(book);
          },
          itemBuilder: (context, index) {
            final book = widget.books[index % widget.books.length];
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final page =
                    _controller.positions.length == 1 &&
                        _controller.position.hasContentDimensions
                    ? _controller.page ?? _index.toDouble()
                    : _index.toDouble();
                final pageOffset = (index - page).clamp(-1.0, 1.0);
                final distance = pageOffset.abs();
                final reduceMotion = MediaQuery.disableAnimationsOf(context);
                final angle = reduceMotion ? 0.0 : pageOffset * -.08;
                return OverflowBox(
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, .001)
                      ..rotateY(angle),
                    child: Transform.scale(
                      scale: 1 - distance * .045,
                      child: RepaintBoundary(
                        child: _MeasuredSlide(
                          onSizeChanged: (size) => _recordHeight(book.id, size),
                          child: SizedBox(
                            width: widget.slideWidth,
                            child: _BookSlide(
                              key: ValueKey('spotlight-slide-${book.id}'),
                              book: book,
                              atmosphere:
                                  widget.atmospheres[book.id] ??
                                  BookAtmosphere.forBook(book),
                              pageOffset: reduceMotion ? 0 : pageOffset,
                              wide: widget.wide,
                              selected: index == _index,
                              favorite: widget.isFavorite(book),
                              onOpen: () => widget.onOpen(book),
                              onFavorite: () => widget.onFavorite(book),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return carousel;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      child: carousel,
    );
  }
}

class _MeasuredSlide extends SingleChildRenderObjectWidget {
  const _MeasuredSlide({required this.onSizeChanged, required super.child});

  final ValueChanged<Size> onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _SlideSizeObserver(onSizeChanged);

  @override
  void updateRenderObject(
    BuildContext context,
    _SlideSizeObserver renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }
}

class _SlideSizeObserver extends RenderProxyBox {
  _SlideSizeObserver(this.onSizeChanged);

  ValueChanged<Size> onSizeChanged;
  Size? _previousSize;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _previousSize) return;
    _previousSize = size;
    final measuredSize = size;
    final callback = onSizeChanged;
    WidgetsBinding.instance.addPostFrameCallback((_) => callback(measuredSize));
  }
}

class _BookSlide extends StatelessWidget {
  const _BookSlide({
    super.key,
    required this.book,
    required this.pageOffset,
    required this.atmosphere,
    required this.wide,
    required this.selected,
    required this.favorite,
    required this.onOpen,
    required this.onFavorite,
  });
  final LibraryBook book;
  final BookAtmosphere atmosphere;
  final double pageOffset;
  final bool wide, selected, favorite;
  final VoidCallback onOpen, onFavorite;

  @override
  Widget build(BuildContext context) {
    final accent = atmosphere.accentFor(Theme.of(context).brightness);
    final movement = Curves.easeInOutSine.transform(pageOffset.abs());
    final direction = pageOffset.sign * movement;
    final cover = Transform.translate(
      offset: Offset(-direction * 18, movement * 5),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0018)
          ..rotateY(direction * .22)
          ..rotateZ(-direction * .045),
        child: Transform.scale(
          scale: 1 - movement * .06,
          child: RepaintBoundary(
            child: _ReflectedCover(book: book, wide: wide, onOpen: onOpen),
          ),
        ),
      ),
    );
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SpotlightBadge(
          accent: accent,
          icon: book.isLocal
              ? Icons.offline_pin_outlined
              : book.canDownload
              ? Icons.cloud_download_outlined
              : Icons.auto_awesome,
          label: book.isLocal
              ? '${book.formatLabel} · На устройстве'
              : book.canDownload
              ? '${book.formatLabel} · Можно скачать'
              : book.mood.isEmpty
              ? 'Для вдохновения'
              : book.mood,
        ),
        SizedBox(height: wide ? 12 : 8),
        if (wide) ...[
          Text(
            book.isLocal ? 'ВАША КНИЖНАЯ ПОЛКА' : 'СТОИТ ПРОЧИТАТЬ',
            style: TextStyle(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.7,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: wide ? 24 : 20,
            fontWeight: FontWeight.w600,
            height: 1.15,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          book.author,
          maxLines: wide ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: accent.withValues(alpha: .85),
            fontSize: wide ? 12 : 11,
            height: 1.4,
          ),
        ),
        if (wide && book.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            book.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
        if (book.isLocal && book.pageCount > 0) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: book.progress,
            color: accent,
            backgroundColor: accent.withValues(alpha: .12),
            minHeight: 4,
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: 'Прогресс книги ${book.title}',
          ),
          const SizedBox(height: 6),
          Text(
            'Стр. ${book.page} из ${book.pageCount} · '
            '${(book.progress * 100).round()}%',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              child: FilledButton.tonal(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  backgroundColor: accent.withValues(alpha: .15),
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: const StadiumBorder(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        book.isLocal
                            ? 'Читать дальше'
                            : book.canDownload
                            ? 'Читать'
                            : 'О книге',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      book.isLocal
                          ? Icons.menu_book_outlined
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: favorite
                  ? 'Убрать книгу из избранного'
                  : 'Сохранить книгу',
              onPressed: onFavorite,
              style: IconButton.styleFrom(
                foregroundColor: accent,
                backgroundColor: accent.withValues(alpha: favorite ? .16 : .06),
              ),
              isSelected: favorite,
              icon: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(favorite),
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ],
    );
    return MirrorSurface(
      accent: accent,
      selected: selected,
      child: Padding(
        padding: EdgeInsets.all(wide ? 20 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [cover, const SizedBox(height: 6), details],
        ),
      ),
    );
  }
}

class _ReflectedCover extends StatelessWidget {
  const _ReflectedCover({
    required this.book,
    required this.wide,
    required this.onOpen,
  });

  final LibraryBook book;
  final bool wide;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final height = wide ? 184.0 : 128.0;
    final width = height * .69;
    final reflectionHeight = wide ? 36.0 : 26.0;
    return SizedBox(
      height: height + reflectionHeight + 8,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: height,
              child: BookCover(
                book: book,
                showAuthorAvatar: false,
                overlay: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onOpen,
                    child: Semantics(
                      button: true,
                      label: 'О книге ${book.title}',
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: height + 6,
            left: 0,
            right: 0,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: Center(
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x65FFFFFF), Colors.transparent],
                    ).createShader(bounds),
                    child: SizedBox(
                      width: width,
                      height: reflectionHeight,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: height,
                          maxHeight: height,
                          child: Transform.flip(
                            flipY: true,
                            child: BookCover(
                              book: book,
                              showAuthorAvatar: false,
                              showShadow: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightBadge extends StatelessWidget {
  const _SpotlightBadge({
    required this.accent,
    required this.icon,
    required this.label,
  });

  final Color accent;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: accent.withValues(alpha: .08),
      border: Border.all(color: accent.withValues(alpha: .16)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: accent),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: accent, fontSize: 10, height: 1.3),
          ),
        ),
      ],
    ),
  );
}

class ReadingJourney extends StatelessWidget {
  const ReadingJourney({
    super.key,
    required this.completed,
    required this.pages,
    required this.quotes,
    required this.onLibrary,
    required this.onQuotes,
    required this.onProgress,
  });
  final int completed, pages, quotes;
  final VoidCallback onLibrary, onQuotes, onProgress;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final goal = InkWell(
      onTap: onProgress,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ваша цель на год',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '$completed / 16',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.north_east_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(
                16,
                (index) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: index < completed
                          ? accent
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Одна история за другой',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
    Widget metric(
      String value,
      String label,
      IconData icon,
      VoidCallback onTap,
    ) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: accent.withValues(alpha: .7), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 27,
                      height: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final pageMetric = metric(
      '$pages',
      'страниц пройдено',
      Icons.menu_book_outlined,
      onLibrary,
    );
    final quoteMetric = metric(
      '$quotes',
      'сохранённых цитат',
      Icons.format_quote_rounded,
      onQuotes,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 720) {
            return Row(
              children: [
                Expanded(flex: 3, child: goal),
                const SizedBox(width: 36),
                Expanded(flex: 2, child: pageMetric),
                Expanded(flex: 2, child: quoteMetric),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              goal,
              const SizedBox(height: 16),
              if (constraints.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20) ...[
                pageMetric,
                const SizedBox(height: 12),
                quoteMetric,
              ] else
                Row(
                  children: [
                    Expanded(child: pageMetric),
                    Expanded(child: quoteMetric),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
