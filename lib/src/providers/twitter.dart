import 'dart:convert' show jsonDecode;

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

export 'package:oauth/src/providers/twitter_user.dart';
export 'package:oauth/src/providers/twitter_verify_credentials.dart';

/// https://developer.twitter.com/en/docs/authentication/oauth-2-0/user-access-token
/// https://developer.twitter.com/en/docs/authentication/oauth-2-0/authorization-code
/// https://developer.twitter.com/en/docs/authentication/guides/v2-authentication-mapping
class TwitterProvider extends OAuthProvider<TwitterUserData> {
  /// https://developer.twitter.com/en/docs/authentication/oauth-2-0/user-access-token
  /// https://developer.twitter.com/en/docs/authentication/oauth-2-0/authorization-code
  /// https://developer.twitter.com/en/docs/authentication/guides/v2-authentication-mapping
  const TwitterProvider({
    super.providerId = ImplementedProviders.twitter,
    required super.clientId,
    required super.clientSecret,
    super.config = const OAuthProviderConfig(
      scope: 'users.read tweet.read offline.access',
    ),
  }) : super(
          // TODO: response_type=code&code_challenge=dwdwa&code_challenge_method=plain
          authorizationEndpoint: 'https://twitter.com/i/oauth2/authorize',
          tokenEndpoint: 'https://api.twitter.com/2/oauth2/token',
          // App only bearer token https://developer.twitter.com/en/docs/authentication/api-reference/invalidate_bearer_token
          // https://api.twitter.com/oauth2/invalidate_token
          revokeTokenEndpoint: 'https://api.twitter.com/2/oauth2/revoke',
        );

  @override
  List<GrantType> get supportedFlows =>
      // S256 OR plain
      const [
        GrantType.authorizationCode,
        GrantType.refreshToken,
        // App only bearer token https://developer.twitter.com/en/docs/authentication/api-reference/invalidate_bearer_token
        // revoke https://api.twitter.com/oauth2/invalidate_token
        // https://developer.twitter.com/en/docs/authentication/api-reference/token
        GrantType.clientCredentials,
      ];

  /// The default user fields for url: "https://api.twitter.com/2/users/me",
  /// https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-me
  static const defaultUserFields =
      'created_at,description,entities,id,location,name,pinned_tweet_id,profile_image_url,protected,public_metrics,url,username,verified,verified_type,withheld';

  @override
  Future<Result<AuthUser<TwitterUserData>, GetUserError>> getUser(
    HttpClient client,
    TokenResponse token, {
    String userFields = defaultUserFields,
  }) async {
    /// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
    final responseEmailFuture = client.get(
      Uri.parse('https://api.twitter.com/1.1/account/verify_credentials.json')
          .replace(
        queryParameters: const TwitterVerifyCredentialsParams(
          include_email: true,
          include_entities: false,
          skip_status: false,
        ).toJson(),
      ),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.access_token}',
      },
    );
    final response = await client.get(
      Uri.parse('https://api.twitter.com/2/users/me?user.fields=$userFields'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.access_token}',
      },
    );

    final responseEmail = await responseEmailFuture;
    if (response.statusCode != 200) {
      return Err(GetUserError(response: response, token: token));
    }
    if (responseEmail.statusCode != 200) {
      return Err(GetUserError(response: responseEmail, token: token));
    }
    final userData = jsonDecode(response.body) as Map;
    final verifyCredentialsData = jsonDecode(responseEmail.body) as Map;

    return Ok(
      parseUser({
        'user': userData,
        'verifyCredentials': verifyCredentialsData,
      }),
    );
  }

  /// Get user email https://stackoverflow.com/questions/22627083/can-we-get-email-id-from-twitter-oauth-api
  /// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
  @override
  AuthUser<TwitterUserData> parseUser(Map<String, Object?> json) {
    final user = TwitterUser.fromJson(json['user']! as Map);
    final verifyCredentials =
        TwitterVerifyCredentials.fromJson(json['verifyCredentials']! as Map);
    return AuthUser(
      emailIsVerified: verifyCredentials.email != null,
      phoneIsVerified: false,
      providerId: providerId,
      providerUserId: user.id,
      email: verifyCredentials.email,
      name: user.name,
      profilePicture: user.profile_image_url ??
          verifyCredentials.profile_image_url_https ??
          verifyCredentials.profile_image_url,
      rawUserData: json,
      providerUser: TwitterUserData(
        user: user,
        verifyCredentials: verifyCredentials,
      ),
    );
  }
}

/// https://developer.twitter.com/en/docs/twitter-api/data-dictionary/object-model/user
/// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
class TwitterUserData {
  /// https://developer.twitter.com/en/docs/twitter-api/data-dictionary/object-model/user
  final TwitterUser user;

  /// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
  final TwitterVerifyCredentials verifyCredentials;

  /// https://developer.twitter.com/en/docs/twitter-api/data-dictionary/object-model/user
  const TwitterUserData({
    required this.verifyCredentials,
    required this.user,
  });

  Map<String, Object?> toJson() => {
        'user': user,
        'verifyCredentials': verifyCredentials,
      };
}
