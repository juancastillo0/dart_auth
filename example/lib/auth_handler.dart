import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;

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
        jsonEncode({
          'providers': config.allProviders.values.map(providerToJson).toList()
        }),
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
    } else if (RegExp('credentials/signin$pIdRegExp').hasMatch(path)) {
      return handler.credentialsSignIn(request, signUp: false);
    } else if (RegExp('credentials/signup$pIdRegExp').hasMatch(path)) {
      return handler.credentialsSignIn(request, signUp: true);
    }
    return Response.ok('Request for "${request.url}"');
  }

  return handleRequest;
}

class AuthHandler {
  final Config config;

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
        '"${config.allProviders.keys.join('","')}"',
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

    final body = await parseBodyOrUrlData(request) as Map<String, Object?>;
    final flow =
        OAuthFlow(providerInstance, config.persistence, client: config.client);
    final authenticated = await flow.handleRedirectUri(
      queryParams: body,
      redirectUri: config.baseRedirectUri,
    );
    return authenticated.when(
      err: (err) {
        switch (err.kind) {
          case AuthResponseErrorKind.endpointError:
            // TODO: edit state session?
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
        final user = await processOAuthToken(
          token,
          providerInstance,
          sessionId: token.stateModel!.sessionId!,
        );

        return user.when(
          err: (err) => Response.internalServerError(
            body: jsonEncode({'message': err.message}),
            headers: jsonHeader,
          ),
          ok: (user) async {
            // TODO: redirect for GETs?
            return Response.ok(null);
          },
        );
      },
    );
  }

  Future<Result<UserSession, GetUserError>> processOAuthToken<U>(
    TokenResponse token,
    OAuthProvider<U> providerInstance, {
    required String sessionId,
  }) async {
    // TODO: make transaction
    final session = await config.persistence.getAnySession(sessionId);
    if (session != null) {
      if (session.isValid) {
        return Ok(session);
      }
      return Err(
        GetUserError(
          token: token,
          response: null,
          message: 'Session revoked',
        ),
      );
    }
    final result = await providerInstance.getUser(
      // TODO: improve this
      OAuthClient.fromTokenResponse(
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
      ).mapErr(
        (message) => GetUserError(
          token: token,
          response: null,
          message: message,
        ),
      ),
    );
  }

  Future<Result<UserSession, String>> onUserAuthenticated(
    AuthUser<Object?> user, {
    required String sessionId,
  }) async {
    final List<AppUser?> users =
        await config.persistence.getUsersById(user.userIds());
    // TODO: casting error whereType<Map<String, Object?>>() does not throw
    final found = users.whereType<AppUser>().toList();
    final userIds = found.map((e) => e.userId).toSet();
    final String userId;
    if (userIds.isEmpty) {
      // create a new user
      userId = generateStateToken();
      await config.persistence.saveUser(userId, user);
    } else if (userIds.length == 1) {
      // merge users
      userId = userIds.first;
      await config.persistence.saveUser(userId, user);
    } else {
      // error multiple users
      return const Err('Multiple users with same credentials');
    }

    final userSession = UserSession(
      refreshToken: makeRefreshToken(
        userId: userId,
        providerId: user.providerId,
        sessionId: sessionId,
      ),
      sessionId: sessionId,
      userId: userId,
      createdAt: DateTime.now(),
    );
    await config.persistence.saveSession(userSession);

    return Ok(userSession);
  }

  Future<Response> getOAuthUrl(Request request) async {
    if (request.method != 'GET') return Response.notFound(null);
    final providerInstance = getProvider(request).throwErr();
    final isImplicit = request.url.queryParameters['flowType'] == 'implicit';
    if (isImplicit &&
        !providerInstance.supportedFlows.contains(GrantType.tokenImplicit)) {
      return Response.badRequest();
    }
    final flow =
        OAuthFlow(providerInstance, config.persistence, client: config.client);
    final state = generateStateToken();
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
    );
    final jwt = config.jwtMaker.createJwt(
      // TODO: maybe anonymous users?
      userId: generateStateToken(),
      sessionId: sessionId,
      duration: authSessionDuration,
      isRefreshToken: false,
      meta: UserMetaClaims.authorizationCode(
        providerId: providerInstance.providerId,
        state: state,
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
    final jwt = config.jwtMaker.createJwt(
      // TODO: maybe anonymous users?
      userId: generateStateToken(),
      sessionId: generateStateToken(),
      duration: authSessionDuration,
      isRefreshToken: false,
      meta: UserMetaClaims.deviceCode(
        providerId: providerInstance.providerId,
        deviceCode: deviceCode.deviceCode,
        interval: deviceCode.interval,
      ).toJson(),
    );
    return Response.ok(
      jsonEncode({'device': deviceCode.toJson(), 'accessToken': jwt}),
      headers: jsonHeader,
    );
  }

  Future<void> verifyStateAndSession({
    required UserClaims claims,
    required String state,
  }) async {
    final stateData = await config.persistence.getState(state);
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
    String? refreshToken = session?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      // has not been logged in
      if (!meta.isDeviceCodeFlow) {
        // no user created at the moment
        return Response.unauthorized(null);
      } else {
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
        final user = await processOAuthToken(
          token,
          providerInstance,
          sessionId: claims.sessionId,
        );
        if (user.isErr()) {
          return Response.internalServerError(
            // TODO: standardize 'error' vs 'message'
            body: jsonEncode({'message': user.unwrapErr().message}),
            headers: jsonHeader,
          );
        }
        refreshToken = user.unwrap().refreshToken;
      }
    }

    // final jwt = makeRefreshToken(
    //   userId: userId,
    //   sessionId: claims.sessionId,
    //   providerId: providerInstance.providerId,
    // );
    return Response.ok(
      jsonEncode({'refreshToken': refreshToken}),
      headers: jsonHeader,
    );
  }

