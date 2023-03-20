import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:oauth/endpoint_models.dart';
import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf.dart' show Request;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'main.dart';
import 'shelf_helpers.dart';

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

class Response<O extends SerializableToJson, E extends SerializableToJson> {
  final int statusCode;
  final O? ok;
  final E? err;

  ///
  const Response(
    this.statusCode, {
    required this.ok,
    required this.err,
  });

  /// ok: 200
  factory Response.ok(O? body) => Response(
        200,
        ok: body,
        err: null,
      );

  /// badRequest: 400
  factory Response.badRequest({required E? body}) => Response(
        400,
        err: body,
        ok: null,
      );

  /// unauthorized: 401
  factory Response.unauthorized(E? err) => Response(
        401,
        err: err,
        ok: null,
      );

  /// forbidden: 403
  factory Response.forbidden(E? err) => Response(
        403,
        err: err,
        ok: null,
      );

  /// notFound: 404
  factory Response.notFound(E? err) => Response(
        404,
        err: err,
        ok: null,
      );

  /// internalServerError: 500
  factory Response.internalServerError({E? body}) => Response(
        500,
        err: body,
        ok: null,
      );

  shelf.Response toShelf(Translations translations) {
    final body = ok ?? err;
    return shelf.Response(
      statusCode,
      body: body == null ? null : jsonEncodeWithTranslate(body, translations),
      headers: body == null ? null : jsonHeader,
    );
  }
}

