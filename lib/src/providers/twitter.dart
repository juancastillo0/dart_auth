import 'dart:convert' show jsonDecode;

import 'package:oauth/oauth.dart';
import 'package:oauth/src/providers/twitter_user.dart';
import 'package:oauth/src/providers/twitter_verify_credentials.dart';

/// https://developer.twitter.com/en/docs/authentication/oauth-2-0/user-access-token
/// https://developer.twitter.com/en/docs/authentication/oauth-2-0/authorization-code
/// https://developer.twitter.com/en/docs/authentication/guides/v2-authentication-mapping
class TwitterProvider extends OAuthProvider {
  /// https://developer.twitter.com/en/docs/authentication/oauth-2-0/user-access-token
  /// https://developer.twitter.com/en/docs/authentication/oauth-2-0/authorization-code
  /// https://developer.twitter.com/en/docs/authentication/guides/v2-authentication-mapping
  const TwitterProvider({
    required super.clientIdentifier,
    required super.clientSecret,
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
        GrantType.authorization_code,
        GrantType.refresh_token,
        // App only bearer token https://developer.twitter.com/en/docs/authentication/api-reference/invalidate_bearer_token
        // revoke https://api.twitter.com/oauth2/invalidate_token
        // https://developer.twitter.com/en/docs/authentication/api-reference/token
        GrantType.client_credentials,
      ];

  // scope: users.read tweet.read offline.access
  //
  // url: "https://api.twitter.com/2/users/me",
  // user.fields: profile_image_url
  // https://developer.twitter.com/en/docs/twitter-api/users/lookup/api-reference/get-users-me

  static const defaultUserFields =
      'created_at,description,entities,id,location,name,pinned_tweet_id,profile_image_url,protected,public_metrics,url,username,verified,verified_type,withheld';

  Future<TwitterUserData> getUser(
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
      throw response;
    }
    if (responseEmail.statusCode != 200) {
      throw responseEmail;
    }
    final user = TwitterUser.fromJson(jsonDecode(response.body) as Map);
    final userV1 = TwitterVerifyCredentials.fromJson(
      jsonDecode(responseEmail.body) as Map,
    );
    return TwitterUserData(user: user, userV1: userV1);
  }
}

/// Get user email https://stackoverflow.com/questions/22627083/can-we-get-email-id-from-twitter-oauth-api
/// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials

class TwitterUserData {
  final TwitterUser user;
  final TwitterVerifyCredentials userV1;

  const TwitterUserData({
    required this.userV1,
    required this.user,
  });
}
