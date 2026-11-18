import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_app/features/home/data/quote_repository.dart';
import 'package:flutter_app/features/home/data/text_book_document.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_page_turn.dart';

class TextReaderScreen extends StatefulWidget {
  const TextReaderScreen({
    super.key,
    required this.filePath,
    required this.title,
    this.initialPage = 1,
    this.onProgressChanged,
  });

  final String filePath, title;
  final int initialPage;
  final void Function(int page, int count)? onProgressChanged;

  @override
  State<TextReaderScreen> createState() => _TextReaderScreenState();
}

class _TextReaderScreenState extends State<TextReaderScreen> {
  final _quotes = QuoteRepository();
  TextBookDocument? _document;
  final _controller = BookPageTurnController();
  String? _error;
  int _page = 1;
  double _fontSize = 20;
  double? _scrubPage;
  bool get _isMarkdown => widget.filePath.toLowerCase().endsWith('.md');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final bytes = await File(widget.filePath).readAsBytes();
      final document = await compute(
        _isMarkdown
            ? TextBookDocument.fromMarkdownBytes
            : TextBookDocument.fromBytes,
        bytes,
      );
      if (!mounted) return;
      setState(() {
        _document = document;
        _page = widget.initialPage.clamp(1, document.pages.length);
      });
      widget.onProgressChanged?.call(_page, document.pages.length);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is FormatException
            ? error.message
            : 'Не удалось открыть документ. Попробуйте добавить файл заново.',
      );
    }
  }

  void _goTo(int page) {
    if (_document == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    ContextMenuController.removeAny();
    _controller.goToPage((page.clamp(1, _document!.pages.length) - 1) ~/ 2);
  }

  Future<void> _saveQuote(String text, int page) async {
    if (text.trim().isEmpty) return;
    try {
      await _quotes.save(
        SavedQuote(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: text.trim(),
          bookPath: widget.filePath,
          pageNumber: page,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Цитата сохранена')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось сохранить цитату.')),
        );
      }
    }
  }

  Future<void> _showQuotes() async {
    var quotes = await _quotes.loadForBook(widget.filePath);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refresh) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            children: [
              ListTile(
                title: const Text('Ваши цитаты'),
                trailing: IconButton(
                  tooltip: 'Закрыть',
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              Expanded(
                child: quotes.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Выделите текст и нажмите «Сохранить цитату».',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: quotes.length,
                        itemBuilder: (context, index) {
                          final quote = quotes[index];
                          return ListTile(
                            title: Text(
                              quote.text,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text('Страница ${quote.pageNumber}'),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _goTo(quote.pageNumber);
                            },
                            trailing: IconButton(
                              tooltip: 'Удалить цитату',
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () async {
                                await _quotes.delete(quote.id);
                                quotes = await _quotes.loadForBook(
                                  widget.filePath,
                                );
                                if (context.mounted) refresh(() {});
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
    );
  }

  Widget _selectionMenu(EditableTextState state, int page) {
    final value = state.textEditingValue;
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: [
        if (!value.selection.isCollapsed && value.selection.isValid)
          ContextMenuButtonItem(
            label: 'Сохранить цитату',
            onPressed: () {
              final text = value.selection.textInside(value.text);
              ContextMenuController.removeAny();
              _saveQuote(text, page);
            },
          ),
        ...state.contextMenuButtonItems,
      ],
    );
  }

  Future<void> _openLink(String? href) async {
    final uri = href == null ? null : Uri.tryParse(href);
    if (uri == null || !['https', 'http', 'mailto'].contains(uri.scheme)) {
      return;
    }
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Report failures in the reader instead of losing the open document.
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку.')),
      );
    }
  }

  Widget _spread(BuildContext context, int spread) => BookSpread(
    left: _buildPage(context, spread * 2),
    right: spread * 2 + 1 < _document!.pages.length
        ? _buildPage(context, spread * 2 + 1)
        : const SizedBox.expand(),
  );

  Widget _buildPage(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      fontSize: _fontSize,
      height: 1.75,
      color: scheme.onSurface,
      fontFamily: 'Georgia',
    );
    return SingleChildScrollView(
      key: PageStorageKey('text-page-$index'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: _isMarkdown
              ? MarkdownBody(
                  key: ValueKey('markdown-page-content-$index'),
                  data:
                      '${_document!.pages[index]}\n\n${_document!.referenceDefinitions}',
                  selectable: true,
                  fitContent: false,
                  onTapLink: (_, href, _) => _openLink(href),
                  contextMenuBuilder: (_, state) =>
                      _selectionMenu(state, index + 1),
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        p: textStyle,
                        h1: textStyle.copyWith(
                          fontSize: _fontSize * 1.6,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h2: textStyle.copyWith(
                          fontSize: _fontSize * 1.35,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h3: textStyle.copyWith(
                          fontSize: _fontSize * 1.15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h4: textStyle.copyWith(fontWeight: FontWeight.bold),
                        h5: textStyle.copyWith(fontWeight: FontWeight.bold),
                        h6: textStyle.copyWith(fontWeight: FontWeight.bold),
                        code: textStyle.copyWith(
                          fontFamily: 'monospace',
                          fontSize: _fontSize * .85,
                          height: 1.5,
                        ),
                        a: TextStyle(
                          color: scheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        blockquote: textStyle,
                        blockquoteDecoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tableBody: textStyle.copyWith(
                          fontSize: _fontSize * .85,
                        ),
                        tableHead: textStyle.copyWith(
                          fontSize: _fontSize * .85,
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: textStyle,
                      ),
                )
              : SelectableText(
                  _document!.pages[index],
                  key: ValueKey('text-page-content-$index'),
                  style: textStyle,
                  contextMenuBuilder: (_, state) =>
                      _selectionMenu(state, index + 1),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = _document?.pages.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Назад в библиотеку',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<double>(
            tooltip: 'Размер текста',
            initialValue: _fontSize,
            onSelected: (value) => setState(() => _fontSize = value),
            icon: const Icon(Icons.text_fields_rounded),
            itemBuilder: (_) => [
              for (final size in [16.0, 20.0, 24.0])
                PopupMenuItem(
                  value: size,
                  child: Text(
                    '${size.toInt()} · ${size == 16
                        ? 'Мелкий'
                        : size == 20
                        ? 'Средний'
                        : 'Крупный'}',
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Цитаты',
            onPressed: _showQuotes,
            icon: const Icon(Icons.format_quote_rounded),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.description_outlined, size: 40),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            )
          : _document == null
          ? const Center(child: CircularProgressIndicator())
          : BookPageTurn(
              key: const ValueKey('text-reader-pages'),
              controller: _controller,
              spread: true,
              page: (_page - 1) ~/ 2,
              pageCount: (count + 1) ~/ 2,
              onTurnStart: () {
                FocusManager.instance.primaryFocus?.unfocus();
                ContextMenuController.removeAny();
              },
              onPageChanged: (index) {
                setState(() => _page = index * 2 + 1);
                widget.onProgressChanged?.call(_page, count);
              },
              previewBuilder: _spread,
              child: _spread(context, (_page - 1) ~/ 2),
            ),
      bottomNavigationBar: count == 0
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Предыдущая страница',
                        onPressed: (_page - 1) ~/ 2 > 0
                            ? () => _goTo(_page - 2)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: count > 1 ? count.toDouble() : 2,
                          value: _scrubPage ?? _page.toDouble(),
                          label: 'Страница $_page',
                          onChanged: count > 1
                              ? (value) => setState(() => _scrubPage = value)
                              : null,
                          onChangeEnd: count > 1
                              ? (value) {
                                  _goTo(value.round());
                                  setState(() => _scrubPage = null);
                                }
                              : null,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Следующая страница',
                        onPressed: (_page - 1) ~/ 2 < (count - 1) ~/ 2
                            ? () => _goTo(_page + 2)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  Text(
                    spreadLabel(
                      (_scrubPage ?? _page.toDouble()).round(),
                      count,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
