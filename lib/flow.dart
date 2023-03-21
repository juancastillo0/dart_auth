import 'package:http/http.dart' as http;
import 'package:oauth/endpoint_models.dart';
import 'package:oauth/oauth.dart';

class OAuthFlow<U> {
  final OAuthProvider<U> provider;
  final Persistence persistence;

  final HttpClient client;

  ///
  OAuthFlow(this.provider, this.persistence, {HttpClient? client})
      : client = client ?? http.Client();

  Future<Uri> getAuthorizeUri({
    required String redirectUri,
    String? loginHint,
    Map<String, String?>? otherParams,
    String? scope,
    String? state,
    OAuthResponseType responseType = OAuthResponseType.code,
    String? sessionId,
    Map<String, Object?>? meta,
  }) async {
    scope ??= provider.config.scope;
    state ??= generateStateToken();
    final nonce = scope.split(RegExp('[ ,]')).contains('openid')
        ? generateStateToken()
        : null;
    final challenge = responseType == OAuthResponseType.code
        ? CodeChallenge.generateS256()
        : null;
    final paramsModel = AuthParams(
      client_id: provider.clientId,
      state: state,
      redirect_uri: redirectUri,
      response_type: responseType.value,
      scope: scope,
      code_challenge: challenge?.codeChallenge,
      code_challenge_method: challenge?.codeChallengeMethod.name,
      nonce: nonce,
      otherParams: otherParams,
      // TODO:
      // access_type: 'offline',
      // login_hint: loginHint,
    );
    final params = provider.mapAuthParamsToQueryParams(paramsModel);
    final uri = Uri.parse(provider.authorizationEndpoint)
        .replace(queryParameters: params);
    final stateMode = AuthStateModel(
      state: state,
      createdAt: DateTime.now(),
      codeVerifier: challenge?.codeVerifier,
      nonce: nonce,
      responseType: responseType,
      sessionId: sessionId,
      providerId: provider.providerId,
      meta: meta,
    );
    // TODO: should we use jwt?
    // TODO: maybe allow more meta data?
    await persistence.setState(state, stateMode);
    return uri;
  }

  Future<Result<TokenResponse, AuthResponseError>> handleRedirectUri({
    required Map<String, Object?> queryParams,
    // TODO: not necessary for implicit
    required String? redirectUri,
    Map<String, String?>? otherParams,
  }) async {
    final data = AuthRedirectResponse.fromJson(queryParams);
    final code = data.code;
    final state = data.state;
    if (state == null) {
      return Err(
        AuthResponseError(
          data,
          AuthResponseErrorKind.noState,
          stateModel: null,
        ),
      );
    }

    final stateModel = await persistence.getState(state);
    Result<TokenResponse, AuthResponseError> retErr(
      AuthResponseErrorKind kind,
    ) {
      return Err(
        AuthResponseError(
          data,
          kind,
          stateModel: stateModel,
        ),
      );
    }

    if (stateModel == null) {
      return retErr(AuthResponseErrorKind.notFoundState);
    } else if (stateModel.providerId != provider.providerId ||
        stateModel.responseType == null) {
      return retErr(AuthResponseErrorKind.invalidState);
    } else if (data.error != null) {
      return retErr(AuthResponseErrorKind.endpointError);
    }
    final grantType = stateModel.responseType!.grantType;

    final TokenResponse token;
    HttpResponse? responseToken;
    if (grantType == GrantType.tokenImplicit) {
      token = TokenResponse.fromJson(
        queryParams,
        stateModel: stateModel,
      );
    } else {
      if (code == null) {
        return retErr(AuthResponseErrorKind.noCode);
      }
      final params = provider.mapTokenParamsToQueryParams(
        TokenParams(
          code: code,
          grant_type: grantType,
          redirect_uri: redirectUri,
          code_verifier: stateModel.codeVerifier,
          otherParams: otherParams,
        ),
      );
      final parsedResponse = await provider.sendHttpPost(
        client,
        Uri.parse(provider.tokenEndpoint),
        params,
      );
      responseToken = parsedResponse.response;
      final tokenBody = parsedResponse.parsedBody;

      if (!parsedResponse.isSuccess || tokenBody == null) {
        final error = OAuthErrorResponse.fromResponse(parsedResponse);
        return Err(
          AuthResponseError(
            data,
            AuthResponseErrorKind.tokenResponseError,
            response: responseToken,
            error: error,
            stateModel: stateModel,
          ),
        );
      }
      token = TokenResponse.fromJson(
        (tokenBody is List ? tokenBody[0] : tokenBody) as Map,
        stateModel: stateModel,
      );
    }
    // TODO: validate token https://developers.google.com/identity/openid-connect/openid-connect#validatinganidtoken
    // final claims = GoogleClaims.fromJson(jsonDecode(token.id_token) as Map);
    // if (claims.nonce == null || claims.nonce != nonce) {
    //   throw Error();
    // }
    // return GoogleSuccessAuth(
    //   token: token,
    //   claims: claims,
    // );
    return Ok(token);
  }
}

