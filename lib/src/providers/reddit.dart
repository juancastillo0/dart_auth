import 'dart:convert';

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth/src/providers/reddit_user.dart';

/// https://github.com/reddit-archive/reddit/wiki/OAuth2
class RedditProvider extends OAuthProvider<RedditUser> {
  /// https://github.com/reddit-archive/reddit/wiki/OAuth2
  const RedditProvider({
    super.providerId = ImplementedProviders.reddit,
    super.config =
        const RedditAuthParams(duration: RedditAuthDuration.permanent),
    required super.clientId,
    required super.clientSecret,
  }) : super(
          authorizationEndpoint:
              'https://www.reddit.com/api/v1/authorize', // or https://www.reddit.com/api/v1/authorize.compact for small screens
          tokenEndpoint: 'https://www.reddit.com/api/v1/access_token',
          revokeTokenEndpoint: 'https://www.reddit.com/api/v1/revoke_token',
        );

  @override
  List<GrantType> get supportedFlows => const [
        GrantType.authorizationCode,
        GrantType.refreshToken,
        GrantType.tokenImplicit,
        // https://github.com/reddit-archive/reddit/wiki/OAuth2#application-only-oauth
        GrantType.clientCredentials,
      ];

  @override
  Map<String, String?> mapAuthParamsToQueryParams(AuthParams params) {
    final values = super.mapAuthParamsToQueryParams(params);
    if (params.response_type == 'token') {
      values['duration'] = RedditAuthDuration.temporary.value;
    }
    return values;
  }

  @override
  Future<Result<AuthUser<RedditUser>, GetUserError>> getUser(
    HttpClient client,
    TokenResponse token,
  ) async {
    final response = await client
        .get(Uri.parse('https://oauth.reddit.com/api/v1/me?raw_json=1'));
    if (response.statusCode != 200) {
      return Err(GetUserError(token: token, response: response));
    }
    final userData = jsonDecode(response.body) as Map<String, Object?>;
    return Ok(parseUser(userData));
  }

  @override
  AuthUser<RedditUser> parseUser(Map<String, Object?> userData) {
    final user = RedditUser.fromJson(userData);
    return AuthUser(
      emailIsVerified: user.hasVerifiedEmail ?? false,
      phoneIsVerified: false,
      providerId: providerId,
      providerUser: user,
      rawUserData: userData,
      providerUserId: user.id,
      name: user.name,
    );
  }

  /// scope -> identity
  /// https://github.com/reddit-archive/reddit/wiki/JSON#account-implements-created
  /// https://www.reddit.com/dev/api/#GET_api_v1_me
}

class RedditAuthParams implements OAuthProviderConfig {
  ///
  const RedditAuthParams({
    required this.duration,
    this.scope = 'identity',
  });

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
  final String scope;

  @override
  Map<String, String?> toJson() {
    return {'duration': duration.value};
  }

  @override
  Map<String, String?>? baseAuthParams() => toJson();

  @override
  Map<String, String?>? baseTokenParams() => null;
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

  /// A one-time use code that may be exchanged for a bearer token.
  final String? code;

  /// This value should be the same as the one sent in the initial
  /// authorization request, and your app should verify that it is, in fact,
  /// the same. Your app may also do anything else it wishes with
  /// the state info, such as parse a portion of it to determine
  /// what action to perform on behalf of the user.
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
