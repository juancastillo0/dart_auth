import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:oauth/endpoint_models.dart';
import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth_example/main.dart';
import 'package:oauth_example/shelf_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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

Handler makeHandler(Config config) {
  final handler = AuthHandler(config);
  const pIdRegExp = '/?([a-zA-Z_-]+)?';

  Future<Response> handleRequest(Request request) async {
    final path = request.url.path;
    if (path == '') {
      if (request.method != 'GET') return Response.notFound(null);
      return Response.ok('<html><body></body></html>');
    } else if (path == 'oauth/providers') {
      if (request.method != 'GET') return Response.notFound(null);
      return Response.ok(
        jsonEncode(
          AuthProvidersData(
            config.allProviders.values
                .map(OAuthProviderData.fromProvider)
                .toList(),
            config.allCredentialsProviders.values
                .map(CredentialsProviderData.fromProvider)
                .toList(),
          ),
        ),
        headers: jsonHeader,
      );
    } else if (RegExp('oauth/url$pIdRegExp').hasMatch(path)) {
      return handler.getOAuthUrl(request);
    } else if (RegExp('oauth/device$pIdRegExp').hasMatch(path)) {
      return handler.getOAuthDeviceCode(request);
    } else if (RegExp('oauth/callback$pIdRegExp').hasMatch(path)) {
      return handler.handleOAuthCallback(request);
    } else if (RegExp('oauth/state').hasMatch(path)) {
      return handler.getOAuthState(request);
    } else if (RegExp('oauth/subscribe').hasMatch(path)) {
      return handler.handlerWebSocketOAuthStateSubscribe(request);
      // TODO: maybe use /token instead?
    } else if (path == 'jwt/refresh') {
      return handler.refreshAuthToken(request);
    } else if (path == 'jwt/revoke') {
      return handler.revokeAuthToken(request);
    } else if (path == 'user/me') {
      return handler.getUserMeInfo(request);
    } else if (path == 'user/mfa') {
      return handler.userMFA(request);
    } else if (RegExp('credentials/signin$pIdRegExp').hasMatch(path)) {
      return handler.credentialsSignIn(request, signUp: false);
    } else if (RegExp('credentials/signup$pIdRegExp').hasMatch(path)) {
      return handler.credentialsSignIn(request, signUp: true);
    }
    return Response.notFound('${request.method} Request for "${request.url}"');
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

  late final wrongProviderResponse = Response.badRequest(
    body: 'provider query parameter must be one of '
        '"${config.allProviders.keys.followedBy(config.allCredentialsProviders.keys).join('", "')}"',
  );

  Result<OAuthProvider, Response> getProvider(Request request) {
    final providerId = request.url.queryParameters['provider'] ??
        (request.url.pathSegments.length > 2
            ? request.url.pathSegments[2]
            : null);
    final providerInstance = config.allProviders[providerId];
    if (providerInstance == null) {
      return Err(wrongProviderResponse);
    }
    return Ok(providerInstance);
  }

  Result<CredentialsProvider, Response> getCredentialsProvider(
    Request request,
  ) {
    final providerId = request.url.queryParameters['provider'] ??
        (request.url.pathSegments.length > 2
            ? request.url.pathSegments[2]
            : null);
    final providerInstance = config.allCredentialsProviders[providerId];
    if (providerInstance == null) {
      return Err(wrongProviderResponse);
    }
    return Ok(providerInstance);
  }

  Future<Response> refreshAuthToken(Request request) async {
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
      jsonEncode({'accessToken': jwt}),
      headers: jsonHeader,
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
              body: jsonEncode({'kind': err.kind.name}),
              headers: jsonHeader,
            );
          case AuthResponseErrorKind.tokenResponseError:
            return Response.internalServerError(
              body: jsonEncode({'kind': err.kind.name}),
              headers: jsonHeader,
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
      MFAItem(
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
    List<MFAItem>? leftMfa;
    if (userIds.isEmpty) {
      // create a new user
      userId = generateStateToken();
      await config.persistence.saveUser(userId, user);
    } else if (userIds.length == 1) {
      // verify multiFactorAuth
      // TODO: split between required and a optional amount of auth providers for MFA
      final mfa = found.first.user.multiFactorAuth;
      leftMfa = [...mfa]..removeWhere(doneMfa.contains);

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
            multiFactorAuth: providerIds
                .map(
                  (e) => MFAItem(
                    // TODO: imrove UserId typing. Maybe a separate ProviderUserId
                    providerId: e.id.split(':').first,
                    providerUserId: e.id.split(':').last,
                  ),
                )
                .toList(),
          ),
        );
      }
    } else {
      // error multiple users
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

  Future<Response> getOAuthUrl(Request request) async {
    if (request.method != 'GET') return Response.notFound(null);
    final providerInstance = getProvider(request).throwErr();
    final isImplicit = request.url.queryParameters['flowType'] == 'implicit';
    if (isImplicit &&
        !providerInstance.supportedFlows.contains(GrantType.tokenImplicit)) {
      return Response.badRequest();
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
    return Response.ok(
      jsonEncode({'url': url.toString(), 'accessToken': jwt}),
      headers: jsonHeader,
    );
  }

  Future<Response> getOAuthDeviceCode(Request request) async {
    if (request.method != 'GET') return Response.notFound(null);
    final providerInstance = getProvider(request).throwErr();

    final deviceCode = await providerInstance.getDeviceCode(
      config.client,
      // TODO: when do we need to send the redirectUri? here or in polling?
      redirectUri: config.baseRedirectUri,
    );
    if (deviceCode == null) {
      // The provider does not support it
      return Response.badRequest();
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
      jsonEncode({'device': deviceCode.toJson(), 'accessToken': jwt}),
      headers: jsonHeader,
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

  Future<Response> getOAuthState(Request request) async {
    if (request.method != 'GET') return Response.notFound(null);

    final claims = await config.jwtMaker.getUserClaims(ctx(request));
    if (claims?.meta == null) {
      return Response.forbidden(null);
    }
    final meta = UserMetaClaims.fromJson(claims!.meta!);
    final providerInstance = config.allProviders[meta.providerId];
    if (providerInstance == null) {
      return Response.badRequest();
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
            jsonEncode({'error': result.unwrapErr()}),
            headers: jsonHeader,
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
            // TODO: improve and standardize error
            jsonEncode({'error': result.unwrapErr().error}),
            headers: jsonHeader,
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
            // TODO: standardize 'error' vs 'message'
            body: jsonEncode({'message': sessionResult.unwrapErr().message}),
            headers: jsonHeader,
          );
        }
        partialSession = sessionResult.unwrap();
      } else {
        return Response.badRequest();
      }
    }
    final responseData =
        await successResponse(partialSession!, providerInstance.providerId);
    return Response.ok(jsonEncode(responseData), headers: jsonHeader);
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
        mfaItems: session.mfa!,
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
    return AuthResponse(
      refreshToken: session.refreshToken,
      accessToken: accessToken,
      // TODO: change for mfa?
      expiresAt: DateTime.now().add(authSessionDuration),
      leftMfaItems: sessionOrPartial.leftMfa
          ?.map((e) => MFAItemWithFlow(e, credentialsMFAFlow[e]))
          .toList(),
      error: null,
      message: null,
      code: null,
    );
  }

  String makeRefreshToken({
    required String userId,
    required String providerId,
    required String sessionId,
    required List<MFAItem>? mfaItems,
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

  FutureOr<Response> handlerWebSocketOAuthStateSubscribe(Request request) {
    final handler = webSocketHandler((
      WebSocketChannel channel,
      String? subprotocol,
    ) async {
      bool didInitConnection = false;

      Future<void> _closeUnauthorized() {
        channel.sink.add(jsonEncode(AuthResponse.error('Unauthorized')));
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
          channel.sink.add(jsonEncode(json.toJson()));
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
        UserMetaClaims.fromJson(claims.meta!).userId == null) {
      throw Response.unauthorized(null);
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

  Future<Response> getUserMeInfo(Request request) async {
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
      jsonEncode(
        UserInfoMe(
          user: user.user,
          authUsers: user.authUsers,
          sessions: sessions?.map(UserSessionBase.fromSession).toList(),
        ),
      ),
      headers: jsonHeader,
    );
  }

  Future<Response> userMFA(Request request) async {
    if (request.method != 'POST') return Response.notFound(null);
    final claims = await authenticatedUserOrThrow(request);
    final user = await config.persistence
        .getUserById(UserId(claims.userId, UserIdKind.innerId));
    if (user == null) return Response.notFound(null);

    final data = await parseBodyOrUrlData(request);
    if (data is! Map<String, Object?>) return Response.badRequest();
    final mfa = (data['mfa']! as Iterable)
        .cast<Map<String, Object?>>()
        .map(MFAItem.fromJson)
        .toSet();

    final notFoundMethods =
        mfa.where((e) => !user.userIds().contains(e.userId)).toList();

    if (notFoundMethods.isNotEmpty) {
      return Response.badRequest(
        body: jsonEncode({'notFoundMethods': notFoundMethods}),
        headers: jsonHeader,
      );
    }
    if (mfa.length == 1) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Can not have a single MFA provider.'}),
        headers: jsonHeader,
      );
    }

    final newUser = user.user.copyWith(multiFactorAuth: mfa.toList());
    await config.persistence.updateUser(newUser);

    final fields = request.url.queryParametersAll['fields'] ?? [];
    List<UserSession>? sessions;
    if (fields.contains('sessions')) {
      sessions = await config.persistence
          .getUserSessions(user.userId, onlyValid: false);
    }

    return Response.ok(
      jsonEncode(
        UserInfoMe(
          user: newUser,
          authUsers: user.authUsers,
          sessions: sessions?.map(UserSessionBase.fromSession).toList(),
        ),
      ),
      headers: jsonHeader,
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
    if (data is! Map<String, Object?>) {
      return Response.badRequest();
    }
    final credentialsResult = providerInstance.parseCredentials(data);
    if (credentialsResult.isErr()) {
      return Response.badRequest(
        body: jsonEncode({
          'fieldErrors': credentialsResult
              .unwrapErr()
              .map((key, value) => MapEntry(key, value.message)),
        }),
        headers: jsonHeader,
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
          body: jsonEncode({
            'error': signUp
                ? 'Can not sign up in a MFA flow'
                : 'Wrong parameters for MFA'
          }),
          headers: jsonHeader,
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
          jsonEncode(validation.unwrapErr().toJson()),
          headers: jsonHeader,
        );
      }
      final response = validation.unwrap();
      if (response.isSome()) {
        final otherUser = response.unwrap().user;
        if (otherUser == null) {
          return Response.ok(
            jsonEncode(response.unwrap().toJson()),
            headers: jsonHeader,
          );
        }
        if (otherUser.key != user.key) {
          return Response.internalServerError(
            body: jsonEncode({'error': 'Error merging users.'}),
            headers: jsonHeader,
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
        body: jsonEncode({'error': 'Credentials not found.'}),
        headers: jsonHeader,
      );
    }

    final userResult = await providerInstance.getUser(credentials);
    if (userResult.isErr()) {
      return Response.badRequest(
        // TODO: standardize 'error' vs 'message'
        body: jsonEncode(userResult.unwrapErr().toJson()),
        headers: jsonHeader,
      );
    }

    final userOrMessage = userResult.unwrap();
    if (userOrMessage.user == null) {
      // The flow keeps going
      return Response.ok(
        jsonEncode(userOrMessage.toJson()),
        headers: jsonHeader,
      );
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
        // TODO: standardize 'error' vs 'message'
        body: jsonEncode(AuthResponse.error(sessionResult.unwrapErr())),
        headers: jsonHeader,
      );
    }
    final responseData =
        await successResponse(sessionResult.unwrap(), user.providerId);
    return Response.ok(
      jsonEncode(responseData),
      headers: jsonHeader,
    );
  }
}

class UserMetaClaims {
  // TODO: what happens with 2fa?
  final String providerId;
  final String? userId;
  final String? deviceCode;
  final int? interval;
  final String? state;
  final List<MFAItem>? mfaItems;
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
    required List<MFAItem> this.mfaItems,
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
            .map(MFAItem.fromJson)
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
