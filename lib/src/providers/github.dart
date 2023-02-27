// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

export 'package:oauth/src/providers/github_token.dart';

/// https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps
class GithubProvider extends OAuthProvider<GithubToken> {
  /// https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps
  const GithubProvider({
    super.providerId = ImplementedProviders.github,
    super.config = const GithubProviderConfig(scope: 'read:user user:email'),
    required super.clientId,
    required super.clientSecret,
  }) : super(
          authorizationEndpoint: 'https://github.com/login/oauth/authorize',
          tokenEndpoint: 'https://github.com/login/oauth/access_token',
          // https://docs.github.com/en/rest/apps/oauth-applications?apiVersion=2022-11-28#about-oauth-apps
          // https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/token-expiration-and-revocation
          // TODO: access_token param instead of token
          revokeTokenEndpoint:
              'https://api.github.com/applications/$clientId/token',
          deviceAuthorizationEndpoint: 'https://github.com/login/device/code',
        );

  @override
  List<GrantType> get supportedFlows => const [
        GrantType.authorizationCode,
        GrantType.deviceCode,
      ];

  @override
  Future<Result<ParsedResponse, OAuthErrorResponse>> revokeToken(
    HttpClient client, {
    required String token,
    required bool isRefreshToken,
  }) async {
    final response = await sendHttpPost(
      client,
      Uri.parse(revokeTokenEndpoint!),
      // github uses access_token instead of token
      // TODO: test this, maybe we should use json
      {'access_token': token},
    );
    if (response.isSuccess) {
      return Ok(response);
    } else {
      return Err(OAuthErrorResponse.fromResponse(response));
    }
  }

  @override
  Future<Result<AuthUser<GithubToken>, GetUserError>> getUser(
    HttpClient client,
    TokenResponse token,
  ) async {
    // Maybe use https://docs.github.com/en/rest/users/users?apiVersion=2022-11-28
    final response = await client.post(
      Uri.parse('https://api.github.com/applications/$clientId/token'),
      headers: {
        Headers.contentType: Headers.appJson,
        'Accept': 'application/vnd.github+json',
        'Authorization': basicAuthHeader(),
        'X-GitHub-Api-Version': '2022-11-28'
      },
      // TODO: test and maybe use Headers.appFormUrlEncoded
      body: jsonEncode({'access_token': token.access_token}),
    );
    if (response.statusCode != 200) {
      return Err(GetUserError(response: response, token: token));
    }
    final tokenData = jsonDecode(response.body) as Map<String, Object?>;
    final userData = tokenData['user'] as Map?;

    if (userData != null && userData['email'] == null) {
      // If the user does not have a public email, fetch other emails with
      // https://docs.github.com/en/rest/users/emails?apiVersion=2022-11-28#list-email-addresses-for-the-authenticated-user
      final emailResponse = await client.get(
        Uri.parse('https://api.github.com/user/emails'),
        headers: {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28'
        },
      );

      if (emailResponse.statusCode != 200) {
        return Err(GetUserError(response: emailResponse, token: token));
      }
      final emails = jsonDecode(emailResponse.body) as List;
      if (emails.isNotEmpty) {
        userData['email'] =
            GithubEmail.fromJson((emails.first as Map).cast()).email;
      }
    }
    return Ok(parseUser(tokenData));
  }

  @override
  AuthUser<GithubToken> parseUser(Map<String, Object?> userData) {
    final token = GithubToken.fromJson(userData);
    final user = token.user!;

    return AuthUser(
      providerId: providerId,
      providerUserId: user.id.toString(),
      emailIsVerified: user.email != null,
      email: user.email,
      name: user.name,
      profilePicture: user.avatar_url,
      phoneIsVerified: false,
      rawUserData: userData,
      providerUser: token,
    );
  }
}

// https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps
// scope = read:user user:email

/// GET https://github.com/login/oauth/authorize
class GithubProviderConfig implements OAuthProviderConfig {
  /// GET https://github.com/login/oauth/authorize
  const GithubProviderConfig({
    required this.scope,
    this.login,
    this.allow_signup,
  });

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
  @override
  final String scope;

  /// Suggests a specific account to use for signing in and authorizing the app.
  final String? login;

  /// Whether or not unauthenticated users will be offered an option to sign up
  /// for GitHub during the OAuth flow. The default is true.
  /// Use false when a policy prohibits signups.
  final String? allow_signup;

  @override
  Map<String, String?>? baseAuthParams() => {
        'scope': scope,
        'login': login,
        'allow_signup': allow_signup,
      };

  @override
  Map<String, String?>? baseTokenParams() => null;
}

class DeviceCodeResponse {
  ///
  const DeviceCodeResponse({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.expiresIn,
    required this.interval,
    required this.expiresAt,
    this.message,
    this.verificationUriComplete,
  });

