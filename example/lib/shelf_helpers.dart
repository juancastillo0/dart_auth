import 'dart:convert' show jsonDecode;

import 'package:oauth/oauth.dart';
import 'package:shelf/shelf.dart';

Map<String, String> get jsonHeader => {Headers.contentType: Headers.appJson};

const _jwtMakerKey = 'package:dart_auth.jwtMaker';

RequestCtx ctx(Request request) => request.context[_jwtMakerKey] as RequestCtx;

Handler ctxMiddleware(Handler next) {
  return (request) {
    final responseHeaders = <String, List<String>>{};
    final value = RequestCtx(
      request.headers,
      (name, value) => responseHeaders.putIfAbsent(name, () => []).add(value),
    );
    final newRequest = request.change(context: {_jwtMakerKey: value});

    Response mapResponse(Response value) {
      return value.change(
        context: {_jwtMakerKey: value},
        headers: responseHeaders.isEmpty
            ? null
            : (responseHeaders
              ..addEntries(value.headersAll.entries.map((e) {
                final l = responseHeaders[e.key];
                return l == null ? e : MapEntry(e.key, [...e.value, ...l]);
              }).toList())),
      );
    }

    try {
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
}

Future<Object?> parseBodyOrUrlData(Request request) async {
  if (request.method == 'HEAD' ||
      request.method == 'GET' ||
      request.method == 'OPTIONS') {
    final params = request.url.queryParameters;
    try {
      if (params.isEmpty && request.url.fragment.isNotEmpty) {
        return Uri.splitQueryString(request.url.fragment);
      }
    } catch (_) {}
    return params;
  } else {
    final data = await request.readAsString();
    if (request.mimeType == Headers.appFormUrlEncoded) {
      return Uri.splitQueryString(data);
    }
    if (data.isEmpty) return null;
    // application/vnd.github+json
    return jsonDecode(data);
  }
}
