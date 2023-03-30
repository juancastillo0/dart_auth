import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:jose/jose.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:test/test.dart';

import 'open_id_connect_configs.dart';
import 'user_models.dart';

class ProviderClientMock {
  final OAuthProvider provider;
  final tokens = <String, TokenResponseTest>{};
  final codeToAuthorizeUri = <String, Uri>{};
  final deviceCodes = <String, DeviceCodeResponseTest>{};

  final identifierResponse = <String, Response>{};

  ProviderClientMock(this.provider);
}

class TokenResponseTest {
  final String tokenKind;
  final GrantType grantType;
  final TokenResponse response;

  TokenResponseTest(this.tokenKind, this.grantType, this.response);
}

class DeviceCodeResponseTest {
  final String scope;
  final DeviceCodeResponse response;
  final String? redirectUri;
  int numPollingRequests = 0;
  final completer = Completer<void>();

  DeviceCodeResponseTest({
    required this.scope,
    required this.response,
    required this.redirectUri,
  });
}

Map<String, String> get jsonHeader => {Headers.contentType: Headers.appJson};

const _testJsonWebKey = {
  'kty': 'RSA',
  'n':
      '29eNx9JsZ5hSfJEonriDodxQMWm0TqpHEi3lveiMz1sirtGVkfbLt8F1hF-Nik40W9suT9ftiWENs4sGWYCBlxbO0cO6cUDBnVDVfr8vQVATuqv7B7nyUNdxaelg9GYdBDS1LcvFASsUtdbmfJujmDwXQna0HKl4-2ltq8XNwjTKP_pRnOv5MZOboJYdNnrYp7s03mwcy60aAUVZ7mo3U_3w3Blb_aiifeoeCmUG9xw_-ATbeXs-eW-xOr9y46qS5JWpMUR2GWInj-Tu-ilQncBknv1dhhfa6khP95OWvGSB6-GWveqpe-4N2DpcLyQXl-lIsB8En_KBwN3T77kRIw==',
  'e': 'AQAB',
  'd':
      'iOSDk78S47s0-f5Fxfftd5fBk9NXhHiBgu9zlLq_G8uLIEK_mUGNfyIHNGNvtoSWE_C6uNsjPZ1is79JN-hOSa_ZH0N60FTbe0M_fgo8ubXMYzv-N8RxACf3plS9m9IOFXVgsGCnjt-tqMFliog76WrZrPhPlV1uSVdQBFtKkbe4GiWE5qLqZ9Q_6VES9E3OdHS1uBh5ef28YJ0ju4iCaZ6m93WpOSciUpQMMrcir2nzhB48622-uBtJedK43BpELtB-HSCxyg8AY0Ym_LijhLSV5e3l0m2JjeTqIyjx6jXvyBNmyMIJnLbnt7kvQMWCzOBFQgtCgxPDTGPFJHQUYQ==',
  'p':
      '7Ze2PzDlpbIcyjsl3w01ML_jzn9r9k2KN57w8rJ65QJ7qfVuEUwQTWUCMl0A-jGEmEe3C1VDLe3OxP0BbDX_sJzIOi3HB_1r9qWyCjHlI02p8eqOZ5QJszBtJ44ViMm9o6WRGFnyYxd12EV-2NGimmwsum6l8ILPXSO6ulkJLpM=',
  'q':
      '7N_JExEvShb-YCTZthA5mbbUFI7mpYIP2W4etAAbRXuWr5-47nlCmDi28p3rUJZQavh9iFD3oealNcFYTzDIBVJX5ptdEUzEli-7pwfKU4hoO7lSTOUxcQ5e9_U-nSf0nHT6o_2ZjGbwHHBoEw7JLLWU7wxRSN5irmCBxUhdnTE=',
  'alg': 'RS256',
  'use': 'sig',
  'keyOperations': ['sign', 'verify']
};

final _jwkKey = JsonWebKey.fromJson(_testJsonWebKey);
String createIdToken(Map<String, Object?> claims) {
  final jws = (JsonWebSignatureBuilder()
        ..jsonContent = claims
        ..addRecipient(_jwkKey, algorithm: 'RS256'))
      .build();

  return jws.toCompactSerialization();
}

