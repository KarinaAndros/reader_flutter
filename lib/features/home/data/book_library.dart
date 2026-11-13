import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LibraryBook {
  const LibraryBook({
    required this.id,
    required this.title,
    required this.author,
    required this.mood,
    required this.description,
    required this.coverStyle,
    this.filePath,
    this.page = 1,
    this.pageCount = 0,
    this.coverSeed,
  });

  final String id;
  final String title;
  final String author;
  final String mood;
  final String description;
  final int coverStyle;
  final String? filePath;
  final int page;
  final int pageCount;
  final int? coverSeed;

  bool get isLocal => filePath != null;
  bool get isText => filePath?.toLowerCase().endsWith('.txt') ?? false;
  bool get isPdf => filePath?.toLowerCase().endsWith('.pdf') ?? false;
  double get progress => pageCount == 0 ? 0 : (page / pageCount).clamp(0, 1);

  LibraryBook withProgress(int page, int count) => LibraryBook(
    id: id,
    title: title,
    author: author,
    mood: mood,
    description: description,
    coverStyle: coverStyle,
    filePath: filePath,
    page: page,
    pageCount: count,
    coverSeed: coverSeed,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'mood': mood,
    'description': description,
    'coverStyle': coverStyle,
    'filePath': filePath,
    'page': page,
    'pageCount': pageCount,
    'coverSeed': coverSeed,
  };

  factory LibraryBook.fromJson(Map<String, dynamic> json) => LibraryBook(
    id: json['id'] as String,
    title: json['title'] as String,
    author: json['author'] as String,
    mood: json['mood'] as String,
    description: json['description'] as String,
    coverStyle: json['coverStyle'] as int,
    filePath: json['filePath'] as String?,
    page: json['page'] as int? ?? 1,
    pageCount: json['pageCount'] as int? ?? 0,
    coverSeed: json['coverSeed'] as int?,
  );
}

class BookLibrary {
  static const booksKey = 'reader_library_v1';
  static const favoritesKey = 'reader_favorites_v1';

  Future<List<LibraryBook>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(booksKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((book) => LibraryBook.fromJson(book as Map<String, dynamic>))
          .toList();
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> save(List<LibraryBook> books) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      booksKey,
      jsonEncode(books.map((book) => book.toJson()).toList()),
    );
  }

  Future<Set<String>> loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(favoritesKey) ?? []).toSet();
  }

  Future<void> saveFavorites(Set<String> favorites) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(favoritesKey, favorites.toList());
  }
}

// Editorial book suggestions. Their PDF files are supplied by the reader.
const editorialBooks = [
  LibraryBook(
    id: 'prince',
    title: 'Маленький принц',
    author: 'Антуан де Сент-Экзюпери',
    mood: 'Мечтательное',
    coverStyle: 0,
    description: 'О маленькой планете, больших путешествиях и самом важном, чего не увидишь глазами. История, которая каждый раз открывается по-новому.',
  ),
  LibraryBook(
    id: 'master',
    title: 'Мастер и Маргарита',
    author: 'Михаил Булгаков',
    mood: 'Загадочное',
    coverStyle: 1,
    description: 'Ночная Москва, неожиданные гости и любовь, которой подвластно время. Роман, в котором реальность встречается с невозможным.',
  ),
  LibraryBook(
    id: '1984',
    title: '1984',
    author: 'Джордж Оруэлл',
    mood: 'Вдумчивое',
    coverStyle: 2,
    description: 'Мир, где даже мысли могут стать преступлением. О свободе, памяти и праве оставаться собой.',
  ),
  LibraryBook(
    id: 'forest',
    title: 'Норвежский лес',
    author: 'Харуки Мураками',
    mood: 'Спокойное',
    coverStyle: 3,
    description: 'Тихая история о взрослении, любви и хрупкости воспоминаний. Для вечера, когда хочется замедлиться.',
  ),
  LibraryBook(
    id: 'dandelion',
    title: 'Вино из одуванчиков',
    author: 'Рэй Брэдбери',
    mood: 'Мечтательное',
    coverStyle: 4,
    description: 'Целое лето, сохранённое в одной книге. Тёплые улицы, маленькие открытия и вкус детства.',
  ),
  LibraryBook(
    id: 'ocean',
    title: 'Старик и море',
    author: 'Эрнест Хемингуэй',
    mood: 'Спокойное',
    coverStyle: 5,
    description: 'Человек, лодка и бескрайний океан. Небольшая повесть о стойкости, достоинстве и диалоге с морем.',
  ),
];
