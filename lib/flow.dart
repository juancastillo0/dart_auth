import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:oauth/oauth.dart';
import 'package:oauth/src/openid_configuration.dart';
import 'package:oauth/src/providers/google.dart';

Future<OpenIdConfiguration> retrieveConfiguration(String wellKnown) async {
  final client = http.Client();
  final responseMetadata = await client.get(Uri.parse(wellKnown));

  if (responseMetadata.statusCode > 300) {
    throw Error();
  }
  final json = jsonDecode(responseMetadata.body) as Map;
  final config = OpenIdConfiguration.fromJson(json);
  return config;
}

Future<Uri> openIdConnectAuthorizeUri({
  required String clientId,
  required String redirectUri,
  required Persistence persistence,
  String? loginHint,
}) async {
  const wellKnown =
      'https://accounts.google.com/.well-known/openid-configuration';
  final config = await retrieveConfiguration(wellKnown);
  final state = generateStateToken();
  final nonce = generateStateToken();
  final params = GoogleAuthParams(
    client_id: clientId,
    state: state,
    redirect_uri: redirectUri,
    response_type: 'code',
    scope: 'openid email profile',
    access_type: 'offline',
    login_hint: loginHint,
    nonce: nonce,
  );
  final uri = Uri.parse(config.authorizationEndpoint)
      .replace(queryParameters: params.toJson());

  await persistence.setState(state, nonce);
  return uri;
}

Future<GoogleSuccessAuth> openIdConnectHandleRedirectUri(
  Uri uri,
  Persistence persistence,
  OAuthProvider provider,
  String redirectUri,
) async {
  final code = uri.queryParameters['code'];
  final state = uri.queryParameters['state'];
  final GoogleAuthError? error = uri.queryParameters['error'];
  if (error != null) {
    throw Exception(error);
  }
  if (code == null || state == null) {
    throw Error();
  }
  final nonce = await persistence.getState(state);
  if (nonce == null) {
    throw Error();
  }

  final client = http.Client();

  final responseToken = await client.post(
    Uri.parse(provider.tokenEndpoint),
    body: GoogleTokenParams(
      client_id: provider.clientIdentifier,
      client_secret: provider.clientSecret,
      code: code,
      grant_type: 'authorization_code',
      redirect_uri: redirectUri,
    ).toJson(),
  );

  if (responseToken.statusCode > 300) {
    throw Error();
  }
  final tokenBody = jsonDecode(responseToken.body);
  final token = GoogleTokenResponse.fromJson(
    (tokenBody is List ? tokenBody[0] : tokenBody) as Map,
  );
  // TODO: validate token https://developers.google.com/identity/openid-connect/openid-connect#validatinganidtoken
  final claims = GoogleClaims.fromJson(jsonDecode(token.id_token) as Map);
  if (claims.nonce == null || claims.nonce != nonce) {
    throw Error();
  }
  return GoogleSuccessAuth(
    token: token,
    claims: claims,
  );
}
