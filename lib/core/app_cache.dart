import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

class AppCache {
  AppCache({Future<Directory> Function()? directory})
    : _directory = directory ?? _pdfCacheDirectory;

  final Future<Directory> Function() _directory;

  static Future<Directory> _pdfCacheDirectory() async {
    final path = Pdfrx.cacheDirectoryPath;
    return path == null ? getTemporaryDirectory() : Directory(path);
  }

  Future<void> clear() async {
    final root = await _directory();
    // Never delete the root: it can also contain fonts and other active files.
    // Only pdfrx's regenerable download cache belongs to this operation.
    final cache = Directory.fromUri(root.uri.resolve('pdfrx.cache'));
    if (await FileSystemEntity.type(cache.path, followLinks: false) ==
        FileSystemEntityType.directory) {
      await cache.delete(recursive: true);
    }
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  }
}
