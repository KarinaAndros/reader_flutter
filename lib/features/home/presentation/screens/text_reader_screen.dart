import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/quote_repository.dart';
import 'package:flutter_app/features/home/data/text_book_document.dart';

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
  PageController? _controller;
  String? _error;
  int _page = 1;
  double _fontSize = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final bytes = await File(widget.filePath).readAsBytes();
      final document = await compute(TextBookDocument.fromBytes, bytes);
      if (!mounted) return;
      setState(() {
        _document = document;
        _page = widget.initialPage.clamp(1, document.pages.length);
        _controller = PageController(initialPage: _page - 1);
      });
      widget.onProgressChanged?.call(_page, document.pages.length);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error is FormatException
            ? error.message
            : 'Не удалось открыть TXT. Попробуйте добавить файл заново.',
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    if (_document == null || !_controller!.hasClients) return;
    FocusManager.instance.primaryFocus?.unfocus();
    ContextMenuController.removeAny();
    _controller!.jumpToPage(page.clamp(1, _document!.pages.length) - 1);
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
          : PageView.builder(
              key: const ValueKey('text-reader-pages'),
              controller: _controller,
              itemCount: count,
              onPageChanged: (index) {
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _page = index + 1);
                widget.onProgressChanged?.call(_page, count);
              },
              itemBuilder: (context, index) => SingleChildScrollView(
                key: PageStorageKey('text-page-$index'),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: SelectableText(
                      _document!.pages[index],
                      key: ValueKey('text-page-content-$index'),
                      style: TextStyle(
                        fontSize: _fontSize,
                        height: 1.75,
                        color: scheme.onSurface,
                        fontFamily: 'Georgia',
                      ),
                      contextMenuBuilder: (context, state) {
                        final value = state.textEditingValue;
                        return AdaptiveTextSelectionToolbar.buttonItems(
                          anchors: state.contextMenuAnchors,
                          buttonItems: [
                            ...state.contextMenuButtonItems,
                            if (!value.selection.isCollapsed &&
                                value.selection.isValid)
                              ContextMenuButtonItem(
                                label: 'Сохранить цитату',
                                onPressed: () {
                                  final text = value.selection.textInside(
                                    value.text,
                                  );
                                  ContextMenuController.removeAny();
                                  _saveQuote(text, index + 1);
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
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
                        onPressed: _page > 1 ? () => _goTo(_page - 1) : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: count > 1 ? count.toDouble() : 2,
                          value: _page.toDouble(),
                          label: 'Страница $_page',
                          onChanged: count > 1
                              ? (value) => _goTo(value.round())
                              : null,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Следующая страница',
                        onPressed: _page < count
                            ? () => _goTo(_page + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  Text(
                    'Страница $_page из $count',
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
