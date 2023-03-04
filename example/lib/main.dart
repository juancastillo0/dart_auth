import 'dart:async';
import 'dart:io';

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_hotreload/shelf_hotreload.dart';

import 'auth_handler.dart';
import 'persistence.dart';
import 'shelf_helpers.dart';

void main() async {
  // ignore: unnecessary_lambdas
  withHotreload(() => init());
}

Future<HttpServer> init() async {
  final persistence = InMemoryPersistance();
  final credentials = AppCredentialsConfig.fromEnvironment();
  final allProviders = await credentials.providersMap();

  const port = 8080;
  const host = 'localhost';

  final config = Config(
    allProviders: allProviders,
    allCredentialsProviders: {
      ImplementedProviders.username: UsernamePasswordProvider(),
      'phone_no_password': IdentifierPasswordProvider.phone(
        providerId: 'phone_no_password',
        magicCodeConfig: MagicCodeConfig(
          onlyMagicCodeNoPassword: true,
          sendMagicCode: ({required identifier, required magicCode}) async {
            print('MAGIC_CODE phone_no_password: $identifier $magicCode');
            return const Ok(unit);
          },
          persistence: persistence,
        ),
      ),
      ImplementedProviders.email: IdentifierPasswordProvider.email(
        magicCodeConfig: MagicCodeConfig(
          onlyMagicCodeNoPassword: false,
          sendMagicCode: ({required identifier, required magicCode}) async {
            print('MAGIC_CODE email: $identifier $magicCode');
            return const Ok(unit);
          },
          persistence: persistence,
        ),
      ),
      ImplementedProviders.totp: TimeOneTimePasswordProvider(
        issuer: 'oauth_example',
        persistence: persistence,
      )
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

  return startServer(config);
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

/// The main configuration por the server
class Config {
  final Map<String, OAuthProvider> allProviders;
  final Map<String, CredentialsProvider> allCredentialsProviders;
  final Persistence persistence;
  final String baseRedirectUri;
  final JsonWebTokenMaker jwtMaker;

  final int port;
  final String host;

  final HttpClient client;

  /// The main configuration por the server
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
