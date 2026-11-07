import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedQuote {
  const SavedQuote({
    required this.id,
    required this.text,
    required this.bookPath,
    required this.pageNumber,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String bookPath;
  final int pageNumber;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'text': text,
    'bookPath': bookPath,
    'pageNumber': pageNumber,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SavedQuote.fromJson(Map<String, dynamic> json) => SavedQuote(
    id: json['id'] as String,
    text: json['text'] as String,
    bookPath: json['bookPath'] as String,
    pageNumber: json['pageNumber'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class QuoteRepository {
  static const _storageKey = 'saved_quotes';

  Future<List<SavedQuote>> loadForBook(String bookPath) async {
    final quotes = await _loadAll();
    return quotes.where((quote) => quote.bookPath == bookPath).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(SavedQuote quote) async {
    final quotes = await _loadAll();
    quotes.add(quote);
    await _saveAll(quotes);
  }

  Future<void> delete(String id) async {
    final quotes = await _loadAll();
    quotes.removeWhere((quote) => quote.id == id);
    await _saveAll(quotes);
  }

  Future<List<SavedQuote>> _loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_storageKey);
    if (value == null) return [];

    try {
      final items = jsonDecode(value) as List<dynamic>;
      return items
          .map((item) => SavedQuote.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> _saveAll(List<SavedQuote> quotes) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(quotes.map((quote) => quote.toJson()).toList()),
    );
  }
}
