import 'dart:convert'
    show base64Encode, base64UrlEncode, jsonDecode, jsonEncode, utf8;
import 'dart:io';
import 'dart:typed_data';

import 'package:oauth/endpoint_models.dart';
import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth_example/auth_handler.dart';
import 'package:oauth_example/credentials.dart';
import 'package:oauth_example/main.dart';
import 'package:oauth_example/persistence.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'credentials_test.dart';
import 'mock_auth_server.dart';
import 'user_models.dart';

extension ApplyFn<V extends Object> on V {
  T applyFn<T>(T Function(V) fn) => fn(this);
}

final jsonHeaderMatcher =
    predicate((d) => d is Map && d[Headers.contentType] == Headers.appJson);

void main() async {
  final credentials = AppCredentialsConfig.fromJson(
    Map.fromEntries(
      [
        // TODO: other providers
        // TODO: user models
        'discord',
        'facebook',
        'github',
        'google',
        'microsoft',
        'reddit',
        'spotify',
        'twitch',
        'twitter',
      ].map(
        (e) => MapEntry(
          e,
          '${e}_client_id:${e}_client_secret'
          '${e == 'facebook' ? ':client_token' : ''}',
        ),
      ),
    ),
  );

  final allProviders =
      await credentials.providersMap(client: jwkOverrideClient);
  final allProvidersMocks = allProviders.map(
    (key, value) => MapEntry(key, ProviderClientMock(value)),
  );
  final persistence = InMemoryPersistance();
  final jwtMaker = JsonWebTokenMaker(
    // TODO:
    base64Key: generateStateToken(),
    issuer: Uri.parse('oauth_example_test'),
    userFromClaims: (claims) => claims,
  );

  group('auth handler', timeout: const Timeout(Duration(seconds: 60)), () {
    late Config config;
    final client = HttpClient();
    late Uri url;
    late HttpServer server;

    setUpAll(() async {
      config = Config(
        allOAuthProviders: allProviders,
        allCredentialsProviders: {
          // TODO: test isolates
          ImplementedProviders.username: UsernamePasswordProvider(),
        },
        persistence: persistence,
        baseRedirectUri: 'http://localhost:8080/base',
        jwtMaker: jwtMaker,
        // TODO:
        client: createMockClient(
          allProviders: allProviders,
          allProvidersMocks: allProvidersMocks,
        ),
      );
      server = await startServer(config, host: 'localhost', port: 0);
      url = Uri.parse('http://${server.address.host}:${server.port}');
    });

    // TODO: test from seeded persistence

    group('oauth/providers endpoint', () {
      test('GET oauth/providers', () async {
        final response = await client.get(url.replace(path: 'oauth/providers'));
        expect(response.headers, jsonHeaderMatcher);
        expect(response.statusCode, 200);
        expect(
          jsonDecode(response.body),
          jsonEncDec({
            'providers': allProviders.values
                .map(OAuthProviderData.fromProvider)
                .toList(),
            'credentialsProviders': [UsernamePasswordProvider()]
                .map(CredentialsProviderData.fromProvider)
                .toList()
          }),
        );
      });

      test('PUT oauth/providers', () async {
        final response = await client.put(url.replace(path: 'oauth/providers'));
        expect(response.statusCode, 404);
      });
    });

    group('oauth/url endpoint', () {
      for (final provider in allProviders.values) {
        final providerId = provider.providerId;
        test('oauth/url/${providerId}', () async {
          final response =
              await client.get(url.replace(path: 'oauth/url/${providerId}'));
          expect(response.headers, jsonHeaderMatcher);
          expect(response.statusCode, 200);
          final data = jsonDecode(response.body) as Map<String, Object?>;
          expect(data.length, 2);
          // TODO; make models
          final authorizeUrl = Uri.parse(data['url'] as String);
          final accessToken = data['accessToken'] as String;
          final claims = await validateUrlResponse(
            client,
            config,
            provider,
            authorizeUrl: authorizeUrl,
            accessToken: accessToken,
            responseType: OAuthResponseType.code,
          );

          final testState = TestState(
            provider: provider,
            providerMock: allProvidersMocks[providerId]!,
            client: client,
            url: url,
            config: config,
            sessionId: claims.sessionId,
          );

          await testState.authenticateAndLogout(
            accessToken: accessToken,
            authorizeUrl: authorizeUrl,
            deviceCode: null,
          );
        });
      }
    });

    group('oauth/url implicit endpoint', () {});

    group('oauth/device endpoint', () {
      for (final provider in allProviders.values) {
        final providerId = provider.providerId;
        test('oauth/device/${providerId}', () async {
          final response = await client.get(
            url.replace(path: 'oauth/device/${providerId}'),
          );

          if (provider.deviceAuthorizationEndpoint == null) {
            expect(response.statusCode, HttpStatus.badRequest);
            return;
          }
          expect(response.headers, jsonHeaderMatcher);
          expect(response.statusCode, 200);
          final data = jsonDecode(response.body) as Map<String, Object?>;
          expect(data.length, 2);
          // TODO; make models
          final deviceCodeModel =
              DeviceCodeResponse.fromJson(data['device'] as Map);
          final accessToken = data['accessToken'] as String;
          final claims = await validateDeviceCodeSession(
            config,
            provider,
            deviceCodeModel,
            accessToken: accessToken,
          );

          final testState = TestState(
            provider: provider,
            providerMock: allProvidersMocks[providerId]!,
            client: client,
            url: url,
            config: config,
            sessionId: claims.sessionId,
          );

          await testState.authenticateAndLogout(
            accessToken: accessToken,
            authorizeUrl: null,
            deviceCode: deviceCodeModel,
          );
        });
      }
    });
  });
}

