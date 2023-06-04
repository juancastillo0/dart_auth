import 'dart:async';
import 'dart:convert' show jsonDecode;

import 'package:oauth/endpoint_models.dart';
import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'main.dart';

extension ThrowErr<O extends Object, E extends Object> on Result<O, E> {
  /// throws [E] if this is an [Err], else it returns [O] if it is [Ok].
  O throwErr() {
    if (isOk()) {
      return unwrap();
    } else {
      throw unwrapErr();
    }
  }
}

/// A function that handles a web socket request.
///
/// The resulting function should return a [FutureOr] of the response object
/// of the web framework. It will be set to [Resp.innerResponse].
typedef WebSocketHandler = FutureOr<Object> Function(RequestCtx) Function(
  void Function(WebSocketChannel channel, String? subprotocol) callback,
);

/// The data used to populate an HTTP response with an optional json body.
class Resp<O extends SerializableToJson, E extends SerializableToJson> {
  /// The status code of the response.
  final int statusCode;

  /// The body of the response when the response is [ok].
  final O? ok;

  /// The body of the response when the response is not [ok].
  final E? err;

  /// The response object of the web framework.
  /// Used for web sockets in [WebSocketHandler].
  final Object? innerResponse;

  /// The data used to populate an HTTP response with an optional json body.
  const Resp(
    this.statusCode, {
    required this.ok,
    required this.err,
    this.innerResponse,
  });

  /// ok: 200
  factory Resp.ok(O? body) => Resp(
        200,
        ok: body,
        err: null,
      );

  /// badRequest: 400
  factory Resp.badRequest({required E? body}) => Resp(
        400,
        err: body,
        ok: null,
      );

  /// unauthorized: 401
  factory Resp.unauthorized(E? err) => Resp(
        401,
        err: err,
        ok: null,
      );

  /// forbidden: 403
  factory Resp.forbidden(E? err) => Resp(
        403,
        err: err,
        ok: null,
      );

  /// notFound: 404
  factory Resp.notFound(E? err) => Resp(
        404,
        err: err,
        ok: null,
      );

  /// internalServerError: 500
  factory Resp.internalServerError({E? body}) => Resp(
        500,
        err: body,
        ok: null,
      );
}

Future<Resp?> Function(RequestCtx) makeHandler(
  Config config, {
  required WebSocketHandler? webSocketHandler,
}) {
  final handler = AuthHandler(config);
  const pIdRegExp = '/?([a-zA-Z_-]+)?';

  Future<Resp?> handleRequest(RequestCtx request) async {
    String path = request.url.path;
    if (path.startsWith('/')) path = path.substring(1);

    Resp<SerializableToJson, SerializableToJson>? response;
    try {
      // TODO: use only '/providers' and add DELETE (authenticationProviderDelete) to this route
      if (path == 'oauth/providers') {
        if (request.method != 'GET') return Resp.notFound(null);
        response = Resp.ok(
          AuthProvidersData(
            config.allOAuthProviders.values
                .map(OAuthProviderData.fromProvider)
                .toList(),
            config.allCredentialsProviders.values
                .map(CredentialsProviderData.fromProvider)
                .toList(),
            // TODO: .toJson(basePath: config.baseRedirectUri) maybe leave it to the front end?
          ),
        );
      } else if (RegExp('oauth/url$pIdRegExp').hasMatch(path)) {
        response = await handler.getOAuthUrl(request);
      } else if (RegExp('oauth/device$pIdRegExp').hasMatch(path)) {
        response = await handler.getOAuthDeviceCode(request);
      } else if (RegExp('oauth/callback$pIdRegExp').hasMatch(path)) {
        response = await handler.handleOAuthCallback(request);
      } else if (RegExp('oauth/state').hasMatch(path)) {
        response = await handler.getOAuthState(request);
      } else if (webSocketHandler != null &&
          RegExp('oauth/subscribe').hasMatch(path)) {
        // TODO: return unsupported for webSocketHandler == null
        final innerResponse = await handler.handlerWebSocketOAuthStateSubscribe(
          request,
          webSocketHandler,
        );
        response = Resp(-1, ok: null, err: null, innerResponse: innerResponse);
        // TODO: maybe use /token instead?
      } else if (path == 'jwt/refresh') {
        response = await handler.refreshAuthToken(request);
      } else if (path == 'jwt/revoke') {
        response = await handler.revokeAuthToken(request);
      } else if (path == 'user/me') {
        response = await handler.getUserMeInfo(request);
      } else if (path == 'user/mfa') {
        response = await handler.userMFA(request);
      } else if (RegExp('providers/delete$pIdRegExp').hasMatch(path)) {
        response = await handler.authenticationProviderDelete(request);
      } else if (RegExp('credentials/update$pIdRegExp').hasMatch(path)) {
        response = await handler.credentialsUpdate(request);
      } else if (RegExp('credentials/signin$pIdRegExp').hasMatch(path)) {
        response = await handler.credentialsSignIn(request, signUp: false);
      } else if (RegExp('credentials/signup$pIdRegExp').hasMatch(path)) {
        response = await handler.credentialsSignIn(request, signUp: true);
      } else if (RegExp('admin/users').hasMatch(path)) {
        response = await handler.getUsersInfoForAdmin(request);
      }
    } on Resp catch (e) {
      response = e;
    }
    return response;
  }

  return handleRequest;
}

class AuthHandler {
  final Config config;

  /// Handler for multiple authentication endpoints
  AuthHandler(
    this.config, {
    this.authSessionDuration = const Duration(minutes: 10),
    this.accessTokenDuration = const Duration(minutes: 10),
    this.refreshTokenDuration = const Duration(days: 60),
  });

  final Duration authSessionDuration;
  final Duration accessTokenDuration;
  final Duration refreshTokenDuration;

  Resp<O, AuthError> _wrongProviderResponse<O extends SerializableToJson>() {
    final providers = config.allProviders.keys.join('", "');
    return Resp.badRequest(
      body: AuthError(
        const Translation(key: Translations.providerNotFoundKey),
        // TODO: should we send the options as args to Translation?
        message: 'Provider url parameter must be one of "${providers}".',
      ),
    );
  }

  static Resp<O, E> _badRequestExpectedObject<O extends SerializableToJson,
          E extends SerializableToJson>() =>
      Resp.badRequest(body: null);

  String? _getProviderId(RequestCtx request) {
    return request.url.queryParameters['providerId'] ??
        (request.url.pathSegments.isNotEmpty
            ? request.url.pathSegments.last
            : null);
  }

