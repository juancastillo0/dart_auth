import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

abstract class Persistence {
  Future<String?> getState(String key);
  Future<void> setState(String key, String value);
}

class AuthUser {
  ///
  const AuthUser({
    required this.provider,
    this.name,
    this.email,
    required this.emailIsVerified,
    this.phone,
  });

  final SupportedProviders provider;
  final String? name;
  final String? email;
  final bool emailIsVerified;
  final String? phone;
}

class GetUserError implements Exception {
  /// The response that contains the error or that was received before the error
  final HttpResponse? response;

  /// A generic message about the error
  final String? message;

  /// The source error's [StackTrace] or the [StackTrace] where this was created
  final StackTrace stackTrace;

  /// The source error, if any
  final Object? sourceError;

  /// The token used to create the response
  final TokenResponse token;

  ///
  GetUserError({
    required this.token,
    required this.response,
    this.message,
    this.sourceError,
    StackTrace? stackTrace,
  }) : stackTrace = stackTrace ?? StackTrace.current;
}

/// Tries to execute [tryFunction] and returns an [Ok] with its returned value.
/// If [tryFunction] throws an exception, the [catchFunction] will be used to
/// map the error and [StackTrace] and return an [Err].
Result<T, E> tryCatch<T extends Object, E extends Object>(
  T Function() tryFunction,
  E Function(Object sourceError, StackTrace stackTrace) catchFunction,
) {
  try {
    return Ok(tryFunction());
  } catch (e, s) {
    return Err(catchFunction(e, s));
  }
}
