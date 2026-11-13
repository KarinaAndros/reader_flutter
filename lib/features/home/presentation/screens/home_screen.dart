import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_input_styles.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/data/book_file_importer.dart';
import 'package:flutter_app/features/home/data/quote_repository.dart';
import 'package:flutter_app/features/home/data/reading_activity.dart';
import 'package:flutter_app/features/home/presentation/screens/book_reader_screen.dart';
import 'package:flutter_app/features/home/presentation/screens/text_reader_screen.dart';
import 'package:flutter_app/features/home/presentation/widgets/ambient_background.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_cover.dart';
import 'package:flutter_app/features/home/presentation/widgets/library_components.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_atmosphere.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_spotlight.dart';
import 'package:flutter_app/features/home/presentation/widgets/reading_charts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onToggleTheme});

  final VoidCallback? onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _library = BookLibrary();
  final _fileImporter = BookFileImporter();
  final _quoteRepository = QuoteRepository();
  final _activityRepository = ReadingActivityRepository();
  ReadingActivity _activity = const ReadingActivity();
  bool _activityErrorShown = false;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  List<LibraryBook> _books = [];
  List<SavedQuote> _quotes = [];
  Set<String> _favorites = {};
  int _section = 0;
  String _query = '';
  bool _onlyFavorites = false;
  bool _importing = false;
  bool _loading = true;
  LibraryBook _activeBook = editorialBooks.first;
  LibraryBook? _previewBook;
  final _atmosphereResolver = BookAtmosphereResolver();
  final _resolvedAtmospheres = <String, BookAtmosphere>{};

  BookAtmosphere get _atmosphere {
    final book = _previewBook ?? _activeBook;
    return _resolvedAtmospheres[book.id] ?? BookAtmosphere.forBook(book);
  }

  Brightness get _brightness => Theme.of(context).brightness;
  Color get _accent => _atmosphere.accentFor(_brightness);
  ThemeData get _bookTheme =>
      AppTheme.forAccent(_accent, brightness: _brightness);

  Future<void> _resolveAtmosphere(LibraryBook book) async {
    if (!book.isLocal || _resolvedAtmospheres.containsKey(book.id)) return;
    final colors = await _atmosphereResolver.resolve(book);
    if (mounted) setState(() => _resolvedAtmospheres[book.id] = colors);
  }

  void _activateBook(LibraryBook book) {
    setState(() {
      _activeBook = book;
      _previewBook = null;
    });
    _resolveAtmosphere(book);
  }

  void _preview(LibraryBook book, bool entered) {
    if (!entered && _previewBook?.id != book.id) return;
    setState(() => _previewBook = entered ? book : null);
    if (entered) _resolveAtmosphere(book);
  }

  List<LibraryBook> get _spotlightBooks {
    final books = [..._books, ...editorialBooks];
    if (!books.any((book) => book.id == _activeBook.id)) {
      books.insert(0, _activeBook);
    }
    return books;
  }

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    try {
      final books = await _library.load();
      final favorites = await _library.loadFavorites();
      final quotes = await _quoteRepository.loadAll();
      final activity = await _activityRepository.load();
      if (!mounted) return;
      setState(() {
        _books = books;
        _activeBook = books.firstOrNull ?? editorialBooks.first;
        _favorites = favorites;
        _quotes = quotes;
        _activity = activity;
        _loading = false;
      });
      _resolveAtmosphere(_activeBook);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message(
        'Не удалось загрузить библиотеку. Попробуйте открыть приложение снова.',
      );
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _recordReadingPage(String bookId, int page) async {
    try {
      final activity = await _activityRepository.record(bookId, page);
      if (mounted) setState(() => _activity = activity);
    } catch (_) {
      if (!_activityErrorShown) {
        _activityErrorShown = true;
        _message('Не удалось сохранить статистику чтения.');
      }
    }
  }

  void _selectSection(int section) {
    setState(() {
      _section = section;
      _previewBook = null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _toggleFavorite(LibraryBook book) async {
    setState(() {
      if (!_favorites.add(book.id)) _favorites.remove(book.id);
    });
    try {
      await _library.saveFavorites(_favorites);
    } catch (_) {
      _message('Не удалось сохранить избранное.');
    }
  }

  Future<void> _importBook() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf'],
      );
      if (files.isEmpty || !mounted) return;
      final file = files.single;
      final previous = file.path == null
          ? null
          : _books.where((book) => book.filePath == file.path).firstOrNull;
      final imported =
          previous ??
          await _fileImporter.import(
            name: file.name,
            bytes: file.readAsByteStream(),
          );
      if (!mounted) return;
      final existing = _books
          .where(
            (book) =>
                book.id == imported.id || book.filePath == imported.filePath,
          )
          .firstOrNull;
      final book = existing ?? imported;
      if (existing == null) {
        setState(() => _books = [book, ..._books]);
        await _library.save(_books);
      }
      if (mounted) await _readBook(book);
    } on FormatException catch (error) {
      _message(error.message);
    } catch (_) {
      _message(
        'Не удалось добавить книгу. Попробуйте выбрать другой TXT или PDF.',
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _readBook(LibraryBook book) async {
    final path = book.filePath;
    if (path == null) return;
    if (!await File(path).exists()) {
      _message('Файл перемещён или удалён. Добавьте файл в библиотеку заново.');
      return;
    }
    if (!mounted) return;
    _activateBook(book);
    await _resolveAtmosphere(book);
    if (!mounted) return;
    var updated = book;
    void onProgress(int page, int count) {
      updated = book.withProgress(page, count);
      if (count > 0 && page >= 1 && page <= count) {
        _recordReadingPage(book.id, page);
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: _bookTheme,
          child: book.isText
              ? TextReaderScreen(
                  filePath: path,
                  title: book.title,
                  initialPage: book.page,
                  onProgressChanged: onProgress,
                )
              : BookReaderScreen(
                  filePath: path,
                  initialPage: book.page,
                  onProgressChanged: onProgress,
                ),
        ),
      ),
    );
    await _activityRepository.flush();
    if (!mounted) return;
    setState(() {
      _books = [updated, ..._books.where((item) => item.id != book.id)];
      _activeBook = updated;
    });
    try {
      await _library.save(_books);
      final quotes = await _quoteRepository.loadAll();
      if (mounted) setState(() => _quotes = quotes);
    } catch (_) {
      _message('Не удалось сохранить прогресс чтения.');
    }
  }

  Future<void> _showBook(LibraryBook book) async {
    _activateBook(book);
    await _resolveAtmosphere(book);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Theme(
        data: _bookTheme,
        child: StatefulBuilder(
          builder: (context, refresh) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    width: 144,
                    height: 208,
                    child: BookCover(book: book),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  book.isLocal ? 'НА ВАШЕЙ ПОЛКЕ' : 'КНИЖНОЕ ВДОХНОВЕНИЕ',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  book.author,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  book.description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        if (book.isLocal) {
                          _readBook(book);
                        } else {
                          _importBook();
                        }
                      },
                      icon: Icon(
                        book.isLocal
                            ? Icons.menu_book_rounded
                            : Icons.add_rounded,
                      ),
                      label: Text(
                        book.isLocal
                            ? 'Продолжить чтение'
                            : 'Добавить свою книгу',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _toggleFavorite(book);
                        if (sheetContext.mounted) refresh(() {});
                      },
                      icon: Icon(
                        _favorites.contains(book.id)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                      label: Text(
                        _favorites.contains(book.id)
                            ? 'В избранном'
                            : 'В избранное',
                      ),
                    ),
                  ],
                ),
                if (!book.isLocal) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Идея для вашей полки. Для чтения добавьте TXT или PDF с устройства.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<LibraryBook> get _filteredBooks {
    final source = _section == 1 || _onlyFavorites
        ? [..._books, ...editorialBooks]
        : _books;
    return source.where((book) {
      final matchesQuery = '${book.title} ${book.author}'
          .toLowerCase()
          .contains(_query.toLowerCase());
      return matchesQuery && (!_onlyFavorites || _favorites.contains(book.id));
    }).toList();
  }

  @override
  Widget build(BuildContext context) => AnimatedTheme(
    data: _bookTheme,
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 650),
    curve: Curves.easeInOutCubic,
    child: Builder(builder: _buildShell),
  );

  Widget _buildShell(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: AmbientBackground(
        atmosphere: _atmosphere,
        child: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (desktop)
                LibrarySideNavigation(
                  selected: _section,
                  onSelected: _selectSection,
                ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              controller: _scrollController,
                              padding: EdgeInsets.fromLTRB(
                                _section == 0
                                    ? 0
                                    : desktop
                                    ? 36
                                    : 20,
                                desktop ? 36 : 24,
                                _section == 0
                                    ? 0
                                    : desktop
                                    ? 36
                                    : 20,
                                _section == 0
                                    ? 128 +
                                          MediaQuery.viewPaddingOf(context)
                                              .bottom
                                    : 96,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1600,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: _section == 0
                                              ? (desktop ? 36 : 20)
                                              : 0,
                                        ),
                                        child: _header(desktop),
                                      ),
                                      const SizedBox(height: 28),
                                      if (_section == 0)
                                        ..._homeContent(desktop),
                                      if (_section == 1 || _section == 2)
                                        ..._libraryContent(),
                                      if (_section == 3) ..._quotesContent(),
                                      if (_section == 4) ..._progressContent(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: AddBookButton(
        onPressed: _importing ? null : _importBook,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              height: 68,
              selectedIndex: _section,
              onDestinationSelected: _selectSection,
              destinations: List.generate(
                librarySections.length,
                (index) => NavigationDestination(
                  icon: Icon(librarySectionIcons[index], size: 22),
                  label: librarySections[index],
                ),
              ),
            ),
    );
  }

  Widget _header(bool desktop) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _section == 0
                  ? 'Популярные книги для чтения'
                  : librarySections[_section],
              style: TextStyle(
                fontSize: desktop ? 34 : 28,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -.9,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _section == 0
                  ? 'Хорошая книга ближе, чем кажется'
                  : _section == 2
                  ? '${_books.length} книг · ваша личная коллекция'
                  : 'Всё, к чему хочется возвращаться',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      IconButton.filledTonal(
        key: const ValueKey('theme-toggle'),
        tooltip: _brightness == Brightness.dark
            ? 'Светлая тема'
            : 'Тёмная тема',
        onPressed: widget.onToggleTheme,
        icon: Icon(
          _brightness == Brightness.dark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
        ),
      ),
      if (_section != 0) ...[
        const SizedBox(width: 12),
        if (desktop)
          FilledButton.tonalIcon(
            onPressed: _importing ? null : _importBook,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Добавить книгу'),
          )
        else
          IconButton.filledTonal(
            tooltip: 'Добавить книгу',
            onPressed: _importing ? null : _importBook,
            icon: const Icon(Icons.add_rounded),
          ),
      ],
    ],
  );

  List<Widget> _homeContent(bool desktop) => [
    BookSpotlight(
      horizontalPadding: desktop ? 36 : 20,
      books: _spotlightBooks,
      selectedId: _activeBook.id,
      onSelected: _activateBook,
      onOpen: (book) => book.isLocal ? _readBook(book) : _showBook(book),
      onFavorite: _toggleFavorite,
      isFavorite: (book) => _favorites.contains(book.id),
    ),
    const SizedBox(height: 32),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: desktop ? 36 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LibrarySectionHeading(
            'Недавно открытые',
            action: _books.isNotEmpty ? 'Все книги' : null,
            onPressed: () => _selectSection(2),
          ),
          const SizedBox(height: 24),
          if (_books.isNotEmpty)
            _shelf(_books, desktop)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Здесь появятся ваши книги',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Откройте TXT или PDF с телефона — книга останется на этой полке, и вы сможете продолжить чтение.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _importing ? null : _importBook,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Открыть TXT или PDF'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          ReadingActivityChart(
            key: const ValueKey('home-activity-chart'),
            activity: _activity,
            compact: true,
            onDetails: () => _selectSection(4),
          ),
        ],
      ),
    ),
  ];

  Widget _shelf(List<LibraryBook> books, bool desktop) {
    final width = desktop ? 176.0 : 142.0;
    final textScaler = MediaQuery.textScalerOf(context);
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    double textHeight(String text, TextStyle style, {int? maxLines}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: baseStyle.merge(style)),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      )..layout(maxWidth: width);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final detailsHeight = books.fold<double>(0, (maximum, book) {
      final height =
          17 +
          textHeight(
            book.title,
            const TextStyle(
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
          ) +
          textHeight(
            book.author,
            const TextStyle(fontSize: 11, height: 1.4),
            maxLines: 2,
          ) +
          (book.pageCount > 0
              ? 18 +
                    textHeight(
                      '${(book.progress * 100).round()}% прочитано',
                      const TextStyle(fontSize: 10),
                    )
              : 0);
      return math.max(maximum, height);
    });
    return SizedBox(
      height: width * 1.45 + detailsHeight.ceilToDouble() + 2,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          if (notification.depth == 0 &&
              notification.metrics.axis == Axis.horizontal &&
              notification.metrics.pixels > 0) {
            final index =
                (notification.metrics.pixels / (width + (desktop ? 24 : 18)))
                    .round()
                    .clamp(0, books.length - 1);
            _activateBook(books[index]);
          }
          return false;
        },
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: books.length,
          separatorBuilder: (_, _) => SizedBox(width: desktop ? 24 : 18),
          itemBuilder: (_, index) =>
              SizedBox(width: width, child: _bookTile(books[index], width)),
        ),
      ),
    );
  }

  Widget _bookTile(LibraryBook book, double width) => BookTile(
    key: ValueKey('book-tile-${book.id}'),
    book: book,
    selected: _activeBook.id == book.id,
    onPreview: (entered) => _preview(book, entered),
    coverHeight: width * 1.45,
    favorite: _favorites.contains(book.id),
    onTap: () => _showBook(book),
    onFavorite: () => _toggleFavorite(book),
  );

  List<Widget> _libraryContent() => [
    TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: AppInputStyles.search(
        context,
        label: 'Название книги или автор',
        accent: _accent,
      ),
    ),
    const SizedBox(height: 20),
    Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ChoiceChip(
          label: const Text('Все книги'),
          selected: !_onlyFavorites,
          onSelected: (_) => setState(() => _onlyFavorites = false),
        ),
        ChoiceChip(
          showCheckmark: false,
          avatar: Icon(
            _onlyFavorites
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 16,
          ),
          label: const Text('Избранное'),
          selected: _onlyFavorites,
          onSelected: (_) => setState(() => _onlyFavorites = true),
        ),
      ],
    ),
    const SizedBox(height: 24),
    if (_filteredBooks.isNotEmpty)
      _bookGrid(_filteredBooks)
    else
      LibraryEmptyState(
        icon: _onlyFavorites
            ? Icons.favorite_border_rounded
            : Icons.auto_stories_outlined,
        title: _query.isNotEmpty
            ? 'История пока не нашлась'
            : _onlyFavorites
            ? 'Здесь будут любимые книги'
            : 'Ваша полка ждёт первую книгу',
        message: _query.isNotEmpty
            ? 'Попробуйте другое название или имя автора.'
            : _onlyFavorites
            ? 'Нажмите на сердечко рядом с обложкой.'
            : 'Добавьте TXT или PDF — книга получит обложку, а прогресс чтения сохранится автоматически.',
        action: _query.isEmpty && !_onlyFavorites
            ? 'Добавить TXT или PDF'
            : null,
        onPressed: _importBook,
      ),
  ];

  Widget _bookGrid(List<LibraryBook> books) => LayoutBuilder(
    builder: (context, constraints) {
      final count = (constraints.maxWidth / 180).floor().clamp(2, 7);
      final width = (constraints.maxWidth - (count - 1) * 20) / count;
      return Wrap(
        spacing: 20,
        runSpacing: 28,
        children: books
            .map(
              (book) => SizedBox(width: width, child: _bookTile(book, width)),
            )
            .toList(),
      );
    },
  );

  List<Widget> _quotesContent() => _quotes.isEmpty
      ? [
          const LibraryEmptyState(
            icon: Icons.format_quote_rounded,
            title: 'Слова, которые останутся',
            message: 'Выделите текст во время чтения и сохраните цитату. Здесь соберутся важные мысли из ваших книг.',
          ),
        ]
      : _quotes
            .map(
              (quote) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: Theme.of(context).colorScheme.surface
                      .withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      final book =
                          _books
                              .where((book) => book.filePath == quote.bookPath)
                              .firstOrNull ??
                          LibraryBook(
                            id: quote.bookPath,
                            title: quote.bookPath.split('/').last,
                            author: 'Из вашей библиотеки',
                            mood: 'Любое',
                            description: '',
                            coverStyle: 0,
                            filePath: quote.bookPath,
                          );
                      _readBook(
                        book.withProgress(quote.pageNumber, book.pageCount),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded, color: _accent),
                          const SizedBox(height: 12),
                          Text(
                            quote.text,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${quote.bookPath.split('/').last} · стр. ${quote.pageNumber}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Удалить цитату',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  try {
                                    await _quoteRepository.delete(quote.id);
                                    final quotes = await _quoteRepository
                                        .loadAll();
                                    if (mounted) {
                                      setState(() => _quotes = quotes);
                                    }
                                  } catch (_) {
                                    _message('Не удалось удалить цитату.');
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList();

  List<Widget> _progressContent() => [
    Text(
      'Каждая прочитанная страница имеет значение.',
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
    const SizedBox(height: 24),
    ..._progressCards(),
    const SizedBox(height: 28),
    ReadingProgressCharts(activity: _activity, books: _books),
  ];

  List<Widget> _progressCards() => [
    ReadingJourney(
      completed: _books
          .where((book) => book.pageCount > 0 && book.page == book.pageCount)
          .length,
      pages: _books.fold<int>(
        0,
        (total, book) => total + (book.pageCount > 0 ? book.page : 0),
      ),
      quotes: _quotes.length,
      onLibrary: () => _selectSection(2),
      onQuotes: () => _selectSection(3),
      onProgress: () => _selectSection(4),
    ),
  ];
}
