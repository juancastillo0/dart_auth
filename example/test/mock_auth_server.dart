import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:jose/jose.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth_example/shelf_helpers.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:test/test.dart';

import 'open_id_connect_configs.dart';

class ProviderClientMock {
  final OAuthProvider provider;
  final tokens = <String, MapEntry<String, TokenResponse>>{};
  final codeToAuthorizeUri = <String, Uri>{};
  final deviceCodes = <String, DeviceCodeResponseTest>{};

  final identifierResponse = <String, Response>{};

  ProviderClientMock(this.provider);
}

class DeviceCodeResponseTest {
  final String scope;
  final DeviceCodeResponse response;
  final String? redirectUri;

  DeviceCodeResponseTest({
    required this.scope,
    required this.response,
    required this.redirectUri,
  });
}

const _testJsonWebKey = {
  "kty": "RSA",
  "n":
      "29eNx9JsZ5hSfJEonriDodxQMWm0TqpHEi3lveiMz1sirtGVkfbLt8F1hF-Nik40W9suT9ftiWENs4sGWYCBlxbO0cO6cUDBnVDVfr8vQVATuqv7B7nyUNdxaelg9GYdBDS1LcvFASsUtdbmfJujmDwXQna0HKl4-2ltq8XNwjTKP_pRnOv5MZOboJYdNnrYp7s03mwcy60aAUVZ7mo3U_3w3Blb_aiifeoeCmUG9xw_-ATbeXs-eW-xOr9y46qS5JWpMUR2GWInj-Tu-ilQncBknv1dhhfa6khP95OWvGSB6-GWveqpe-4N2DpcLyQXl-lIsB8En_KBwN3T77kRIw==",
  "e": "AQAB",
  "d":
      "iOSDk78S47s0-f5Fxfftd5fBk9NXhHiBgu9zlLq_G8uLIEK_mUGNfyIHNGNvtoSWE_C6uNsjPZ1is79JN-hOSa_ZH0N60FTbe0M_fgo8ubXMYzv-N8RxACf3plS9m9IOFXVgsGCnjt-tqMFliog76WrZrPhPlV1uSVdQBFtKkbe4GiWE5qLqZ9Q_6VES9E3OdHS1uBh5ef28YJ0ju4iCaZ6m93WpOSciUpQMMrcir2nzhB48622-uBtJedK43BpELtB-HSCxyg8AY0Ym_LijhLSV5e3l0m2JjeTqIyjx6jXvyBNmyMIJnLbnt7kvQMWCzOBFQgtCgxPDTGPFJHQUYQ==",
  "p":
      "7Ze2PzDlpbIcyjsl3w01ML_jzn9r9k2KN57w8rJ65QJ7qfVuEUwQTWUCMl0A-jGEmEe3C1VDLe3OxP0BbDX_sJzIOi3HB_1r9qWyCjHlI02p8eqOZ5QJszBtJ44ViMm9o6WRGFnyYxd12EV-2NGimmwsum6l8ILPXSO6ulkJLpM=",
  "q":
      "7N_JExEvShb-YCTZthA5mbbUFI7mpYIP2W4etAAbRXuWr5-47nlCmDi28p3rUJZQavh9iFD3oealNcFYTzDIBVJX5ptdEUzEli-7pwfKU4hoO7lSTOUxcQ5e9_U-nSf0nHT6o_2ZjGbwHHBoEw7JLLWU7wxRSN5irmCBxUhdnTE=",
  "alg": "RS256",
  "use": "sig",
  "keyOperations": ["sign", "verify"]
};

final _jwkKey = JsonWebKey.fromJson(_testJsonWebKey);
String createIdToken(Map<String, Object?> claims) {
  final jws = (JsonWebSignatureBuilder()
        ..jsonContent = claims
        ..addRecipient(_jwkKey, algorithm: 'RS256'))
      .build();

  return jws.toCompactSerialization();
}