/// 'data:application/json;charset=utf-8;base64,eyJrZXlzIjpbeyJrdHkiOiJSU0EiLCJuIjoiMjllTng5SnNaNWhTZkpFb25yaURvZHhRTVdtMFRxcEhFaTNsdmVpTXoxc2lydEdWa2ZiTHQ4RjFoRi1OaWs0MFc5c3VUOWZ0aVdFTnM0c0dXWUNCbHhiTzBjTzZjVURCblZEVmZyOHZRVkFUdXF2N0I3bnlVTmR4YWVsZzlHWWRCRFMxTGN2RkFTc1V0ZGJtZkp1am1Ed1hRbmEwSEtsNC0ybHRxOFhOd2pUS1BfcFJuT3Y1TVpPYm9KWWRObnJZcDdzMDNtd2N5NjBhQVVWWjdtbzNVXzN3M0JsYl9haWlmZW9lQ21VRzl4d18tQVRiZVhzLWVXLXhPcjl5NDZxUzVKV3BNVVIyR1dJbmotVHUtaWxRbmNCa252MWRoaGZhNmtoUDk1T1d2R1NCNi1HV3ZlcXBlLTROMkRwY0x5UVhsLWxJc0I4RW5fS0J3TjNUNzdrUkl3PT0iLCJlIjoiQVFBQiIsImFsZyI6IlJTMjU2IiwidXNlIjoic2lnIiwia2V5T3BlcmF0aW9ucyI6WyJzaWduIiwidmVyaWZ5Il19XX0='
final _jwkUri = 'data:application/json;charset=utf-8;base64,${base64Encode(
  utf8.encode(
    jsonEncode({
      'keys': [
        Map.fromEntries(
          _testJsonWebKey.entries.where(
            (e) => const ["kty", "n", "e", "alg", "use"].contains(e.key),
          ),
        )
      ]
    }),
  ),
)}';

final jwkOverrideClient = MockClient((request) async {
  final config = {
    MicrosoftProvider.wellKnownOpenIdEndpoint(): microsoftConfig,
    TwitchProvider.wellKnownOpenIdEndpoint: twitchConfig,
    GoogleProvider.wellKnownOpenIdEndpoint: googleConfig,
    AppleProvider.wellKnownOpenIdEndpoint: appleConfig,
  }[request.url.toString()]!;

  return Response(
    jsonEncode({...config, 'jwks_uri': _jwkUri}),
    200,
    headers: jsonHeader,
  );
});