  String makeRefreshToken({
    required String userId,
    required String providerId,
    required String sessionId,
  }) {
    final jwt = config.jwtMaker.createJwt(
      userId: userId,
      sessionId: sessionId,
      duration: refreshTokenDuration,
      isRefreshToken: true,
      meta: UserMetaClaims.loggedUser(
        providerId: providerId,
        userId: userId,
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
        channel.sink.add(jsonEncode({'error': 'Unauthorized'}));
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
        Future<void> sendAndClose(Map<String, Object?> json) async {
          if (isClosed) return;
          channel.sink.add(jsonEncode(json));
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
                    return sendAndClose({'error': err.toString()});
                  }
                  // not yet authenticated
                  // should we send the polling result? channel.sink.add(jsonEncode({'error': err.toString()}));
                },
                ok: (token) async {
                  final sessionResult = await processOAuthToken(
                    token,
                    provider,
                    sessionId: claims.sessionId,
                  );

                  return sessionResult.when(
                    // TODO: make a better error
                    err: (err) => sendAndClose({'error': err.toString()}),
                    ok: (session) {
                      // final jwt = makeRefreshToken(
                      //   userId: user.key,
                      //   sessionId: claims.sessionId,
                      //   providerId: provider.providerId,
                      // );
                      return sendAndClose(
                        {'refreshToken': session.refreshToken},
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
        } else {
          // fetch persisted state
          final startTime = DateTime.now();
          const duration = Duration(seconds: 1);
          Future<void> timerCallback() async {
            final session =
                await config.persistence.getValidSession(claims.sessionId);
            if (channel.closeCode != null || isClosed) {
              return;
            }
            if (session != null && session.userId.isNotEmpty) {
              // final jwt = makeRefreshToken(
              //   userId: session.userId,
              //   sessionId: claims.sessionId,
              //   providerId: provider.providerId,
              // );
              return sendAndClose({'refreshToken': session.refreshToken});
            } else if (DateTime.now().difference(startTime) >
                authSessionDuration) {
              return sendAndClose({'error': 'timeout'});
            } else {
              Timer(duration, timerCallback);
            }
          }

          Timer(duration, timerCallback);
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
    final claims = await authenticatedUserOrThrow(request);
    final fields = request.url.queryParametersAll['fields'] ?? [];

    final user = await config.persistence
        .getUserById(UserId(claims.userId, UserIdKind.innerId));
    if (user == null) return Response.notFound(null);

    final payload = user.toJson();
    if (fields.contains('sessions')) {
      final sessions = await config.persistence
          .getUserSessions(user.userId, onlyValid: false);
      // TODO: map sessions and remove refreshToken
      payload['sessions'] = sessions;
    }

    return Response.ok(jsonEncode(payload), headers: jsonHeader);
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
        body: jsonEncode(
          credentialsResult
              .unwrapErr()
              .map((key, value) => MapEntry(key, value.message)),
        ),
        headers: jsonHeader,
      );
    }
    final credentials = credentialsResult.unwrap();
    // TODO: multiple credentials email and phone
    final userId = UserId(
      '${providerInstance.providerId}:${credentials.providerUserId}',
      UserIdKind.providerId,
    );
    final foundUser = await config.persistence.getUserById(userId);
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
        sessionId: generateStateToken(),
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
      return Response.internalServerError(
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
        sessionId: generateStateToken(),
      );
      return sessionResponse;
    }
  }

  Future<Response> onUserAuthenticatedResponse(
    AuthUser<Object?> user, {
    required String sessionId,
  }) async {
    final sessionResult = await onUserAuthenticated(
      user,
      sessionId: sessionId,
    );

    if (sessionResult.isErr()) {
      return Response.internalServerError(
        // TODO: standardize 'error' vs 'message'
        body: jsonEncode({'error': sessionResult.unwrapErr()}),
        headers: jsonHeader,
      );
    }
    return Response.ok(
      jsonEncode({'refreshToken': sessionResult.unwrap().refreshToken}),
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

  UserMetaClaims.loggedUser({
    required this.providerId,
    required String this.userId,
  })  : state = null,
        deviceCode = null,
        interval = null;

  UserMetaClaims.deviceCode({
    required this.providerId,
    required String this.deviceCode,
    required int this.interval,
  })  : state = null,
        userId = null;

  UserMetaClaims.authorizationCode({
    required this.providerId,
    required String this.state,
  })  : deviceCode = null,
        interval = null,
        userId = null;

  bool get isDeviceCodeFlow => deviceCode != null;

  factory UserMetaClaims.fromJson(Map<String, Object?> json) {
    if (json['deviceCode'] is String) {
      return UserMetaClaims.deviceCode(
        providerId: json['providerId'] as String,
        deviceCode: json['deviceCode'] as String,
        interval: json['interval'] as int,
      );
    } else if (json['userId'] is String) {
      return UserMetaClaims.loggedUser(
        providerId: json['providerId'] as String,
        userId: json['userId'] as String,
      );
    } else {
      return UserMetaClaims.authorizationCode(
        providerId: json['providerId'] as String,
        state: json['state'] as String,
      );
    }
  }

  Map<String, Object?> toJson() {
    return {
      'providerId': providerId,
      'deviceCode': deviceCode,
      'interval': interval,
      'state': state,
      'userId': userId,
    }..removeWhere((key, value) => value == null);
  }
}
