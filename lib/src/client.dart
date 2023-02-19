import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:oauth/oauth.dart';

class OAuth2Client extends http.BaseClient {
  final String clientId;
  final String clientSecret;
  final String tokenEndpoint;
  final String? scope;

  String _accessToken;
  DateTime? _accessTokenExpiration;
  String? _refreshToken;

  final http.Client _innerClient;

  ///
  OAuth2Client({
    required this.clientId,
    required this.clientSecret,
    required this.tokenEndpoint,
    required String accessToken,
    required DateTime? accessTokenExpiration,
    required String? refreshToken,
    this.scope,
    http.Client? innerClient,
  })  : _accessToken = accessToken,
        _accessTokenExpiration = accessTokenExpiration,
        _refreshToken = refreshToken,
        _innerClient = innerClient ?? http.Client();

  factory OAuth2Client.fromProvider(
    OAuthProvider<dynamic> provider,
    TokenResponse token, {
    http.Client? innerClient,
  }) =>
      OAuth2Client(
        accessToken: token.access_token,
        accessTokenExpiration: token.expires_at,
        refreshToken: token.refresh_token,
        clientId: provider.clientId,
        clientSecret: provider.clientSecret,
        tokenEndpoint: provider.tokenEndpoint,
        scope: token.scope,
        innerClient: innerClient,
      );

  String get accessToken => _accessToken;

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
        _accessTokenExpiration!.isAfter(DateTime.now())) {
      return _accessToken;
    }

    // The access token has expired or is not set.
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }
    // Exchange the refresh token for a new access token.
    final response = await _innerClient.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ${base64.encode(utf8.encode('$clientId:$clientSecret'))}',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken,
        if (scope != null) 'scope': scope,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to refresh access token: ${response.body}');
    }
    final tokenResponse = json.decode(response.body) as Map<String, dynamic>;
    _accessToken = tokenResponse['access_token'] as String;
    _accessTokenExpiration = DateTime.now()
        .add(Duration(seconds: tokenResponse['expires_in'] as int));
    _refreshToken = tokenResponse['refresh_token'] as String;

    return _accessToken;
  }
}
