import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:http/http.dart';

class ClientWithConfig {
  final Client client;
  final String baseUrl;
  final FutureOr<Request> Function(Request request)? mapRequest;
  final ResponseData<P, O> Function<P, O>(ResponseData<P, O> response)?
      mapResponse;

  ///
  ClientWithConfig({
    required this.baseUrl,
    this.mapRequest,
    this.mapResponse,
    Client? client,
  }) : client = client ?? Client();

  ClientWithConfig copyWith({
    Client? client,
    String? baseUrl,
    FutureOr<Request> Function(Request request)? mapRequest,
    ResponseData<P, O> Function<P, O>(ResponseData<P, O> response)? mapResponse,
  }) {
    return ClientWithConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      client: client ?? this.client,
      mapRequest: mapRequest ?? this.mapRequest,
      mapResponse: mapResponse ?? this.mapResponse,
    );
  }
}

class ReqParams {
  final List<String> pathSegments;
  final Object? data;
  final String? contentType;

  ///
  const ReqParams(
    this.pathSegments,
    this.data, {
    this.contentType,
  });

  static const empty = ReqParams([], null);
}

bool areTypesEqual<T, O>() => T == O;

class Endpoint<P, O> {
  final String path;
  final String method;

  final O Function(Map<String, Object?>) deserialize;
  final ReqParams Function(P) serialize;
  final Map<String, String>? headers;

  ///
  const Endpoint({
    required this.path,
    required this.method,
    required this.deserialize,
    required this.serialize,
    this.headers,
  });

  bool get isNullOutput => areTypesEqual<O, Null>() || areTypesEqual<O, void>();

  Future<ResponseData<P, O>> request(
    ClientWithConfig clientConfig,
    P params, {
    Map<String, String>? headers,
  }) async {
    final newHeaders = {
      ...?this.headers,
      ...?headers,
    };
    Uri uri = Uri.parse('${clientConfig.baseUrl}/$path');
    Object? body;
    if (params != null) {
      try {
        final reqParams = serialize(params);
        if (reqParams.contentType != null) {
          newHeaders['content-type'] = reqParams.contentType!;
        }
        if (reqParams.pathSegments.isNotEmpty) {
          uri = uri.replace(
            pathSegments: [...uri.pathSegments, ...reqParams.pathSegments],
          );
        }
        final contentType = newHeaders['content-type'];
        final payload = reqParams.data;
        if (payload != null) {
          if (method == 'GET') {
            uri = uri.replace(
              queryParameters: {
                ...uri.queryParametersAll,
                ...(payload as Map).cast()
              },
            );
          } else if (contentType == 'application/x-www-form-urlencoded') {
            // text/csv, multipart/form-data
            body = Uri(queryParameters: (payload as Map).cast()).query;
          } else if (contentType == 'application/octet-stream') {
            body = payload as List<int>;
          } else if (const ['text/plain', 'text/html'].contains(contentType)) {
            body = payload as String;
          } else {
            if (contentType == null) {
              newHeaders['content-type'] = 'application/json';
            }
            body = jsonEncode(payload);
          }
        }
      } catch (e, s) {
        final resp = ResponseData<P, O>(
          endpoint: this,
          data: null,
          param: params,
          response: null,
          error: e,
          stackTrace: s,
        );
        return clientConfig.mapResponse?.call(resp) ?? resp;
      }
    }
    Request requestData = Request(method, uri);
    if (body is String) {
      requestData.body = body;
    } else if (body is List<int>) {
      requestData.bodyBytes = body;
    }
    Response? response;
    ResponseData<P, O> resp;
    try {
      requestData.headers.addAll(newHeaders);
      if (clientConfig.mapRequest != null) {
        requestData = await clientConfig.mapRequest!(requestData);
      }
      final streamedResponse = await clientConfig.client.send(requestData);
      response = await Response.fromStream(streamedResponse);

      O? parsed;
      // ignore: prefer_void_to_null
      if (!isNullOutput) {
        final Object? body;
        if (response.headers['content-type'] ==
            'application/x-www-form-urlencoded') {
          body = Uri.splitQueryString(response.body);
        } else {
          body = jsonDecode(response.body);
        }
        parsed = deserialize(body! as Map<String, Object?>);
      }
      resp = ResponseData(
        endpoint: this,
        data: parsed,
        param: params,
        response: response,
      );
    } catch (e, s) {
      resp = ResponseData(
        endpoint: this,
        data: null,
        param: params,
        response: response,
        error: e,
        stackTrace: s,
      );
    }
    return clientConfig.mapResponse?.call(resp) ?? resp;
  }

  @override
  String toString() {
    return 'Endpoint${{
      'path': path,
      'method': method,
    }}';
  }
}

class ResponseData<P, O> implements Exception {
  final O? data;
  final P param;
  final Response? response;
  final Object? error;
  final StackTrace? stackTrace;
  final Endpoint<P, O> endpoint;

  bool get didParseBody =>
      response != null &&
      (endpoint.isNullOutput || response!.body.isNotEmpty) &&
      data is O;

  ///
  ResponseData({
    required this.endpoint,
    required this.data,
    required this.param,
    required this.response,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'ResponseData${{
      'data': data,
      'param': param,
      if (response != null)
        'response': '${{
          'statusCode': response!.statusCode,
          'reasonPhrase': response!.reasonPhrase,
          'contentLength': response!.contentLength,
          'contentType': response!.headers['content-type'],
        }..removeWhere((key, value) => value == null)}',
      'error': error,
      'stackTrace': stackTrace,
      'endpoint': endpoint,
    }..removeWhere((key, value) => value == null)}';
  }
}

/// A debouncer that can be used to debounce a [callback]
/// for [duration] by executing [get].
class Debouncer<P, T> {
  Completer<T>? _completer;
  Timer? _timer;

  /// The callback to be called when the debouncer [_timer] is done.
  final FutureOr<T> Function(P query) callback;

  /// The duration to wait before calling the [callback].
  final Duration duration;

  /// The query to be passed to the [callback].
  P? query;

  /// Creates a new [Debouncer] with the given [duration] and [callback].
  Debouncer(
    this.duration,
    this.callback,
  );

  /// Cancels the current [_timer] preventing the [callback] from executing.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _completer = null;
  }

  /// Returns a [Future] that will complete after debouncing the
  /// execution of [callback].
  ///
  /// If the [get] method is called again
  /// before the [_timer] is done, the [query] for [callback] will be updated.
  Future<T> get(P query) {
    this.query = query;
    if (_completer != null) return _completer!.future;

    final comp = Completer<T>();
    _completer = comp;
    _timer = Timer(duration, () {
      _timer = null;
      _completer = null;
      comp.complete(callback(this.query as P));
    });

    return comp.future;
  }
}