  Result<OAuthProvider, Resp> getOAuthProvider(RequestCtx request) {
    final providerId = _getProviderId(request);
    final providerInstance = config.allOAuthProviders[providerId];
    if (providerInstance == null) {
      return Err(_wrongProviderResponse());
    }
    return Ok(providerInstance);
  }

  Result<CredentialsProvider, Resp> getCredentialsProvider(
    RequestCtx request,
  ) {
    final providerId = _getProviderId(request);
    final providerInstance = config.allCredentialsProviders[providerId];
    if (providerInstance == null) {
      return Err(_wrongProviderResponse());
    }
    return Ok(providerInstance);
  }

  Future<Resp<AuthResponseSuccess, SerializableToJson>> refreshAuthToken(
    RequestCtx request,
  ) async {
    if (request.method != 'POST') return Resp.notFound(null);

    final claims = await config.jwtMaker.getUserClaims(
      request,
      isRefreshToken: true,
    );
    if (claims == null) return Resp.unauthorized(null);

    final session = await config.persistence.getValidSession(claims.sessionId);
    if (session == null) return Resp.unauthorized(null);

    final newSession = session.copyWith(
      lastRefreshAt: DateTime.now(),
      clientData: await config.sessionClientDataFromRequest(request),
    );
    if (session.requiresVerification(
      newSession,
      // TODO: make configurable
      minLastRefreshAtDiff: const Duration(days: 8),
    )) {
      // TODO: verify session data
      return Resp.unauthorized(
        const AuthError(
          Translation(key: Translations.authProviderNotFoundToDeleteKey),
        ),
      );
    }

    // TODO: maybe pass expiresAt to createJwt
    final expiresAt = DateTime.now().add(accessTokenDuration);
    final jwt = config.jwtMaker.createJwt(
      userId: claims.userId,
      sessionId: claims.sessionId,
      duration: accessTokenDuration,
      isRefreshToken: false,
      meta: claims.meta,
    );
    await config.persistence.saveSession(newSession);
    return Resp.ok(
      AuthResponseSuccess(
        accessToken: jwt,
        expiresAt: expiresAt,
        refreshToken: null,
      ),
    );
  }

  Future<Resp> handleOAuthCallback(RequestCtx request) async {
    if (request.method != 'GET' && request.method != 'POST') {
      return Resp.notFound(null);
    }
    final providerInstance = getOAuthProvider(request).throwErr();

    final body = await parseBodyOrUrlData(request);
    if (body is! Map<String, Object?>) return _badRequestExpectedObject();
    final flow =
        OAuthFlow(providerInstance, config.persistence, client: config.client);
    final authenticated = await flow.handleRedirectUri(
      queryParams: body,
      redirectUri: config.baseRedirectUri,
    );
    return authenticated.when(
      err: (err) async {
        if (const [
          AuthResponseErrorKind.endpointError,
          AuthResponseErrorKind.noCode,
          AuthResponseErrorKind.tokenResponseError,
        ].contains(err.kind)) {
          await _addMetadataToOAuthModelState(
            err.data.state!,
            err.stateModel!,
            OAuthCodeStateMeta(error: err),
          );
        }
        switch (err.kind) {
          case AuthResponseErrorKind.endpointError:
            return Resp.ok(null);
          case AuthResponseErrorKind.noState:
          case AuthResponseErrorKind.noCode:
          case AuthResponseErrorKind.notFoundState:
          case AuthResponseErrorKind.invalidState:
            return Resp.badRequest(body: err.kind.error);
          case AuthResponseErrorKind.tokenResponseError:
            return Resp.internalServerError(body: err.kind.error);
        }
      },
      ok: (token) async {
        await _addMetadataToOAuthModelState(
          token.stateModel!.state,
          token.stateModel!,
          OAuthCodeStateMeta(token: token),
        );
        return Resp.ok(null);
        // final stateModel = token.stateModel!;
        // final claims = stateModel.meta?['claims'];
        // TODO: should we save the session and user right away?
        // final userSession = await processOAuthToken(
        //   token,
        //   providerInstance,
        //   sessionId: stateModel.sessionId!,
        //   claims: claims == null
        //       ? null
        //       : UserClaims.fromJson((claims as Map).cast()),
        // );

        // return userSession.when(
        //   err: (err) => Response.internalServerError(
        //     body: jsonEncode({'message': err.message}),
        //     headers: jsonHeader,
        //   ),
        //   ok: (userSession) async {
        //     // TODO: redirect for GETs?
        //     return Response.ok(null);
        //   },
        // );
      },
    );
  }

  Future<Result<UserSessionOrPartial, AuthError>> processOAuthToken<U>(
    TokenResponse token,
    OAuthProvider<U> providerInstance, {
    required RequestCtx request,
    required String sessionId,
    required UserClaims? claims,
  }) async {
    // TODO: make transaction
    final session = await config.persistence.getAnySession(sessionId);
    if (session != null) {
      if (!session.isValid) {
        return const Err(
          AuthError(Translation(key: Translations.sessionRevokedKey)),
        );
      } else if (!session.isInMFA) {
        // TODO: maybe save partial sessions?
        return Ok(UserSessionOrPartial(session, leftMfa: null));
      }
    }
    final result = await providerInstance.getUser(
      // TODO: improve this
      OAuthClient.fromProvider(
        providerInstance,
        token,
        innerClient: config.client,
      ),
      token,
    );

    return result.mapErr(AuthError.fromGetUserError).andThenAsync(
          (user) => onUserAuthenticated(
            user,
            request: request,
            sessionId: sessionId,
            mfaSession: session,
            claims: claims,
          ),
        );
  }

