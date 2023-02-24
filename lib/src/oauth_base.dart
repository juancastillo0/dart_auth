import 'dart:async';
import 'dart:convert' show base64Encode, jsonDecode, utf8;

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth/src/openid_configuration.dart';

export 'package:oauth/src/code_challenge.dart';
export 'package:oauth/src/response_models.dart';

class Headers {
  static const contentType = 'Content-Type';
  static const accept = 'Accept';
  static const authorization = 'Authorization';
  static const appJson = 'application/json';
  static const appFormUrlEncoded = 'application/x-www-form-urlencoded';
}

/// A base configuration for a provider
class OAuthProviderConfig {
  /// A base configuration for a [OAuthProvider].
  ///
  /// Other implementations include:
  ///   - [SpotifyAuthParams],
  ///   - [RedditAuthParams]
  ///   - [GoogleAuthParams]
  ///   - [MicrosoftAuthParams]
  ///   - [GithubProviderConfig]
  ///
  const OAuthProviderConfig({
    required this.scope,
    Map<String, String?>? baseAuthParams,
    Map<String, String?>? baseTokenParams,
  })  : _baseAuthParams = baseAuthParams,
        _baseTokenParams = baseTokenParams;

  factory OAuthProviderConfig.merge(List<OAuthProviderConfig> configs) =>
      OAuthProviderConfig(
        scope: configs.last.scope,
        baseAuthParams: Map.fromEntries(
          configs.expand(
            (element) => element.baseAuthParams()?.entries ?? const [],
          ),
        ),
        baseTokenParams: Map.fromEntries(
          configs.expand(
            (element) => element.baseTokenParams()?.entries ?? const [],
          ),
        ),
      );

  /// The default scope
  final String scope;
  final Map<String, String?>? _baseAuthParams;
  final Map<String, String?>? _baseTokenParams;

  /// The base auth params used in the authorization endpoint
  Map<String, String?>? baseAuthParams() => _baseAuthParams;

  /// The base token params used in the token endpoint
  Map<String, String?>? baseTokenParams() => _baseTokenParams;
}

abstract class OAuthProvider<U> {
  ///
  const OAuthProvider({
    required this.providerId,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.revokeTokenEndpoint,
    required this.clientId,
    required this.clientSecret,
    required this.config,
    this.deviceAuthorizationEndpoint,
  });

  /// A unique id for the provider. One of [ImplementedProviders]
  /// or a custom for the ones you implement.
  /// Should match [providerIdRegExp].
  final String providerId;

  static final providerIdRegExp = RegExp(r'$[a-zA-Z0-9-_]+^');

  /// The client identifier for the application.
  /// Typically found in the dashboard, developer portal/console of the provider.
  final String clientId;

  /// The client secret for the application.
  /// Typically found in the dashboard, developer portal/console of the provider.
  /// Can be an empty String for flows that do not require a client secret
  /// (implicit flow).
  final String clientSecret;

  /// The OAuth2 authorization endpoint.
  final String authorizationEndpoint;

  /// The OAuth2 token endpoint.
  final String tokenEndpoint;

  /// The OAuth2 token revocation endpoint.
  final String? revokeTokenEndpoint;

  /// The OAuth2 device authorization endpoint (For device flow).
  final String? deviceAuthorizationEndpoint;

  /// The supported authorization flows.
  List<GrantType> get supportedFlows;

  final OAuthProviderConfig config;

  List<String> get defaultScopes => config.scope.split(RegExp('[ ,]+'));

  /// Retrieves the user information given an authenticated [client]
  /// and the [token] from [tokenEndpoint].
  Future<Result<AuthUser<U>, GetUserError>> getUser(
    HttpClient client,
    TokenResponse token,
  );

  /// Parses the [userData] JSON and returns the generic [AuthUser] model.
  AuthUser<U> parseUser(Map<String, Object?> userData);

  /// The authentication method used for [tokenEndpoint].
  HttpAuthMethod get authMethod => HttpAuthMethod.basicHeader;

  /// The supported code challenge for Proof Key for Code Exchange (PKCE).
  CodeChallengeMethod get codeChallengeMethod => CodeChallengeMethod.S256;

  /// The Authorization header used for Basic HTTP authentication
  String basicAuthHeader() =>
      'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';

  /// Maps the [AuthParams] to the query parameters
  /// used in [authorizationEndpoint].
  Map<String, String?> mapAuthParamsToQueryParams(AuthParams params) =>
      _mergeParams(config.baseAuthParams(), params.toJson());