MockClient createMockClient({
  required Map<String, OAuthProvider<dynamic>> allProviders,
  required Map<String, ProviderClientMock> allProvidersMocks,
}) {
  final userEndpoints = {
    ImplementedProviders.microsoft: [
      r'https://graph.microsoft.com/v1.0/me/photos/96x96/$value',
    ],
    ImplementedProviders.discord: ['https://discord.com/api/oauth2/@me'],
    ImplementedProviders.facebook: ['https://graph.facebook.com/v16.0/me'],
    ImplementedProviders.github: [
      'https://api.github.com/applications/${allProviders[ImplementedProviders.github]!.clientId}/token',
      'https://api.github.com/user/emails',
    ],
    ImplementedProviders.reddit: [
      'https://oauth.reddit.com/api/v1/me?raw_json=1'
    ],
    ImplementedProviders.spotify: ['https://api.spotify.com/v1/me'],
    ImplementedProviders.twitter: [
      'https://api.twitter.com/1.1/account/verify_credentials.json',
      'https://api.twitter.com/2/users/me',
    ],
  }.map((key, value) => MapEntry(key, value.map(Uri.parse).toList()));

  return MockClient(
    (request) async {
      if (request.method == 'GET' ||
          request.headers[Headers.accept] == 'application/vnd.github+json') {
        // get user endpoints

        final providerId = userEndpoints.entries
            .firstWhere(
              (element) => element.value.any(
                (uri) => request.url.toString().startsWith(uri.toString()),
              ),
            )
            .key;
        final providerMock = allProvidersMocks[providerId]!;
        final provider = allProviders[providerId]!;

        return _handleGetUserEndpoint(request, provider, providerMock);
      }

      expect(request.method, 'POST');
      expect(
        request.headers[Headers.contentType],
        '${Headers.appFormUrlEncoded}; charset=utf-8',
      );
      final authorization = request.headers[Headers.authorization];
      final data = Uri.splitQueryString(request.body);
      expect(data.values.where((e) => e == 'null'), isEmpty);

      final isFacebookDeviceFlow =
          data['access_token'] == 'facebook_client_id|client_token';
      final String clientId;
      final String? clientSecret;
      if (authorization != null) {
        final authSplit = authorization.split(' ');
        expect(authSplit[0], 'Basic');
        expect(authSplit.length, 2);

        final split = utf8.decode(base64Decode(authSplit[1])).split(':');
        clientId = split[0];
        clientSecret = split[1];
      } else {
        if (isFacebookDeviceFlow) {
          clientId = 'facebook_client_id';
        } else {
          clientId = data['client_id']!;
        }
        clientSecret = data['client_secret'];
      }

      final providerId = clientId.replaceFirst('_client_id', '');
      if (clientSecret != null) {
        expect(providerId, clientSecret.replaceFirst('_client_secret', ''));
      }
      final provider = allProviders[providerId]!;
      final providerMock = allProvidersMocks[providerId]!;

      final response =
          'code refresh_token device_code username token access_token'
              .split(' ')
              .fold<Response?>(
                null,
                (prev, e) => prev ?? providerMock.identifierResponse[data[e]],
              );
      if (response != null) return response;

      final tokenEndpoint = Uri.parse(provider.tokenEndpoint);
      final deviceAuthorizationEndpoint =
          provider.deviceAuthorizationEndpoint == null
              ? null
              : Uri.parse(provider.deviceAuthorizationEndpoint!);
      final revokeTokenEndpoint = provider.revokeTokenEndpoint == null
          ? null
          : Uri.parse(provider.revokeTokenEndpoint!);

      final scopeRegExp = provider is FacebookProvider
          ? RegExp(r'^[a-z_-]+|[a-z_-]+(,[a-z_-]+)+$')
          : RegExp(r'^[a-z_-]+|[a-z_-]+( [a-z_-]+)+$');

      final isDeviceAuthorizationUrl =
          request.url.path == deviceAuthorizationEndpoint?.path;
      if (isDeviceAuthorizationUrl) {
        expect(clientSecret, isNull);
        expect(request.headers[Headers.accept], Headers.appJson);
      } else if (isFacebookDeviceFlow) {
        expect(clientSecret, isNull);
        // TODO: shold we use Headers.appFormUrlEncoded?
        expect(request.headers[Headers.accept], Headers.appJson);
      } else {
        expect(clientSecret, isNotNull);
        expect(
          request.headers[Headers.accept],
          '${Headers.appJson}, ${Headers.appFormUrlEncoded}',
        );
        expect(
          provider.authMethod,
          authorization != null
              ? HttpAuthMethod.basicHeader
              : HttpAuthMethod.formUrlencodedBody,
        );
      }

      if (request.url.path == tokenEndpoint.path ||
          (isFacebookDeviceFlow &&
              request.url.toString().startsWith(
                    'https://graph.facebook.com/v16.0/device/login_status',
                  ))) {
        final grantType = isFacebookDeviceFlow
            ? GrantType.deviceCode
            : GrantType.values
                .firstWhere((v) => v.value == data['grant_type']!);

        bool sendRefreshToken = true;
        String scope;
        switch (grantType) {
          case GrantType.authorizationCode:
            expect(data['redirect_uri'], 'http://localhost:8080/base');
            final code = data['code'];
            expect(code, isA<String>());
            final authUrl = providerMock.codeToAuthorizeUri[code];
            if (authUrl == null) {
              return Response(
                jsonEncode({'error': 'invalid_code'}),
                400,
                headers: jsonHeader,
              );
            }

            /// check code_verifier
            expect(data['code_verifier'], isA<String>());
            final digest = SHA256Digest().process(
              Uint8List.fromList(utf8.encode(data['code_verifier']!)),
            );
            expect(
              base64UrlEncode(digest).replaceAll('=', ''),
              authUrl.queryParameters['code_challenge'],
            );
            scope = authUrl.queryParameters['scope']!;

            break;
          case GrantType.refreshToken:
            final refreshToken = data['refresh_token'];
            expect(refreshToken, isA<String>());
            final value = providerMock.tokens[refreshToken]!;
            expect(value.tokenKind, 'refresh_token');
            scope = value.response.scope;
            sendRefreshToken = false;
            break;
          case GrantType.deviceCode:
            final deviceCode =
                isFacebookDeviceFlow ? data['code'] : data['device_code'];
            expect(deviceCode, isA<String>());

            // TODO: is it necessary on the header?
            if (!isFacebookDeviceFlow) expect(data['client_id'], clientId);
            // TODO: maybe send a keep polling or slow down response?

            final deviceCodeData = providerMock.deviceCodes[deviceCode]!;
            if (deviceCodeData.numPollingRequests < 2) {
              deviceCodeData.numPollingRequests++;
              if (deviceCodeData.numPollingRequests == 1) {
                return Response(
                  isFacebookDeviceFlow
                      ? facebookDeviceErrorAuthorizationPending
                      : jsonEncode({
                          'error': DeviceFlowError.authorization_pending.name,
                        }),
                  HttpStatus.unauthorized,
                  headers: jsonHeader,
                );
              } else {
                Future<dynamic>.delayed(
                  Duration.zero,
                  deviceCodeData.completer.complete,
                );
                return Response(
                  isFacebookDeviceFlow
                      ? facebookDeviceErrorSlowDown
                      : jsonEncode({'error': DeviceFlowError.slow_down.name}),
                  HttpStatus.tooManyRequests,
                  headers: jsonHeader,
                );
              }
            }
            scope = deviceCodeData.scope;
            break;
          case GrantType.password:
            // TODO: not required
            scope = data['scope']!;
            expect(scope, matches(scopeRegExp));
            expect(data['username'], isA<String>());
            expect(data['password'], isA<String>());
            // TODO: wrong password

            break;
          case GrantType.clientCredentials:
            // TODO: not required
            scope = data['scope']!;
            expect(scope, matches(scopeRegExp));
            break;
          case GrantType.jwtBearer:
          default:
            throw UnimplementedError();
        }

        final tokenResponse = TokenResponse(
          accessToken: generateStateToken(),
          expiresIn: 900,
          idToken: scope.split(RegExp('[ ,]+')).contains('openid')
              ? createIdToken({
                  // TODO: additional data specific for providers
                  // TODO: nonce and wrong nonce
                  // 'nonce': providerMock.codeToAuthorizeUri[data['code']]!
                  //     .queryParameters['nonce']!,
                  'azp': clientId,
                  'aud': [clientId],
                  // TODO: FacebookProvider with openid scope
                  'iss':
                      (provider as OpenIdConnectProvider).openIdConfig.issuer,
                  'sub': '',
                  'exp': DateTime.now()
                          .add(const Duration(days: 2))
                          .millisecondsSinceEpoch ~/
                      1000,
                  'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  ...mockUser(
                    provider,
                    grantType: grantType,
                    nonce: grantType == GrantType.deviceCode
                        ? 'NONE'
                        : providerMock.codeToAuthorizeUri[data['code']]!
                            .queryParameters['nonce']!,
                  ).openIdClaims!.toJson(),
                })
              : null,
          scope: scope,
          tokenType: 'bearer',
          refreshToken: sendRefreshToken ? generateStateToken() : null,
          expiresAt: DateTime.now(),
        );

        providerMock.tokens[tokenResponse.accessToken] =
            TokenResponseTest('access_token', grantType, tokenResponse);
        if (sendRefreshToken) {
          providerMock.tokens[tokenResponse.refreshToken!] =
              TokenResponseTest('refresh_token', grantType, tokenResponse);
        }
        return Response(
          jsonEncode(tokenResponse.toJson()..remove('expires_at')),
          200,
          headers: jsonHeader,
        );
      } else if (isDeviceAuthorizationUrl) {
        expect(data['scope'], provider.config.scope);
        if (!isFacebookDeviceFlow) {
          expect(data['client_id'], clientId);
        }

        final deviceCode = generateStateToken();
        final deviceCodeModel = DeviceCodeResponse(
          deviceCode: deviceCode,
          userCode: 'ABC-DEF',
          verificationUri: 'https://github.com/login/device',
          expiresIn: 900,
          interval: 3,
          expiresAt: DateTime.now(),
          // TODO: test
          message: null,
          verificationUriComplete: null,
        );
        expect(data['redirect_uri'], 'http://localhost:8080/base');
        providerMock.deviceCodes[deviceCode] = DeviceCodeResponseTest(
          response: deviceCodeModel,
          redirectUri: data['redirect_uri'] as String,
          scope: data['scope']!,
        );

        // TODO: test fromUrlEncoded response
        return Response(
          jsonEncode(deviceCodeModel.toJson()..remove('expires_at')),
          200,
          headers: jsonHeader,
        );
      } else if (request.url.path == revokeTokenEndpoint?.path) {
        final String token;
        if (provider is GithubProvider) {
          token = data['access_token']!;
        } else {
          token = data['token']!;
        }
        final kind = providerMock.tokens[token];
        if (kind == null) {
          return Response(
            // TODO: maybe use another error?
            jsonEncode({'error': 'invalid_token'}),
            400,
            headers: jsonHeader,
          );
        } else if (provider is GithubProvider) {
          return Response('', 204);
        } else {
          expect(data['token_type_hint'], kind);
          return Response('', 200);
        }
      }

      throw Exception(
        'Invalid request ${request.method} '
        '${request.url} ${request.headers} ${request.body}',
      );
    },
  );
}

