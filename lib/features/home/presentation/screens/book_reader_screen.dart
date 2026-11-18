import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/features/home/data/quote_repository.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_page_turn.dart';
import 'package:pdfrx/pdfrx.dart';

class BookReaderScreen extends StatefulWidget {
  final String filePath;
  final int initialPage;
  final void Function(int page, int count)? onProgressChanged;
  const BookReaderScreen({
    super.key,
    required this.filePath,
    this.initialPage = 1,
    this.onProgressChanged,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final controller = PdfViewerController();
  final _pageTurn = BookPageTurnController();
  PdfDocument? _document;
  final _quoteRepository = QuoteRepository();
  int _pageCount = 0;
  int _page = 0;
  double? _scrubPage;
  List<SavedQuote> _quotes = [];

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    final quotes = await _quoteRepository.loadForBook(widget.filePath);
    if (mounted) setState(() => _quotes = quotes);
  }

  Future<void> _saveSelectedQuote(PdfTextSelectionDelegate selection) async {
    if (!selection.isCopyAllowed || !selection.hasSelectedText) return;

    final text = (await selection.getSelectedText())
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final ranges = await selection.getSelectedTextRanges();
    if (text.isEmpty || ranges.isEmpty) return;

    final quote = SavedQuote(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      bookPath: widget.filePath,
      pageNumber: ranges.first.pageNumber,
      createdAt: DateTime.now(),
    );
    await _quoteRepository.save(quote);
    await selection.clearTextSelection();
    await _loadQuotes();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Цитата сохранена')));
  }

  void _showQuotes() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ваши цитаты',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Закрыть',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _quotes.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  child: Icon(
                                    Icons.format_quote_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    size: 32,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Слова, к которым хочется вернуться',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 19,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Выделите текст в книге и нажмите\n«Сохранить цитату».',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _quotes.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final quote = _quotes[index];
                            return Material(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(18),
                                title: Text(
                                  '«${quote.text}»',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Страница ${quote.pageNumber}  ↗',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                  _pageTurn.goToPage(
                                    (quote.pageNumber - 1) ~/ 2,
                                  );
                                },
                                trailing: IconButton(
                                  tooltip: 'Удалить цитату',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await _quoteRepository.delete(quote.id);
                                    await _loadQuotes();
                                    if (sheetContext.mounted) {
                                      setSheetState(() {});
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Rect _spreadRect(int index) {
    final pages = controller.layout.pageLayouts;
    final left = pages[index * 2];
    final spine = pages.length > index * 2 + 1
        ? pages[index * 2 + 1].left
        : left.right;
    final half = pages.length > index * 2 + 1
        ? (spine - left.left).clamp(pages[index * 2 + 1].width, double.infinity)
        : left.width;
    return Rect.fromLTRB(spine - half, left.top, spine + half, left.bottom);
  }

  Future<void> _openSpread(int index) async {
    if (!controller.isReady || _pageCount == 0) return;
    await controller.goToArea(
      rect: _spreadRect(index),
      anchor: PdfPageAnchor.all,
      duration: Duration.zero,
    );
    if (!mounted) return;
    setState(() => _page = index * 2 + 1);
    widget.onProgressChanged?.call(_page, _pageCount);
  }

  Widget _buildPagePreview(BuildContext context, int index) {
    if (!controller.isReady || _document == null) {
      return const SizedBox.shrink();
    }
    final matrix = controller.calcMatrixForArea(
      rect: _spreadRect(index),
      anchor: PdfPageAnchor.all,
    );
    return Stack(
      children: [
        for (var i = index * 2; i < _pageCount && i < index * 2 + 2; i++)
          Positioned.fromRect(
            rect: MatrixUtils.transformRect(
              matrix,
              controller.layout.pageLayouts[i],
            ),
            child: PdfPageView(
              document: _document,
              pageNumber: i + 1,
              maximumDpi: 144,
              decoration: const BoxDecoration(color: Colors.white),
            ),
          ),
      ],
    );
  }

  PdfPageLayout _horizontalLayout(List<PdfPage> pages, PdfViewerParams params) {
    final height = pages.fold<double>(0, (h, p) => p.height > h ? p.height : h);
    final layouts = <Rect>[];
    // Leave space around each spread so neighboring sheets stay outside the viewport.
    var x = height * 4;
    for (var i = 0; i < pages.length; i += 2) {
      final leftWidth = pages[i].width * height / pages[i].height;
      final rightWidth = i + 1 < pages.length
          ? pages[i + 1].width * height / pages[i + 1].height
          : leftWidth;
      final half = leftWidth > rightWidth ? leftWidth : rightWidth;
      final spine = x + half;
      layouts.add(Rect.fromLTWH(spine - leftWidth, 0, leftWidth, height));
      if (i + 1 < pages.length)
        layouts.add(Rect.fromLTWH(spine, 0, rightWidth, height));
      x += half * 2 + height * 4;
    }
    return PdfPageLayout(pageLayouts: layouts, documentSize: Size(x, height));
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        titleSpacing: 12,
        leadingWidth: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName.replaceFirst(
                RegExp(r'\.pdf$', caseSensitive: false),
                '',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'РЕЖИМ ЧТЕНИЯ',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 9,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: SizedBox.square(
              dimension: 48,
              child: IconButton.filledTonal(
                tooltip: 'Назад в библиотеку',
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 21),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: SizedBox.square(
              dimension: 48,
              child: IconButton.filledTonal(
                tooltip: 'Цитаты (${_quotes.length})',
                style: IconButton.styleFrom(
                  backgroundColor: accent.withValues(alpha: .15),
                  foregroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _showQuotes,
                icon: Badge(
                  isLabelVisible: _quotes.isNotEmpty,
                  label: Text('${_quotes.length}'),
                  backgroundColor: accent,
                  child: const Icon(Icons.format_quote_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BookPageTurn(
              controller: _pageTurn,
              spread: true,
              page: (_page - 1) ~/ 2,
              pageCount: (_pageCount + 1) ~/ 2,
              overlayGestures: true,
              paperColor: Colors.white,
              sheetBounds: () => MatrixUtils.transformRect(
                controller.value,
                _spreadRect((_page - 1) ~/ 2),
              ),
              onTurnStart: () {
                ContextMenuController.removeAny();
                if (controller.isReady) {
                  controller.textSelectionDelegate.clearTextSelection();
                }
              },
              onPageChanged: _openSpread,
              previewBuilder: _buildPagePreview,
              child: PdfViewer.file(
                widget.filePath,
                controller: controller,
                initialPageNumber: widget.initialPage,
                params: PdfViewerParams(
                  layoutPages: _horizontalLayout,
                  onKey: (params, key, isRealKeyPress) {
                    if (const [
                      LogicalKeyboardKey.arrowLeft,
                      LogicalKeyboardKey.arrowRight,
                      LogicalKeyboardKey.pageUp,
                      LogicalKeyboardKey.pageDown,
                      LogicalKeyboardKey.escape,
                    ].contains(key)) {
                      return false;
                    }
                    return null;
                  },
                  backgroundColor: Color.alphaBlend(
                    accent.withValues(alpha: .035),
                    Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                  loadingBannerBuilder:
                      (context, bytesDownloaded, totalBytes) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  errorBannerBuilder:
                      (context, error, stackTrace, documentRef) => Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Не удалось открыть PDF',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Вернитесь в библиотеку и выберите другой файл.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  textSelectionParams: const PdfTextSelectionParams(
                    enabled: true,
                    enableSelectionHandles: true,
                    showContextMenuAutomatically: true,
                  ),
                  customizeContextMenuItems: (params, items) {
                    if (!params.isTextSelectionEnabled ||
                        !params.textSelectionDelegate.isCopyAllowed ||
                        !params.textSelectionDelegate.hasSelectedText) {
                      return;
                    }
                    items.add(
                      ContextMenuButtonItem(
                        label: 'Сохранить цитату',
                        onPressed: () {
                          params.dismissContextMenu();
                          _saveSelectedQuote(params.textSelectionDelegate);
                        },
                      ),
                    );
                  },
                  onViewerReady: (document, controller) {
                    if (!mounted) return;
                    setState(() {
                      _document = document;
                      _pageCount = document.pages.length;
                      _page = controller.pageNumber ?? 1;
                    });
                    _openSpread(
                      (widget.initialPage.clamp(1, _pageCount) - 1) ~/ 2,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _pageCount > 0
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Center(
                heightFactor: 1,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 680),
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x086554D9),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_stories_outlined,
                              size: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Прогресс чтения',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              '${(_page / _pageCount * 100).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Предыдущая страница',
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: _page > 1
                                ? () => _pageTurn.goToPage((_page - 1) ~/ 2 - 1)
                                : null,
                          ),
                          Expanded(
                            child: Slider(
                              label:
                                  'Страница ${(_scrubPage ?? _page.toDouble()).round()}',
                              min: 1,
                              max: _pageCount > 1 ? _pageCount.toDouble() : 2,
                              value: (_scrubPage ?? _page.toDouble()).clamp(
                                1,
                                _pageCount.toDouble(),
                              ),
                              onChanged: _pageCount > 1
                                  ? (value) =>
                                        setState(() => _scrubPage = value)
                                  : null,
                              onChangeEnd: (value) {
                                _pageTurn.goToPage((value.round() - 1) ~/ 2);
                                setState(() => _scrubPage = null);
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Следующая страница',
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: _page + 1 < _pageCount
                                ? () => _pageTurn.goToPage((_page - 1) ~/ 2 + 1)
                                : null,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        child: Text(
                          spreadLabel(
                            (_scrubPage ?? _page.toDouble()).round(),
                            _pageCount,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
