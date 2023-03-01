import 'package:http/http.dart' as http;
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
      createdAt: DateTime.now(),
      codeVerifier: challenge?.codeVerifier,
      nonce: nonce,
      responseType: responseType,
      sessionId: sessionId,
      providerId: provider.providerId,
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
    if (data.error != null) {
      return Err(AuthResponseError(data, AuthResponseErrorKind.endpointError));
    }
    final code = data.code;
    final state = data.state;
    if (state == null) {
      return Err(AuthResponseError(data, AuthResponseErrorKind.noState));
    }
    final stateModel = await persistence.getState(state);
    if (stateModel == null) {
      return Err(AuthResponseError(data, AuthResponseErrorKind.notFoundState));
    } else if (stateModel.providerId != provider.providerId ||
        stateModel.responseType == null) {
      return Err(AuthResponseError(data, AuthResponseErrorKind.invalidState));
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
        return Err(
          AuthResponseError(data, AuthResponseErrorKind.noCode),
        );
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

class AuthResponseError {
  final AuthRedirectResponse data;
  final AuthResponseErrorKind kind;
  final HttpResponse? response;
  final OAuthErrorResponse? error;

  AuthResponseError(
    this.data,
    this.kind, {
    this.response,
    this.error,
  });
}

enum AuthResponseErrorKind {
  endpointError,
  noState,
  noCode,
  notFoundState,
  tokenResponseError,
  invalidState,
}

/// The data saved for authentication flows
class AuthStateModel {
  final String providerId;
  final DateTime createdAt;
  final OAuthResponseType? responseType;
  final String? sessionId;
  final String? codeVerifier;
  final String? nonce;
  final Map<String, Object?>? meta;

  /// The data saved for authentication flows
  AuthStateModel({
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