Response _handleGetUserEndpoint(
  Request request,
  OAuthProvider<dynamic> provider,
  ProviderClientMock providerMock,
) {
  final isMicrosoftPicture = provider is MicrosoftProvider &&
      request.url.toString().startsWith(
            r'https://graph.microsoft.com/v1.0/me/photos/96x96/$value',
          );
  final isGithubUser = provider is GithubProvider &&
      !request.url.toString().startsWith('https://api.github.com/user/emails');
  if (provider is GithubProvider) {
    expect(request.method, isGithubUser ? 'POST' : 'GET');
    expect(
      request.headers[Headers.accept],
      'application/vnd.github+json',
    );
  } else if (!isMicrosoftPicture) {
    expect(request.headers[Headers.accept], Headers.appJson);
  }

  /// Authorizaiton header
  final authorization = request.headers[Headers.authorization]!.split(' ');
  expect(authorization, hasLength(2));

  final String accessToken;
  if (isGithubUser) {
    expect(authorization[0], 'Basic');
    expect(
      utf8.decode(base64Decode(authorization[1])).split(':'),
      [provider.clientId, provider.clientSecret],
    );
    expect(
      request.headers[Headers.contentType],
      // TODO: maybe use from url y github supports it
      '${Headers.appJson}; charset=utf-8',
    );
    accessToken = (jsonDecode(request.body) as Map)['access_token'] as String;
  } else {
    expect(authorization[0], 'Bearer');
    accessToken = authorization[1];
  }
  final tokenInfo = providerMock.tokens[accessToken];
  expect(tokenInfo!.tokenKind, 'access_token');
  final grantType = tokenInfo.grantType;

  // nonce is only for id_token, at the moment we do not use endpoints
  final user = mockUser(
    provider,
    nonce: 'NONE',
    grantType: grantType,
  );
  final Object? jsonData;
  if (provider is TwitterProvider) {
    final twitterUser = user as AuthUser<TwitterUserData>;
    if (request.url
        .toString()
        .startsWith('https://api.twitter.com/2/users/me')) {
      jsonData = twitterUser.providerUser.user.toJson();
    } else {
      jsonData = twitterUser.providerUser.verifyCredentials.toJson();
    }
  } else if (provider is GithubProvider) {
    final githubUser = user as AuthUser<GithubToken>;
    if (request.url
        .toString()
        .startsWith('https://api.github.com/user/emails')) {
      jsonData = [
        GithubEmail(
          email: githubUser.email!,
          primary: true,
          verified: true,
          visibility: 'public',
        ).toJson()
      ];
    } else {
      jsonData = githubUser.providerUser.toJson();
    }
  } else if (isMicrosoftPicture) {
    return Response.bytes(
      [0, 1, 2, 3],
      200,
      headers: {'content-type': 'image/png'},
    );
  } else {
    jsonData = user.toJson();
  }
  return Response(jsonEncode(jsonData), 200, headers: jsonHeader);
}

const facebookDeviceErrorAuthorizationPending =
    '{"error":{"message":"This request requires the user to take a pending action","code":31,"error_subcode":1349174,"error_user_title":"Device Login Authorization Pending","error_user_msg":"User has not yet authorized your application. Continue polling."}}';
const facebookDeviceErrorSlowDown =
    '{"error":{"message":"User request limit reached","code":17,"error_subcode":1349172,"error_user_title":"OAuth Device Excessive Polling","error_user_msg":"Your device is polling too frequently. Space your requests with a minium interval of 5 seconds."}}';
const facebookDeviceErrorSessionExpired =
    '{"error":{"message":"The session has expired""code":463,"error_subcode":1349152, "error_user_title":"Activation Code Expired","error_user_msg":"The code you entered has expired. Please go back to your device for a new code and try again."}}';