  /// Maps the [TokenParams] to the query parameters used in [tokenEndpoint].
  Map<String, String?> mapTokenParamsToQueryParams(TokenParams params) =>
      _mergeParams(config.baseTokenParams(), params.toJson());

  static Map<String, String?> _mergeParams(
    Map<String, String?>? baseParams,
    Map<String, String?> params,
  ) {
    baseParams?.forEach((key, value) {
      if (value != null && !params.containsKey(key)) params[key] = value;
    });
    return params;
  }

  ///
  Future<DeviceCodeResponse?> getDeviceCode(
    HttpClient client, {
    String? scope,
    String? redirectUri,
    Map<String, String?>? otherParams,
  }) async {
    if (deviceAuthorizationEndpoint == null) return null;
    final response = await client.post(
      Uri.parse(deviceAuthorizationEndpoint!),
      body: {
        'client_id': clientId,
        'scope': scope ?? defaultScopes,
        if (redirectUri != null) 'redirect_uri': redirectUri,
        ...?otherParams,
      },
    );
    final jsonData = jsonDecode(response.body) as Map<String, Object?>;
    return DeviceCodeResponse.fromJson(jsonData);
  }

  ///
  Future<Result<TokenResponse, OAuthErrorResponse>> pollDeviceCodeToken(
    HttpClient client, {
    required String deviceCode,
    Map<String, String?>? otherParams,
  }) async {
    final response = await client.post(
      Uri.parse(tokenEndpoint),
      body: {
        'grant_type': GrantType.deviceCode.value,
        'device_code': deviceCode,
        'client_id': clientId,
        ...?otherParams,
      },
    );
    final jsonData = jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode == 200) {
      return Ok(TokenResponse.fromJson(jsonData));
    } else {
      return Err(OAuthErrorResponse.fromJson(jsonData));
    }
  }

  Stream<Result<TokenResponse, OAuthErrorResponse>> subscribeToDeviceCodeState(
    HttpClient client,
    DeviceCodeResponse deviceCode, {
    Map<String, String?>? otherParams,
  }) {
    final controller =
        StreamController<Result<TokenResponse, OAuthErrorResponse>>();

    Duration duration = Duration(seconds: deviceCode.interval);
    Timer timer;
    Future<void> callback() async {
      final response = await pollDeviceCodeToken(
        client,
        deviceCode: deviceCode.deviceCode,
        otherParams: otherParams,
      );
      if (controller.isClosed) return;

      controller.add(response);
      await response.when(
        ok: (ok) => controller.sink.close(),
        err: (err) async {
          if (err.error == DeviceFlowError.slow_down.name) {
            duration = Duration(seconds: duration.inSeconds + 1);
          } else if (err.error != DeviceFlowError.authorization_pending.name) {
            await controller.sink.close();
          }
        },
      );
      if (!controller.isClosed) {
        timer = Timer(duration, callback);
      }
    }

    timer = Timer(duration, callback);
    controller.onCancel = timer.cancel;

    return controller.stream;
  }

  Future<ParsedResponse> sendHttpPost(
    HttpClient client,
    Map<String, String?> params,
  ) async {
    if (authMethod == HttpAuthMethod.formUrlencodedBody) {
      params['client_id'] = clientId;
      params['client_secret'] = clientSecret;
    }
    final response = await client.post(
      Uri.parse(tokenEndpoint),
      headers: {
        Headers.accept: '${Headers.appJson}, ${Headers.appFormUrlEncoded}',
        Headers.contentType: Headers.appFormUrlEncoded,
        if (authMethod == HttpAuthMethod.basicHeader)
          Headers.authorization: basicAuthHeader(),
      },
      body: params,
    );

    Object? parsedBody;
    try {
      if (response.headers[Headers.contentType] == Headers.appFormUrlEncoded) {
        parsedBody = Uri.splitQueryString(response.body);
      } else {
        parsedBody = jsonDecode(response.body);
      }
    } catch (_) {}

    return ParsedResponse(response, parsedBody);
  }
}

class ParsedResponse {
  final HttpResponse response;
  final Object? parsedBody;

  ParsedResponse(this.response, this.parsedBody);
}

abstract class OpenIdConnectProvider<U> extends OAuthProvider<U> {
  ///
  OpenIdConnectProvider({
    required this.openIdConfig,
    required super.clientId,
    required super.clientSecret,
    required super.config,
    required super.providerId,
  }) : super(
          authorizationEndpoint: openIdConfig.authorizationEndpoint,
          revokeTokenEndpoint: openIdConfig.revocationEndpoint,
          tokenEndpoint: openIdConfig.tokenEndpoint!,
          deviceAuthorizationEndpoint: openIdConfig.deviceAuthorizationEndpoint,
        );