enum OAuthResponseType {
  code('code'),
  token('token');

  const OAuthResponseType(this.value);
  final String value;

  String toJson() => value;

  factory OAuthResponseType.fromJson(Object? value) =>
      values.firstWhere((e) => e.value == value);

  GrantType get grantType {
    switch (this) {
      case OAuthResponseType.code:
        return GrantType.authorizationCode;
      case OAuthResponseType.token:
        return GrantType.tokenImplicit;
    }
  }
}

class AuthResponseError implements SerializableToJson {
  final AuthRedirectResponse data;
  final AuthResponseErrorKind kind;
  final HttpResponse? response;
  final OAuthErrorResponse? error;
  final AuthStateModel? stateModel;

  ///
  AuthResponseError(
    this.data,
    this.kind, {
    this.response,
    this.error,
    required this.stateModel,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'data': data,
      'kind': kind.name,
      'error': error,
      'stateModel': stateModel,
    };
  }

  factory AuthResponseError.fromJson(Map<String, Object?> json) {
    return AuthResponseError(
      AuthRedirectResponse.fromJson(json['data']! as Map),
      AuthResponseErrorKind.values.byName(json['kind']! as String),
      error: json['error'] == null
          ? null
          : OAuthErrorResponse.fromJson(json['error']! as Map, null),
      stateModel: json['stateModel'] == null
          ? null
          : AuthStateModel.fromJson((json['stateModel']! as Map).cast()),
      response: null,
    );
  }
}

enum AuthResponseErrorKind {
  endpointError,
  noState,
  noCode,
  notFoundState,
  tokenResponseError,
  invalidState;

  AuthError get error {
    switch (this) {
      case endpointError:
        return const AuthError(
          Translation(key: Translations.oauthEndpointErrorKey),
        );
      case noState:
        return const AuthError(
          Translation(key: Translations.oauthNoStateKey),
        );
      case noCode:
        return const AuthError(
          Translation(key: Translations.oauthNoCodeKey),
        );
      case notFoundState:
        return const AuthError(
          Translation(key: Translations.oauthNotFoundStateKey),
        );
      case tokenResponseError:
        return const AuthError(
          Translation(key: Translations.oauthTokenResponseErrorKey),
        );
      case invalidState:
        return const AuthError(
          Translation(key: Translations.oauthInvalidStateKey),
        );
    }
  }
}

/// The data saved for authentication flows
class AuthStateModel {
  final String state;
  final String providerId;
  final DateTime createdAt;
  final OAuthResponseType? responseType;
  final String? sessionId;
  final String? codeVerifier;
  final String? nonce;
  final Map<String, Object?>? meta;

  /// The data saved for authentication flows
  AuthStateModel({
    required this.state,
    required this.providerId,
    required this.createdAt,
    required this.responseType,
    this.codeVerifier,
    this.nonce,
    this.sessionId,
    this.meta,
  });

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'createdAt': createdAt.toIso8601String(),
      'codeVerifier': codeVerifier,
      'providerId': providerId,
      'nonce': nonce,
      'responseType': responseType?.toJson(),
      'sessionId': sessionId,
      'meta': meta,
    }..removeWhere((key, value) => value == null);
  }

  factory AuthStateModel.fromJson(Map<String, dynamic> map) {
    return AuthStateModel(
      state: map['state'] as String,
      providerId: map['providerId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      responseType: map['responseType'] == null
          ? null
          : OAuthResponseType.fromJson(map['responseType'] as String),
      codeVerifier: map['codeVerifier'] as String?,
      nonce: map['nonce'] as String?,
      sessionId: map['sessionId'] as String?,
      meta: map['meta'] as Map<String, Object?>?,
    );
  }
}

class OAuthCodeStateMeta implements SerializableToJson {
  final UserClaims? claims;
  final TokenResponse? token;
  final AuthResponseError? error;
  final AuthError? getUserError;

  ///
  OAuthCodeStateMeta({
    this.claims,
    this.token,
    this.error,
    this.getUserError,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'claims': claims,
      'token': token,
      'error': error,
      'getUserError': getUserError,
    }..removeWhere((key, value) => value == null);
  }

  factory OAuthCodeStateMeta.fromJson(Map<String, Object?> json) {
    return OAuthCodeStateMeta(
      claims: json['claims'] == null
          ? null
          : UserClaims.fromJson((json['claims']! as Map).cast()),
      token: json['token'] == null
          ? null
          : TokenResponse.fromJson((json['token']! as Map).cast()),
      error: json['error'] == null
          ? null
          : AuthResponseError.fromJson((json['error']! as Map).cast()),
      getUserError: json['getUserError'] == null
          ? null
          : AuthError.fromJson(json['getUserError']! as Map<String, Object?>),
    );
  }
}
