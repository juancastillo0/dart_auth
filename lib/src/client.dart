import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:oauth/oauth.dart';

class OAuth2Client<U> extends http.BaseClient {
  final OAuthProvider<U> provider;
  final String? scope;

  String get accessToken => _accessToken;
  String _accessToken;
  DateTime? _accessTokenExpiration;
  String? _refreshToken;

  final http.Client _innerClient;

  ///
  OAuth2Client({
    required this.provider,
    required String accessToken,
    required DateTime? accessTokenExpiration,
    required String? refreshToken,
    this.scope,
    http.Client? innerClient,
  })  : _accessToken = accessToken,
        _accessTokenExpiration = accessTokenExpiration,
        _refreshToken = refreshToken,
        _innerClient = innerClient ?? http.Client();

  factory OAuth2Client.fromTokenResponse(
    OAuthProvider<U> provider,
    TokenResponse tokenResponse, {
    http.Client? innerClient,
  }) =>
      OAuth2Client(
        provider: provider,
        accessToken: tokenResponse.access_token,
        accessTokenExpiration: tokenResponse.expires_at,
        refreshToken: tokenResponse.refresh_token,
        scope: tokenResponse.scope,
        innerClient: innerClient,
      );

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final accessToken = await _getAccessToken();
    if (request.headers['Authorization'] == null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
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
    final response = await provider.sendTokenHttpPost(_innerClient, {
      'grant_type': GrantType.refreshToken.value,
      'refresh_token': _refreshToken,
      if (scope != null) 'scope': scope,
    });
    if (response.isErr()) throw response.unwrapErr();

    final tokenResponse = response.unwrap();
    _accessToken = tokenResponse.access_token;
    _accessTokenExpiration = tokenResponse.expires_at;
    _refreshToken = tokenResponse.refresh_token ?? _refreshToken;

    return _accessToken;
  }
}