// TODO: test redict uris configuration

Future<UserClaims> validateDeviceCodeSession(
  Config config,
  OAuthProvider provider,
  DeviceCodeResponse deviceCode, {
  required String accessToken,
}) async {
  final claims = (await config.jwtMaker.getUserClaimsFromToken(accessToken))!;
  expect(
    claims.meta,
    UserMetaClaims.deviceCode(
      providerId: provider.providerId,
      deviceCode: deviceCode.deviceCode,
      interval: deviceCode.interval,
      mfaItems: null,
    ).toJson(),
  );
  final session = await config.persistence.getAnySession(claims.sessionId);
  expect(session, isNull); // not created yet

  // final stateData = (await config.persistence.getState(state))!;
  // expect(stateData.sessionId, claims.sessionId);

  // TODO: validate deviceCodeModel, maybe with the MockClient
  return claims;
}

Future<UserClaims> validateUrlResponse(
  HttpClient client,
  Config config,
  OAuthProvider provider, {
  required Uri authorizeUrl,
  required String accessToken,
  required OAuthResponseType responseType,
}) async {
  final isImplicitFlow = responseType == OAuthResponseType.token;
  final state = authorizeUrl.queryParameters['state']!;

  /// Validate claims and session
  final claims = (await config.jwtMaker.getUserClaimsFromToken(accessToken))!;
  expect(
    claims.meta,
    UserMetaClaims.authorizationCode(
      providerId: provider.providerId,
      state: state,
      mfaItems: null,
    ).toJson(),
  );
  final session = await config.persistence.getAnySession(claims.sessionId);
  expect(session, isNull); // not created yet

  /// Validate stateData
  final stateData = (await config.persistence.getState(state))!;
  expect(stateData.sessionId, claims.sessionId);
  expect(stateData.nonce != null, provider.defaultScopes.contains('openid'));
  expect(stateData.responseType, responseType);
  final code_challenge = authorizeUrl.queryParameters['code_challenge'];
  expect(code_challenge == null, isImplicitFlow);
  if (code_challenge != null) {
    final method = CodeChallengeMethod.values.byName(
      authorizeUrl.queryParameters['code_challenge_method'] as String,
    );
    switch (method) {
      case CodeChallengeMethod.plain:
        expect(stateData.codeVerifier, code_challenge);
        break;
      case CodeChallengeMethod.S256:
        final digest = SHA256Digest()
            .process(Uint8List.fromList(utf8.encode(stateData.codeVerifier!)));
        expect(base64UrlEncode(digest).replaceAll('=', ''), code_challenge);
        break;
    }
  }

  /// Validate providers
  if (provider is RedditProvider) {
    expect(
      authorizeUrl.queryParameters['duration'],
      isImplicitFlow ? isNull : RedditAuthDuration.permanent.name,
    );
  }
  // TODO: more provider specific verifications

  return claims;
}

class TestState {
  final OAuthProvider provider;
  final ProviderClientMock providerMock;
  final HttpClient client;
  final Uri url;
  final Config config;
  final String sessionId;

  InMemoryPersistance get persistence =>
      config.persistence as InMemoryPersistance;

  TestState({
    required this.provider,
    required this.providerMock,
    required this.client,
    required this.url,
    required this.config,
    required this.sessionId,
  });

