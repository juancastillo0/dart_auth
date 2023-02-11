import 'package:oauth/oauth.dart';

/// https://github.com/reddit-archive/reddit/wiki/OAuth2
class RedditAuthProvider extends OAuthProvider {
  /// https://github.com/reddit-archive/reddit/wiki/OAuth2
  const RedditAuthProvider({
    required super.clientIdentifier,
    required super.clientSecret,
  }) : super(
          authorizationEndpoint:
              'https://www.reddit.com/api/v1/authorize', // or https://www.reddit.com/api/v1/authorize.compact for small screens
          tokenEndpoint: 'https://www.reddit.com/api/v1/access_token',
          revokeTokenEndpoint: 'https://www.reddit.com/api/v1/revoke_token',
        );

  @override
  HttpAuthMethod get authMethod => HttpAuthMethod.basic;
}

class RedditAuthParams with AuthParamsBaseMixin {
  ///
  RedditAuthParams({
    required this.baseAuthParams,
    required this.duration,
  });

  @override
  final AuthParams baseAuthParams;

  /// Indicates whether or not your app needs a permanent token.
  /// All bearer tokens expire after 1 hour. If you indicate you need permanent
  /// access to a user's account, you will additionally receive a refresh_token
  /// when acquiring the bearer token. You may use the refresh_token to acquire
  /// a new bearer token after your current token expires.
  /// Choose temporary if you're completing a one-time request for the user
  /// (such as analyzing their recent comments); choose permanent if you will
  /// be performing ongoing tasks for the user, such as notifying them whenever
  /// they receive a private message.
  /// The implicit grant flow does not allow permanent tokens.
  final RedditAuthDuration duration;

  /// All bearer tokens are limited in what functions they may perform.
  /// You must explicitly request access to areas of the api, such as private
  /// messaging or moderator actions. See our automatically generated API docs.
  /// Scope Values: identity, edit, flair, history, modconfig, modflair, modlog,
  /// modposts, modwiki, mysubreddits, privatemessages, read, report, save,
  /// submit, subscribe, vote, wikiedit, wikiread.
  @override
  String get scope => baseAuthParams.scope;

  @override
  Map<String, String?> toJson() {
    return {...baseAuthParams.toJson(), 'duration': duration.value};
  }
}

enum RedditAuthDuration {
  permanent('permanent'),
  temporary('temporary');

  const RedditAuthDuration(this.value);

  final String value;
}

class RedditAuthRedirect {
  ///
  RedditAuthRedirect({
    this.error,
    this.code,
    this.state,
  });

  factory RedditAuthRedirect.fromJson(Map<dynamic, dynamic> json) =>
      RedditAuthRedirect(
        error: json['error'] != null
            ? RedditAuthError.values.byName(json['error'] as String)
            : null,
        code: json['code'] as String?,
        state: json['state'] as String?,
      );

  /// See [RedditAuthError] for list of causes.
  final RedditAuthError? error;

  /// A one-time use code that may be exchanged for a bearer token. See the next step
  final String? code;

  /// This value should be the same as the one sent in the initial authorization request, and your app should verify that it is, in fact, the same. Your app may also do anything else it wishes with the state info, such as parse a portion of it to determine what action to perform on behalf of the user.
  final String? state;
}

enum RedditAuthError {
  /// User chose not to grant your app permissions
  /// Fail gracefully - let the user know you cannot continue, and be respectful of their choice to decline to use your app
  access_denied,

  /// Invalid response_type parameter in initial Authorization
  /// Ensure that the response_type parameter is one of the allowed values
  unsupported_response_type,

  /// Invalid scope parameter in initial Authorization
  /// Ensure that the scope parameter is a space-separated list of valid scopes
  invalid_scope,

  /// There was an issue with the request sent to /api/v1/authorize
  /// Double check the parameters being sent during the request to /api/v1/authorize above.
  invalid_request,
}