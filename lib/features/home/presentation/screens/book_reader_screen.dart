import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/quote_repository.dart';
import 'package:pdfrx/pdfrx.dart';

class BookReaderScreen extends StatefulWidget {
  final String filePath;
  const BookReaderScreen({super.key, required this.filePath});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final controller = PdfViewerController();
  final _pageTextController = TextEditingController();
  final _quoteRepository = QuoteRepository();
  int _pageCount = 0;
  int _page = 0;
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote),
                      SizedBox(width: 12),
                      Text(
                        'Сохранённые цитаты',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _quotes.isEmpty
                      ? const Center(
                          child: Text(
                            'Выделите текст в книге,\nчтобы сохранить цитату',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: _quotes.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final quote = _quotes[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              title: Text('«${quote.text}»'),
                              subtitle: Text('Страница ${quote.pageNumber}'),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                controller.goToPage(
                                  pageNumber: quote.pageNumber,
                                );
                              },
                              trailing: IconButton(
                                tooltip: 'Удалить цитату',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  await _quoteRepository.delete(quote.id);
                                  await _loadQuotes();
                                  setSheetState(() {});
                                },
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

  @override
  void dispose() {
    _pageTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split('/').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Цитаты (${_quotes.length})',
            onPressed: _showQuotes,
            icon: Badge(
              isLabelVisible: _quotes.isNotEmpty,
              label: Text('${_quotes.length}'),
              child: const Icon(Icons.format_quote),
            ),
          ),
        ],
      ),
      body: PdfViewer.file(
        widget.filePath,
        controller: controller,
        params: PdfViewerParams(
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
            setState(() {
              _pageCount = document.pages.length;
              _page = controller.pageNumber ?? 1;
              _pageTextController.text = '$_page';
            });
          },
          onPageChanged: (page) {
            setState(() {
              _page = page ?? 1;
              _pageTextController.text = '$_page';
            });
          },
        ),
      ),
      bottomNavigationBar: _pageCount > 0
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _page > 1
                        ? () => controller.goToPage(pageNumber: _page - 1)
                        : null,
                  ),
                  SizedBox(
                    width: 48,
                    child: TextField(
                      controller: _pageTextController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      onSubmitted: (value) {
                        final page = int.tryParse(value);
                        if (page != null && page >= 1 && page <= _pageCount) {
                          controller.goToPage(pageNumber: page);
                        }
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Text(' / $_pageCount'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _page < _pageCount
                        ? () => controller.goToPage(pageNumber: _page + 1)
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
