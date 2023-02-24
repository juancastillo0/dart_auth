import 'dart:convert';

import 'package:jose/jose.dart';
import 'package:oauth/src/password.dart';
import 'package:oxidized/oxidized.dart';

String? _getAuthToken(RequestCtx ctx) {
  return ctx.requestHeaders['authorization'];
}

abstract class RequestCtx {
  Map<String, String> get requestHeaders;

  void appendResponseHeader(String name, String value);

  Map<Object, Object?> get scope;

  ///
  factory RequestCtx(
    Map<String, String> requestHeaders,
    void Function(String name, String value) appendResponseHeader,
  ) = _CtxValue;
}

class _CtxValue implements RequestCtx {
  @override
  final Map<String, String> requestHeaders;
  final void Function(String name, String value) _appendResponseHeader;
  @override
  final Map<Object, Object?> scope = {};

  _CtxValue(this.requestHeaders, this._appendResponseHeader);

  @override
  void appendResponseHeader(String name, String value) =>
      _appendResponseHeader(name, value);
}

class UserClaims {
  final String userId;
  final String sessionId;
  // TODO: should we add providerId? what happends for 2fa
  final Map<String, Object?>? meta;

  UserClaims({
    required this.userId,
    required this.sessionId,
    required this.meta,
  });
}

class JsonWebTokenMaker<U> {
  ///
  JsonWebTokenMaker({
    required String base64Key,
    String? keyId,
    required this.issuer,
    required this.userFromClaims,
  }) : _key = JsonWebKey.fromJson({
          'kty': 'oct',
          'k': base64Key,
          if (keyId != null) 'kid': keyId,
        }) {
    _keyStore.addKey(_key);
  }

  final U Function(JsonWebTokenClaims claims) userFromClaims;
  final Uri issuer;
  final _keyStore = JsonWebKeyStore();
  final JsonWebKey _key;

  final _webSocketSessionsRef = <String, Set<WebSocketServer>>{};

  void closeWebSocketSessionConnections({
    required String sessionId,
  }) {
    final connections = _webSocketSessionsRef[sessionId];
    if (connections != null) {
      for (final conn in connections) {
        // TODO: Unauthorized
        // conn.client.closeWithReason(4401, 'Session ended.');
        conn.close();
      }
    }
  }

  Future<WebSocketConnCtx> initWebSocketConnection(
    RequestCtx /**ScopedHolder*/ holder,
    WebSocketServer server, {
    required Map<String, Object?>? initialPayload,
    required bool isRefreshToken,
  }) async {
    late final WebSocketConnCtx connCtx;
    UserClaims? claims;
    if (initialPayload == null) {
      connCtx = const WebSocketConnCtx();
    } else {
      final token =
          initialPayload[isRefreshToken ? 'refreshToken' : 'accessToken'];
      if (token is String) {
        claims = await getUserClaimsFromToken(
          token,
          isRefreshToken: isRefreshToken,
        );
        if (claims != null) {
          final set = _webSocketSessionsRef.putIfAbsent(
            claims.sessionId,
            () => {},
          );
          set.add(server);

          void onDone(Object? _) {
            set.remove(server);
            if (set.isEmpty) {
              _webSocketSessionsRef.remove(claims!.sessionId);
            }
          }

          // ignore: unawaited_futures
          server.done.then(onDone).catchError(onDone);
        }
      }
      connCtx = WebSocketConnCtx(
        claims: claims,
        platform: initialPayload['platform'] as String?,
        appVersion: initialPayload['appVersion'] as String?,
        initialPayload: initialPayload,
      );
    }
    // server.scopeOverrides.add(_webSocketConnCtxRef.override((scope) => connCtx));
    holder.scope[_webSocketConnCtxRef] = connCtx;
    return connCtx;
  }

  Future<UserClaims?> getUserClaims(
    RequestCtx ctx, {
    bool isRefreshToken = false,
  }) async {
    final webSocketClaims = WebSocketConnCtx.fromCtx(ctx)?.claims;
    if (webSocketClaims != null) {
      return webSocketClaims;
    }
    final authToken = _getAuthToken(ctx);
    if (authToken != null) {
      return getUserClaimsFromToken(
        authToken,
        isRefreshToken: isRefreshToken,
      );
    }
    return null;
  }

  Future<Result<JsonWebToken, List<Object>>> parseJwt(
    String encoded, {
    String? clientId,
    Duration expiryTolerance = Duration.zero,
  }) async {
    final JsonWebToken jwt;
    try {
      jwt = await JsonWebToken.decodeAndVerify(encoded, _keyStore);
    } catch (e, s) {
      return Err([e, s]);
    }

    final errors = jwt.claims
        .validate(
          clientId: clientId,
          issuer: issuer,
          expiryTolerance: expiryTolerance,
        )
        .toList();
    if (errors.isNotEmpty) {
      return Err(errors);
    }
    return Ok(jwt);
  }