  Future<Result<UserSessionOrPartial, AuthError>> onUserAuthenticated(
    AuthUser<Object?> user, {
    required RequestCtx request,
    required String sessionId,
    required UserSession? mfaSession,
    required UserClaims? claims,
  }) async {
    // TODO: make transaction
    assert(mfaSession == null || mfaSession.isInMFA, 'Should be a mfa session');
    assert(
      mfaSession == null || mfaSession.sessionId == sessionId,
      'Should be the same session id',
    );

    final metaClaims =
        claims?.meta == null ? null : UserMetaClaims.fromJson(claims!.meta!);
    final doneMfa = {
      ...?metaClaims?.mfaItems,
      ...?mfaSession?.mfa,
      ProviderUserId(
        providerId: user.providerId,
        providerUserId: user.providerUserId,
      ),
    };

    final authUserIds = claims != null
        ? [...user.userIds(), UserId(claims.userId, UserIdKind.innerId)]
        : user.userIds();
    final List<AppUserComplete?> users =
        await config.persistence.getUsersById(authUserIds);
    // TODO: casting error whereType<Map<String, Object?>>() does not throw
    final found = users.whereType<AppUserComplete>().toList();
    final userIds = found.map((e) => e.userId).toSet();

    final String userId;
    List<ProviderUserId>? leftMfa;
    if (userIds.isEmpty) {
      // create a new user
      userId = generateStateToken();
      await config.persistence.saveUser(userId, user);
    } else if (userIds.length == 1) {
      // verify multiFactorAuth
      // TODO: split between required and a optional amount of auth providers for MFA
      final mfa = found.first.user.multiFactorAuth;
      leftMfa = mfa.itemsLeft(doneMfa);

      // merge users
      userId = userIds.first;
      // TODO: revoke previous user token?
      final newUser = await config.persistence.saveUser(userId, user);

      final providerIds = found.first
          .userIds()
          .followedBy(user.userIds())
          .where((e) => e.kind == UserIdKind.providerId)
          .toSet();
      if (mfa.isEmpty && providerIds.length == 2) {
        // TODO: maybe only change multiFactorAuth in the separate endpoint
        await config.persistence.updateUser(
          newUser.user.copyWith(
            multiFactorAuth: MFAConfig(
              optionalCount: 0,
              optionalItems: {},
              requiredItems: providerIds
                  .map(
                    (e) => ProviderUserId(
                      // TODO: imrove UserId typing. Maybe a separate ProviderUserId
                      providerId: e.id.split(':').first,
                      providerUserId: e.id.split(':').last,
                    ),
                  )
                  .toSet(),
            ),
          ),
        );
      }
    } else {
      // error multiple users
      // TODO: Merge users? make it configurable
      const error = AuthError(
        Translation(key: Translations.multipleUsersWithSameCredentialsKey),
      );
      return const Err(error);
    }

    final hasLeftMFA = leftMfa != null && leftMfa.isNotEmpty;
    final clientData = await config.sessionClientDataFromRequest(request);
    final userSession = UserSession(
      refreshToken: hasLeftMFA
          ? null
          : makeRefreshToken(
              userId: userId,
              providerId: user.providerId,
              sessionId: sessionId,
              mfaItems: doneMfa.toList(),
            ),
      sessionId: sessionId,
      userId: userId,
      createdAt: mfaSession?.createdAt ?? DateTime.now(),
      mfa: doneMfa.toList(),
      lastRefreshAt: DateTime.now(),
      clientData: clientData,
    );
    // TODO: should we save the session for MFA? Maybe just use access token claims? OAuth relies on sessions
    if (!hasLeftMFA) {
      await config.persistence.saveSession(userSession);
    }

    return Ok(UserSessionOrPartial(userSession, leftMfa: leftMfa));
  }

  Future<Resp<OAuthProviderUrl, AuthError>> getOAuthUrl(
    RequestCtx request,
  ) async {
    if (request.method != 'GET') return Resp.notFound(null);
    final providerInstance = getOAuthProvider(request).throwErr();
    final isImplicit = request.url.queryParameters['flowType'] == 'implicit';
    if (isImplicit &&
        !providerInstance.supportedFlows.contains(GrantType.tokenImplicit)) {
      return Resp.badRequest(
        body: const AuthError(
          Translation(key: Translations.providerDoesNotSupportImplicitFlowKey),
        ),
      );
    }

    final claims = await config.jwtMaker.getUserClaims(request);
    final claimsMeta =
        claims == null ? null : UserMetaClaims.fromJson(claims.meta!);
    final flow =
        OAuthFlow(providerInstance, config.persistence, client: config.client);
    final state = generateStateToken();
    // TODO: use same session from claims? should we save the loggedin status in the state instead of session
    final sessionId = generateStateToken();
    final userId = claims?.userId ?? generateStateToken();

    final meta = UserMetaClaims.authorizationCode(
      providerId: providerInstance.providerId,
      state: state,
      mfaItems: claimsMeta?.mfaItems,
    );
    final url = await flow.getAuthorizeUri(
      redirectUri:
          '${config.baseRedirectUri}/oauth/callback/${providerInstance.providerId}',
      // TODO: other params
      loginHint: request.url.queryParameters['loginHint'],
      state: state,
      sessionId: sessionId,
      responseType:
          isImplicit ? OAuthResponseType.token : OAuthResponseType.code,
      meta: OAuthCodeStateMeta(
        claims: claims ??
            UserClaims(
              userId: userId,
              sessionId: sessionId,
              meta: meta.toJson(),
            ),
      ).toJson(),
    );
    final jwt = config.jwtMaker.createJwt(
      // TODO: maybe anonymous users?
      userId: userId,
      sessionId: sessionId,
      duration: authSessionDuration,
      isRefreshToken: false,
      meta: meta.toJson(),
    );
    return Resp.ok(OAuthProviderUrl(url: url.toString(), accessToken: jwt));
  }

  Future<Resp<OAuthProviderDevice, AuthError>> getOAuthDeviceCode(
    RequestCtx request,
  ) async {
    if (request.method != 'GET') return Resp.notFound(null);
    final providerInstance = getOAuthProvider(request).throwErr();

    final deviceCode = await providerInstance.getDeviceCode(
      config.client,
      // TODO: when do we need to send the redirectUri? here or in polling?
      redirectUri: config.baseRedirectUri,
    );
    if (deviceCode == null) {
      // The provider does not support it
      return Resp.badRequest(
        body: const AuthError(
          Translation(key: Translations.providerDoesNotSupportDeviceFlowKey),
        ),
      );
    }
    final claims = await config.jwtMaker.getUserClaims(request);
    final meta = claims == null ? null : UserMetaClaims.fromJson(claims.meta!);

    final jwt = config.jwtMaker.createJwt(
      // TODO: maybe anonymous users?
      userId: claims?.userId ?? generateStateToken(),
      sessionId: generateStateToken(),
      duration: authSessionDuration,
      isRefreshToken: false,
      meta: UserMetaClaims.deviceCode(
        providerId: providerInstance.providerId,
        deviceCode: deviceCode.deviceCode,
        interval: deviceCode.interval,
        mfaItems: meta?.mfaItems,
      ).toJson(),
    );
    return Resp.ok(
      OAuthProviderDevice(device: deviceCode, accessToken: jwt),
    );
  }

