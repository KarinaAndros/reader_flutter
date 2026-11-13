import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_app/features/home/data/book_library.dart';
import 'package:flutter_app/features/home/data/reading_activity.dart';

const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const _months = [
  'янв',
  'фев',
  'мар',
  'апр',
  'мая',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек',
];
String _date(DateTime date) => '${date.day} ${_months[date.month - 1]}';

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: .025),
          scheme.surface,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onSurface),
        child: child,
      ),
    );
  }
}

class ReadingActivityChart extends StatefulWidget {
  const ReadingActivityChart({
    super.key,
    required this.activity,
    this.compact = false,
    this.onDetails,
  });
  final ReadingActivity activity;
  final bool compact;
  final VoidCallback? onDetails;

  @override
  State<ReadingActivityChart> createState() => _ReadingActivityChartState();
}

class _ReadingActivityChartState extends State<ReadingActivityChart> {
  int _days = 7;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = widget.activity.series(widget.compact ? 7 : _days);
    final buckets = _days == 28 && !widget.compact
        ? [
            for (var i = 0; i < 4; i++)
              _ActivityBucket(
                days[i * 7].date,
                days[i * 7 + 6].date,
                days
                    .sublist(i * 7, i * 7 + 7)
                    .fold<int>(0, (sum, day) => sum + day.pages),
              ),
          ]
        : [
            for (final day in days)
              _ActivityBucket(day.date, day.date, day.pages),
          ];
    final total = days.fold<int>(0, (sum, day) => sum + day.pages);
    final activeDays = days.where((day) => day.pages > 0).length;
    final maximum = buckets.fold<int>(
      1,
      (max, bucket) => math.max(max, bucket.pages),
    );
    final selected = _selected == null
        ? null
        : buckets[_selected!.clamp(0, buckets.length - 1)];
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 350);
    return _ChartPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.compact ? 'Ваш ритм' : 'Активность чтения',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              if (widget.onDetails != null)
                TextButton(
                  onPressed: widget.onDetails,
                  child: const Text(
                    'Подробнее',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final count in [7, 28])
                  ChoiceChip(
                    showCheckmark: false,
                    label: Text('$count дней'),
                    selected: _days == count,
                    onSelected: (_) => setState(() {
                      _days = count;
                      _selected = null;
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              _ChartMetric(
                '$total',
                widget.compact ? 'страниц за 7 дней' : 'открытых страниц',
              ),
              if (!widget.compact) _ChartMetric('$activeDays', 'дней с книгой'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: widget.compact ? 100 : 144,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  for (final fraction in [.0, .5, 1.0])
                    Positioned(
                      top: fraction * (constraints.maxHeight - 1),
                      left: 0,
                      right: 0,
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: scheme.outlineVariant.withValues(alpha: .5),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < buckets.length; index++)
                        Expanded(
                          child: Semantics(
                            button: true,
                            selected: _selected == index,
                            label:
                                '${buckets[index].dateLabel}: ${buckets[index].pages} страниц',
                            child: Tooltip(
                              message:
                                  '${buckets[index].dateLabel} · ${buckets[index].pages} страниц',
                              child: InkWell(
                                key: ValueKey('activity-bar-$index'),
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(() => _selected = index),
                                onHover: (entered) {
                                  if (entered) {
                                    setState(() => _selected = index);
                                  }
                                },
                                child: Center(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: SizedBox(
                                      width: math.min(
                                        56,
                                        constraints.maxWidth /
                                            buckets.length *
                                            .55,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 56,
                                        ),
                                        child: AnimatedContainer(
                                          duration: duration,
                                          curve: Curves.easeOutCubic,
                                          height: buckets[index].pages == 0
                                              ? 3
                                              : math.max(
                                                  8,
                                                  constraints.maxHeight *
                                                      buckets[index].pages /
                                                      maximum,
                                                ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: buckets[index].pages == 0
                                                  ? [
                                                      scheme.outlineVariant,
                                                      scheme.outlineVariant,
                                                    ]
                                                  : [
                                                      scheme.primary.withValues(
                                                        alpha:
                                                            _selected == index
                                                            ? 1
                                                            : .7,
                                                      ),
                                                      scheme.primary.withValues(
                                                        alpha: .3,
                                                      ),
                                                    ],
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
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var index = 0; index < buckets.length; index++)
                Expanded(
                  child: Text(
                    buckets.length == 7
                        ? _weekdays[buckets[index].end.weekday - 1]
                        : '${buckets[index].end.day}.${buckets[index].end.month.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: _selected == index
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            selected != null
                ? '${selected.dateLabel} · ${selected.pages} страниц'
                : total == 0
                ? 'Откройте книгу — здесь появится ваша активность.'
                : 'Нажмите на столбик, чтобы посмотреть подробности.',
            key: const ValueKey('activity-chart-caption'),
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityBucket {
  const _ActivityBucket(this.start, this.end, this.pages);
  final DateTime start, end;
  final int pages;
  String get dateLabel =>
      start == end ? _date(end) : '${_date(start)} — ${_date(end)}';
}

class _ChartMetric extends StatelessWidget {
  const _ChartMetric(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 32,
          height: 1.1,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class ReadingShelfChart extends StatefulWidget {
  const ReadingShelfChart({
    super.key,
    required this.books,
    required this.activity,
  });
  final List<LibraryBook> books;
  final ReadingActivity activity;
  @override
  State<ReadingShelfChart> createState() => _ReadingShelfChartState();
}

class _ReadingShelfChartState extends State<ReadingShelfChart> {
  int? _selected;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var reading = 0, completed = 0, unopened = 0;
    for (final book in widget.books) {
      if (book.pageCount > 0 && book.page >= book.pageCount) {
        completed++;
      } else if (book.pageCount > 0 ||
          book.page > 1 ||
          widget.activity.hasOpened(book.id)) {
        reading++;
      } else {
        unopened++;
      }
    }
    final values = [reading, completed, unopened];
    const labels = ['В процессе', 'Прочитано', 'Ещё не открыты'];
    final colors = [
      scheme.primary,
      Color.alphaBlend(
        scheme.primary.withValues(alpha: .4),
        scheme.onSurfaceVariant,
      ),
      scheme.outlineVariant,
    ];
    return _ChartPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Книжная полка',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox.square(
              dimension: 170,
              child: Semantics(
                image: true,
                label:
                    'Всего ${widget.books.length} книг. В процессе $reading, прочитано $completed, ещё не открыты $unopened.',
                child: CustomPaint(
                  painter: _ShelfDonutPainter(
                    values,
                    colors,
                    scheme.outlineVariant,
                    _selected,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.books.length}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'книг на полке',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < values.length; i++)
            Semantics(
              selected: _selected == i,
              child: InkWell(
                key: ValueKey('shelf-status-$i'),
                onTap: () =>
                    setState(() => _selected = _selected == i ? null : i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _selected == i
                        ? scheme.primary.withValues(alpha: .07)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          labels[i],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${values[i]}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.books.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Добавьте первую книгу, чтобы наполнить свою полку.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShelfDonutPainter extends CustomPainter {
  const _ShelfDonutPainter(this.values, this.colors, this.track, this.selected);
  final List<int> values;
  final List<Color> colors;
  final Color track;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(12);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final total = values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) {
      canvas.drawOval(ring, paint..color = track.withValues(alpha: .5));
      return;
    }
    var angle = -math.pi / 2;
    final segments = values.where((value) => value > 0).length;
    for (var i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweep = values[i] / total * math.pi * 2;
      final gap = segments > 1 ? math.min(.1, sweep * .3) : 0.0;
      paint.color = selected == null || selected == i
          ? colors[i]
          : colors[i].withValues(alpha: .2);
      canvas.drawArc(ring, angle + gap / 2, sweep - gap, false, paint);
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(_ShelfDonutPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.colors != colors ||
      oldDelegate.track != track ||
      oldDelegate.selected != selected;
}

class ReadingProgressCharts extends StatelessWidget {
  const ReadingProgressCharts({
    super.key,
    required this.activity,
    required this.books,
  });
  final ReadingActivity activity;
  final List<LibraryBook> books;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final activityChart = ReadingActivityChart(
        key: const ValueKey('progress-activity'),
        activity: activity,
      );
      final shelf = ReadingShelfChart(books: books, activity: activity);
      if (constraints.maxWidth >= 800 &&
          MediaQuery.textScalerOf(context).scale(14) < 22) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: activityChart),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: shelf),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [activityChart, const SizedBox(height: 20), shelf],
      );
    },
  );
}
