import 'dart:convert' show base64UrlEncode, jsonDecode, jsonEncode, utf8;
import 'dart:io';

import 'package:crypto/crypto.dart' show sha256;
import 'package:http/testing.dart';
import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth_example/auth_handler.dart';
import 'package:oauth_example/credentials.dart';
import 'package:oauth_example/main.dart';
import 'package:oauth_example/persistence.dart';
import 'package:oauth_example/shelf_helpers.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

extension ApplyFn<V extends Object> on V {
  T applyFn<T>(T Function(V) fn) => fn(this);
}

void main() async {
  final credentials = AppCredentialsConfig.fromJson(
    Map.fromEntries(
      [
        'discord',
        'facebook',
        'github',
        'google',
        'microsoft',
        'reddit',
        'spotify',
        'twitch',
        'twitter',
      ].map((e) => MapEntry(e, '${e}_client_id:${e}_client_secret')),
    ),
  );
  final allProviders = await credentials.providersMap();
  final persistence = InMemoryPersistance();

  MockClient createMockClient(OAuthProvider provider) {
    final tokenEndpoint = Uri.parse(provider.tokenEndpoint);
    final authorizationEndpoint = Uri.parse(provider.authorizationEndpoint);
    final deviceAuthorizationEndpoint =
        provider.deviceAuthorizationEndpoint?.applyFn(Uri.parse);

    return MockClient(
      (request) {
        if (request.url.path == tokenEndpoint.path) {
        } else if (request.url.path == deviceAuthorizationEndpoint?.path) {}

        throw Exception(
          'Invalid request ${request.method} '
          '${request.url} ${request.headers} ${request.body}',
        );
      },
    );
  }

  final jwtMaker = JsonWebTokenMaker(
    // TODO:
    base64Key: generateStateToken(),
    issuer: Uri.parse('oauth_example_test'),
    userFromClaims: (claims) => claims,
  );
  final config = Config(
    allProviders: allProviders,
    host: 'localhost',
    port: 0,
    persistence: persistence,
    baseRedirectUri: 'http://localhost:8080/base',
    jwtMaker: jwtMaker,
    // TODO:
    client: createMockClient(allProviders.values.first),
  );
  final client = HttpClient();

  final server = await startServer(config);
  final url = Uri.parse('http://${server.address.host}:${server.port}');

  group('providers endpoint', () {
    test('GET providers', () async {
      final response = await client.get(url.replace(path: 'providers'));
      expect(response.headers, jsonHeader);
      expect(response.statusCode, 200);
      expect(
        jsonDecode(response.body),
        {'providers': allProviders.values.map(providerToJson).toList()},
      );
    });

    test('PUT providers', () async {
      final response = await client.put(url.replace(path: 'providers'));
      expect(response.statusCode, 404);
    });
  });

  group('oauth/url endpoint', () {
    for (final provider in allProviders.values) {
      final providerId = provider.providerId;
      test('GET oauth/url/${providerId}', () async {
        final response =
            await client.get(url.replace(path: 'oauth/url/${providerId}'));
        expect(response.headers, jsonHeader);
        expect(response.statusCode, 200);
        final data = jsonDecode(response.body) as Map<String, Object?>;
        expect(data.length, 2);
        final dataUrl = Uri.parse(data['url'] as String);
        final accessToken = data['accessToken'] as String;
        final state = dataUrl.queryParameters['state']!;
        final claims = (await jwtMaker.getUserClaimsFromToken(accessToken))!;
        expect(
          claims.meta,
          UserMetaClaims.authorizationCode(
            providerId: providerId,
            state: state,
          ).toJson(),
        );
        final session = await persistence.getAnySession(claims.sessionId);
        expect(session, isNull); // not created yet
        final stateData = (await persistence.getState(state))!;
        expect(stateData.sessionId, claims.sessionId);
        expect(
            stateData.nonce != null, provider.defaultScopes.contains('openid'));
        expect(stateData.responseType, OAuthResponseType.code);
        final code_challenge = dataUrl.queryParameters['code_challenge'];
        expect(code_challenge == null, provider.codeChallengeMethod == null);
        if (code_challenge != null) {
          final method = CodeChallengeMethod.values.byName(
            dataUrl.queryParameters['code_challenge_method'] as String,
          );
          switch (method) {
            case CodeChallengeMethod.plain:
              expect(stateData.codeVerifier, code_challenge);
              break;
            case CodeChallengeMethod.S256:
              expect(
                  base64UrlEncode(
                    sha256.convert(utf8.encode(stateData.codeVerifier!)).bytes,
                  ).replaceAll('=', ''),
                  code_challenge);
              break;
          }
        }

        if (provider is RedditProvider) {
          expect(
            dataUrl.queryParameters['duration'],
            RedditAuthDuration.permanent.name,
          );
        }
        // TODO: more verifications

        final responseState = await client.get(url.replace(path: 'oauth/state'),
            headers: {Headers.authorization: accessToken});
        expect(responseState.statusCode, HttpStatus.unauthorized);

        final wsChannel = WebSocketChannel.connect(
            url.replace(scheme: 'ws', path: 'oauth/subscribe'));
        wsChannel.sink.add(jsonEncode({'accessToken': accessToken}));
        final events = <Map<String, Object?>>[];
        wsChannel.stream
            .map((e) => jsonDecode(e) as Map<String, Object?>)
            .listen(events.add);

        wsChannel.closeCode;

        final responseCallback = await client.post(
          url.replace(path: 'oauth/callback/${providerId}'),
          body: AuthRedirectResponse(),
        );
      });
    }
  });
}
