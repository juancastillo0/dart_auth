import 'package:flutter/material.dart';

abstract class PageConfig<P, T> {
  List<String> get pathSegments;

  Widget builder(P params);
  P parseUri(Uri uri);
  UriParams toUriParams(P params);

  P? matches(Uri uri) {
    try {
      int i = 0;
      if (pathSegments.any((p) => p != uri.pathSegments[i++])) return null;
      return parseUri(uri);
    } catch (_) {
      return null;
    }
  }

  static Route<T> defaultRoute<T>(RouteSettings settings, Widget body) {
    return MaterialPageRoute<T>(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(),
        body: body,
      ),
    );
  }

  Route<T> route(P params) {
    final partial = toUriParams(params);
    return defaultRoute(
      RouteSettings(
        arguments: params,
        name: Uri(
          pathSegments: [...pathSegments, ...partial.pathParams],
          queryParameters: partial.queryParams,
        ).toString(),
      ),
      builder(params),
    );
  }
}

class UriParams implements ToUriParams {
  final List<String> pathParams;
  final Map<String, String>? queryParams;

  ///
  const UriParams(
    this.pathParams,
    this.queryParams,
  );

  @override
  UriParams toUriParams() => this;
}

abstract class ToUriParams {
  UriParams toUriParams();
}

class PageValue<P extends ToUriParams, T> extends PageConfig<P, T> {
  ///
  PageValue(
    this.pathSegments,
    this._parseUri,
    this._builder,
  );

  final Widget Function(P params) _builder;
  final P Function(Uri uri) _parseUri;

  @override
  final List<String> pathSegments;
  @override
  Widget builder(P params) => _builder(params);
  @override
  P parseUri(Uri uri) => _parseUri(uri);
  @override
  UriParams toUriParams(P params) => params.toUriParams();
}
