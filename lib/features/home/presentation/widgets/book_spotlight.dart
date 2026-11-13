import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_atmosphere.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_cover.dart';
import 'package:flutter_app/features/home/presentation/widgets/author_avatar.dart';

class BookSpotlight extends StatelessWidget {
  const BookSpotlight({
    super.key,
    this.horizontalPadding = 0,
    required this.books,
    required this.selectedId,
    required this.onSelected,
    required this.onOpen,
    required this.onFavorite,
    required this.isFavorite,
  });
  final double horizontalPadding;
  final List<LibraryBook> books;
  final String selectedId;
  final ValueChanged<LibraryBook> onSelected, onOpen, onFavorite;
  final bool Function(LibraryBook) isFavorite;

  int get _selectedIndex =>
      math.max(0, books.indexWhere((book) => book.id == selectedId));

  void _step(int delta) =>
      onSelected(books[(_selectedIndex + delta) % books.length]);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
        1.0,
        3.0,
      );
      final slideWidth = wide
          ? (constraints.maxWidth * .62).clamp(520.0, 700.0)
          : (constraints.maxWidth - 96).clamp(224.0, 320.0);
      final slideHeight = wide
          ? 288 + (textScale - 1) * 230
          : 320 + (textScale - 1) * 160;
      final accent = Theme.of(context).colorScheme.primary;
      final dotCount = math.min(books.length, 7);
      final firstDot = (_selectedIndex - 3).clamp(0, books.length - dotCount);
      return Column(
        children: [
          SizedBox(
            height: slideHeight + 52,
            child: _BookSlideCarousel(
              width: constraints.maxWidth,
              slideWidth: slideWidth,
              slideHeight: slideHeight,
              gap: wide ? 40 : 28,
              wide: wide,
              books: books,
              selectedId: selectedId,
              onSelected: onSelected,
              onOpen: onOpen,
              onFavorite: onFavorite,
              isFavorite: isFavorite,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Предыдущая книга',
                  onPressed: books.length > 1 ? () => _step(-1) : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 19),
                ),
                const SizedBox(width: 8),
                for (var index = firstDot; index < firstDot + dotCount; index++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      width: index == _selectedIndex ? 20 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: index == _selectedIndex
                            ? accent
                            : Theme.of(context).colorScheme.outline
                                  .withValues(alpha: .5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Следующая книга',
                  onPressed: books.length > 1 ? () => _step(1) : null,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                ),
              ],
            ),
          ),
        ],
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
  final String selectedId;
  final ValueChanged<LibraryBook> onSelected, onOpen, onFavorite;
  final bool Function(LibraryBook) isFavorite;

  @override
  State<_BookSlideCarousel> createState() => _BookSlideCarouselState();
}

class _BookSlideCarouselState extends State<_BookSlideCarousel> {
  late PageController _controller;
  late int _index;
  int get _selectedIndex => math.max(
    0,
    widget.books.indexWhere((book) => book.id == widget.selectedId),
  );
  double get _viewportFraction =>
      ((widget.slideWidth + widget.gap) / widget.width).clamp(.01, 1.0);

  @override
  void initState() {
    super.initState();
    _index = _selectedIndex;
    _controller = PageController(
      initialPage: _index,
      viewportFraction: _viewportFraction,
    );
  }

  @override
  void didUpdateWidget(covariant _BookSlideCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _selectedIndex;
    if (oldWidget.width != widget.width ||
        oldWidget.slideWidth != widget.slideWidth ||
        oldWidget.gap != widget.gap) {
      final previous = _controller;
      _index = next;
      _controller = PageController(
        initialPage: next,
        viewportFraction: _viewportFraction,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      return;
    }
    if (_index == next) return;
    _index = next;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.jumpToPage(_index);
      } else {
        _controller.animateToPage(
          _index,
          duration: const Duration(milliseconds: 400),
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
  Widget build(BuildContext context) => PageView.builder(
    key: const ValueKey('spotlight-books'),
    controller: _controller,
    itemCount: widget.books.length,
    onPageChanged: (index) {
      _index = index;
      widget.onSelected(widget.books[index]);
    },
    itemBuilder: (context, index) => AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final page =
            _controller.positions.length == 1 &&
                _controller.position.hasContentDimensions
            ? _controller.page ?? _index.toDouble()
            : _index.toDouble();
        final distance = (index - page).abs().clamp(0.0, 1.0);
        return Center(
          child: Transform.scale(
            scale: 1 - distance * .025,
            child: SizedBox(
              width: widget.slideWidth,
              height: widget.slideHeight,
              child: _BookSlide(
                book: widget.books[index],
                index: index,
                wide: widget.wide,
                selected: index == _selectedIndex,
                favorite: widget.isFavorite(widget.books[index]),
                onOpen: () => widget.onOpen(widget.books[index]),
                onFavorite: () => widget.onFavorite(widget.books[index]),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _BookSlide extends StatelessWidget {
  const _BookSlide({
    required this.book,
    required this.index,
    required this.wide,
    required this.selected,
    required this.favorite,
    required this.onOpen,
    required this.onFavorite,
  });
  final LibraryBook book;
  final int index;
  final bool wide, selected, favorite;
  final VoidCallback onOpen, onFavorite;

  @override
  Widget build(BuildContext context) {
    final accent = selected
        ? Theme.of(context).colorScheme.primary
        : BookAtmosphere.forBook(book).accentFor(Theme.of(context).brightness);
    final coverHeight = wide ? 180.0 : 128.0;
    final cover = SizedBox(
      height: coverHeight + 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: -4,
            child: Text(
              (index + 1).toString().padLeft(2, '0'),
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: accent.withValues(alpha: .07),
                fontSize: wide ? 68 : 44,
                fontWeight: FontWeight.w300,
                height: 1,
              ),
            ),
          ),
          Center(
            child: Transform.rotate(
              angle: selected ? -.025 : .025,
              child: SizedBox(
                width: coverHeight * .69,
                height: coverHeight,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    BookCover(
                      book: book,
                      showAuthorAvatar: false,
                      showShadow: false,
                      overlay: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onOpen,
                          borderRadius: BorderRadius.circular(10),
                          child: Semantics(
                            button: true,
                            label: 'О книге ${book.title}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (wide) ...[
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
                        book.isLocal ? 'Читать дальше' : 'О книге',
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
              style: IconButton.styleFrom(foregroundColor: accent),
              icon: Icon(
                favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 21,
              ),
            ),
          ],
        ),
      ],
    );
    final avatarSize = wide ? 44.0 : 38.0;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  accent.withValues(alpha: .045),
                  Theme.of(context).colorScheme.surface,
                ),
                Theme.of(context).colorScheme.surface,
              ],
            ),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: .25)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .045),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(wide ? 20 : 16),
            child: wide
                ? Row(
                    children: [
                      SizedBox(width: 154, child: cover),
                      const SizedBox(width: 20),
                      Expanded(child: details),
                    ],
                  )
                : Column(
                    children: [
                      cover,
                      const SizedBox(height: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: details,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        Positioned(
          top: -avatarSize / 2,
          right: -avatarSize / 2,
          child: AuthorAvatar(author: book.author, size: avatarSize),
        ),
      ],
    );
  }
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