shelf.Handler makeHandler(Config config) {
  final handler = AuthHandler(config);
  const pIdRegExp = '/?([a-zA-Z_-]+)?';

  Future<shelf.Response> handleRequest(Request request) async {
    final path = request.url.path;

    Response<SerializableToJson, SerializableToJson>? response;

    if (path == '') {
      if (request.method != 'GET') return shelf.Response.notFound(null);
      return shelf.Response.ok('<html><body></body></html>');
      // TODO: use only '/providers' and add DELETE (authenticationProviderDelete) to this route
    } else if (path == 'oauth/providers') {
      if (request.method != 'GET') return shelf.Response.notFound(null);
      response = Response.ok(
        AuthProvidersData(
          config.allProviders.values
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
    } else if (RegExp('oauth/subscribe').hasMatch(path)) {
      final shelfResponse =
          await handler.handlerWebSocketOAuthStateSubscribe(request);
      return shelfResponse;
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
    }
    if (response != null) {
      final translations = config.getTranslationForLanguage(
        request.headersAll[Headers.acceptLanguage],
      );
      return response.toShelf(translations);
    }
    return shelf.Response.notFound(
      '${request.method} Request for "${request.url}"',
    );
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

  Response<O, AuthResponse>
      wrongProviderResponse<O extends SerializableToJson>() {
    final providers = config.allProviders.keys
        .followedBy(config.allCredentialsProviders.keys)
        .join('", "');
    return Response.badRequest(
      body: AuthResponse.error(
        'provider query parameter must be one of "${providers}"',
      ),
    );
  }

  static Response<O, E> badRequestExpectedObjectPayload<
          O extends SerializableToJson, E extends SerializableToJson>() =>
      Response.badRequest(body: null);

  String? getProviderId(Request request) {
    return request.url.queryParameters['providerId'] ??
        (request.url.pathSegments.isNotEmpty
            ? request.url.pathSegments.last
            : null);
  }

  Result<OAuthProvider, Response> getProvider(Request request) {
    final providerId = getProviderId(request);
    final providerInstance = config.allProviders[providerId];
    if (providerInstance == null) {
      return Err(wrongProviderResponse());
    }
    return Ok(providerInstance);
  }

  Result<CredentialsProvider, Response> getCredentialsProvider(
    Request request,
  ) {
    final providerId = getProviderId(request);
    final providerInstance = config.allCredentialsProviders[providerId];
    if (providerInstance == null) {
      return Err(wrongProviderResponse());
    }
    return Ok(providerInstance);
  }

  Future<Response<AuthResponse, SerializableToJson>> refreshAuthToken(
    Request request,
  ) async {
    if (request.method != 'POST') return Response.notFound(null);

    final claims = await config.jwtMaker.getUserClaims(
      ctx(request),
      isRefreshToken: true,
    );
    if (claims == null) return Response.unauthorized(null);

    final session = await config.persistence.getValidSession(claims.sessionId);
    if (session == null) return Response.unauthorized(null);

    final jwt = config.jwtMaker.createJwt(
      userId: claims.userId,
      sessionId: claims.sessionId,
      duration: accessTokenDuration,
      isRefreshToken: false,
      meta: claims.meta,
    );
    return Response.ok(
      AuthResponse.success(
        accessToken: jwt,
        expiresAt: DateTime.now().add(accessTokenDuration),
        refreshToken: null,
      ),
    );
  }

  Future<Response> handleOAuthCallback(Request request) async {
    if (request.method != 'GET' && request.method != 'POST') {
      return Response.notFound(null);
    }
    final providerInstance = getProvider(request).throwErr();

    final body = (await parseBodyOrUrlData(request))! as Map<String, Object?>;
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
            return Response.ok(null);
          case AuthResponseErrorKind.noState:
          case AuthResponseErrorKind.noCode:
          case AuthResponseErrorKind.notFoundState:
          case AuthResponseErrorKind.invalidState:
            return Response.badRequest(
              body: AuthResponse.error(err.kind.name),
            );
          case AuthResponseErrorKind.tokenResponseError:
            return Response.internalServerError(
              body: AuthResponse.error(err.kind.name),
            );
        }
      },
      ok: (token) async {
        await _addMetadataToOAuthModelState(
          token.stateModel!.state,
          token.stateModel!,
          OAuthCodeStateMeta(token: token),
        );
        return Response.ok(null);
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

  Future<Result<UserSessionOrPartial, GetUserError>> processOAuthToken<U>(
    TokenResponse token,
    OAuthProvider<U> providerInstance, {
    required String sessionId,
    required UserClaims? claims,
  }) async {
    // TODO: make transaction
    final session = await config.persistence.getAnySession(sessionId);
    if (session != null) {
      if (!session.isValid) {
        return Err(
          GetUserError(
            token: token,
            response: null,
            message: 'Session revoked',
          ),
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

    return result.andThenAsync(
      (user) => onUserAuthenticated(
        user,
        sessionId: sessionId,
        mfaSession: session,
        claims: claims,
      ).mapErr(
        (message) => GetUserError(
          token: token,
          response: null,
          message: message,
        ),
      ),
    );
  }

  Future<Result<UserSessionOrPartial, String>> onUserAuthenticated(
    AuthUser<Object?> user, {
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
      return const Err('Multiple users with same credentials');
    }

    final hasLeftMFA = leftMfa != null && leftMfa.isNotEmpty;
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
    );
    // TODO: should we save the session for MFA? Maybe just use access token claims? OAuth relies on sessions
    if (!hasLeftMFA) {
      await config.persistence.saveSession(userSession);
    }

    return Ok(UserSessionOrPartial(userSession, leftMfa: leftMfa));
  }

  Future<Response<OAuthProviderUrl, AuthResponse>> getOAuthUrl(
    Request request,
  ) async {
    if (request.method != 'GET') return Response.notFound(null);
    final providerInstance = getProvider(request).throwErr();
    final isImplicit = request.url.queryParameters['flowType'] == 'implicit';
    if (isImplicit &&
        !providerInstance.supportedFlows.contains(GrantType.tokenImplicit)) {
      return Response.badRequest(
        body: AuthResponse.error(
          'Provider ${providerInstance.providerId} '
          'does not support implicit flow.',
        ),
      );
    }

    final claims = await config.jwtMaker.getUserClaims(ctx(request));
    final claimsMeta =
        claims == null ? null : UserMetaClaims.fromJson(claims.meta!);
    final flow =
        OAuthFlow(providerInstance, config.persistence, client: config.client);
    final state = generateStateToken();
    // TODO: use same session from claims? should we save the loggedin status in the state instead of session
    final sessionId = generateStateToken();
    final url = await flow.getAuthorizeUri(
      redirectUri:
          '${config.baseRedirectUri}/oauth/callback/${providerInstance.providerId}',
      // TODO: other params
      loginHint: request.url.queryParameters['loginHint'],
      state: state,
      sessionId: sessionId,
      responseType:
          isImplicit ? OAuthResponseType.token : OAuthResponseType.code,
      meta: claims == null ? null : OAuthCodeStateMeta(claims: claims).toJson(),
    );
    final jwt = config.jwtMaker.createJwt(
      // TODO: maybe anonymous users?
      userId: claims?.userId ?? generateStateToken(),
      sessionId: sessionId,
      duration: authSessionDuration,
      isRefreshToken: false,
      meta: UserMetaClaims.authorizationCode(
        providerId: providerInstance.providerId,
        state: state,
        mfaItems: claimsMeta?.mfaItems,
      ).toJson(),
    );
    return Response.ok(OAuthProviderUrl(url: url.toString(), accessToken: jwt));
  }

  Future<Response<OAuthProviderDevice, AuthResponse>> getOAuthDeviceCode(
    Request request,
  ) async {
    if (request.method != 'GET') return Response.notFound(null);
    final providerInstance = getProvider(request).throwErr();

    final deviceCode = await providerInstance.getDeviceCode(
      config.client,
      // TODO: when do we need to send the redirectUri? here or in polling?
      redirectUri: config.baseRedirectUri,
    );
    if (deviceCode == null) {
      // The provider does not support it
      return Response.badRequest(
        body: AuthResponse.error(
          'Provider ${providerInstance.providerId} '
          'does not support device code flow.',
        ),
      );
    }
    final claims = await config.jwtMaker.getUserClaims(ctx(request));
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
    return Response.ok(
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

  // TODO: make the error an enum or translation
  Future<Result<Option<UserSessionOrPartial>, String>> verifyOAuthCodeState({
    required UserClaims claims,
  }) async {
    final claimsMeta = UserMetaClaims.fromJson(claims.meta!);
    final state = claimsMeta.state;
    if (state == null) {
      return Err(AuthResponseErrorKind.notFoundState.name);
    }
    final stateData = await config.persistence.getState(state);
    if (stateData == null) {
      return Err(AuthResponseErrorKind.notFoundState.name);
    }
    final meta = OAuthCodeStateMeta.fromJson(stateData.meta!);
    if (meta.claims?.userId != claims.userId) {
      return Err(AuthResponseErrorKind.invalidState.name);
    }
    if (meta.error != null) {
      return Err(meta.error!.kind.name);
    } else if (meta.getUserError != null) {
      return Err(meta.getUserError!);
    } else if (meta.token == null) {
      return const Ok(None());
    } else {
      final providerInstance = config.allProviders[claimsMeta.providerId]!;
      final result = await processOAuthToken(
        meta.token!,
        providerInstance,
        sessionId: claims.sessionId,
        claims: claims,
      );
      if (result.isErr()) {
        final error = result.unwrapErr();
        final getUserError =
            error.message ?? 'Error retrieving user information';
        await _addMetadataToOAuthModelState(
          state,
          stateData,
          OAuthCodeStateMeta(getUserError: getUserError),
        );
        return Err(getUserError);
      } else {
        return Ok(Some(result.unwrap()));
      }
    }
  }

  Future<Response<AuthResponse, AuthResponse>> getOAuthState(
    Request request,
  ) async {
    if (request.method != 'GET') return Response.notFound(null);

    final claims = await config.jwtMaker.getUserClaims(ctx(request));
    if (claims?.meta == null) {
      return Response.forbidden(null);
    }
    final meta = UserMetaClaims.fromJson(claims!.meta!);
    final providerInstance = config.allProviders[meta.providerId];
    if (providerInstance == null) {
      return Response.internalServerError(
        body: AuthResponse.error('Provider not found'),
      );
    }

    final session = await config.persistence.getValidSession(claims.sessionId);
    UserSessionOrPartial? partialSession =
        session == null ? null : UserSessionOrPartial(session, leftMfa: null);
    final refreshToken = session?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      // has not been logged in
      if (meta.isAuthorizationCodeFlow) {
        final result = await verifyOAuthCodeState(claims: claims);
        if (result.isErr()) {
          // Error in flow
          return Response.unauthorized(
            // TODO: make it an enum or translation
            AuthResponse.error(result.unwrapErr()),
          );
        } else if (result.unwrap().isNone()) {
          // no user created at the moment
          return Response.unauthorized(null);
        }
        partialSession = result.unwrap().unwrap();
        return Response.unauthorized(null);
      } else if (meta.isDeviceCodeFlow) {
        // poll
        final result = await providerInstance.pollDeviceCodeToken(
          config.client,
          deviceCode: meta.deviceCode!,
        );
        if (result.isErr()) {
          return Response.unauthorized(
            AuthResponse.error(
              // TODO: should we send it to the user?
              OAuthErrorResponse.errorUserMessage(result.unwrapErr()) ??
                  'Error polling device code authentication status.',
            ),
          );
        }
        final token = result.unwrap();
        final sessionResult = await processOAuthToken(
          token,
          providerInstance,
          sessionId: claims.sessionId,
          claims: claims,
        );
        if (sessionResult.isErr()) {
          return Response.internalServerError(
            body: AuthResponse.error(
              sessionResult.unwrapErr().message ??
                  'Error retrieving user information.',
            ),
          );
        }
        partialSession = sessionResult.unwrap();
      } else {
        return Response.badRequest(
          body: AuthResponse.error('Wrong access token'),
        );
      }
    }
    final responseData =
        await successResponse(partialSession!, providerInstance.providerId);
    return Response.ok(responseData);
  }

  Future<AuthResponse> successResponse(
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
    return AuthResponse.success(
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
    required List<ProviderUserId>? mfaItems,
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

  FutureOr<shelf.Response> handlerWebSocketOAuthStateSubscribe(
    Request request,
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
            AuthResponse.error('Unauthorized'),
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
          ctx(request),
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
        final provider = config.allProviders[meta.providerId];
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
                    return sendAndClose(AuthResponse.error(err.toString()));
                  }
                  // not yet authenticated
                  // should we send the polling result? channel.sink.add(jsonEncode({'error': err.toString()}));
                },
                ok: (token) async {
                  final sessionResult = await processOAuthToken(
                    token,
                    provider,
                    sessionId: claims.sessionId,
                    claims: claims,
                  );

                  return sessionResult.when(
                    // TODO: make a better error
                    err: (err) =>
                        sendAndClose(AuthResponse.error(err.toString())),
                    ok: (session) async {
                      final responseData =
                          await successResponse(session, provider.providerId);
                      return sendAndClose(responseData);
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
              return sendAndClose(responseData);
            } else if (DateTime.now().difference(startTime) >
                authSessionDuration) {
              return sendAndClose(AuthResponse.error('timeout'));
            } else {
              final result = await verifyOAuthCodeState(claims: claims);
              if (result.isErr()) {
                return sendAndClose(AuthResponse.error(result.unwrapErr()));
              } else if (result.unwrap().isSome()) {
                final responseData = await successResponse(
                  result.unwrap().unwrap(),
                  provider.providerId,
                );
                return sendAndClose(responseData);
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

  Future<UserClaims> authenticatedUserOrThrow(Request request) async {
    final claims = await config.jwtMaker.getUserClaims(ctx(request));
    if (claims == null ||
        claims.meta == null ||
        !UserMetaClaims.fromJson(claims.meta!).isLoggedIn) {
      throw Response<SerializableToJson, SerializableToJson>.unauthorized(null);
    }
    return claims;
  }

  Future<Response> revokeAuthToken(Request request) async {
    if (request.method != 'POST') return Response.notFound(null);
    final claims = await authenticatedUserOrThrow(request);

    final session = await config.persistence.getValidSession(claims.sessionId);
    if (session == null) return Response.ok(null);
    await config.persistence.saveSession(
      session.copyWith(endedAt: DateTime.now()),
    );
    // TODO: revoke provider token
    return Response.ok(null);
  }

  Future<Response<UserInfoMe, SerializableToJson>> getUserMeInfo(
    Request request,
  ) async {
    if (request.method != 'GET') return Response.notFound(null);
    final claims = await authenticatedUserOrThrow(request);
    final fields = request.url.queryParametersAll['fields'] ?? [];

    final user = await config.persistence
        .getUserById(UserId(claims.userId, UserIdKind.innerId));
    if (user == null) return Response.notFound(null);

    List<UserSession>? sessions;
    if (fields.contains('sessions')) {
      sessions = await config.persistence
          .getUserSessions(user.userId, onlyValid: false);
    }

    return Response.ok(
      UserInfoMe.fromComplete(
        user,
        config.allCredentialsProviders,
        sessions: sessions?.map(UserSessionBase.fromSession).toList(),
      ),
    );
  }

  Future<Response<UserInfoMe, AuthResponse>> userMFA(Request request) async {
    if (request.method != 'POST') return Response.notFound(null);
    final claims = await authenticatedUserOrThrow(request);
    // TODO: limit claims authentication time
    final user = await config.persistence
        .getUserById(UserId(claims.userId, UserIdKind.innerId));
    if (user == null) return Response.notFound(null);

    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return badRequestExpectedObjectPayload();
    final mfa = MFAConfig.fromJson(data['mfa']! as Map<String, Object?>);

    final notFoundMethods = mfa.requiredItems
        .followedBy(mfa.optionalItems)
        .where((e) => !user.userIds().contains(e.userId))
        .toList();

    if (notFoundMethods.isNotEmpty) {
      return Response.badRequest(
        // TODO: improve error
        body: AuthResponse.error('notFoundMethods'),
      );
    }
    if (!mfa.isValid) {
      return Response.badRequest(
        // TODO: improve error message. There ar emultiple validation errors
        body: AuthResponse.error('Can not have a single MFA provider.'),
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

    return Response.ok(
      UserInfoMe.fromComplete(
        AppUserComplete(user: newUser, authUsers: user.authUsers),
        config.allCredentialsProviders,
        sessions: sessions?.map(UserSessionBase.fromSession).toList(),
      ),
    );
  }

  Future<Response<UserInfoMe, AuthResponse>> authenticationProviderDelete(
    Request request,
  ) async {
    if (request.method != 'DELETE') return Response.notFound(null);
    final providerId = getProviderId(request);
    final providerInstance = config.allProviders[providerId] ??
        config.allCredentialsProviders[providerId];
    if (providerId == null || providerInstance == null) {
      return wrongProviderResponse();
    }
    final claims = await authenticatedUserOrThrow(request);
    // TODO: limit claims authentication time
    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return badRequestExpectedObjectPayload();

    final providerUserId = data['providerUserId'];
    if (providerUserId is! String) {
      return Response.badRequest(
        body: AuthResponse.error('providerUserId is required.'),
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
      return Response.internalServerError();
    } else if (authUserIndex == -1) {
      // No account found
      return Response.badRequest(
        body: AuthResponse.error('No authentication provider found.'),
      );
    } else if (user.authUsers.length == 1) {
      // Can't delete the only provider
      return Response.badRequest(
        body: AuthResponse.error(
          'Can not delete the only authentication provider.',
        ),
      );
    } else if (user.user.multiFactorAuth.kind(mfaItem) !=
        MFAProviderKind.none) {
      // Can't delete a provider in MFA
      return Response.badRequest(
        body: AuthResponse.error(
          'Can not delete an authentication provider used in MFA.',
        ),
      );
    }

    final authUser = user.authUsers[authUserIndex!];
    await config.persistence.deleteAuthUser(
      user.userId,
      authUser,
    );

    return Response.ok(
      UserInfoMe.fromComplete(
        AppUserComplete(
          user: user.user,
          authUsers: [...user.authUsers]..removeAt(authUserIndex),
        ),
        config.allCredentialsProviders,
      ),
    );
  }

  Future<Response<SerializableToJson, AuthResponse>> credentialsUpdate(
    Request request,
  ) async {
    if (request.method != 'PUT') return Response.notFound(null);
    final providerInstance = getCredentialsProvider(request).throwErr();
    return _credentialsUpdate(request, providerInstance);
  }

  // TODO: proper type SerializableToJson UserMeOrResponse
  Future<Response<SerializableToJson, AuthResponse>>
      _credentialsUpdate<C extends CredentialsData, U>(
    Request request,
    CredentialsProvider<C, U> providerInstance,
  ) async {
    final claims = await config.jwtMaker.getUserClaims(ctx(request));
    final claimsMeta =
        claims?.meta == null ? null : UserMetaClaims.fromJson(claims!.meta!);
    if (claims == null || claimsMeta == null || !claimsMeta.isLoggedIn) {
      // TODO: limit claims authentication time
      return Response.unauthorized(null);
    }
    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return badRequestExpectedObjectPayload();

    final providerUserId = data['providerUserId'];
    if (providerUserId is! String) {
      return Response.badRequest(
        body: AuthResponse.error('providerUserId is required.'),
      );
    }
    final credentialsResult = providerInstance.parseCredentials(data);
    if (credentialsResult.isErr()) {
      return Response.badRequest(
        body: AuthResponse.error(
          'Field input errors.',
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
        return Response.badRequest(body: AuthResponse.error('Duplicate User.'));
      }
    }
    final userId = UserId(
      '${providerInstance.providerId}:${providerUserId}',
      UserIdKind.providerId,
    );
    final foundUser = await config.persistence.getUserById(userId);
    if (foundUser == null) {
      return Response.badRequest(body: AuthResponse.error('User not found.'));
    } else if (foundUser.userId != claims.userId) {
      return Response.unauthorized(AuthResponse.error('User not found.'));
    }
    final previousUser =
        foundUser.authUsers.firstWhere((u) => u.userIds().contains(userId));
    final validation = await providerInstance.updateCredentials(
      previousUser.providerUser as U,
      credentials,
    );

    if (validation.isErr()) {
      return Response.unauthorized(
        AuthResponse.fromError(validation.unwrapErr()),
      );
    }
    final response = validation.unwrap();
    if (response.flow != null) {
      return Response.ok(response.flow!);
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

    return Response.ok(
      UserInfoMe.fromComplete(
        userComplete,
        config.allCredentialsProviders,
      ),
    );
  }

  Future<Response> credentialsSignIn(
    Request request, {
    required bool signUp,
  }) async {
    if (request.method != 'POST') return Response.notFound(null);
    final providerInstance = getCredentialsProvider(request).throwErr();
    return _credentialsSignIn(request, providerInstance, signUp: signUp);
  }

  Future<Response> _credentialsSignIn<C extends CredentialsData, U>(
    Request request,
    CredentialsProvider<C, U> providerInstance, {
    required bool signUp,
  }) async {
    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return badRequestExpectedObjectPayload();

    final credentialsResult = providerInstance.parseCredentials(data);
    if (credentialsResult.isErr()) {
      return Response.badRequest(
        body: AuthResponse.error(
          'Field input errors',
          fieldErrors: credentialsResult.unwrapErr(),
        ),
      );
    }

    final claims = await config.jwtMaker.getUserClaims(ctx(request));
    UserSession? mfaSession;
    if (claims != null) {
      mfaSession = await config.persistence.getAnySession(claims.sessionId);
      if (mfaSession != null && !mfaSession.isValid) {
        return Response.unauthorized(AuthResponse.error('Session expired.'));
      }
      if (mfaSession != null && !mfaSession.isInMFA) {
        mfaSession = null;
      }
    }

    if (claims != null) {
      final metaClaims = UserMetaClaims.fromJson(claims.meta!);
      if (metaClaims.isInMFAFlow &&
          (data['providerUserId'] is! String || signUp)) {
        return Response.badRequest(
          body: AuthResponse.error(
            signUp
                ? 'Can not sign up in a MFA flow'
                : 'Wrong parameters for MFA',
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
        return Response.unauthorized(
          AuthResponse.fromError(validation.unwrapErr()),
        );
      }
      final response = validation.unwrap();
      if (response.isSome()) {
        final otherUser = response.unwrap().user;
        if (otherUser == null) {
          return Response.ok(response.unwrap().flow!);
        }
        if (otherUser.key != user.key) {
          return Response.internalServerError(
            body: AuthResponse.error('Error merging users.'),
          );
        }
      }
      // TODO: maybe merge with the current session?
      final sessionResponse = await onUserAuthenticatedResponse(
        user,
        // TODO: check sessionId
        sessionId: mfaSession?.sessionId ?? generateStateToken(),
        mfaSession: mfaSession,
        claims: claims,
      );
      return sessionResponse;
    } else if (!signUp) {
      return Response.badRequest(
        body: AuthResponse.error('Credentials not found.'),
      );
    }

    final userResult = await providerInstance.getUser(credentials);
    if (userResult.isErr()) {
      return Response.badRequest(
        body: AuthResponse.fromError(userResult.unwrapErr()),
      );
    }

    final userOrMessage = userResult.unwrap();
    if (userOrMessage.user == null) {
      // The flow keeps going
      return Response.ok(userOrMessage.flow!);
    } else {
      // TODO: maybe merge with the current session?
      final sessionResponse = await onUserAuthenticatedResponse(
        userOrMessage.user!,
        // TODO: check sessionId
        sessionId: mfaSession?.sessionId ?? generateStateToken(),
        mfaSession: mfaSession,
        claims: claims,
      );
      return sessionResponse;
    }
  }

  Future<Response> onUserAuthenticatedResponse(
    AuthUser<Object?> user, {
    required String sessionId,
    required UserSession? mfaSession,
    required UserClaims? claims,
  }) async {
    final sessionResult = await onUserAuthenticated(
      user,
      sessionId: sessionId,
      mfaSession: mfaSession,
      claims: claims,
    );

    if (sessionResult.isErr()) {
      return Response.internalServerError(
        body: AuthResponse.error(sessionResult.unwrapErr()),
      );
    }
    final responseData =
        await successResponse(sessionResult.unwrap(), user.providerId);
    return Response.ok(responseData);
  }
}

class UserMetaClaims {
  // TODO: what happens with 2fa?
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
    required this.mfaItems,
  })  : state = null,
        deviceCode = null,
        interval = null,
        isInMFAFlow = false;

  UserMetaClaims.inMFA({
    required List<ProviderUserId> this.mfaItems,
    required this.providerId,
    required String this.userId,
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
        mfaItems: mfaItems,
      );
    } else {
      throw Exception('$json');
    }
  }

  Map<String, Object?> toJson() {
    return {
      'providerId': providerId,
      'deviceCode': deviceCode,
      'interval': interval,
      'state': state,
      'userId': userId,
      'mfaItems': mfaItems,
    }..removeWhere((key, value) => value == null);
  }
}