  Future<void> _addMetadataToOAuthModelState(
    String state,
    AuthStateModel stateData,
    OAuthCodeStateMeta meta,
  ) async {
    await config.persistence.setState(
      state,
      AuthStateModel.fromJson({
        ...stateData.toJson(),
        'meta': {
          ...?stateData.meta,
          ...meta.toJson(),
        },
      }),
    );
  }

  Future<Result<Option<UserSessionOrPartial>, AuthError>> verifyOAuthCodeState({
    required UserClaims claims,
    required RequestCtx request,
  }) async {
    final claimsMeta = UserMetaClaims.fromJson(claims.meta!);
    final state = claimsMeta.state;
    if (state == null) {
      return Err(AuthResponseErrorKind.notFoundState.error);
    }
    final stateData = await config.persistence.getState(state);
    if (stateData == null) {
      return Err(AuthResponseErrorKind.notFoundState.error);
    }
    final meta = OAuthCodeStateMeta.fromJson(stateData.meta!);
    if (meta.claims?.userId != claims.userId) {
      return Err(AuthResponseErrorKind.invalidState.error);
    }
    if (meta.error != null) {
      return Err(AuthError.fromAuthResponseError(meta.error!));
    } else if (meta.getUserError != null) {
      return Err(meta.getUserError!);
    } else if (meta.token == null) {
      return const Ok(None());
    } else {
      final providerInstance = config.allOAuthProviders[claimsMeta.providerId]!;
      final result = await processOAuthToken(
        meta.token!,
        providerInstance,
        request: request,
        sessionId: claims.sessionId,
        claims: claims,
      );
      if (result.isErr()) {
        final error = result.unwrapErr();
        await _addMetadataToOAuthModelState(
          state,
          stateData,
          OAuthCodeStateMeta(getUserError: error),
        );
        return Err(error);
      } else {
        return Ok(Some(result.unwrap()));
      }
    }
  }

