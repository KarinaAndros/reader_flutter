import 'package:flutter/material.dart';

class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({super.key, required this.author, required this.size});
  final String author;
  final double size;

  static const portraits = {
    'Антуан де Сент-Экзюпери': 'assets/images/author_saint_exupery.jpg',
    'Михаил Булгаков': 'assets/images/author_bulgakov.jpg',
    'Джордж Оруэлл': 'assets/images/author_orwell.jpg',
    'Харуки Мураками': 'assets/images/author_murakami.png',
    'Рэй Брэдбери': 'assets/images/author_bradbury.jpg',
    'Эрнест Хемингуэй': 'assets/images/author_hemingway.jpg',
  };

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final knownAuthor =
        author.trim().isNotEmpty && author != 'Из вашей библиотеки';
    final words = author.trim().split(RegExp(r'\s+'));
    final initials = knownAuthor
        ? '${words.first.characters.first}${words.length > 1 ? words.last.characters.first : ''}'
              .toUpperCase()
        : '';
    final fallback = ColoredBox(
      color: Color.alphaBlend(
        accent.withValues(alpha: .2),
        Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: Center(
        child: knownAuthor
            ? Text(
                initials,
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  color: accent,
                  fontSize: size * .3,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Icon(
                Icons.person_outline_rounded,
                color: accent,
                size: size * .5,
              ),
      ),
    );
    final path = portraits[author];
    return Tooltip(
      message: knownAuthor ? 'Автор: $author' : 'Автор не указан',
      child: Semantics(
        image: true,
        label: knownAuthor ? 'Портрет автора: $author' : 'Автор не указан',
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size < 24 ? 1 : 2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border.all(color: accent.withValues(alpha: .65), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: path == null
                ? fallback
                : Image.asset(
                    path,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -.5),
                    cacheWidth: 128,
                    excludeFromSemantics: true,
                    errorBuilder: (_, error, stackTrace) => fallback,
                  ),
          ),
        ),
      ),
    );
  }
}
