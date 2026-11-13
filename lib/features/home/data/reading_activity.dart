import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ReadingDay {
  const ReadingDay(this.date, this.pages);
  final DateTime date;
  final int pages;
}

/// Unique pages opened per book per local calendar day, including rereading.
class ReadingActivity {
  const ReadingActivity([this.days = const {}]);
  final Map<String, Map<String, Set<int>>> days;

  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  ReadingActivity record(String bookId, int page, DateTime time) {
    if (page < 1) return this;
    final date = time.toLocal();
    final key = dayKey(date);
    final day = days[key] ?? const <String, Set<int>>{};
    if (day[bookId]?.contains(page) ?? false) return this;
    final cutoff = dayKey(DateTime(date.year, date.month, date.day - 365));
    return ReadingActivity(
      Map<String, Map<String, Set<int>>>.unmodifiable({
        for (final entry in days.entries)
          if (entry.key.compareTo(cutoff) >= 0) entry.key: entry.value,
        key: Map<String, Set<int>>.unmodifiable({
          ...day,
          bookId: Set<int>.unmodifiable({...?day[bookId], page}),
        }),
      }),
    );
  }

  bool hasOpened(String bookId) =>
      days.values.any((day) => day.containsKey(bookId));

  List<ReadingDay> series(int count, {DateTime? now}) {
    final today = (now ?? DateTime.now()).toLocal();
    return [
      for (var i = count - 1; i >= 0; i--)
        _point(DateTime(today.year, today.month, today.day - i)),
    ];
  }

  ReadingDay _point(DateTime date) => ReadingDay(
    date,
    days[dayKey(date)]?.values.fold<int>(
          0,
          (sum, pages) => sum + pages.length,
        ) ??
        0,
  );

  Map<String, Object> toJson() => days.map(
    (date, books) => MapEntry(
      date,
      books.map((id, pages) => MapEntry(id, pages.toList()..sort())),
    ),
  );

  factory ReadingActivity.fromJson(Map<String, dynamic> json) {
    final days = <String, Map<String, Set<int>>>{};
    for (final entry in json.entries) {
      final date = DateTime.tryParse(entry.key);
      if (date == null || dayKey(date) != entry.key || entry.value is! Map) {
        continue;
      }
      final books = <String, Set<int>>{};
      for (final book in (entry.value as Map).entries) {
        if (book.key is! String || book.value is! List) continue;
        final pages = (book.value as List)
            .whereType<int>()
            .where((page) => page > 0)
            .toSet();
        if (pages.isNotEmpty) {
          books[book.key as String] = Set.unmodifiable(pages);
        }
      }
      if (books.isNotEmpty) days[entry.key] = Map.unmodifiable(books);
    }
    return ReadingActivity(Map.unmodifiable(days));
  }
}

class ReadingActivityRepository {
  static const storageKey = 'reader_daily_activity_v1';
  Future<void> _pending = Future.value();

  Future<void> flush() => _pending;

  Future<ReadingActivity> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null) return const ReadingActivity();
    try {
      return ReadingActivity.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const ReadingActivity();
    } on TypeError {
      return const ReadingActivity();
    }
  }

  Future<ReadingActivity> record(String bookId, int page, {DateTime? now}) {
    final time = now ?? DateTime.now();
    final operation = _pending.then((_) async {
      final current = await load();
      final updated = current.record(bookId, page, time);
      if (!identical(current, updated)) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(storageKey, jsonEncode(updated.toJson()));
      }
      return updated;
    });
    // Serialize rapid page changes so one write cannot overwrite another.
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
