import 'package:oauth/oauth.dart';
import 'package:oauth/src/openid_claims.dart';

export 'package:oauth/src/openid_claims.dart';

/// https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api
/// https://developer.apple.com/documentation/sign_in_with_apple/configuring_your_environment_for_sign_in_with_apple
/// https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_js/incorporating_sign_in_with_apple_into_other_platforms
class AppleProvider extends OAuthProvider {
  /// https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api
  /// https://developer.apple.com/documentation/sign_in_with_apple/configuring_your_environment_for_sign_in_with_apple
  /// https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_js/incorporating_sign_in_with_apple_into_other_platforms
  const AppleProvider({
    required super.clientIdentifier,
    required super.clientSecret,
  }) : super(
          authorizationEndpoint: 'https://appleid.apple.com/auth/authorize',
          tokenEndpoint: 'https://appleid.apple.com/auth/token',
          revokeTokenEndpoint: 'https://appleid.apple.com/auth/revoke',
        );

  @override
  List<GrantType> get supportedFlows => const [
        // code id_token
        GrantType.authorization_code,
        GrantType.refresh_token,
      ];

  // TODO: webhooks https://developer.apple.com/documentation/sign_in_with_apple/processing_changes_for_sign_in_with_apple_accounts

  String get scope => 'name email';

  Future<OpenIdClaims> getUser(
    HttpClient client,
    TokenResponse token,
  ) async {
    final jwt = JsonWebToken.unverified(token.id_token!);
    final claims = OpenIdClaims.fromJson(jwt.claims.toJson());

    return claims;
  }
}

/// The only error code that might be returned is user_cancelled_authorize.
/// This error code is returned if the user clicks Cancel during the web flow.
class AppleAuthParams {
  /// The type of response mode expected. Valid values are query, fragment, and form_post.
  /// If you requested any scopes, the value must be form_post.
  final String response_mode;

  /// Required. The type of response requested. Valid values are code and id_token.
  /// You can request only code, or both code and id_token.
  /// Requesting only id_token is unsupported. When requesting id_token,
  /// response_mode must be either fragment or form_post.
  final String response_type;

  /// The amount of user information requested from Apple. Valid values are name and email.
  /// You can request one, both, or none. Use space separation and percent-encoding
  /// for multiple scopes; for example, "scope=name%20email".
  final String scope;

  /// The only error code that might be returned is user_cancelled_authorize.
  /// This error code is returned if the user clicks Cancel during the web flow.
  const AppleAuthParams({
    required this.response_mode,
    required this.response_type,
    required this.scope,
  });
// generated-dart-fixer-start{"md5Hash":"E9GuA529+G8V/Q+R/24WCA=="}

