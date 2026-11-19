import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:techy_trashker/data/api/api_client.dart';
import 'package:techy_trashker/data/api/api_exception.dart';
import 'package:techy_trashker/data/api/token_store.dart';

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

void main() {
  test('sends bearer token and decodes successful JSON', () async {
    final tokens = MemoryTokenStore(accessToken: 'access-1');
    final client = ApiClient(
      baseUrl: 'http://localhost:3000',
      tokenStore: tokens,
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/v1/me');
        expect(request.headers['Authorization'], 'Bearer access-1');
        return http.Response(
          jsonEncode({'name': 'Andhika'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    expect(await client.get('/api/v1/me'), {'name': 'Andhika'});
  });

  test('refreshes an expired access token and retries once', () async {
    final tokens = MemoryTokenStore(
      accessToken: 'expired-access',
      refreshToken: 'refresh-1',
    );
    var profileRequests = 0;
    final client = ApiClient(
      baseUrl: 'http://localhost:3000',
      tokenStore: tokens,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          expect(jsonDecode(request.body), {'refreshToken': 'refresh-1'});
          return http.Response(
            jsonEncode({
              'accessToken': 'access-2',
              'refreshToken': 'refresh-2',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        profileRequests += 1;
        if (request.headers['Authorization'] == 'Bearer expired-access') {
          return http.Response(
            jsonEncode({
              'error': {'code': 'INVALID_TOKEN', 'message': 'Expired'},
            }),
            401,
            headers: {'content-type': 'application/json'},
          );
        }
        expect(request.headers['Authorization'], 'Bearer access-2');
        return http.Response(
          jsonEncode({'name': 'Andhika'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    expect(await client.get('/api/v1/me'), {'name': 'Andhika'});
    expect(profileRequests, 2);
    expect(tokens.accessToken, 'access-2');
    expect(tokens.refreshToken, 'refresh-2');
  });

  test('clears invalid tokens and notifies the session controller', () async {
    final tokens = MemoryTokenStore(
      accessToken: 'expired-access',
      refreshToken: 'expired-refresh',
    );
    var sessionExpired = false;
    final client = ApiClient(
      baseUrl: 'http://localhost:3000',
      tokenStore: tokens,
      httpClient: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'code': 'INVALID_TOKEN', 'message': 'Expired'},
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    )..onSessionExpired = () => sessionExpired = true;

    await expectLater(client.get('/api/v1/me'), throwsA(isA<ApiException>()));
    expect(tokens.accessToken, isNull);
    expect(tokens.refreshToken, isNull);
    expect(sessionExpired, isTrue);
  });
}
