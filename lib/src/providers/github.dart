// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:oauth/oauth.dart';

/// https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps
class GithubProvider extends OAuthProvider {
  /// https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps
  const GithubProvider({
    required super.clientIdentifier,
    required super.clientSecret,
  }) : super(
          authorizationEndpoint: 'https://github.com/login/oauth/authorize',
          tokenEndpoint: 'https://github.com/login/oauth/access_token',
          // https://docs.github.com/en/rest/apps/oauth-applications?apiVersion=2022-11-28#about-oauth-apps
          // TODO: access_token param instead of token
          revokeTokenEndpoint:
              'https://api.github.com/applications/$clientIdentifier/token',
        );
}

// https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps
// scope = read:user user:email

/// GET https://github.com/login/oauth/authorize
class GithubOAuthAuthorize {
  /// GET https://github.com/login/oauth/authorize
  const GithubOAuthAuthorize({
    required this.client_id,
    this.redirect_uri,
    this.scope,
    this.state,
    this.login,
    this.allow_signup,
  });

  ///  The client ID you received from GitHub when you registered.
  final String client_id;

  /// The URL in your application where users will be sent after authorization.
  /// See details below about redirect urls.
  final String? redirect_uri;

  /// Suggests a specific account to use for signing in and authorizing the app.
  /// A space-delimited list of scopes. If not provided, scope defaults to an
  /// empty list for users that have not authorized any scopes for the application.
  /// For users who have authorized scopes for the application, the user won't
  /// be shown the OAuth authorization page with the list of scopes. Instead,
  /// this step of the flow will automatically complete with the set of scopes
  /// the user has authorized for the application. For example, if a user has
  /// already performed the web flow twice and has authorized one token with
  /// user scope and another token with repo scope, a third web flow that does
  /// not provide a scope will receive a token with user and repo scope.
  final String? scope;

  /// An unguessable random string. It is used to protect against cross-site
  /// request forgery attacks.
  final String? state;

  /// Suggests a specific account to use for signing in and authorizing the app.
  final String? login;

  /// Whether or not unauthenticated users will be offered an option to sign up
  /// for GitHub during the OAuth flow. The default is true.
  /// Use false when a policy prohibits signups.
  final String? allow_signup;
}

/// REDIRECT GET https://github.com/login/oauth/authorize
class GithubOAuthAuthorizeRedirected {
  /// REDIRECT GET https://github.com/login/oauth/authorize
  const GithubOAuthAuthorizeRedirected({
    required this.code,
    required this.state,
  });
  final String code;
  final String state;
}

/// POST https://github.com/login/oauth/access_token
class GithubOAuthAccessTokenPayload implements TokenParams {
  /// POST https://github.com/login/oauth/access_token
  const GithubOAuthAccessTokenPayload({
    required this.client_id,
    required this.client_secret,
    required this.code,
    required this.redirect_uri,
  });

  /// The client ID you received from GitHub for your OAuth App.
  @override
  final String client_id;

  /// The client secret you received from GitHub for your OAuth App.
  @override
  final String client_secret;

  /// The code you received as a response to Step 1.
  @override
  final String code;

  /// (Optional) The URL in your application where users are sent after authorization.
  @override
  final String /*?*/ redirect_uri;
}

/// RESPONSE POST https://github.com/login/oauth/access_token
class GithubOAuthAccessTokenResponse {
  /// RESPONSE POST https://github.com/login/oauth/access_token
  const GithubOAuthAccessTokenResponse({
    required this.access_token,
    required this.token_type,
    required this.scope,
  });

  /// @example "gho_16C7e42F292c6912E7710c838347Ae178B4a"
  final String access_token;

  /// @example "bearer"
  final String token_type;

  /// @example "repo,gist"
  final String scope;
}

/// POST https://github.com/login/device/code
class DeviceCode {
  /// POST https://github.com/login/device/code
  const DeviceCode({
    required this.client_id,
    required this.scope,
  });

  /// Required. The client ID you received from GitHub for your app.
  final String client_id;

  /// The scope that your app is requesting access to.
  final String scope;
}

class DeviceCodeResponse {
  ///
  const DeviceCodeResponse({
    required this.device_code,
    required this.user_code,
    required this.verification_uri,
    required this.expires_in,
    required this.interval,
  });

  /// The device verification code is 40 characters and used to verify the device.
  final String device_code;

  /// The user verification code is displayed on the device so the user
  /// can enter the code in a browser.
  /// This code is 8 characters with a hyphen in the middle.
  final String user_code;

  /// The verification URL where users need to enter the user_code: https://github.com/login/device.
  final String verification_uri;

  /// The number of seconds before the device_code and user_code expire.
  /// The default is 900 seconds or 15 minutes.
  final int expires_in;

  /// The minimum number of seconds that must pass before you can make a new
  /// access token request (POST https://github.com/login/oauth/access_token)
  /// to complete the device authorization. For example, if the interval is 5,
  /// then you cannot make a new request until 5 seconds pass.
  /// If you make more than one request over 5 seconds, then you will
  /// hit the rate limit and receive a slow_down error.
  final int interval;
}

/// Your device will show the user verification code and
/// prompt the user to enter the code at https://github.com/login/device.

/// POST https://github.com/login/oauth/access_token
class GithubOAuthAccessTokenPayloadDevice {
  /// POST https://github.com/login/oauth/access_token
  const GithubOAuthAccessTokenPayloadDevice({
    required this.client_id,
    required this.device_code,
    required this.grant_type,
  });

  /// The client ID you received from GitHub for your OAuth App.
  final String client_id;

  /// The device verification code you received from the POST https://github.com/login/device/code request.
  final String device_code;

  /// The grant type must be urn:ietf:params:oauth:grant-type:device_code.
  final String grant_type;
}

/// Error codes for the device flow
enum DeviceFlowError {
  /// This error occurs when the authorization request is pending and the
  /// user hasn't entered the user code yet. The app is expected to keep polling
  /// the POST https://github.com/login/oauth/access_token request without exceeding
  /// the interval, which requires a minimum number of seconds between each request.
  authorization_pending,

  /// When you receive the slow_down error, 5 extra seconds are added to the minimum
  /// interval or timeframe required between your requests
  /// using POST https://github.com/login/oauth/access_token.
  /// For example, if the starting interval required at least 5 seconds between
  /// requests and you get a slow_down error response, you must now
  /// wait a minimum of 10 seconds before making a new request for an
  /// OAuth access token. The error response includes the new interval
  /// that you must use.
  slow_down,

  /// If the device code expired, then you will see the token_expired error.
  /// You must make a new request for a device code.
  expired_token,

  /// The grant type must be urn:ietf:params:oauth:grant-type:device_code and
  /// included as an input parameter when you poll the OAuth token request
  /// POST https://github.com/login/oauth/access_token.
  unsupported_grant_type,

  /// For the device flow, you must pass your app's client ID, which you can
  /// find on your app settings page. The client_secret is not needed
  /// for the device flow.
  incorrect_client_credentials,

  /// The device_code provided is not valid.
  incorrect_device_code,

  /// When a user clicks cancel during the authorization process,
  /// you'll receive a access_denied error and the user won't be able
  /// to use the verification code again.
  access_denied,

  /// Device flow has not been enabled in the app's settings.
  /// For more information, see "Device flow."
  device_flow_disabled,
}
