import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:oauth/oauth.dart';

class OAuthClient extends http.BaseClient {
  String _accessToken;
  DateTime? _accessTokenExpiration;
  String? _refreshToken;

  final http.Client _innerClient;

  /// Refreshes the access token with a refresh token
  final Future<RefreshTokenResponse> Function(
    HttpClient client,
    String refreshToken,
  ) refreshAccessToken;

  ///
  OAuthClient({
    required this.refreshAccessToken,
    required String accessToken,
    required DateTime? accessTokenExpiration,
    required String? refreshToken,
    http.Client? innerClient,
  })  : _accessToken = accessToken,
        _accessTokenExpiration = accessTokenExpiration,
        _refreshToken = refreshToken,
        _innerClient = innerClient ?? http.Client();

  factory OAuthClient.fromProvider(
    OAuthProvider<Object?> provider,
    RefreshTokenResponse tokenResponse, {
    http.Client? innerClient,
  }) {
    return OAuthClient(
      refreshAccessToken: (client, refreshToken) async {
        // Exchange the refresh token for a new access token.
        final response = await provider.sendTokenHttpPost(client, {
          'grant_type': GrantType.refreshToken.value,
          'refresh_token': refreshToken,
        });
        if (response.isErr()) throw response.unwrapErr();

        return response.unwrap();
      },
      accessToken: tokenResponse.accessToken,
      accessTokenExpiration: tokenResponse.expiresAt,
      refreshToken: tokenResponse.refreshToken,
      innerClient: innerClient,
    );
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.headers[Headers.authorization] == null) {
      final accessToken = await _getAccessToken();
      request.headers[Headers.authorization] = 'Bearer $accessToken';
    }
    return _innerClient.send(request);
  }

  Future<String> _getAccessToken() async {
    if (_accessTokenExpiration != null &&
        _accessTokenExpiration!
            .subtract(const Duration(seconds: 30))
            .isAfter(DateTime.now())) {
      return _accessToken;
    }

    // The access token has expired or is not set.
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }
    // Exchange the refresh token for a new access token.
    final tokenResponse =
        await refreshAccessToken(_innerClient, _refreshToken!);
    _accessToken = tokenResponse.accessToken;
    _accessTokenExpiration = tokenResponse.expiresAt;
    _refreshToken = tokenResponse.refreshToken ?? _refreshToken;

    return _accessToken;
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });
}