  Future<void> authenticateAndLogout({
    required String accessToken,
    required Uri? authorizeUrl,
    required DeviceCodeResponse? deviceCode,
  }) async {
    final providerId = provider.providerId;
    final isDeviceCodeFlow = authorizeUrl == null;
    assert(!isDeviceCodeFlow || deviceCode != null);
    final state = authorizeUrl?.queryParameters['state'];

    {
      final responseState = await client.get(
        url.replace(path: 'oauth/state'),
      );
      expect(responseState.statusCode, HttpStatus.forbidden);
    }
    {
      final responseState = await client.get(
        url.replace(path: 'oauth/state'),
        headers: {Headers.authorization: accessToken},
      );
      expect(responseState.statusCode, HttpStatus.unauthorized);
    }

    /// GET successful oauth/state
    final wsChannel = WebSocketChannel.connect(
      url.replace(scheme: 'ws', path: 'oauth/subscribe'),
    );
    wsChannel.sink.add(jsonEncode({'accessToken': accessToken}));
    final events = <Map<String, Object?>>[];
    final wsSubscription = wsChannel.stream
        .cast<String>()
        .map((e) => jsonDecode(e) as Map<String, Object?>)
        .listen(events.add);

    if (!isDeviceCodeFlow) {
      /// code or token flow
      /// send successful oauth/callback
      final code = generateStateToken();
      // TODO: validate code in MockClient
      await testHandleOAuthCallBack(code: code, state: state!);
      // TODO: test error flow
      // TODO: AuthResponseErrorKind.endpointError
      providerMock.codeToAuthorizeUri[code] = authorizeUrl;

      final responseCallback = await client.get(
        url.replace(
          path: 'oauth/callback/${providerId}',
          queryParameters:
              AuthRedirectResponse(state: state, code: code).toJson(),
        ),
      );
      expect(responseCallback.statusCode, 200);
      expect(responseCallback.contentLength, 0);
    } else {
      /// device code flow
      // TODO: MockClient fetch completer
      await providerMock.deviceCodes[deviceCode!.deviceCode]!.completer.future;
    }

    /// GET successful oauth/state
    final responseState2 = await client.get(
      url.replace(path: 'oauth/state'),
      headers: {Headers.authorization: accessToken},
    );
    expect(responseState2.statusCode, 200);
    expect(responseState2.headers, jsonHeaderMatcher);

    /// Validate web socket subscription
    // TODO: advance time and check
    wsChannel.closeCode;

    final body2Data = jsonDecode(responseState2.body) as Map;
    final refreshToken = body2Data['refreshToken'] as String;

    /// Verify sessions
    final session2 = await persistence.getAnySession(sessionId);
    final session2Valid = await persistence.getValidSession(sessionId);
    expect(session2?.sessionId, sessionId);
    expect(session2!.sessionId, session2Valid?.sessionId);

    /// Refresh token
    final responseRefresh = await client.post(
      url.replace(path: 'jwt/refresh'),
      headers: {
        Headers.authorization: refreshToken,
        Headers.acceptLanguage: 'en',
        'timezone': 'Europe/Berlin',
      },
    );
    expect(responseRefresh.statusCode, 200);
    final responseRefreshData = jsonDecode(responseRefresh.body) as Map;
    final accessToken2 = responseRefreshData['accessToken'] as String;

    /// GET successful /user/me
    final responseMe = await client.get(
      url.replace(
        path: 'user/me',
        queryParameters: {
          'fields': ['sessions']
        },
      ),
      headers: {Headers.authorization: accessToken2},
    );
    expect(responseMe.statusCode, 200);
    expect(responseMe.headers, jsonHeaderMatcher);
    // TODO: more params: name email verified

    const noPicture = [
      ImplementedProviders.discord,
      ImplementedProviders.apple,
    ];
    const noName = [ImplementedProviders.discord];
    final grantType =
        isDeviceCodeFlow ? GrantType.deviceCode : GrantType.authorizationCode;

    final isoDateMatcher =
        predicate((p) => DateTime.tryParse(p! as String) != null);
    expect(
      jsonDecode(responseMe.body),
      {
        'user': {
          'userId': session2.userId,
          'name': providerId == ImplementedProviders.twitch
              ? 'preferred_username'
              : noName.contains(providerId)
                  ? 'username'
                  : 'name',
          if (!noPicture.contains(providerId))
            'picture': providerId == ImplementedProviders.microsoft
                ? 'data:image/png;base64,${base64Encode([0, 1, 2, 3])}'
                : 'https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228',
          if (providerId != ImplementedProviders.reddit)
            'email': 'email-${providerId}-${grantType.name}@example.com',
          'emailIsVerified': providerId != ImplementedProviders.reddit,
          // 'phone': null,
          'phoneIsVerified': false,
          'multiFactorAuth': {
            'requiredItems': <dynamic>[],
            'optionalCount': 0,
            'optionalItems': <dynamic>[]
          },
          'createdAt': isoDateMatcher,
        },
        'sessions': [
          {
            'sessionId': session2.sessionId,
            'userId': session2.userId,
            'endedAt': null,
            'createdAt': isoDateMatcher,
            'lastRefreshAt': isoDateMatcher,
            'clientData': {
              'userAgent': matches(RegExp(r'^Dart/\d\.\d\d \(dart:io\)$')),
              'host': 'localhost:${url.port}',
              'languages': ['en'],
              'timezone': 'Europe/Berlin',
            },
            'mfa': [
              {
                'providerId': providerId,
                'providerUserId': ImplementedProviders.github == providerId
                    ? '${grantType.hashCode}'
                    : 'id-${grantType.name}'
              }
            ]
          },
        ],
        'authUsers': [
          jsonDecode(
            jsonEncode(
              {
                'authUser': mockUser(
                  provider,
                  nonce: authorizeUrl?.queryParameters['nonce'] ?? 'NONE',
                  grantType: isDeviceCodeFlow
                      ? GrantType.deviceCode
                      : GrantType.authorizationCode,
                ),
                'providerName': {
                  'key': '${providerId}ProviderName',
                  'msg': '${providerId.substring(0, 1).toUpperCase()}'
                      '${providerId.substring(1)}',
                }
              },
            ),
          )
        ],
      },
    );

    /// Verify subscription
    if (wsChannel.closeCode == null) {
      await wsSubscription.asFuture<dynamic>();
    }
    expect(events, hasLength(1));
    final lastEvent = events.last;
    expect(lastEvent, {
      'refreshToken': refreshToken,
      'accessToken': isA<String>(),
      'expiresAt': isoDateMatcher,
    });

    // TODO: logout

    await logoutAndValidate(
      refreshToken: refreshToken,
      accessToken: accessToken2,
    );
  }