  factory AppleAuthParams.fromJson(Map json) {
    return AppleAuthParams(
      response_mode: json['response_mode'] as String,
      response_type: json['response_type'] as String,
      scope: json['scope'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'response_mode': response_mode,
      'response_type': response_type,
      'scope': scope,
    };
  }

  @override
  String toString() {
    return "AppleAuthParams${{
      "response_mode": response_mode,
      "response_type": response_type,
      "scope": scope,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"E9GuA529+G8V/Q+R/24WCA=="}

/// https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/authenticating_users_with_sign_in_with_apple#3383773
class AppleClaims {
  /// The issuer registered claim identifies the principal that issues the identity token.
  /// Because Apple generates the token, the value is https://appleid.apple.com.
  final String iss;

  /// The subject registered claim identifies the principal that’s the subject
  /// of the identity token. Because this token is for your app,
  /// the value is the unique identifier for the user.
  final String sub;

  /// The audience registered claim identifies the recipient of the identity token.
  /// Because the token is for your app, the value is the client_id from your developer account.
  final String aud;

  /// The issued at registered claim indicates the time that Apple issues the
  /// identity token, in the number of seconds since the Unix epoch in UTC.
  final int iat;

  /// The expiration time registered claim identifies the time that the identity
  /// token expires, in the number of seconds since the Unix epoch in UTC.
  /// The value must be greater than the current date and time when verifying the token.
  final int exp;

  /// A string for associating a client session with the identity token.
  /// This value mitigates replay attacks and is present only if you pass it in
  /// the authorization request.
  final String nonce;

  /// A Boolean value that indicates whether the transaction is on a
  /// nonce-supported platform. If you send a nonce in the authorization request,
  /// but don’t see the nonce claim in the identity token, check this claim to
  /// determine how to proceed. If this claim returns true, treat nonce as
  /// mandatory and fail the transaction; otherwise, you can proceed treating
  /// the nonce as optional.
  final bool nonce_supported;

  /// A string value that represents the user’s email address.
  /// The email address is either the user’s real email address or
  /// the proxy address, depending on their private email relay service.
  /// This value may be empty for Sign in with Apple at Work & School users.
  /// For example, younger students may not have an email address.
  /// If the user signs in with a managed Apple ID, the value of the email claim is a real email address, not a proxy address. Alternatively, if the managed Apple ID is in Apple School Manager, the email claim may be empty. Students, for example, often don’t have an email that the school issues.
  final String? email;

  /// A string or Boolean value that indicates whether the service verifies the email.
  /// The value can either be a string ("true" or "false") or a Boolean (true or false).
  /// The system may not verify email addresses for Sign in with Apple at Work & School users,
  /// and this claim is "false" or false for those users.
  final bool email_verified;

  /// A string or Boolean value that indicates whether the email that the
  /// user shares is the proxy address. The value can either be a string ("true" or "false")
  /// or a Boolean (true or false).
  final bool is_private_email;

  /// An Integer value that indicates whether the user appears to be a real person.
  /// Use the value of this claim to mitigate fraud.
  /// The possible values are: 0 (or Unsupported), 1 (or Unknown), 2 (or LikelyReal).
  /// For more information, see ASUserDetectionStatus. This claim is present
  /// only in iOS 14 and later, macOS 11 and later, watchOS 7 and later, tvOS 14 and later.
  /// The claim isn’t present or supported for web-based apps.
  final int real_user_status;

  /// A string value that represents the transfer identifier for migrating users
  /// to your team. This claim is present only during the 60-day transfer period
  /// after you transfer an app. For more information, see Bringing new apps
  /// and users into your team.
  final String transfer_sub;

  /// https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/authenticating_users_with_sign_in_with_apple#3383773
  const AppleClaims({
    required this.iss,
    required this.sub,
    required this.aud,
    required this.iat,
    required this.exp,
    required this.nonce,
    required this.nonce_supported,
    this.email,
    required this.email_verified,
    required this.is_private_email,
    required this.real_user_status,
    required this.transfer_sub,
  });
// generated-dart-fixer-start{"md5Hash":"bhFa6yQaiJmTWNKf4lRNXQ=="}

  factory AppleClaims.fromJson(Map json) {
    return AppleClaims(
      iss: json['iss'] as String,
      sub: json['sub'] as String,
      aud: json['aud'] as String,
      iat: json['iat'] as int,
      exp: json['exp'] as int,
      nonce: json['nonce'] as String,
      nonce_supported: json['nonce_supported'] as bool,
      email: json['email'] as String?,
      email_verified: json['email_verified'] as bool,
      is_private_email: json['is_private_email'] as bool,
      real_user_status: json['real_user_status'] as int,
      transfer_sub: json['transfer_sub'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'iss': iss,
      'sub': sub,
      'aud': aud,
      'iat': iat,
      'exp': exp,
      'nonce': nonce,
      'nonce_supported': nonce_supported,
      'email': email,
      'email_verified': email_verified,
      'is_private_email': is_private_email,
      'real_user_status': real_user_status,
      'transfer_sub': transfer_sub,
    };
  }

  @override
  String toString() {
    return "AppleClaims${{
      "iss": iss,
      "sub": sub,
      "aud": aud,
      "iat": iat,
      "exp": exp,
      "nonce": nonce,
      "nonce_supported": nonce_supported,
      "email": email,
      "email_verified": email_verified,
      "is_private_email": is_private_email,
      "real_user_status": real_user_status,
      "transfer_sub": transfer_sub,
    }}";
  }
}


// generated-dart-fixer-end{"md5Hash":"bhFa6yQaiJmTWNKf4lRNXQ=="}