  Future<Resp<AuthResponseSuccess, AuthError>> getOAuthState(
    RequestCtx request,
  ) async {
    if (request.method != 'GET') return Resp.notFound(null);

    final claims = await config.jwtMaker.getUserClaims(request);
    if (claims?.meta == null) {
      return Resp.forbidden(null);
    }
    final meta = UserMetaClaims.fromJson(claims!.meta!);
    final providerInstance = config.allOAuthProviders[meta.providerId];
    if (providerInstance == null) {
      return Resp.internalServerError(
        body: const AuthError(
          Translation(key: Translations.providerNotFoundKey),
        ),
      );
    }

    final session = await config.persistence.getValidSession(claims.sessionId);
    UserSessionOrPartial? partialSession =
        session == null ? null : UserSessionOrPartial(session, leftMfa: null);
    final refreshToken = session?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      // has not been logged in
      if (meta.isAuthorizationCodeFlow) {
        final result = await verifyOAuthCodeState(
          claims: claims,
          request: request,
        );
        if (result.isErr()) {
          // Error in flow
          return Resp.unauthorized(result.unwrapErr());
        } else if (result.unwrap().isNone()) {
          // no user created at the moment
          return Resp.unauthorized(null);
        }
        partialSession = result.unwrap().unwrap();
      } else if (meta.isDeviceCodeFlow) {
        // poll
        final result = await providerInstance.pollDeviceCodeToken(
          config.client,
          deviceCode: meta.deviceCode!,
        );
        if (result.isErr()) {
          return Resp.unauthorized(
            AuthError.fromOAuthResponseError(result.unwrapErr()),
          );
        }
        final token = result.unwrap();
        final sessionResult = await processOAuthToken(
          token,
          providerInstance,
          request: request,
          sessionId: claims.sessionId,
          claims: claims,
        );
        if (sessionResult.isErr()) {
          return Resp.internalServerError(body: sessionResult.unwrapErr());
        }
        partialSession = sessionResult.unwrap();
      } else {
        return Resp.badRequest(
          body: const AuthError(
            Translation(key: Translations.wrongAccessTokenKey),
          ),
        );
      }
    }
    final responseData =
        await successResponse(partialSession!, providerInstance.providerId);
    return Resp.ok(responseData);
  }

  Future<AuthResponseSuccess> successResponse(
    UserSessionOrPartial sessionOrPartial,
    String providerId,
  ) async {
    final session = sessionOrPartial.session;
    UserMetaClaims meta;
    if (session.isInMFA) {
      assert(
        sessionOrPartial.leftMfa != null &&
            sessionOrPartial.leftMfa!.isNotEmpty,
        'Partial isInMFA session with no leftMfa',
      );
      meta = UserMetaClaims.inMFA(
        mfaItems: session.mfa,
        providerId: providerId,
        userId: session.userId,
      );
    } else {
      meta = UserMetaClaims.loggedUser(
        providerId: providerId,
        userId: session.userId,
        mfaItems: session.mfa,
      );
    }
    final accessToken = config.jwtMaker.createJwt(
      userId: session.userId,
      sessionId: session.sessionId,
      duration: authSessionDuration,
      isRefreshToken: false,
      meta: meta.toJson(),
    );
    final credentialsMFAFlow = Map.fromEntries(
      await Future.wait(
        (sessionOrPartial.leftMfa ?? []).map(
          (e) async {
            final cred = await config.allCredentialsProviders[e.providerId]
                ?.mfaCredentialsFlow(e);
            return MapEntry(e, cred);
          },
        ),
      ),
    );
    return AuthResponseSuccess(
      refreshToken: session.refreshToken,
      accessToken: accessToken,
      // TODO: change for mfa?
      expiresAt: DateTime.now().add(authSessionDuration),
      leftMfaItems: sessionOrPartial.leftMfa
          ?.map((e) => MFAItemWithFlow(e, credentialsMFAFlow[e]))
          .toList(),
    );
  }

  String makeRefreshToken({
    required String userId,
    required String providerId,
    required String sessionId,
    required List<ProviderUserId> mfaItems,
  }) {
    final jwt = config.jwtMaker.createJwt(
      userId: userId,
      sessionId: sessionId,
      duration: refreshTokenDuration,
      isRefreshToken: true,
      meta: UserMetaClaims.loggedUser(
        providerId: providerId,
        userId: userId,
        mfaItems: mfaItems,
      ).toJson(),
    );
    return jwt;
  }

  FutureOr<Object> handlerWebSocketOAuthStateSubscribe(
    RequestCtx request,
    WebSocketHandler webSocketHandler,
  ) {
    final translations = config.getTranslationForLanguage(
      request.headersAll[Headers.acceptLanguage],
    );
    final handler = webSocketHandler((
      WebSocketChannel channel,
      String? subprotocol,
    ) async {
      bool didInitConnection = false;

      Future<void> _closeUnauthorized() {
        channel.sink.add(
          jsonEncodeWithTranslate(
            const AuthError(Translation(key: Translations.unauthorizedKey)),
            translations,
          ),
        );
        return channel.sink.close();
      }

      bool isClosed = false;
      await channel.stream
          .cast<String>()
          .map(jsonDecode)
          .asyncMap((Object? event) async {
        if (didInitConnection) {
          // ignore other messages
          return;
        }
        didInitConnection = true;

        if (event is! Map<String, Object?>) {
          return _closeUnauthorized();
        }
        final conn = await config.jwtMaker.initWebSocketConnection(
          request,
          WebSocketServer(
            close: channel.sink.close,
            done: channel.sink.done,
          ),
          initialPayload: event,
          isRefreshToken: false,
        );
        final claims = conn.claims;

        if (claims?.meta == null) {
          return _closeUnauthorized();
        }

        final meta = UserMetaClaims.fromJson(claims!.meta!);
        final provider = config.allOAuthProviders[meta.providerId];
        if (provider == null) {
          // TODO: maybe other error
          return _closeUnauthorized();
        }
        Future<void> sendAndClose(AuthResponse json) async {
          if (isClosed) return;
          channel.sink.add(jsonEncodeWithTranslate(json, translations));
          return channel.sink.close();
        }

        if (meta.isDeviceCodeFlow) {
          // poll
          final subs = provider
              .subscribeToDeviceCodeState(
            config.client,
            deviceCode: meta.deviceCode!,
            interval: Duration(seconds: meta.interval!),
          )
              .asyncMap(
            (event) {
              return event.when(
                err: (err) {
                  if (err.error == null ||
                      DeviceFlowError.isDeviceFlowFinished(err.error!)) {
                    return sendAndClose(
                      AuthResponse.fromError(
                        AuthError.fromOAuthResponseError(err),
                      ),
                    );
                  }
                  // not yet authenticated
                  // should we send the polling result? channel.sink.add(jsonEncode({'error': err.toString()}));
                },
                ok: (token) async {
                  final sessionResult = await processOAuthToken(
                    token,
                    provider,
                    request: request,
                    sessionId: claims.sessionId,
                    claims: claims,
                  );

                  return sessionResult.when(
                    err: (err) {
                      return sendAndClose(AuthResponse.fromError(err));
                    },
                    ok: (session) async {
                      final responseData =
                          await successResponse(session, provider.providerId);
                      return sendAndClose(
                        AuthResponse.fromSuccess(responseData),
                      );
                    },
                  );
                },
              );
            },
          ).listen((_) {});
          try {
            await channel.sink.done;
          } finally {
            await subs.cancel();
          }
        } else if (meta.isAuthorizationCodeFlow) {
          // fetch persisted state
          final startTime = DateTime.now();
          const duration = Duration(seconds: 1);
          Future<void> timerCallback() async {
            final session =
                await config.persistence.getValidSession(claims.sessionId);
            if (channel.closeCode != null || isClosed) {
              return;
            }
            // TODO: maybe save partial sessions?
            if (session != null && !session.isInMFA) {
              final responseData = await successResponse(
                UserSessionOrPartial(session, leftMfa: null),
                provider.providerId,
              );
              return sendAndClose(AuthResponse.fromSuccess(responseData));
            } else if (DateTime.now().difference(startTime) >
                authSessionDuration) {
              return sendAndClose(
                AuthResponse.fromError(
                  const AuthError(Translation(key: Translations.timeoutKey)),
                ),
              );
            } else {
              final result = await verifyOAuthCodeState(
                claims: claims,
                request: request,
              );
              if (result.isErr()) {
                return sendAndClose(AuthResponse.fromError(result.unwrapErr()));
              } else if (result.unwrap().isSome()) {
                final responseData = await successResponse(
                  result.unwrap().unwrap(),
                  provider.providerId,
                );
                return sendAndClose(AuthResponse.fromSuccess(responseData));
              }
              Timer(duration, timerCallback);
            }
          }

          Timer(duration, timerCallback);
        } else {
          return _closeUnauthorized();
        }
      }).last;
      isClosed = true;
    });
    return handler(request);
  }

  Future<UserClaims> authenticatedUserOrThrow(RequestCtx request) async {
    final claims = await config.jwtMaker.getUserClaims(request);
    if (claims == null ||
        claims.meta == null ||
        !UserMetaClaims.fromJson(claims.meta!).isLoggedIn) {
      throw Resp<SerializableToJson, SerializableToJson>.unauthorized(null);
    }
    return claims;
  }

  Future<Resp> revokeAuthToken(RequestCtx request) async {
    if (request.method != 'POST') return Resp.notFound(null);
    final claims = await authenticatedUserOrThrow(request);

    final session = await config.persistence.getValidSession(claims.sessionId);
    if (session == null) return Resp.ok(null);
    await config.persistence.saveSession(
      session.copyWith(endedAt: DateTime.now()),
    );
    // TODO: revoke provider token
    return Resp.ok(null);
  }

  Future<Resp<UserInfoMe, SerializableToJson>> getUserMeInfo(
    RequestCtx request,
  ) async {
    if (request.method != 'GET') return Resp.notFound(null);
    final claims = await authenticatedUserOrThrow(request);
    final fields = request.url.queryParametersAll['fields'] ?? [];

    final user = await config.persistence
        .getUserById(UserId(claims.userId, UserIdKind.innerId));
    if (user == null) return Resp.notFound(null);

    List<UserSession>? sessions;
    if (fields.contains('sessions')) {
      sessions = await config.persistence
          .getUserSessions(user.userId, onlyValid: false);
    }

    return Resp.ok(
      UserInfoMe.fromComplete(
        user,
        config.allProviders,
        sessions: sessions?.map(UserSessionBase.fromSession).toList(),
      ),
    );
  }

  Future<Result<T, Resp>> _parseBody<T extends Object>(
    RequestCtx request,
    T Function(Map<String, Object?>) fromBody,
  ) async {
    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return Err(_badRequestExpectedObject());
    final T query;
    try {
      query = fromBody(data);
    } catch (_) {
      return Err(_badRequestExpectedObject());
    }

    return Ok(query);
  }

  Future<Resp<UsersInfo, SerializableToJson>> getUsersInfoForAdmin(
    RequestCtx request,
  ) async {
    if (request.method != 'GET') return Resp.notFound(null);
    // TODO: check is admin
    final claims = await authenticatedUserOrThrow(request);
    final query =
        (await _parseBody(request, UsersInfoQuery.fromJson)).throwErr();

    // final fields = request.url.queryParametersAll['fields'] ?? [];

    final allIds =
        query.ids.followedBy(query.queries.map(UserId.fromString)).toList();
    final List<AppUserComplete?> users =
        await config.persistence.getUsersById(allIds);

    final values = Map.fromEntries(
      users.whereType<AppUserComplete>().map((e) => MapEntry(e.userId, e)),
    ).values.toList();

    // TODO: add sessions to getUsersById && fields.contains('sessions') &&
    List<UserSession>? sessions;
    if (values.length == 1) {
      sessions = await config.persistence
          .getUserSessions(values.first.userId, onlyValid: false);
    }

    return Resp.ok(
      UsersInfo(
        values.map(
          (e) {
            return UserInfoMe.fromComplete(
              e,
              config.allProviders,
              sessions: sessions?.map(UserSessionBase.fromSession).toList(),
            );
          },
        ).toList(),
      ),
    );
  }

  Future<Resp<SerializableToJson, AuthError>> userSignOutSessions(
    RequestCtx request,
  ) async {
    if (request.method != 'POST') return Resp.notFound(null);
    final claims = await authenticatedUserOrThrow(request);
    final data = (await _parseBody(request, UserSignOutSessionsQuery.fromJson))
        .throwErr();
    final sessionIds = data.sessionIds ?? [];

    if (!data.signOutAll && sessionIds.isEmpty) {
      return Resp.badRequest(
        body: const AuthError(
          Translation(key: Translations.sessionIdsIsRequiredKey),
        ),
      );
    }
    final currentSessions = await config.persistence.getUserSessions(
      claims.userId,
      onlyValid: true,
    );

    final List<UserSession> sessionToSignOut;
    if (data.signOutAll) {
      sessionToSignOut = currentSessions;
    } else {
      final validSessionIds = currentSessions.map((e) => e.sessionId).toSet();
      final invalidSession =
          sessionIds.indexWhere((id) => !validSessionIds.contains(id));
      if (invalidSession != -1) {
        return Resp.badRequest(
          body: AuthError(
            Translation(
              key: Translations.invalidSessionIdKey,
              args: {'sessionId': sessionIds[invalidSession]},
            ),
          ),
        );
      }
      sessionToSignOut = currentSessions
          .where((session) => sessionIds.contains(session.sessionId))
          .toList();
    }

    await Future.wait(
      sessionToSignOut.map(
        (session) => config.persistence.saveSession(
          session.copyWith(refreshTokenToNull: true, endedAt: DateTime.now()),
        ),
      ),
    );

    return Resp.ok(null);
  }

  Future<Resp<UserInfoMe, AuthError>> userMFA(RequestCtx request) async {
    if (request.method != 'POST') return Resp.notFound(null);
    final claims = await authenticatedUserOrThrow(request);
    // TODO: limit claims authentication time
    final user = await config.persistence
        .getUserById(UserId(claims.userId, UserIdKind.innerId));
    if (user == null) return Resp.notFound(null);

    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return _badRequestExpectedObject();
    final mfa = MFAConfig.fromJson(data['mfa']! as Map<String, Object?>);

    final notFoundMethods = mfa.requiredItems
        .followedBy(mfa.optionalItems)
        .where((e) => !user.userIds().contains(e.userId))
        .toList();

    if (notFoundMethods.isNotEmpty) {
      return Resp.badRequest(
        body: AuthError(
          Translation(
            key: Translations.notFoundMethodsKey,
            args: {
              'notFoundMethods': notFoundMethods.map((e) => e.toJson()).toList()
            },
          ),
        ),
      );
    }
    final validationErrors = mfa.validationErrors;
    if (validationErrors.isNotEmpty) {
      return Resp.badRequest(
        body: AuthError(
          validationErrors.first.translation,
          otherErrors: validationErrors.length == 1
              ? null
              : ([...validationErrors]..removeAt(1))
                  .map((e) => e.translation)
                  .toList(),
        ),
      );
    }

    final newUser = user.user.copyWith(multiFactorAuth: mfa);
    await config.persistence.updateUser(newUser);

    final fields = request.url.queryParametersAll['fields'] ?? [];
    List<UserSession>? sessions;
    if (fields.contains('sessions')) {
      sessions = await config.persistence
          .getUserSessions(user.userId, onlyValid: false);
    }

    return Resp.ok(
      UserInfoMe.fromComplete(
        AppUserComplete(user: newUser, authUsers: user.authUsers),
        config.allProviders,
        sessions: sessions?.map(UserSessionBase.fromSession).toList(),
      ),
    );
  }

  Future<Resp<UserInfoMe, AuthError>> authenticationProviderDelete(
    RequestCtx request,
  ) async {
    if (request.method != 'DELETE') return Resp.notFound(null);
    final providerInstance = config.allProviders[_getProviderId(request)];
    if (providerInstance == null) return _wrongProviderResponse();

    final claims = await authenticatedUserOrThrow(request);
    // TODO: limit claims authentication time
    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return _badRequestExpectedObject();

    final providerUserId = data['providerUserId'];
    if (providerUserId is! String) {
      return Resp.badRequest(
        body: const AuthError(
          Translation(key: Translations.providerUserIdIsRequiredKey),
        ),
      );
    }
    final mfaItem = ProviderUserId(
      providerId: providerInstance.providerId,
      providerUserId: providerUserId,
    );
    final user = await config.persistence
        .getUserById(UserId(claims.userId, UserIdKind.innerId));

    final authUserIndex = user?.authUsers.indexWhere(
      (e) =>
          e.providerUserId == providerUserId &&
          e.providerId == providerInstance.providerId,
    );
    if (user == null) {
      return Resp.internalServerError();
    } else if (authUserIndex == -1) {
      // No account found
      return Resp.badRequest(
        body: const AuthError(
          Translation(key: Translations.authProviderNotFoundToDeleteKey),
        ),
      );
    } else if (user.authUsers.length == 1) {
      // Can't delete the only provider
      return Resp.badRequest(
        body: const AuthError(
          Translation(key: Translations.canNotDeleteOnlyProviderKey),
        ),
      );
    } else if (user.user.multiFactorAuth.kind(mfaItem) !=
        MFAProviderKind.none) {
      // Can't delete a provider in MFA
      return Resp.badRequest(
        body: const AuthError(
          Translation(key: Translations.canNotDeleteMFAProviderKey),
        ),
      );
    }

    final authUser = user.authUsers[authUserIndex!];
    await config.persistence.deleteAuthUser(
      user.userId,
      authUser,
    );

    return Resp.ok(
      UserInfoMe.fromComplete(
        AppUserComplete(
          user: user.user,
          authUsers: [...user.authUsers]..removeAt(authUserIndex),
        ),
        config.allProviders,
      ),
    );
  }

  Future<Resp<UserMeOrResponse, AuthError>> credentialsUpdate(
    RequestCtx request,
  ) async {
    if (request.method != 'PUT') return Resp.notFound(null);
    final providerInstance = getCredentialsProvider(request).throwErr();
    return _credentialsUpdate(request, providerInstance);
  }

  // TODO: proper type SerializableToJson UserMeOrResponse
  Future<Resp<UserMeOrResponse, AuthError>>
      _credentialsUpdate<C extends CredentialsData, U>(
    RequestCtx request,
    CredentialsProvider<C, U> providerInstance,
  ) async {
    final claims = await config.jwtMaker.getUserClaims(request);
    final claimsMeta =
        claims?.meta == null ? null : UserMetaClaims.fromJson(claims!.meta!);
    if (claims == null || claimsMeta == null || !claimsMeta.isLoggedIn) {
      // TODO: limit claims authentication time
      return Resp.unauthorized(null);
    }
    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return _badRequestExpectedObject();

    final providerUserId = data['providerUserId'];
    if (providerUserId is! String) {
      return Resp.badRequest(
        body: const AuthError(
          Translation(key: Translations.providerUserIdIsRequiredKey),
        ),
      );
    }
    final credentialsResult = providerInstance.parseCredentials(data);
    if (credentialsResult.isErr()) {
      return Resp.badRequest(
        body: AuthError(
          const Translation(key: Translations.fieldErrorsKey),
          fieldErrors: credentialsResult.unwrapErr(),
        ),
      );
    }

    final credentials = credentialsResult.unwrap();
    if (providerUserId != credentials.providerUserId &&
        credentials.providerUserId != null) {
      final newUser = await config.persistence.getUserById(
        UserId(
          '${providerInstance.providerId}:${credentials.providerUserId}',
          UserIdKind.providerId,
        ),
      );
      if (newUser != null) {
        return Resp.badRequest(
          body: const AuthError(
            Translation(key: Translations.duplicateUserKey),
          ),
        );
      }
    }
    final userId = UserId(
      '${providerInstance.providerId}:${providerUserId}',
      UserIdKind.providerId,
    );
    final foundUser = await config.persistence.getUserById(userId);
    if (foundUser == null) {
      return Resp.badRequest(
        body: const AuthError(Translation(key: Translations.userNotFoundKey)),
      );
    } else if (foundUser.userId != claims.userId) {
      return Resp.unauthorized(
        const AuthError(Translation(key: Translations.userNotFoundKey)),
      );
    }
    final previousUser =
        foundUser.authUsers.firstWhere((u) => u.userIds().contains(userId));
    final validation = await providerInstance.updateCredentials(
      previousUser.providerUser as U,
      credentials,
    );

    if (validation.isErr()) {
      return Resp.unauthorized(validation.unwrapErr());
    }
    final response = validation.unwrap();
    if (response.flow != null) {
      return Resp.ok(
        UserMeOrResponse.response(
          AuthResponse(
            error: null,
            success: null,
            // TODO: maybe improve this?
            credentials: response.flow!,
          ),
        ),
      );
    }

    // TODO: transaction
    if (response.user!.key != previousUser.key) {
      // delete previous user
      // TODO: should we use a different generated primary key instead of providerId-providerUserId?
      //  We would not need to delete, just make the update
      await config.persistence.deleteAuthUser(
        claims.userId,
        previousUser,
      );
    }
    // update user
    final userComplete = await config.persistence.saveUser(
      claims.userId,
      response.user!,
    );

    return Resp.ok(
      UserMeOrResponse.user(
        UserInfoMe.fromComplete(
          userComplete,
          config.allProviders,
        ),
      ),
    );
  }

  Future<Resp<SerializableToJson, AuthError>> credentialsSignIn(
    RequestCtx request, {
    required bool signUp,
  }) async {
    if (request.method != 'POST') return Resp.notFound(null);
    final providerInstance = getCredentialsProvider(request).throwErr();
    return _credentialsSignIn(request, providerInstance, signUp: signUp);
  }

  // TODO: change SerializableToJson
  Future<Resp<SerializableToJson, AuthError>>
      _credentialsSignIn<C extends CredentialsData, U>(
    RequestCtx request,
    CredentialsProvider<C, U> providerInstance, {
    required bool signUp,
  }) async {
    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return _badRequestExpectedObject();

    final credentialsResult = providerInstance.parseCredentials(data);
    if (credentialsResult.isErr()) {
      return Resp.badRequest(
        body: AuthError(
          const Translation(key: Translations.fieldErrorsKey),
          fieldErrors: credentialsResult.unwrapErr(),
        ),
      );
    }

    final claims = await config.jwtMaker.getUserClaims(request);
    UserSession? mfaSession;
    if (claims != null) {
      mfaSession = await config.persistence.getAnySession(claims.sessionId);
      if (mfaSession != null && !mfaSession.isValid) {
        return Resp.unauthorized(
          const AuthError(Translation(key: Translations.sessionExpiredKey)),
        );
      }
      if (mfaSession != null && !mfaSession.isInMFA) {
        mfaSession = null;
      }
    }

    if (claims != null) {
      final metaClaims = UserMetaClaims.fromJson(claims.meta!);
      if (metaClaims.isInMFAFlow &&
          (data['providerUserId'] is! String || signUp)) {
        return Resp.badRequest(
          body: AuthError(
            signUp
                ? const Translation(key: Translations.canNotSignUpInMFAFlowKey)
                : const Translation(key: Translations.wrongParametersForMFAKey),
          ),
        );
      }
    }

    final credentials = credentialsResult.unwrap();
    final providerUserId = credentials.providerUserId ?? data['providerUserId'];
    // TODO: multiple credentials email and phone
    final userId = UserId(
      '${providerInstance.providerId}:${providerUserId}',
      UserIdKind.providerId,
    );
    final foundUser = providerUserId == null
        ? null
        : await config.persistence.getUserById(userId);
    if (foundUser != null) {
      final user =
          foundUser.authUsers.firstWhere((u) => u.userIds().contains(userId));
      final validation = await providerInstance.verifyCredentials(
        user.providerUser as U,
        credentials,
      );

      if (validation.isErr()) {
        return Resp.unauthorized(validation.unwrapErr());
      }
      final response = validation.unwrap();
      if (response.isSome()) {
        final otherUser = response.unwrap().user;
        if (otherUser == null) {
          return Resp.ok(response.unwrap().flow!);
        }
        if (otherUser.key != user.key) {
          return Resp.internalServerError(
            body: const AuthError(
              Translation(key: Translations.errorMergingUsersKey),
            ),
          );
        }
      }
      // TODO: maybe merge with the current session?
      final sessionResponse = await onUserAuthenticatedResponse(
        user,
        request: request,
        // TODO: check sessionId
        sessionId: mfaSession?.sessionId ?? generateStateToken(),
        mfaSession: mfaSession,
        claims: claims,
      );
      return sessionResponse;
    } else if (!signUp) {
      return Resp.badRequest(
        body: const AuthError(
          Translation(key: Translations.credentialsNotFoundKey),
        ),
      );
    }

    final userResult = await providerInstance.getUser(credentials);
    if (userResult.isErr()) {
      return Resp.badRequest(body: userResult.unwrapErr());
    }

    final userOrMessage = userResult.unwrap();
    if (userOrMessage.user == null) {
      // The flow keeps going
      return Resp.ok(userOrMessage.flow!);
    } else {
      // TODO: maybe merge with the current session?
      final sessionResponse = await onUserAuthenticatedResponse(
        userOrMessage.user!,
        request: request,
        // TODO: check sessionId
        sessionId: mfaSession?.sessionId ?? generateStateToken(),
        mfaSession: mfaSession,
        claims: claims,
      );
      return sessionResponse;
    }
  }

  Future<Resp<AuthResponseSuccess, AuthError>> onUserAuthenticatedResponse(
    AuthUser<Object?> user, {
    required RequestCtx request,
    required String sessionId,
    required UserSession? mfaSession,
    required UserClaims? claims,
  }) async {
    final sessionResult = await onUserAuthenticated(
      user,
      request: request,
      sessionId: sessionId,
      mfaSession: mfaSession,
      claims: claims,
    );

    if (sessionResult.isErr()) {
      return Resp.internalServerError(body: sessionResult.unwrapErr());
    }
    final responseData =
        await successResponse(sessionResult.unwrap(), user.providerId);
    return Resp.ok(responseData);
  }
}

