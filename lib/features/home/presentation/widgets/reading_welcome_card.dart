import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/presentation/widgets/book_cover.dart';

class ReadingWelcomeCard extends StatelessWidget {
  const ReadingWelcomeCard({
    super.key,
    this.book,
    required this.onOpen,
    required this.onImport,
  });

  final LibraryBook? book;
  final VoidCallback onOpen;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentBook = book;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withValues(alpha: .9),
            colors.surface.withValues(alpha: .75),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: .15)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 650;
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Продолжить чтение последнего открываемого документа',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                currentBook == null
                    ? 'Здесь появится последний открытый документ. Откройте TXT, PDF или MD, чтобы начать чтение.'
                    : currentBook.title,
                style: TextStyle(
                  color: currentBook == null
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                  fontSize: currentBook == null ? 14 : 16,
                  fontWeight: currentBook == null
                      ? FontWeight.normal
                      : FontWeight.w600,
                  height: 1.45,
                ),
              ),
              if (currentBook != null) ...[
                const SizedBox(height: 4),
                Text(
                  currentBook.author,
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
                ),
                if (currentBook.pageCount > 0) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: currentBook.progress,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                    backgroundColor: colors.primary.withValues(alpha: .12),
                    semanticsLabel: 'Прогресс чтения',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Страница ${currentBook.page} из ${currentBook.pageCount} · '
                    '${(currentBook.progress * 100).round()}% прочитано',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ],
          );
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide || currentBook != null) ...[
                if (currentBook != null)
                  SizedBox(
                    width: wide ? 72 : 54,
                    height: wide ? 104 : 78,
                    child: BookCover(book: currentBook),
                  )
                else
                  Icon(
                    Icons.auto_stories_rounded,
                    color: colors.primary,
                    size: 40,
                  ),
                SizedBox(width: wide ? 24 : 16),
              ],
              Expanded(child: details),
            ],
          );
          final action = FilledButton.icon(
            onPressed: currentBook == null ? onImport : onOpen,
            icon: Icon(
              currentBook == null ? Icons.add_rounded : Icons.menu_book_rounded,
              size: 20,
            ),
            label: Text(
              currentBook == null ? 'Открыть документ' : 'Продолжить',
            ),
          );
          if (wide) {
            return Row(
              children: [
                Expanded(child: content),
                const SizedBox(width: 32),
                action,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [content, const SizedBox(height: 20), action],
          );
        },
      ),
    );
  }
}