  final OpenIdConfiguration openIdConfig;

  @override
  HttpAuthMethod get authMethod =>
      openIdConfig.tokenEndpointAuthMethodsSupported == null
          ? super.authMethod
          : (openIdConfig.tokenEndpointAuthMethodsSupported!
                  .contains('client_secret_basic')
              ? HttpAuthMethod.basicHeader
              : HttpAuthMethod.formUrlencodedBody);
  @override
  CodeChallengeMethod get codeChallengeMethod =>
      openIdConfig.codeChallengeMethodsSupported == null
          ? super.codeChallengeMethod
          : (openIdConfig.codeChallengeMethodsSupported!.contains('S256')
              ? CodeChallengeMethod.S256
              : CodeChallengeMethod.plain);
  @override
  List<GrantType> get supportedFlows => openIdConfig.grantTypesSupported!
      .map(
        (e) {
          return e == 'implicit'
              ? GrantType.tokenImplicit
              : GrantType.values
                  .cast<GrantType?>()
                  .firstWhere((g) => g?.value == e, orElse: () => null);
        },
      )
      .whereType<GrantType>()
      .toList();

  /// Retrieves the user information given an authenticated [client]
  /// and the [token] from [tokenEndpoint].
  static Future<Result<OpenIdClaims, GetUserError>> getOpenIdConnectUser({
    required TokenResponse token,
    required String clientId,
    required String? jwksUri,
    required String issuer,
  }) async {
    final jwt = JsonWebToken.unverified(token.id_token!);
    final claims = OpenIdClaims.fromJson(jwt.claims.toJson());

    final keyStore = JsonWebKeyStore();
    if (jwksUri != null) {
      keyStore.addKeySetUrl(Uri.parse(jwksUri));
    }

    if (!await jwt.verify(keyStore)) {
      return Err(
        GetUserError(
          token: token,
          response: null,
          message: 'Could not verify the idToken',
        ),
      );
    }
    final errors = claims
        .validate(
          expiryTolerance: const Duration(seconds: 30),
          clientId: clientId,
          issuer: Uri.parse(issuer),
          // TODO: should be use it from token?
          nonce: token.nonce,
        )
        .toList();

    if (errors.isNotEmpty) {
      return Err(
        GetUserError(
          token: token,
          response: null,
          message: 'Could not validate the idToken claims',
          sourceError: errors,
        ),
      );
    }
    return Ok(claims);
  }

  static Future<OpenIdConfiguration> retrieveConfiguration(
    String wellKnown,
  ) async {
    final client = HttpClient();
    final responseMetadata = await client.get(Uri.parse(wellKnown));

    if (responseMetadata.statusCode != 200) {
      throw Error();
    }
    final json = jsonDecode(responseMetadata.body) as Map;
    final config = OpenIdConfiguration.fromJson(json);
    return config;
  }

  /// If this provider supports OpenIDConnect and has a configuration endpoint
  // final String? wellKnownOpenIdEndpoint;

  // OpenIdConfiguration? _openIdConfig;
  // OpenIdConfiguration? get openIdConfig => _openIdConfig;
  // bool get pendingRetrieveOpenIdConfig =>
  //     openIdConfig == null && wellKnownOpenIdEndpoint != null;

