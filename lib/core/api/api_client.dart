import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient({Uri? baseUrl, HttpClient Function()? clientFactory})
    : baseUrl = baseUrl ?? defaultBaseUrl,
      _clientFactory = clientFactory ?? HttpClient.new;

  final Uri baseUrl;
  final HttpClient Function() _clientFactory;

  static Uri get defaultBaseUrl {
    const configured = String.fromEnvironment('BOOKS_API_URL');
    return Uri.parse(
      configured.isNotEmpty
          ? configured
          : defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8080/'
          : 'http://127.0.0.1:8080/',
    );
  }

  Future<Object?> getJson(String path) async {
    final client = _clientFactory()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final root = baseUrl.toString().endsWith('/')
          ? baseUrl
          : Uri.parse('$baseUrl/');
      final request = await client
          .getUrl(root.resolve(path))
          .timeout(const Duration(seconds: 10));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: request.uri);
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 10))) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) {
          throw const FormatException('Каталог слишком большой.');
        }
      }
      return jsonDecode(utf8.decode(bytes));
    } finally {
      client.close(force: true);
    }
  }
}
