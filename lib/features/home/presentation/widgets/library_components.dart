import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_cover.dart';

const librarySections = [
  'Главная',
  'Поиск',
  'Библиотека',
  'Цитаты',
  'Прогресс',
];
const librarySectionIcons = [
  Icons.home_outlined,
  Icons.search_rounded,
  Icons.local_library_outlined,
  Icons.format_quote_rounded,
  Icons.bar_chart_rounded,
];

class LibrarySideNavigation extends StatelessWidget {
  const LibrarySideNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    width: 88,
    margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
    padding: const EdgeInsets.symmetric(vertical: 20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest
          .withValues(alpha: .55),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 26,
          ),
        ),
        const SizedBox(height: 32),
        for (var index = 0; index < librarySections.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IconButton(
              tooltip: librarySections[index],
              isSelected: selected == index,
              style: IconButton.styleFrom(
                minimumSize: const Size(54, 54),
                backgroundColor: selected == index
                    ? Theme.of(context).colorScheme.primary
                          .withValues(alpha: .09)
                    : Colors.transparent,
                foregroundColor: selected == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () => onSelected(index),
              icon: Icon(librarySectionIcons[index], size: 25),
            ),
          ),
        const Spacer(),
        const SizedBox(height: 20),
      ],
    ),
  );
}

class BookTile extends StatefulWidget {
  const BookTile({
    super.key,
    required this.book,
    required this.coverHeight,
    required this.favorite,
    required this.onTap,
    required this.onFavorite,
    this.selected = false,
    this.onPreview,
  });
  final LibraryBook book;
  final double coverHeight;
  final bool favorite, selected;
  final VoidCallback onTap, onFavorite;
  final ValueChanged<bool>? onPreview;

  @override
  State<BookTile> createState() => _BookTileState();
}

class _BookTileState extends State<BookTile> {
  bool _hovered = false, _focused = false;
  void _interact({bool? hover, bool? focus}) {
    setState(() {
      _hovered = hover ?? _hovered;
      _focused = focus ?? _focused;
    });
    widget.onPreview?.call(_hovered || _focused);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final lifted = _hovered || _focused;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return MouseRegion(
      onEnter: (_) => _interact(hover: true),
      onExit: (_) => _interact(hover: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSlide(
            offset: Offset(0, lifted ? -.025 : 0),
            duration: duration,
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: duration,
              transformAlignment: Alignment.center,
              transform: Matrix4.rotationZ(lifted ? -.018 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(
                      alpha: lifted
                          ? .24
                          : widget.selected
                          ? .12
                          : 0,
                    ),
                    blurRadius: lifted ? 30 : 18,
                    spreadRadius: lifted ? 2 : 0,
                  ),
                ],
              ),
              child: SizedBox(
                height: widget.coverHeight,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    BookCover(
                      book: widget.book,
                      overlay: Stack(
                        fit: StackFit.expand,
                        children: [
                          IgnorePointer(
                            child: AnimatedContainer(
                              duration: duration,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 1.5,
                                  color: widget.selected || lifted
                                      ? accent.withValues(alpha: .8)
                                      : Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: widget.onTap,
                              onFocusChange: (value) => _interact(focus: value),
                              child: Semantics(
                                button: true,
                                selected: widget.selected,
                                label: 'Открыть ${widget.book.title}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 7,
                      bottom: 10,
                      child: IconButton.filled(
                        tooltip: widget.favorite
                            ? 'Убрать ${widget.book.title} из избранного'
                            : 'В избранное: ${widget.book.title}',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0x99171B22),
                          foregroundColor: widget.favorite
                              ? accent
                              : Colors.white,
                          minimumSize: const Size(36, 36),
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: widget.onFavorite,
                        icon: Icon(
                          widget.favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.selected
                  ? accent
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.book.author,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          if (widget.book.pageCount > 0) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: widget.book.progress,
              color: accent,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
              minHeight: 3,
            ),
            const SizedBox(height: 5),
            Text(
              '${(widget.book.progress * 100).round()}% прочитано',
              style: TextStyle(fontSize: 10, color: accent),
            ),
          ],
        ],
      ),
    );
  }
}

class AddBookButton extends StatelessWidget {
  const AddBookButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      key: const ValueKey('add-book-button'),
      tooltip: 'Открыть TXT или PDF',
      onPressed: onPressed,
      backgroundColor: Color.alphaBlend(
        scheme.primary.withValues(alpha: .1),
        scheme.surface,
      ),
      foregroundColor: scheme.primary,
      shape: CircleBorder(
        side: BorderSide(color: scheme.primary.withValues(alpha: .2)),
      ),
      elevation: 4,
      hoverElevation: 6,
      focusElevation: 6,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}

class LibrarySectionHeading extends StatelessWidget {
  const LibrarySectionHeading(
    this.title, {
    super.key,
    this.subtitle,
    this.action,
    this.onPressed,
  });
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -.5,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onPressed,
              child: Text(action!, style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    ],
  );
}

class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onPressed,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 12),
    child: Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: Theme.of(context).colorScheme.primary
              .withValues(alpha: .15),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(action!),
          ),
        ],
      ],
    ),
  );
}