class UserMetaClaims implements SerializableToJson {
  final String providerId;
  final String? userId;
  final String? deviceCode;
  final int? interval;
  final String? state;
  final List<ProviderUserId>? mfaItems;
  final bool isInMFAFlow;

  UserMetaClaims.loggedUser({
    required this.providerId,
    required String this.userId,
    required List<ProviderUserId> this.mfaItems,
  })  : state = null,
        deviceCode = null,
        interval = null,
        isInMFAFlow = false;

  UserMetaClaims.inMFA({
    required this.providerId,
    required String this.userId,
    required List<ProviderUserId> this.mfaItems,
  })  : state = null,
        deviceCode = null,
        interval = null,
        isInMFAFlow = true;

  UserMetaClaims.deviceCode({
    required this.providerId,
    required String this.deviceCode,
    required int this.interval,
    required this.mfaItems,
  })  : state = null,
        userId = null,
        isInMFAFlow = false;

  UserMetaClaims.authorizationCode({
    required this.providerId,
    required String this.state,
    required this.mfaItems,
  })  : deviceCode = null,
        interval = null,
        userId = null,
        isInMFAFlow = false;

  bool get isDeviceCodeFlow => deviceCode != null;
  bool get isAuthorizationCodeFlow => state != null;
  bool get isLoggedIn => !isInMFAFlow && userId != null;

