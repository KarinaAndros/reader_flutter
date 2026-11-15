import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/data/random_book_picker.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_cover.dart';
import 'package:flutter_app/features/home/presentation/widgets/mirror_surface.dart';

class BookDiscoverySheet extends StatefulWidget {
  const BookDiscoverySheet({
    super.key,
    required this.books,
    required this.onSelected,
    required this.onOpen,
  });

  final List<LibraryBook> books;
  final ValueChanged<LibraryBook> onSelected;
  final ValueChanged<LibraryBook> onOpen;

  @override
  State<BookDiscoverySheet> createState() => _BookDiscoverySheetState();
}

class _BookDiscoverySheetState extends State<BookDiscoverySheet> {
  final _picker = RandomBookPicker();
  String _genre = '';
  String _mood = '';
  LibraryBook? _selection;

  void _pick() {
    final book = _picker.pick(
      widget.books,
      genre: _genre,
      mood: _mood,
      previousId: _selection?.id,
    );
    setState(() => _selection = book);
    if (book != null) widget.onSelected(book);
  }

  Widget _filter({
    required String key,
    required String label,
    required String anyLabel,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    final entries = [
      ('', anyLabel),
      for (final option in options) (option, option),
    ];
    return DropdownButtonFormField<String>(
      key: ValueKey('$key-$value'),
      initialValue: value,
      isExpanded: true,
      isDense: false,
      itemHeight: null,
      menuMaxHeight: 320,
      dropdownColor: colors.surface,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: colors.onSurface, height: 1.5),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: colors.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      selectedItemBuilder: (context) => [
        for (final (_, label) in entries)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(label, softWrap: true),
          ),
      ],
      items: [
        for (final (value, label) in entries)
          DropdownMenuItem(
            value: value,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                label,
                key: ValueKey('$key-option-$value'),
                softWrap: true,
              ),
            ),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          onChanged(value);
          _selection = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final genres =
        widget.books
            .map((book) => book.genre)
            .where((genre) => genre.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final moods =
        widget.books
            .map((book) => book.mood)
            .where((mood) => mood.isNotEmpty && mood != 'Любое')
            .toSet()
            .toList()
          ..sort();
    final matches = _picker.matching(widget.books, genre: _genre, mood: _mood);
    final selection = _selection;
    final genreField = _filter(
      key: 'discovery-genre',
      label: 'Жанр',
      anyLabel: 'Любой жанр',
      value: _genre,
      options: genres,
      onChanged: (value) => _genre = value,
    );
    final moodField = _filter(
      key: 'discovery-mood',
      label: 'Настроение',
      anyLabel: 'Любое настроение',
      value: _mood,
      options: moods,
      onChanged: (value) => _mood = value,
    );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shuffle_rounded, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Что почитать?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Закрыть подбор',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите жанр и настроение — найдём случайную книгу из подборки и вашей библиотеки.',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 500 &&
                  MediaQuery.textScalerOf(context).scale(14) <= 20) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: genreField),
                    const SizedBox(width: 12),
                    Expanded(child: moodField),
                  ],
                );
              }
              return Column(
                children: [genreField, const SizedBox(height: 16), moodField],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Подходит книг: ${matches.length}',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('pick-random-book'),
            onPressed: matches.isEmpty ? null : _pick,
            icon: const Icon(Icons.shuffle_rounded),
            label: Text(
              selection == null
                  ? 'Выбрать случайно'
                  : matches.length > 1
                  ? 'Выбрать другую'
                  : 'Выбрать снова',
            ),
          ),
          if (matches.isEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Нет книг с таким сочетанием',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Измените жанр или настроение, чтобы найти свою историю.',
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
            ),
            TextButton(
              onPressed: () => setState(() {
                _genre = '';
                _mood = '';
                _selection = null;
              }),
              child: const Text('Сбросить фильтры'),
            ),
          ],
          if (selection != null) ...[
            const SizedBox(height: 24),
            Semantics(
              liveRegion: true,
              child: MirrorSurface(
                key: ValueKey(selection.id),
                accent: colors.primary,
                showShadow: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 64,
                            height: 94,
                            child: BookCover(book: selection),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selection.title,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  selection.author,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (selection.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          selection.description,
                          style: const TextStyle(height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        key: const ValueKey('open-picked-book'),
                        onPressed: () => widget.onOpen(selection),
                        icon: Icon(
                          selection.isLocal
                              ? Icons.menu_book_rounded
                              : Icons.info_outline_rounded,
                        ),
                        label: Text(selection.isLocal ? 'Читать' : 'О книге'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
