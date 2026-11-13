import 'dart:convert';
import 'dart:typed_data';

/// Stable text sections keep saved positions independent of screen/font size.
class TextBookDocument {
  const TextBookDocument(this.pages);
  final List<String> pages;

  static TextBookDocument fromBytes(Uint8List bytes) {
    final text = decode(bytes).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text.trim().isEmpty) {
      throw const FormatException('В файле нет текста для чтения.');
    }
    if (RegExp(r'[\x00-\x08\x0B\x0E-\x1F]').hasMatch(text)) {
      throw const FormatException(
        'Не удалось прочитать текст. Выберите файл TXT.',
      );
    }
    const sectionLength = 1800;
    final pages = <String>[];
    var start = 0;
    while (start < text.length) {
      var end = (start + sectionLength).clamp(0, text.length);
      if (end < text.length) {
        final boundary = text.lastIndexOf(RegExp(r'\s'), end - 1);
        if (boundary > start + sectionLength * .6) {
          end = boundary + 1;
        } else if (text.codeUnitAt(end - 1) >= 0xD800 &&
            text.codeUnitAt(end - 1) <= 0xDBFF) {
          end--;
        }
      }
      pages.add(text.substring(start, end));
      start = end;
    }
    return TextBookDocument(pages);
  }

  static String decode(Uint8List bytes) {
    if (bytes.length >= 2 &&
        ((bytes[0] == 0xFF && bytes[1] == 0xFE) ||
            (bytes[0] == 0xFE && bytes[1] == 0xFF))) {
      if (bytes.length.isOdd) {
        throw const FormatException('Текстовый файл повреждён.');
      }
      final data = ByteData.sublistView(bytes);
      final endian = bytes[0] == 0xFF ? Endian.little : Endian.big;
      return String.fromCharCodes([
        for (var i = 2; i < bytes.length; i += 2) data.getUint16(i, endian),
      ]);
    }
    try {
      return utf8.decode(bytes).replaceFirst(RegExp(r'^\uFEFF'), '');
    } on FormatException {
      // Legacy Russian text files commonly use Windows-1251.
      return String.fromCharCodes([
        for (final byte in bytes)
          byte < 128 ? byte : _windows1251.codeUnitAt(byte - 128),
      ]);
    }
  }

  static const _windows1251 =
      "\u0402\u0403\u201a\u0453\u201e\u2026\u2020\u2021\u20ac\u2030\u0409\u2039\u040a\u040c\u040b\u040f\u0452\u2018\u2019\u201c\u201d\u2022\u2013\u2014\ufffd\u2122\u0459\u203a\u045a\u045c\u045b\u045f\u00a0\u040e\u045e\u0408\u00a4\u0490\u00a6\u00a7\u0401\u00a9\u0404\u00ab\u00ac\u00ad\u00ae\u0407\u00b0\u00b1\u0406\u0456\u0491\u00b5\u00b6\u00b7\u0451\u2116\u0454\u00bb\u0458\u0405\u0455\u0457\u0410\u0411\u0412\u0413\u0414\u0415\u0416\u0417\u0418\u0419\u041a\u041b\u041c\u041d\u041e\u041f\u0420\u0421\u0422\u0423\u0424\u0425\u0426\u0427\u0428\u0429\u042a\u042b\u042c\u042d\u042e\u042f\u0430\u0431\u0432\u0433\u0434\u0435\u0436\u0437\u0438\u0439\u043a\u043b\u043c\u043d\u043e\u043f\u0440\u0441\u0442\u0443\u0444\u0445\u0446\u0447\u0448\u0449\u044a\u044b\u044c\u044d\u044e\u044f";
}
