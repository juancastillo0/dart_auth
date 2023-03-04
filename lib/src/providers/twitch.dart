import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

/// https://dev.twitch.tv/docs/authentication/scopes/
class TwitchProvider extends OpenIdConnectProvider<TwitchUser> {
  //  channel:manage:polls

  /// https://dev.twitch.tv/docs/authentication/scopes/
  TwitchProvider({
    required super.openIdConfig,
    required super.clientId,
    required super.clientSecret,
    super.config = const OAuthProviderConfig(scope: defaultScopesString),
    super.providerId = ImplementedProviders.twitch,
  });

  static const wellKnownOpenIdEndpoint =
      'https://id.twitch.tv/oauth2/.well-known/openid-configuration';

  /// The default scopes used for the [TwitchProvider]
  static const defaultScopesString = 'user:read:email openid';

  @override
  Future<Result<AuthUser<TwitchUser>, GetUserError>> getUser(
    HttpClient client,
    TokenResponse token,
  ) async {
    final user = await OpenIdConnectProvider.getOpenIdConnectUser(
      token: token,
      clientId: clientId,
      jwksUri: openIdConfig.jwksUri,
      issuer: openIdConfig.issuer,
    );
    return user.map((claims) => parseUser(claims.toJson()));
  }

  @override
  AuthUser<TwitchUser> parseUser(Map<String, Object?> userData) {
    final claims = OpenIdClaims.fromJson(userData);

    return AuthUser(
      emailIsVerified: claims.emailVerified ?? false,
      phoneIsVerified: claims.phoneNumberVerified ?? false,
      providerId: providerId,
      providerUser: TwitchUser(
        sub: claims.subject,
        preferredUsername: claims.preferredUsername!,
        picture: claims.picture!.toString(),
        email: claims.email!,
        emailVerified: claims.emailVerified!,
        updatedAt: claims.updatedAt!,
        issuedAt: claims.issuedAt,
        expiresAt: claims.expiry,
      ),
      providerUserId: claims.subject,
      rawUserData: userData,
      email: claims.email,
      name: claims.preferredUsername,
      openIdClaims: claims,
      picture: claims.picture?.toString(),
    );
  }

  @override
  List<GrantType> get supportedFlows => const [
        GrantType.tokenImplicit,
        GrantType.authorizationCode,
        GrantType.refreshToken,
        GrantType.clientCredentials
      ];
}

/// A Twitch user from the open id token claims
class TwitchUser {
  /// id An ID that identifies the user.
  final String sub;
  //  login	String	The user’s login name.
  /// display_name The user’s display name.
  final String preferredUsername;

  /// profile_image_url A URL to the user’s profile image.
  final String picture;

  /// The user’s verified email address. The object includes this field only
  /// if the user access token includes the user:read:email scope.
  ///
  /// If the request contains more than one user, only the user associated
  /// with the access token that provided consent will include an email address
  /// — the email address for all other users will be empty.
  final String email;

  /// Whether the email is verified
  final bool emailVerified;

  /// The date when the user was updated
  final DateTime updatedAt;

  /// iat The date when this was issued
  final DateTime issuedAt;

  /// exp The date when the token will expire
  final DateTime expiresAt;

  /// A Twitch user from the open id token claims
  const TwitchUser({
    required this.sub,
    required this.preferredUsername,
    required this.picture,
    required this.email,
    required this.emailVerified,
    required this.updatedAt,
    required this.issuedAt,
    required this.expiresAt,
  });
// generated-dart-fixer-start{"md5Hash":"BUhsGd5FysUYNlJ20+hYuA=="}

  factory TwitchUser.fromJson(Map json) {
    return TwitchUser(
      sub: json['sub'] as String,
      preferredUsername: json['preferred_username'] as String,
      picture: json['picture'] as String,
      email: json['email'] as String,
      emailVerified: json['email_verified'] as bool,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updated_at'] as int) * 1000,
      ),
      issuedAt:
          DateTime.fromMillisecondsSinceEpoch((json['iat'] as int) * 1000),
      expiresAt:
          DateTime.fromMillisecondsSinceEpoch((json['exp'] as int) * 1000),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'sub': sub,
      'preferred_username': preferredUsername,
      'picture': picture,
      'email': email,
      'email_verified': emailVerified,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
      'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  @override
  String toString() {
    return "TwitchUser${{
      "sub": sub,
      "preferred_username": preferredUsername,
      "picture": picture,
      "email": email,
      "email_verified": emailVerified,
      "updated_at": updatedAt,
      "issuedAt": issuedAt,
      "expiresAt": expiresAt,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"BUhsGd5FysUYNlJ20+hYuA=="}

