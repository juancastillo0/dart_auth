import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final persistence = InMemoryPersistance();
  final allProviders = {
    SupportedProviders.google: GoogleProvider(
      clientIdentifier: '',
      clientSecret: '',
    ),
  };
  const port = 8080;
  const host = 'localhost';
  final config = Config(
    allProviders: allProviders,
    persistence: persistence,
    baseRedirectUri: 'http://${host}:${port}',
  );

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(makeHandler(config));
  final server = await shelf_io.serve(handler, host, port);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
}

class InMemoryPersistance extends Persistence {
  final Map<String, String> map = {};
  @override
  Future<String?> getState(String key) async {
    return map[key];
  }

  @override
  Future<void> setState(String key, String value) async {
    map[key] = value;
  }
}

class Config {
  final Map<SupportedProviders, GoogleProvider> allProviders;
  final Persistence persistence;
  final String baseRedirectUri;

  const Config({
    required this.allProviders,
    required this.persistence,
    required this.baseRedirectUri,
  });
}

SupportedProviders? parseProvider(String? providerString) =>
    providerString != null &&
            SupportedProviders.values.any((e) => e.name == providerString)
        ? SupportedProviders.values.byName(providerString)
        : null;

final wrongProviderResponse = Response.badRequest(
  body: 'provider query parameter must be one of '
      '"${SupportedProviders.values.join('","')}"',
);

Handler makeHandler(Config config) {
  final baseRedirectUri = config.baseRedirectUri;
  Future<Response> _echoRequest(Request request) async {
    if (request.url.path == '') {
      if (request.method != 'GET') return Response.notFound(null);
      return Response.ok('<html><body></body></html>');
    } else if (request.url.path == 'oauth/callback') {
      final providerString =
          request.url.queryParameters["provider"]?.toLowerCase();
      final provider = parseProvider(providerString);
      final providerInstance = config.allProviders[provider];
      if (provider == null || providerInstance == null) {
        return wrongProviderResponse;
      }

      final authenticated = await openIdConnectHandleRedirectUri(
        request.url,
        config.persistence,
        providerInstance,
        '$baseRedirectUri/',
      );

      return Response.ok('<html><body></body></html>');
    } else if (request.url.path == 'oauth/url') {
      if (request.method != 'GET') return Response.notFound(null);
      final providerString =
          request.url.queryParameters["provider"]?.toLowerCase();
      final provider = parseProvider(providerString);
      final providerInstance = config.allProviders[provider];
      if (provider == null || providerInstance == null) {
        return wrongProviderResponse;
      }

      final uri = await openIdConnectAuthorizeUri(
        clientId: providerInstance.clientIdentifier,
        redirectUri:
            '$baseRedirectUri/oauth/callback?provider=${provider.name}',
        persistence: config.persistence,
        loginHint: request.url.queryParameters["loginHint"],
      );
      return Response.ok(uri.toString());
    }
    return Response.ok('Request for "${request.url}"');
  }

  return _echoRequest;
}
