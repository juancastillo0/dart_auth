import 'dart:async';
import 'dart:io';

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'auth_handler.dart';
import 'credentials.dart';
import 'persistence.dart';
import 'shelf_helpers.dart';

void main() async {
  final persistence = InMemoryPersistance();
  final credentials = AppCredentialsConfig.fromEnvironment();
  final allProviders = await credentials.providersMap();

  const port = 8080;
  const host = 'localhost';

  final config = Config(
    allProviders: allProviders,
    allCredentialsProviders: {
      ImplementedProviders.username: UsernamePasswordProvider(),
    },
    persistence: persistence,
    host: host,
    port: port,
    baseRedirectUri: 'http://${host}:${port}',
    jwtMaker: JsonWebTokenMaker(
      issuer: Uri.parse('oauth_example'),
      // TODO:
      base64Key: Platform.environment['JWT_KEY']!,
      userFromClaims: (claims) => claims,
    ),
  );

  await startServer(config);
}

Future<HttpServer> startServer(Config config) async {
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(ctxMiddleware)
      .addHandler(makeHandler(config));
  final server = await shelf_io.serve(handler, config.host, config.port);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
  return server;
}

class Config {
  final Map<String, OAuthProvider> allProviders;
  final Map<String, CredentialsProvider> allCredentialsProviders;
  final Persistence persistence;
  final String baseRedirectUri;
  final JsonWebTokenMaker jwtMaker;

  final int port;
  final String host;

  final HttpClient client;

  Config({
    required this.allProviders,
    required this.allCredentialsProviders,
    required this.persistence,
    required this.baseRedirectUri,
    required this.jwtMaker,
    required this.port,
    required this.host,
    HttpClient? client,
  }) : client = client ?? HttpClient();
}

Map<String, Object?> providerToJson(OAuthProvider e) {
  return {
    'providerId': e.providerId,
    'defaultScopes': e.defaultScopes,
    'openIdConnectSupported': e.defaultScopes.contains('openid'),
    'deviceCodeFlowSupported': e.supportedFlows.contains(GrantType.deviceCode),
    'implicitFlowSupported': e.supportedFlows.contains(GrantType.tokenImplicit)
  };
}
