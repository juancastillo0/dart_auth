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
  basicHeader,

  /// Header: "Content-Type: application/x-www-form-urlencoded"
  /// Body: "client_id=your_client_id&client_secret=your_client_secret"
  formUrlencodedBody
}

abstract class UrlParams {
  /// Returns a Map with the url query parameters represented by this
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
    this.nonce,
    this.code_challenge,
    this.code_challenge_method,
    this.show_dialog,
    this.otherParams,
  });

  final String client_id;

  /// code, token
  final String response_type;
  final String redirect_uri;
  final String scope;
  final String state;
  final String? code_challenge;
  final String? code_challenge_method;

  final String? nonce;

  /// Whether or not to force the user to approve the app again
  /// if they’ve already done so. If false (default), a user who has
  /// already approved the application may be automatically redirected
  /// to the URI specified by redirect_uri. If true, the user will not be
  /// automatically redirected and will have to approve the app again.
  /// Providers: spotify
  final String? show_dialog;

  final Map<String, String?>? otherParams;

  @override
  Map<String, String?> toJson() => {
        'client_id': client_id,
        'response_type': response_type,
        'redirect_uri': redirect_uri,
        'scope': scope,
        'state': state,
        'nonce': nonce,
        if (code_challenge != null) 'code_challenge': code_challenge,
        if (code_challenge_method != null)
          'code_challenge_method': code_challenge_method,
        if (show_dialog != null) 'show_dialog': show_dialog,
        ...?otherParams
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
  authorizationCode('authorization_code'),

  /// response_type=code
  refreshToken('refresh_token'),

  /// deviceAuthorizationEndpoint
  deviceCode('urn:ietf:params:oauth:grant-type:device_code'),
  password('password'),
  clientCredentials('client_credentials'),

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
    this.otherParams,
  });

  const TokenParams.refreshToken({
    required this.client_id,
    required this.client_secret,
    required String refreshToken,
    this.otherParams,
  })  : code = refreshToken,
        redirect_uri = '',
        code_verifier = null,
        grant_type = GrantType.refreshToken;

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

  /// The code verifier When using a code_challenge to retrieve the
  /// authorization code in Proof Key for Code Exchange (PKCE).
  final String? code_verifier;

  /// Other parameters to be sent to the token endpoint
  final Map<String, String?>? otherParams;

  @override
  Map<String, String> toJson() => {
        'client_id': client_id,
        'client_secret': client_secret,
        'grant_type': grant_type.value,
        if (grant_type == GrantType.authorizationCode)
          'code': code
        else if (grant_type == GrantType.refreshToken)
          'refresh_token': code,
        if (grant_type == GrantType.authorizationCode ||
            // TODO: check flow for GrantType.password
            grant_type == GrantType.password)
          'redirect_uri': redirect_uri,
        if (code_verifier != null) 'code_verifier': code_verifier!,
        if (otherParams != null)
          ...Map.fromEntries(
            otherParams!.entries.where((element) => element.value != null),
          ).cast()
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

DateTime parseExpiresAt(Map<dynamic, dynamic> json) =>
    json['expires_at'] != null
        ? DateTime.parse(json['expires_at'] as String)
        : DateTime.now().add(Duration(seconds: json['expires_in'] as int));

/// The parsed body of the token OAuth2 endpoint
class TokenResponse {
  /// The parsed body of the token OAuth2 endpoint
  const TokenResponse({
    required this.access_token,
    required this.expires_in,
    required this.id_token,
    required this.scope,
    required this.token_type,
    required this.refresh_token,
    required this.expires_at,
    this.state,
    this.rawJson,
    this.nonce,
  });

  /// Parses the token response body
  factory TokenResponse.fromJson(
    Map<dynamic, dynamic> json, {
    String? nonce,
  }) =>
      TokenResponse(
        access_token: json['access_token'] as String,
        expires_in: json['expires_in'] as int,
        id_token: json['id_token'] as String?,
        scope: json['scope'] as String,
        token_type: json['token_type'] as String,
        refresh_token: json['refresh_token'] as String?,
        state: json['state'] as String?,
        expires_at: parseExpiresAt(json),
        rawJson: json.cast(),
        nonce: nonce,
      );

  /// A token that can be sent to a Google API.
  final String access_token;

  /// Identifies the type of token returned.
  /// At this time, this field always has the value "Bearer".
  final String token_type;

  /// The remaining lifetime of the access token in seconds.
  final int expires_in;

  /// The date where the [access_token] expires. Computed from [expires_in]
  final DateTime expires_at;

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

  /// The JSON map with the values retrieved from the endpoint.
  final Map<String, Object?>? rawJson;

  // TODO: should be save it here?
  /// The nonce sent to the provider to verify the [id_token]
  final String? nonce;
}
