import 'dart:async';
import 'dart:io';

import 'package:oauth/endpoint_models.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth_example/credentials.dart';
import 'package:oauth_example/rate_limit.dart';
import 'package:oauth_example/rate_limits_config.dart';
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
    baseRedirectUri: 'http://${host}:${port}',
    translations: const [
      Translations.defaultEnglish,
      Translations.defaultSpanish,
    ],
    sessionClientDataFromRequest: shelfSessionClientData,
    jwtMaker: JsonWebTokenMaker(
      issuer: Uri.parse('oauth_example'),
      // TODO:
      base64Key: Platform.environment['JWT_KEY']!,
      userFromClaims: (claims) => claims,
    ),
  );

  return startServer(config, host: host, port: port);
}

Future<HttpServer> startServer(
  Config config, {
  required String host,
  required int port,
}) async {
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(authMiddleware(config))
      .addHandler(
        (request) => request.url.path == '' && request.method == 'GET'
            ? Response.ok('<html><body></body></html>')
            : Response.notFound(null),
      );
  final server = await shelf_io.serve(handler, host, port);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
  return server;
}

/// The main configuration for the server
class Config {
  final Map<String, OAuthProvider<Object?>> allOAuthProviders;
  final Map<String, CredentialsProvider<CredentialsData, Object?>>
      allCredentialsProviders;
  late final Map<String, AuthenticationProvider<Object?>> allProviders;

  /// The text translations used for localizing the server responses
  final List<Translations> translations;

  /// The persistence used for the server
  final Persistence persistence;

  /// The base redirect uri used for oauth
  final String baseRedirectUri;

  /// The JsonWebToken maker used to create and verify tokens
  final JsonWebTokenMaker jwtMaker;

  /// A function that returns the session client data from the request
  final FutureOr<SessionClientData> Function(RequestCtx)
      sessionClientDataFromRequest;

  /// The rate limiter used for the server with [rateLimits]
  final RateLimiter rateLimiter;

  /// The default rate limits for the server by [rateLimiter]
  final RateLimits rateLimits;

  /// A function that returns the identifiers from the request
  /// used for rate limiting in [rateLimiter]
  final FutureOr<List<String>> Function(Config config, RequestCtx request)
      identifiersFromRequest;

  /// The http client used to make requests to other services
  final HttpClient client;

  /// The main configuration for the server
  Config({
    required this.allOAuthProviders,
    required this.allCredentialsProviders,
    required this.persistence,
    required this.baseRedirectUri,
    required this.jwtMaker,
    RateLimiter? rateLimiter,
    this.rateLimits = const RateLimits(),
    this.identifiersFromRequest = defaultIdentifiersFromRequest,
    this.translations = const [Translations.defaultEnglish],
    this.sessionClientDataFromRequest = defaultSessionClientData,
    HttpClient? client,
  })  : client = client ?? HttpClient(),
        rateLimiter = rateLimiter ?? PersistenceRateLimiter(persistence) {
    _validate();
  }

  static Future<Config> fromJson(
    Persistence persistence,
    Map<String, Object?> json, {
    RateLimiter? rateLimiter,
    HttpClient? client,
    FutureOr<List<String>> Function(Config config, RequestCtx request)
        identifiersFromRequest = defaultIdentifiersFromRequest,
    FutureOr<SessionClientData> Function(RequestCtx)
        sessionClientDataFromRequest = defaultSessionClientData,
  }) async {
    // TODO: refresh configuration state
    final jwtMaker = json['jwtMaker']! as Map<String, Object?>;
    final issuer = json['issuer']! as String;

    return Config(
      allOAuthProviders: await AppCredentialsConfig.fromJson(
        json['oAuthProviders']! as Map<String, Object?>,
      ).providersMap(),
      allCredentialsProviders: {},
      persistence: persistence,
      baseRedirectUri: json['baseRedirectUri']! as String,
      jwtMaker: JsonWebTokenMaker(
        base64Key: jwtMaker['base64Key']! as String,
        keyId: jwtMaker['keyId'] as String?,
        issuer: Uri.parse(issuer),
        userFromClaims: (claims) => null,
      ),
      client: client,
      identifiersFromRequest: identifiersFromRequest,
      sessionClientDataFromRequest: sessionClientDataFromRequest,
      rateLimiter: rateLimiter,
      rateLimits: json['rateLimits'] == null
          ? const RateLimits()
          : RateLimits.fromJson(json['rateLimits']! as Map<String, Object?>),
      // TODO: transaltions
    );
  }

  // TODO: fromPersistence

  void _validate() {
    allProviders = {...allOAuthProviders, ...allCredentialsProviders};
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

  static SessionClientData defaultSessionClientData(RequestCtx ctx) {
    final headers = ctx.headersAll;

    return SessionClientData(
      // TODO: maybe pass the list
      ipAddress: headers['x-forwarded-for']?.firstOrNull ??
          headers['x-real-ip']?.firstOrNull ??
          headers['x-client-ip']?.firstOrNull ??
          headers['x-cluster-client-ip']?.firstOrNull ??
          headers['x-forwarded']?.firstOrNull,
      host: headers['x-forwarded-host']?.firstOrNull ??
          headers['x-forwarded-server']?.firstOrNull ??
          headers['host']?.firstOrNull,
      country: headers['country']?.firstOrNull,
      // Standard headers
      userAgent: headers['user-agent']?.firstOrNull,
      languages: headers[Headers.acceptLanguage],
      // Own headers
      apiVersion: headers['auth-api-v']?.firstOrNull,
      deviceId: headers['device-id']?.firstOrNull,
      platform: headers['platform']?.firstOrNull,
      timezone: headers['timezone']?.firstOrNull,
    );
  }

  /// Returns the identifiers for a request used in rate limiting.
  ///
  /// The default implementation returns:
  /// - [SessionClientData.ipAddress]
  /// - [SessionClientData.deviceId]
  /// - [UserClaims.userId] or [UserClaims.sessionId]
  ///
  static Future<List<String>> defaultIdentifiersFromRequest(
    Config config,
    RequestCtx request,
  ) async {
    final clientData = await config.sessionClientDataFromRequest(request);
    final claims = await config.jwtMaker.getUserClaims(request);
    return [
      if (clientData.ipAddress != null) clientData.ipAddress!,
      // TODO: take deviceId From claims or session
      if (clientData.deviceId != null) clientData.deviceId!,
      if (claims?.userId != null && claims!.userId.isNotEmpty)
        claims.userId
      else if (claims?.sessionId != null)
        claims!.sessionId,
    ];
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
        // TODO: country code
      }
    }
    return translations.first;
  }
}
