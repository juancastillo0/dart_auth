/// Support for doing something awesome.
///
/// More dartdocs go here.
library oauth;

import 'package:http/http.dart' as http;

export 'package:oxidized/oxidized.dart';

export 'src/backend_translation.dart' show Translation;
export 'src/client.dart';
export 'src/data.dart';
export 'src/jwt_and_sessions.dart';
export 'src/oauth_base.dart';
export 'src/username_password_provider.dart';

typedef HttpClient = http.Client;
typedef HttpResponse = http.Response;

extension CollectionExtension<T> on Iterable<T> {
  /// Returns the first element satisfying the given [predicate], or `null` if
  /// no such element is found.
  T? firstWhereOrNull(bool Function(T element) predicate) {
    for (final element in this) {
      if (predicate(element)) return element;
    }
    return null;
  }

  /// Returns the first element, or `null` if the collection is empty.
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