  // ///
  // FutureOr<OpenIdConfiguration?> retrieveOpenIdConfig() {
  //   if (!pendingRetrieveOpenIdConfig) {
  //     return openIdConfig;
  //   }
  //   return retrieveConfiguration(wellKnownOpenIdEndpoint!).then((value) {
  //     _openIdConfig = value;
  //     return value;
  //   });
  // }
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
    this.response_mode,
    this.prompt,
    this.login_hint,
    this.domain_hint,
  });

  /// The client ID string that you obtain from the API Console Credentials
  /// page, as described in Obtain OAuth 2.0 credentials.
  final String client_id;

  /// A random value generated by your app that enables replay protection.
  final String? nonce;

  /// If the value is code, launches a Basic authorization code flow,
  /// requiring a POST to the token endpoint to obtain the tokens.
  /// If the value is token id_token or id_token token,
  /// launches an Implicit flow, requiring the use of JavaScript at the
  /// redirect URI to retrieve tokens from the URI #fragment identifier.
  final String response_type;

  /// Determines where the response is sent. The value of this parameter must
  /// exactly match one of the authorized redirect values that you set in the
  /// API Console Credentials page (including the HTTP or HTTPS scheme, case,
  /// and trailing '/', if any).
  final String redirect_uri;
  final String scope;

  /// (Optional, but strongly recommended)
  /// An opaque string that is round-tripped in the protocol; that is to say,
  /// it is returned as a URI parameter in the Basic flow,
  /// and in the URI #fragment identifier in the Implicit flow.
  /// The state can be useful for correlating requests and responses.
  /// Because your redirect_uri can be guessed, using a state value can
  /// increase your assurance that an incoming connection is the result
  /// of an authentication request initiated by your app.
  /// If you generate a random string or encode the hash of some
  /// client state (e.g., a cookie) in this state variable, you can
  /// validate the response to additionally ensure that the request and
  /// response originated in the same browser. This provides protection
  /// against attacks such as cross-site request forgery.
  final String state;
  final String? code_challenge;
  final String? code_challenge_method;

  /// 	recommended	Specifies how the identity platform should return the
  /// requested token to your app.
  ///
  /// Supported values:
  /// - query: Default when requesting an access token. Provides the code as a
  /// query string parameter on your redirect URI. The query parameter is not
  /// supported when requesting an ID token by using the implicit flow.
  /// - fragment: Default when requesting an ID token by using the implicit flow.
  /// Also supported if requesting only a code.
  /// - form_post: Executes a POST containing the code to your redirect URI.
  /// Supported when requesting a code.
  /// Providers: [MicrosoftProvider], [AppleProvider]
  final String? response_mode;

  /// Whether or not to force the user to approve the app again
  /// if they’ve already done so. If false (default), a user who has
  /// already approved the application may be automatically redirected
  /// to the URI specified by redirect_uri. If true, the user will not be
  /// automatically redirected and will have to approve the app again.
  /// Providers: [SpotifyProvider]
  final String? show_dialog;

  /// 	optional	Indicates the type of user interaction that is required. Valid
  /// values are login, none, consent, and select_account.
  ///
  /// - prompt=login forces the user to enter their credentials on that request,
  /// negating single-sign on.
  /// - prompt=none is the opposite. It ensures that the user isn't presented
  /// with any interactive prompt. If the request can't be completed silently
  /// by using single-sign on, the Microsoft identity platform returns an
  /// interaction_required error.
  /// - prompt=consent triggers the OAuth consent dialog after the user signs in,
  /// asking the user to grant permissions to the app.
  /// - prompt=select_account interrupts single sign-on providing account
  /// selection experience listing all the accounts either in session or any
  /// remembered account or an option to choose to use a different account altogether.
  /// Providers: [MicrosoftProvider]
  final String? prompt;

  /// 	optional	You can use this parameter to pre-fill the username and
  /// email address field of the sign-in page for the user.
  /// Apps can use this parameter during reauthentication, after already
  ///  extracting the login_hint optional claim from an earlier sign-in.
  /// Providers: [MicrosoftProvider], [GoogleProvider]
  final String? login_hint;

  /// 	optional	If included, the app skips the email-based discovery process
  /// that user goes through on the sign-in page, leading to a slightly more
  /// streamlined user experience. For example, sending them to their federated
  /// identity provider. Apps can use this parameter during reauthentication,
  /// by extracting the tid from a previous sign-in.
  /// Providers: [MicrosoftProvider]
  final String? domain_hint;

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
        if (response_mode != null) 'response_mode': response_mode,
        if (prompt != null) 'prompt': prompt,
        if (login_hint != null) 'login_hint': login_hint,
        if (domain_hint != null) 'domain_hint': domain_hint,
        ...?otherParams
      };
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
    required this.code,
    required this.redirect_uri,
    required this.grant_type,
    this.code_verifier,
    this.otherParams,
  });

  const TokenParams.refreshToken({
    required String refreshToken,
    this.otherParams,
  })  : code = refreshToken,
        redirect_uri = '',
        code_verifier = null,
        grant_type = GrantType.refreshToken;

  /// The authorization code that is returned from the initial request.
  final String code;

  /// An authorized redirect URI for the given client_id specified in the
  /// API Console Credentials page, as described in Set a redirect URI.
  final String? redirect_uri;

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
  Map<String, String?> toJson() => {
        'grant_type': grant_type.value,
        if (grant_type == GrantType.authorizationCode)
          'code': code
        else if (grant_type == GrantType.refreshToken)
          'refresh_token': code,
        if (redirect_uri != null && grant_type == GrantType.authorizationCode)
          'redirect_uri': redirect_uri,
        if (code_verifier != null) 'code_verifier': code_verifier,
        if (otherParams != null) ...?otherParams,
      };
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
