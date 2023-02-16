import 'dart:convert';

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

abstract class Persistence {
  Future<String?> getState(String key);
  Future<void> setState(String key, String value);

  Future<void> saveUser(AuthUser user) {
    return setState(
      // TODO: provider.name may be "other" maybe use a String instead of enum
      '${user.userAppId}:${user.provider.name}',
      jsonEncode(user.toJson()),
    );
  }
}

T matchProvider<T>(
  OAuthProvider provider, {
  required T Function(OAuthProvider) other,
  T Function(AppleProvider)? apple,
  T Function(DiscordProvider)? discord,
  T Function(FacebookProvider)? facebook,
  T Function(GithubProvider)? github,
  T Function(GoogleProvider)? google,
  // T Function(linkedinProvider)? linkedin,
  T Function(MicrosoftProvider)? microsoft,
  T Function(RedditProvider)? reddit,
  // T Function(steamProvider)? steam,
  T Function(TwitterProvider)? twitter,
  T Function(SpotifyProvider)? spotify,
}) {
  if (provider is AppleProvider) {
    return (apple ?? other)(provider);
  } else if (provider is DiscordProvider) {
    return (discord ?? other)(provider);
  } else if (provider is FacebookProvider) {
    return (facebook ?? other)(provider);
  } else if (provider is GithubProvider) {
    return (github ?? other)(provider);
  } else if (provider is GoogleProvider) {
    return (google ?? other)(provider);
    // } else if (provider is linkedinProvider) {
    // return (linkedin ?? other)(provider);
  } else if (provider is MicrosoftProvider) {
    return (microsoft ?? other)(provider);
  } else if (provider is RedditProvider) {
    return (reddit ?? other)(provider);
    // } else if (provider is steamProvider) {
    // return (steam ?? other)(provider);
  } else if (provider is TwitterProvider) {
    return (twitter ?? other)(provider);
  } else if (provider is SpotifyProvider) {
    return (spotify ?? other)(provider);
  }
  return other(provider);
}

class AuthUser<T> {
  ///
  const AuthUser({
    required this.provider,
    required this.userAppId,
    this.name,
    this.profilePicture,
    this.email,
    required this.emailIsVerified,
    this.phone,
    required this.phoneIsVerified,
    required this.rawUserData,
    this.openIdClaims,
    required this.providerUser,
  });

  final SupportedProviders provider;
  final String userAppId;
  final String? name;
  final String? profilePicture;
  final String? email;
  final bool emailIsVerified;
  final String? phone;
  final bool phoneIsVerified;
  final Map<String, Object?> rawUserData;
  final OpenIdClaims? openIdClaims;
  final T providerUser;

  Map<String, Object?> toJson() => {
        ...rawUserData,
        'provider': provider.name,
        'userAppId': userAppId,
        'name': name,
        'profilePicture': profilePicture,
        'email': email,
        'emailIsVerified': emailIsVerified,
        'phone': phone,
        'phoneIsVerified': phoneIsVerified,
        'rawUserData': rawUserData,
      };
}

/// An error found when getting the user's data
class GetUserError implements Exception {
  /// The response that contains the error or that was received before the error
  final HttpResponse? response;

  /// A generic message about the error
  final String? message;

  /// The [sourceError]'s [StackTrace] or the [StackTrace] where this was created
  final StackTrace stackTrace;

  /// The source error, if any
  final Object? sourceError;

  /// The token used to create the response
  final TokenResponse token;

  /// An error found when getting the user's data
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