  /// The device verification code is 40 characters and used to verify the device.
  final String deviceCode;

  /// The user verification code is displayed on the device so the user
  /// can enter the code in a browser.
  /// This code is 8 characters with a hyphen in the middle.
  final String userCode;

  /// The verification URL where users need to enter the user_code: https://github.com/login/device.
  final String verificationUri;

  /// The number of seconds before the device_code and user_code expire.
  /// The default is 900 seconds or 15 minutes.
  final int expiresIn;

  /// The date where the [deviceCode] and [userCode] expire.
  /// Serialized as an ISO date time. Computed from [expiresIn].
  final DateTime expiresAt;

  /// The minimum number of seconds that must pass before you can make a new
  /// access token request (POST https://github.com/login/oauth/access_token)
  /// to complete the device authorization. For example, if the interval is 5,
  /// then you cannot make a new request until 5 seconds pass.
  /// If you make more than one request over 5 seconds, then you will
  /// hit the rate limit and receive a slow_down error.
  final int interval;

  /// A verification URI that includes the "user_code" (or
  /// other information with the same function as the "user_code"),
  /// which is designed for non-textual transmission.
  final String? verificationUriComplete;

  /// From Microsoft https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-device-code
  /// A human-readable string with instructions for the user.
  /// This can be localized by including a query parameter in the request
  /// of the form ?mkt=xx-XX, filling in the appropriate language culture code.
  final String? message;

// generated-dart-fixer-start{"jsonKeyCase":"snake_case","md5Hash":"AhyXQgvT12+RbqzO0xDxBQ=="}

  factory DeviceCodeResponse.fromJson(Map json) {
    return DeviceCodeResponse(
      deviceCode: json['device_code'] as String,
      userCode: json['user_code'] as String,
      verificationUri:
          (json['verification_uri'] ?? json['verification_url']) as String,
      expiresIn: json['expires_in'] as int,
      interval: json['interval'] as int,
      message: json['message'] as String?,
      verificationUriComplete: json['verification_uri_complete'] as String?,
      expiresAt: parseExpiresAt(json),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'device_code': deviceCode,
      'user_code': userCode,
      'verification_uri': verificationUri,
      'expires_in': expiresIn,
      'interval': interval,
      'verification_uri_complete': verificationUriComplete,
      'message': message,
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return "DeviceCodeResponse${{
      "deviceCode": deviceCode,
      "userCode": userCode,
      "verificationUri": verificationUri,
      "expiresIn": expiresIn,
      "interval": interval,
      "verificationUriComplete": verificationUriComplete,
      "message": message,
      "expiresAt": expiresAt,
    }}";
  }
}

// generated-dart-fixer-end{"jsonKeyCase":"snake_case","md5Hash":"AhyXQgvT12+RbqzO0xDxBQ=="}

/// Your device will show the user verification code and
/// prompt the user to enter the code at https://github.com/login/device.

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
  device_flow_disabled;

  /// Whether the device flow has finished.
  /// If this is true, we should stop polling.
  static bool isDeviceFlowFinished(String error) =>
      error != DeviceFlowError.slow_down.name &&
      error != DeviceFlowError.authorization_pending.name;
}

// generated-dart-fixer-json{"from":"./github_email.schema.json","kind":"schema","md5Hash":"33otMXuVAM4DyJBAxMBFgA=="}

/// Email
class GithubEmail {
  /// #### Example
  /// ```json
  /// "octocat@github.com"
  /// ```
  final String email;

  /// #### Example
  /// ```json
  /// true
  /// ```
  final bool primary;

  /// #### Example
  /// ```json
  /// true
  /// ```
  final bool verified;

  /// #### Example
  /// ```json
  /// "public"
  /// ```
  final String? visibility;

  const GithubEmail({
    required this.email,
    required this.primary,
    required this.verified,
    this.visibility,
  });

// generated-dart-fixer-start{"jsonKeyCase":"snake_case","md5Hash":"+yoEqmeJgxjYMIGerbn5Eg=="}

  factory GithubEmail.fromJson(Map json) {
    return GithubEmail(
      email: json['email'] as String,
      primary: json['primary'] as bool,
      verified: json['verified'] as bool,
      visibility: json['visibility'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'email': email,
      'primary': primary,
      'verified': verified,
      'visibility': visibility,
    };
  }

  @override
  String toString() {
    return "GithubEmail${{
      "email": email,
      "primary": primary,
      "verified": verified,
      "visibility": visibility,
    }}";
  }
}

// generated-dart-fixer-end{"jsonKeyCase":"snake_case","md5Hash":"+yoEqmeJgxjYMIGerbn5Eg=="}
