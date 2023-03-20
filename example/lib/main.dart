import 'dart:async';
import 'dart:io';

import 'package:oauth/endpoint_models.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth_example/auth_handler.dart';
import 'package:oauth_example/shelf_helpers.dart';
import 'package:oauth_example/sql_database_persistence.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:sqlite3/sqlite3.dart';

void main() async {
  // ignore: unnecessary_lambdas
  withHotreload(() => init());
}

Future<HttpServer> init() async {
  final allCredentialsProviders =
      <String, CredentialsProvider<CredentialsData, dynamic>>{};
  final persistence = await SQLitePersistence(
    database: sqlite3.open('./database.sqlite3'),
    providers: allCredentialsProviders,
  ).init();
  // final credentials = AppCredentialsConfig.fromEnvironment();
  // final allProviders = await credentials.providersMap();

  const port = 3000;
  const host = 'localhost';

  allCredentialsProviders.addAll({
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
  });

  final config = Config(
    allOAuthProviders: {},
    allCredentialsProviders: allCredentialsProviders,
    persistence: persistence,
    host: host,
    port: port,
    baseRedirectUri: 'http://${host}:${port}',
    translations: const [
      Translations.defaultEnglish,
      Translations.defaultSpanish,
    ],
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

/// The main configuration for the server
class Config {
  final Map<String, OAuthProvider> allOAuthProviders;
  final Map<String, CredentialsProvider> allCredentialsProviders;
  final List<Translations> translations;
  final Persistence persistence;
  final String baseRedirectUri;
  final JsonWebTokenMaker jwtMaker;

  final int port;
  final String host;

  final HttpClient client;

  /// The main configuration for the server
  Config({
    required this.allOAuthProviders,
    required this.allCredentialsProviders,
    required this.persistence,
    required this.baseRedirectUri,
    required this.jwtMaker,
    required this.port,
    required this.host,
    this.translations = const [Translations.defaultEnglish],
    HttpClient? client,
  }) : client = client ?? HttpClient() {
    _validate();
  }

  void _validate() {
    final allProviders = {...allOAuthProviders, ...allCredentialsProviders};
    if (allProviders.length !=
        allOAuthProviders.length + allCredentialsProviders.length) {
      throw Exception(
        'Duplicate authentication provider ids found.'
        '\n$allOAuthProviders\n$allCredentialsProviders',
      );
    }
    final wrongProviderId = allProviders.entries
        .where(
          (e) =>
              e.key != e.value.providerId ||
              !AuthenticationProvider.providerIdRegExp.hasMatch(e.key),
        )
        .toList();
    if (wrongProviderId.isNotEmpty) {
      throw Exception('Wrong provider ids $wrongProviderId.');
    }
    if (translations.isEmpty) {
      throw Exception(
        'Can not have an empty translations list.'
        ' You could use Translations.defaultEnglish as a default.',
      );
    }
  }

  /// Retrieves the [Translations] from [translations] given the [languages]
  /// in a https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language header
  /// format.
  ///
  /// Returns the first translation if no [languages] matches any of
  /// the supported [translations].
  Translations getTranslationForLanguage(List<String>? languages) {
    if (languages == null || languages.isEmpty) {
      return translations.first;
    }
    for (final lang in languages) {
      final langKey = lang.split(';').first.split('-').first.toLowerCase();
      for (final translation in translations) {
        if (translation.languageCode == langKey) {
          return translation;
        }
      }
    }
    return translations.first;
  }
}