/// 'data:eyJrZXlzIjpbeyJrdHkiOiJSU0EiLCJuIjoiMjllTng5SnNaNWhTZkpFb25yaURvZHhRTVdtMFRxcEhFaTNsdmVpTXoxc2lydEdWa2ZiTHQ4RjFoRi1OaWs0MFc5c3VUOWZ0aVdFTnM0c0dXWUNCbHhiTzBjTzZjVURCblZEVmZyOHZRVkFUdXF2N0I3bnlVTmR4YWVsZzlHWWRCRFMxTGN2RkFTc1V0ZGJtZkp1am1Ed1hRbmEwSEtsNC0ybHRxOFhOd2pUS1BfcFJuT3Y1TVpPYm9KWWRObnJZcDdzMDNtd2N5NjBhQVVWWjdtbzNVXzN3M0JsYl9haWlmZW9lQ21VRzl4d18tQVRiZVhzLWVXLXhPcjl5NDZxUzVKV3BNVVIyR1dJbmotVHUtaWxRbmNCa252MWRoaGZhNmtoUDk1T1d2R1NCNi1HV3ZlcXBlLTROMkRwY0x5UVhsLWxJc0I4RW5fS0J3TjNUNzdrUkl3PT0iLCJlIjoiQVFBQiIsImFsZyI6IlJTMjU2IiwidXNlIjoic2lnIiwia2V5T3BlcmF0aW9ucyI6WyJzaWduIiwidmVyaWZ5Il19XX0='
final _jwkUri = 'data:${base64Encode(
  utf8.encode(jsonEncode({
    'keys': [
      Map.fromEntries(_testJsonWebKey.entries
          .where((e) => const ["kty", "n", "e", "alg", "use"].contains(e.key)))
    ]
  })),
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
  return MockClient(
    (request) async {
      expect(request.method, 'POST');
      expect(
        request.headers[Headers.contentType],
        Headers.appFormUrlEncoded + '; charset=utf-8',
      );
      expect(
        request.headers[Headers.accept],
        '${Headers.appJson}, ${Headers.appFormUrlEncoded}',
      );
      final authorization = request.headers[Headers.authorization];
      final data = Uri.splitQueryString(request.body);
      expect(data.values.where((e) => e == 'null'), isEmpty);

      final String clientId;
      final String clientSecret;
      if (authorization != null) {
        final authSplit = authorization.split(' ');
        expect(authSplit[0], 'Basic');
        expect(authSplit.length, 2);

        final split = utf8.decode(base64Decode(authSplit[1])).split(':');
        clientId = split[0];
        clientSecret = split[1];
      } else {
        clientId = data['client_id']!;
        clientSecret = data['client_secret']!;
      }

      final providerId = clientId.replaceFirst('_client_id', '');
      expect(providerId, clientSecret.replaceFirst('_client_secret', ''));
      final provider = allProviders[providerId]!;
      final providerMock = allProvidersMocks[providerId]!;

      expect(
        provider.authMethod,
        authorization != null
            ? HttpAuthMethod.basicHeader
            : HttpAuthMethod.formUrlencodedBody,
      );
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

      if (request.url.path == tokenEndpoint.path) {
        final grantType =
            GrantType.values.firstWhere((v) => v.value == data['grant_type']!);

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
                Uint8List.fromList(utf8.encode(data['code_verifier']!)));
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
            expect(value.key, 'refresh_token');
            scope = value.value.scope;
            sendRefreshToken = false;
            break;
          case GrantType.deviceCode:
            final deviceCode = data['device_code'];
            expect(deviceCode, isA<String>());

            // TODO: is it necessary on the header?
            expect(data['client_id'], clientId);
            // TODO: maybe send a keep polling or slow down response?

            final deviceCodeData = providerMock.deviceCodes[deviceCode]!;
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
          access_token: generateStateToken(),
          expires_in: 900,
          id_token: scope.split(RegExp('[ ,]+')).contains('openid')
              ? createIdToken({
                  // TODO: additional data specific for providers
                  // TODO: nonce and wrong nonce
                  'nonce': providerMock.codeToAuthorizeUri[data['code']]!
                      .queryParameters['nonce']!,
                  'azp': clientId,
                  'aud': [clientId],
                  'iss':
                      (provider as OpenIdConnectProvider).openIdConfig.issuer,
                  'sub': '',
                  'exp': DateTime.now()
                          .add(const Duration(days: 2))
                          .millisecondsSinceEpoch ~/
                      1000,
                  'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                })
              : null,
          scope: scope,
          token_type: 'bearer',
          refresh_token: sendRefreshToken ? generateStateToken() : null,
          expires_at: DateTime.now(),
        );

        providerMock.tokens[tokenResponse.access_token] =
            MapEntry('access_token', tokenResponse);
        if (sendRefreshToken) {
          providerMock.tokens[tokenResponse.refresh_token!] =
              MapEntry('refresh_token', tokenResponse);
        }
        return Response(
          jsonEncode(tokenResponse.toJson()..remove('expires_at')),
          200,
          headers: jsonHeader,
        );
      } else if (request.url.path == deviceAuthorizationEndpoint?.path) {
        expect(data['scope'], provider.config.scope);
        expect(data['client_id'], clientId);

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