  String createJwt({
    required String userId,
    required String sessionId,
    required Duration duration,
    required bool isRefreshToken,
    List<String>? audience,
    Map<String, Object?>? meta,
  }) {
    final int issuedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final int expiresAt = issuedAt + duration.inSeconds;
    final jwtId = base64Encode(getRandomBytes(24));
    return _createJwt({
      'sub': userId,
      'exp': expiresAt,
      'iat': issuedAt,
      'iss': issuer.toString(),
      'jti': jwtId,
      if (audience != null) 'aud': audience,
      'sessionId': sessionId,
      'isRefresh': isRefreshToken,
      if (meta != null) 'meta': meta,
    });
  }

  // @visibleForTesting
  Future<UserClaims?> getUserClaimsFromToken(
    String authToken, {
    bool isRefreshToken = false,
  }) async {
    final jwtResult = await parseJwt(authToken);
    if (jwtResult.isErr()) return null;
    final jwt = jwtResult.unwrap();

    final userId = jwt.claims.subject!;
    final sessionId = jwt.claims.getTyped<String?>('sessionId');
    final isRefresh = jwt.claims.getTyped<bool?>('isRefresh') ?? false;

    if (sessionId != null &&
        (isRefreshToken && isRefresh == true ||
            !isRefreshToken && isRefresh == false)) {
      return UserClaims(
        userId: userId,
        sessionId: sessionId,
        meta: jwt.claims['meta'] as Map<String, Object?>?,
      );
    }
    return null;
  }

  String _createJwt(Map<String, Object?> claimsMap) {
    // create a builder, decoding the JWT in a JWS, so using a
    // JsonWebSignatureBuilder
    final builder = JsonWebSignatureBuilder();
    // set the content
    builder.jsonContent = claimsMap;
    // add a key to sign, can only add one for JWT
    builder.addRecipient(_key, algorithm: 'HS256');
    // build the jws
    final jws = builder.build();
    // output the compact serialization
    return jws.toCompactSerialization();
  }
}

class ScopedRef<T> {
  final String? name;
  final T Function(RequestCtx ctx) create;

  ///
  ScopedRef(this.create, {this.name});

  T get(RequestCtx ctx) {
    if (ctx.scope.containsKey(this)) {
      return ctx.scope[this] as T;
    }
    return ctx.scope[this] = create(ctx);
  }
}

final _webSocketConnCtxRef = ScopedRef<WebSocketConnCtx?>(
  (scope) => null,
  name: 'webSocketConnCtxRef',
);

abstract class WebSocketServer {
  ///
  factory WebSocketServer({
    required void Function() close,
    required Future<void> done,
  }) = _WebSocketServerValue;

  Future<void> get done;

  void close();
}

class _WebSocketServerValue implements WebSocketServer {
  final void Function() _close;
  final Future<void> _done;

  _WebSocketServerValue({
    required void Function() close,
    required Future<void> done,
  })  : _close = close,
        _done = done;

  @override
  void close() {
    _close();
  }

  @override
  Future<void> get done => _done;
}

class WebSocketConnCtx {
  final UserClaims? claims;
  final String? platform;
  final String? appVersion;
  final Map<String, Object?>? initialPayload;

  const WebSocketConnCtx({
    this.claims,
    this.platform,
    this.appVersion,
    this.initialPayload,
  });

  static WebSocketConnCtx? fromCtx(RequestCtx ctx) =>
      _webSocketConnCtxRef.get(ctx);
}

// String? getCookie(Map<String, String> headers, String name) {
//   final cookies = headers[HttpHeaders.cookieHeader]?.split(RegExp(', ?'));
//   final cookie = cookies?.expand((element) {
//     final cookiesList = element.split(RegExp('; ?'));
//     return cookiesList.map<MapEntry<String, String>?>((e) {
//       final kv = e.split('=');
//       return MapEntry(kv[0], kv[1]);
//     });
//   }).firstWhere(
//     (element) => element?.key == name,
//     orElse: () => null,
//   );
//   return cookie?.value;
// }

// const AUTH_COOKIE_KEY = 'shelf-graphql-chat-auth';

// void setAuthCookie(Ctx ctx, String token, int maxAgeSecs) {
//   ctx.appendHeader(
//     HttpHeaders.setCookieHeader,
//     '$AUTH_COOKIE_KEY=$token; HttpOnly; SameSite=Lax; Max-Age=$maxAgeSecs',
//   );
// }
