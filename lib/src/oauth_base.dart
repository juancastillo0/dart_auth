// ignore_for_file: non_constant_identifier_names

import 'dart:convert' show base64Encode, utf8;

import 'package:oauth/src/code_challenge.dart';

export 'package:oauth/src/code_challenge.dart';

abstract class OAuthProvider {
  ///
  const OAuthProvider({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.revokeTokenEndpoint,
    required this.clientIdentifier,
    required this.clientSecret,
    this.wellKnownOpenIdEndpoint,
    this.deviceAuthorizationEndpoint,
  });

  final String clientIdentifier;
  final String clientSecret;
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String? revokeTokenEndpoint;
  final String? deviceAuthorizationEndpoint;
  final String? wellKnownOpenIdEndpoint;

  String basicAuthHeader() =>
      'Basic ${base64Encode(utf8.encode('$clientIdentifier:$clientSecret'))}';

  HttpAuthMethod get authMethod => HttpAuthMethod.basic;
  CodeChallengeMethod get codeChallengeMethod => CodeChallengeMethod.S256;
  List<GrantType> get supportedFlows;
}

enum HttpAuthMethod {
  /// Header: "Authorization: Basic <credentials>",
  /// where credentials is the Base64 encoding of ID and password
  /// joined by a single colon :. "your_client_id:your_client_secret"
  basic,

  /// Header: "Content-Type: application/x-www-form-urlencoded"
  /// Body: "client_id=your_client_id&client_secret=your_client_secret"
  formUrlencoded
}

abstract class UrlParams {
  /// Returns a Map with the url query parameters
  Map<String, String?> toJson();
}

class AuthParams implements UrlParams {
  ///
  const AuthParams({
    required this.client_id,
    required this.response_type,
    required this.redirect_uri,
    required this.scope,
    required this.state,
    this.code_challenge,
    this.code_challenge_method,
  });

  final String client_id;

  /// code, token
  final String response_type;
  final String redirect_uri;
  final String scope;
  final String state;
  final String? code_challenge;
  final String? code_challenge_method;

  @override
  Map<String, String?> toJson() => {
        'client_id': client_id,
        'response_type': response_type,
        'redirect_uri': redirect_uri,
        'scope': scope,
        'state': state,
        if (code_challenge != null) 'code_challenge': code_challenge,
        if (code_challenge_method != null)
          'code_challenge_method': code_challenge_method,
      };
}

///
mixin AuthParamsBaseMixin implements AuthParams {
  AuthParams get baseAuthParams;

  @override
  String get client_id => baseAuthParams.client_id;
  @override
  String get response_type => baseAuthParams.response_type;
  @override
  String get redirect_uri => baseAuthParams.redirect_uri;
  @override
  String get scope => baseAuthParams.scope;
  @override
  String get state => baseAuthParams.state;
  @override
  String? get code_challenge => baseAuthParams.code_challenge;
  @override
  String? get code_challenge_method => baseAuthParams.code_challenge_method;
}

enum GrantType {
  /// response_type=code
  authorization_code('authorization_code'),

  /// response_type=code
  refresh_token('refresh_token'),

  /// deviceAuthorizationEndpoint
  device_code('urn:ietf:params:oauth:grant-type:device_code'),
  password('password'),
  client_credentials('client_credentials'),

  /// response_type=token and grant_type=null
  tokenImplicit('token'),
  jwtBearer('urn:ietf:params:oauth:grant-type:jwt-bearer');

  const GrantType(this.value);

  /// The grant_type to set in the url parameter
  final String value;
}

class TokenParams implements UrlParams {
  ///
  const TokenParams({
    required this.client_id,
    required this.client_secret,
    required this.code,
    required this.redirect_uri,
    required this.grant_type,
    this.code_verifier,
  });

  const TokenParams.refreshToken({
    required this.client_id,
    required this.client_secret,
    required String refreshToken,
  })  : code = refreshToken,
        redirect_uri = '',
        code_verifier = null,
        grant_type = GrantType.refresh_token;

  /// The authorization code that is returned from the initial request.
  final String code;

  /// The client ID that you obtain from the API Console Credentials page,
  /// as described in Obtain OAuth 2.0 credentials.
  final String client_id;

  /// The client secret that you obtain from the API Console Credentials page,
  /// as described in Obtain OAuth 2.0 credentials.
  final String client_secret;

  /// An authorized redirect URI for the given client_id specified in the
  /// API Console Credentials page, as described in Set a redirect URI.
  final String redirect_uri;

  /// This field must contain a value of authorization_code,
  /// as defined in the OAuth 2.0 specification.
  /// authorization_code, refresh_token, token or password
  final GrantType grant_type;

  final String? code_verifier;

  @override
  Map<String, String> toJson() => {
        'client_id': client_id,
        'client_secret': client_secret,
        'grant_type': grant_type.value,
        if (grant_type == GrantType.authorization_code)
          'code': code
        else if (grant_type == GrantType.refresh_token)
          'refresh_token': code,
        if (grant_type == GrantType.authorization_code ||
            // TODO: check flow for GrantType.password
            grant_type == GrantType.password)
          'redirect_uri': redirect_uri,
        if (code_verifier != null) 'code_verifier': code_verifier!,
      };
}

///
mixin TokenParamsBaseMixin implements TokenParams {
  TokenParams get baseTokenParams;

  @override
  String get code => baseTokenParams.code;
  @override
  String get client_id => baseTokenParams.client_id;
  @override
  String get client_secret => baseTokenParams.client_secret;
  @override
  String get redirect_uri => baseTokenParams.redirect_uri;
  @override
  GrantType get grant_type => baseTokenParams.grant_type;
}

class TokenResponse {
  ///
  const TokenResponse({
    required this.access_token,
    required this.expires_in,
    required this.id_token,
    required this.scope,
    required this.token_type,
    required this.refresh_token,
    this.state,
  });

  ///
  factory TokenResponse.fromJson(Map<dynamic, dynamic> json) => TokenResponse(
        access_token: json['access_token'] as String,
        expires_in: json['expires_in'] as int,
        id_token: json['id_token'] as String?,
        scope: json['scope'] as String,
        token_type: json['token_type'] as String,
        refresh_token: json['refresh_token'] as String?,
        state: json['state'] as String?,
      );

  /// A token that can be sent to a Google API.
  final String access_token;

  /// Identifies the type of token returned.
  /// At this time, this field always has the value "Bearer".
  final String token_type;

  /// The remaining lifetime of the access token in seconds.
  final int expires_in;

  /// The scopes of access granted by the access_token expressed as a
  /// list of space-delimited, case-sensitive strings.
  final String scope;

  /// A JWT that contains identity information about the user
  /// that is digitally signed by Google.
  final String? id_token;

  /// This field is only present if the access_type parameter was set to
  /// offline in the authentication request. For details, see Refresh tokens.
  final String? refresh_token;

  /// TODO: for implicint flow
  final String? state;
}
