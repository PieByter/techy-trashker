import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient, TokenStore? tokenStore})
    : baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(RegExp(r'/$'), ''),
      _http = httpClient ?? http.Client(),
      tokenStore = tokenStore ?? SecureTokenStore();

  final String baseUrl;
  final http.Client _http;
  final TokenStore tokenStore;
  void Function()? onSessionExpired;
  Future<bool>? _refreshing;

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(queryParameters: query);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _request('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _request('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _request('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool retryOnUnauthorized = true,
  }) async {
    final accessToken = await tokenStore.readAccessToken();
    final response = await _send(
      method,
      path,
      query: query,
      body: body,
      accessToken: accessToken,
    );

    if (response.statusCode == 401 &&
        retryOnUnauthorized &&
        accessToken != null &&
        !path.startsWith('/api/v1/auth/')) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _request(
          method,
          path,
          query: query,
          body: body,
          retryOnUnauthorized: false,
        );
      }
      await tokenStore.clear();
      onSessionExpired?.call();
    }

    return _decode(response);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    String? accessToken,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    try {
      final request = http.Request(method, _uri(path, query))
        ..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _http
          .send(request)
          .timeout(const Duration(seconds: 20));
      return http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException('Koneksi ke server terlalu lama. Coba lagi.');
    } on http.ClientException {
      throw ApiException(
        'Tidak bisa terhubung ke server ($baseUrl). Periksa koneksi dan API_BASE_URL.',
      );
    }
  }

  Future<bool> _refreshAccessToken() {
    return _refreshing ??= _performRefresh().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _send(
        'POST',
        '/api/v1/auth/refresh',
        body: {'refreshToken': refreshToken},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final json = _decode(response) as Map<String, dynamic>;
      await tokenStore.saveTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    dynamic payload;
    if (text.isNotEmpty) {
      try {
        payload = jsonDecode(text);
      } on FormatException {
        payload = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = payload is Map ? payload['error'] : null;
      throw ApiException(
        error is Map && error['message'] is String
            ? error['message'] as String
            : 'Permintaan gagal (${response.statusCode}).',
        statusCode: response.statusCode,
        code: error is Map && error['code'] is String
            ? error['code'] as String
            : null,
      );
    }

    return payload;
  }

  void close() => _http.close();
}