  Future<void> logoutAndValidate({
    required String refreshToken,
    required String accessToken,
  }) async {
    /// Revoke token
    final responseRevoke = await client.post(
      url.replace(path: 'jwt/revoke'),
      headers: {Headers.authorization: accessToken},
    );
    expect(responseRevoke.statusCode, 200);
    {
      /// Verify revoked sessions
      final sessionRevoked = await persistence.getAnySession(sessionId);
      final sessionRevokedValid = await persistence.getValidSession(sessionId);
      expect(sessionRevokedValid, isNull);
      expect(sessionRevoked?.sessionId, sessionId);
    }
    {
      /// Refresh token unauthenticated
      final responseRefreshUnauthenticated = await client.post(
        url.replace(path: 'jwt/refresh'),
        headers: {Headers.authorization: refreshToken},
      );
      expect(responseRefreshUnauthenticated.statusCode, 401);
    }
    {
      /// TODO: maybe pass time to invalidate accessToken GET unauthenticated /user/me
      // final responseMeFailed = await client.get(
      //   url.replace(path: 'user/me'),
      //   headers: {Headers.authorization: accessToken},
      // );
      // expect(responseMeFailed.statusCode, 401);
    }
  }

  Future<void> testHandleOAuthCallBack({
    required String code,
    required String state,
  }) async {
    final providerId = provider.providerId;
    {
      final responseCallback = await client.get(
        url.replace(
          path: 'oauth/callback/${providerId}',
          fragment: Uri(
            queryParameters:
                AuthRedirectResponse(state: null, code: code).toJson(),
          ).query,
        ),
      );
      expect(responseCallback.statusCode, HttpStatus.badRequest);
      expect(responseCallback.headers, jsonHeaderMatcher);
      expect(
        jsonDecode(responseCallback.body),
        {
          'error': {'key': Translations.oauthNoStateKey, 'msg': 'No state'}
        },
      );
    }
    {
      final responseCallback = await client.get(
        url.replace(
          path: 'oauth/callback/${providerId}',
          queryParameters:
              AuthRedirectResponse(state: 'WRONG_STATE', code: code).toJson(),
        ),
      );
      expect(responseCallback.statusCode, HttpStatus.badRequest);
      expect(responseCallback.headers, jsonHeaderMatcher);
      expect(
        jsonDecode(responseCallback.body),
        {
          'error': {
            'key': Translations.oauthNotFoundStateKey,
            'msg': 'State not found'
          },
        },
      );
    }
    // TODO: test this outside of successful flow
    // {
    //   final responseCallback = await client.post(
    //     url.replace(path: 'oauth/callback/${providerId}'),
    //     body: AuthRedirectResponse(
    //       state: state,
    //       code: code,
    //     ).toJson(),
    //   );
    //   expect(responseCallback.statusCode, HttpStatus.internalServerError);
    //   expect(responseCallback.headers, jsonHeaderMatcher);
    //   expect(
    //     jsonDecode(responseCallback.body),
    //     {
    //       'error': {
    //         'key': Translations.oauthTokenResponseErrorKey,
    //         'msg': 'Token endpoint error'
    //       },
    //     },
    //   );
    // }
  }
}
