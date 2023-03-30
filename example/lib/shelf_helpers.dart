import 'dart:io';

import 'package:oauth/endpoint_models.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth_example/auth_handler.dart';
import 'package:oauth_example/main.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

extension ShelfRequestExtension on Resp {
  Response toShelf(Translations translations) {
    if (innerResponse != null) {
      return innerResponse! as Response;
    }
    final body = ok ?? err;
    return Response(
      statusCode,
      body: body == null ? null : jsonEncodeWithTranslate(body, translations),
      headers: body == null ? null : {Headers.contentType: Headers.appJson},
    );
  }
}

const _jwtMakerKey = 'package:dart_auth.jwtMaker';

RequestCtx requestCtx(Request request) =>
    request.context[_jwtMakerKey]! as RequestCtx;

SessionClientData shelfSessionClientData(RequestCtx ctx) {
  final connectionInfo = (ctx.innerRequest as Request)
      .context['shelf.io.connection_info']! as HttpConnectionInfo;
  final remoteAddress = connectionInfo.remoteAddress;

  final base = Config.defaultSessionClientData(ctx);
  return base.merge(
    SessionClientData(
      ipAddress: remoteAddress.address,
      host: remoteAddress.host,
    ),
  );
}

Middleware authMiddleware(Config config) {
  final authHandler = makeHandler(
    config,
    webSocketHandler: (callback) {
      final wsHandler = webSocketHandler(callback);
      return (request) {
        return wsHandler(request.innerRequest as Request);
      };
    },
  );

  return (Handler next) {
    return (request) async {
      final responseHeaders = <String, List<String>>{};
      // request.read();
      // request.isEmpty;
      // request.mimeType;
      // request.encoding;
      final req = RequestCtx(
        innerRequest: request,
        headersAll: request.headersAll,
        appendResponseHeader: (name, value) =>
            responseHeaders.putIfAbsent(name, () => []).add(value),
        method: request.method,
        readAsString: request.readAsString,
        url: request.requestedUri,
      );

      Future<Response> mapResponse(Response value) async {
        if (value.statusCode == 404) {
          // TODO: maybe split this into a separate handler
          final authResponse = await authHandler(req);
          if (authResponse != null) {
            final translations = config.getTranslationForLanguage(
              request.headersAll[Headers.acceptLanguage],
            );
            // ignore: parameter_assignments
            value = authResponse.toShelf(translations);
          }
        }
        return value.change(
          context: {_jwtMakerKey: value},
          headers: responseHeaders.isEmpty
              ? null
              : (responseHeaders
                ..addEntries(
                  value.headersAll.entries.map((e) {
                    final l = responseHeaders[e.key];
                    return l == null ? e : MapEntry(e.key, [...e.value, ...l]);
                  }).toList(),
                )),
        );
      }

      try {
        final newRequest = request.change(context: {_jwtMakerKey: req});
        final response = next(newRequest);
        if (response is Response) {
          return mapResponse(response);
        }
        return response
            .then(mapResponse)
            .onError<Response>((error, stackTrace) => error);
      } on Response catch (e) {
        return e;
      }
    };
  };
}
