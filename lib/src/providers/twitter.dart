import 'package:oauth/oauth.dart';

/// https://developer.twitter.com/en/docs/authentication/oauth-2-0/user-access-token
class TwitterProvider extends OAuthProvider {
  /// https://developer.twitter.com/en/docs/authentication/oauth-2-0/user-access-token
  const TwitterProvider({
    required super.clientIdentifier,
    required super.clientSecret,
  }) : super(
          // TODO: response_type=code&code_challenge=dwdwa&code_challenge_method=plain
          authorizationEndpoint: 'https://twitter.com/i/oauth2/authorize',
          tokenEndpoint: 'https://api.twitter.com/2/oauth2/token',
          revokeTokenEndpoint: 'https://api.twitter.com/2/oauth2/revoke',
        );

  @override
  HttpAuthMethod get authMethod => HttpAuthMethod.formUrlencoded;

  // scope: users.read tweet.read offline.access
  //
  // url: "https://api.twitter.com/2/users/me",
  // user.fields: profile_image_url
}

class TwitterToken {
  ///
  const TwitterToken({
    required this.code,
    required this.client_id,
    required this.redirect_uri,
  });
  final String code;
  final String client_id;
  final String redirect_uri;

//  grant_type=authorization_code, code_verifier=challenge
// refresh_token, client_id, grant_type=refresh_token
}


/// Get user email https://stackoverflow.com/questions/22627083/can-we-get-email-id-from-twitter-oauth-api
/// https://developer.twitter.com/en/docs/twitter-api/v1/accounts-and-users/manage-account-settings/api-reference/get-account-verify_credentials