  factory UserMetaClaims.fromJson(Map<String, Object?> json) {
    final mfaItems = json['mfaItems'] == null
        ? null
        : (json['mfaItems']! as List)
            .cast<Map<String, Object?>>()
            .map(ProviderUserId.fromJson)
            .toList();

    if (json['deviceCode'] is String) {
      return UserMetaClaims.deviceCode(
        providerId: json['providerId']! as String,
        deviceCode: json['deviceCode']! as String,
        interval: json['interval']! as int,
        mfaItems: mfaItems,
      );
    } else if (json['state'] is String) {
      return UserMetaClaims.authorizationCode(
        providerId: json['providerId']! as String,
        state: json['state']! as String,
        mfaItems: mfaItems,
      );
    } else if (json['isInMFAFlow'] == true) {
      return UserMetaClaims.inMFA(
        mfaItems: mfaItems!,
        providerId: json['providerId']! as String,
        userId: json['userId']! as String,
      );
    } else if (json['userId'] is String) {
      return UserMetaClaims.loggedUser(
        providerId: json['providerId']! as String,
        userId: json['userId']! as String,
        mfaItems: mfaItems!,
      );
    } else {
      throw Exception('$json');
    }
  }

  Map<String, Object?> toJson() {
    return {
      'isInMFAFlow': isInMFAFlow,
      'providerId': providerId,
      'deviceCode': deviceCode,
      'interval': interval,
      'state': state,
      'userId': userId,
      'mfaItems': mfaItems,
    }..removeWhere((key, value) => value == null);
  }
}

Future<Object?> parseBodyOrUrlData(RequestCtx request) async {
  if (request.method == 'HEAD' ||
      request.method == 'GET' ||
      request.method == 'OPTIONS') {
    var params = request.url.queryParametersAll;
    try {
      if (params.isEmpty && request.url.fragment.isNotEmpty) {
        params = Uri(query: request.url.fragment).queryParametersAll;
      }
    } catch (_) {}
    return params.map(
      (key, value) =>
          value.length == 1 ? MapEntry(key, value.first) : MapEntry(key, value),
    );
  } else {
    final data = await request.readAsString();
    if (request.mimeType == Headers.appFormUrlEncoded) {
      return Uri.splitQueryString(data);
    }
    if (data.isEmpty) return null;
    // application/vnd.github+json
    return jsonDecode(data);
  }
}
