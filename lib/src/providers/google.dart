import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

/// https://developers.google.com/identity/openid-connect/openid-connect
/// https://developers.google.com/identity/protocols/oauth2/web-server
/// https://pub.dev/packages/googleapis_auth
class GoogleProvider extends OpenIdConnectProvider<GoogleClaims> {
  // /// https://developers.google.com/identity/openid-connect/openid-connect
  // /// https://developers.google.com/identity/protocols/oauth2/web-server
  // const GoogleProvider({
  //   required super.clientIdentifier,
  //   required super.clientSecret,
  // }) : super(
  //         // wellKnownOpenIdEndpoint:
  //         //     'https://accounts.google.com/.well-known/openid-configuration',
  //         authorizationEndpoint: 'https://accounts.google.com/o/oauth2/auth',
  //         tokenEndpoint: 'https://oauth2.googleapis.com/token',
  //         revokeTokenEndpoint: 'https://oauth2.googleapis.com/revoke',
  //       );

  /// https://developers.google.com/identity/openid-connect/openid-connect
  /// https://developers.google.com/identity/protocols/oauth2/web-server
  GoogleProvider({
    super.providerId = ImplementedProviders.google,
    OAuthProviderConfig? config,
    required super.openIdConfig,
    required super.clientId,
    required super.clientSecret,
    OAuthButtonStyles? buttonStyles,
  }) : super(
          buttonStyles: buttonStyles ??
              const OAuthButtonStyles(
                logo: 'google.svg',
                logoDark: 'google.svg',
                bgDark: 'FFFFFF',
                bg: 'FFFFFF',
                text: '000000',
                textDark: '000000',
              ),
          config: config ??
              const GoogleAuthParams(
                scope: 'openid email profile',
              ),
        );

  static const wellKnownOpenIdEndpoint =
      'https://accounts.google.com/.well-known/openid-configuration';

  static Future<GoogleProvider> retrieve({
    required String clientId,
    required String clientSecret,
    OAuthProviderConfig? config,
    HttpClient? client,
    OAuthButtonStyles? buttonStyles,
  }) async =>
      GoogleProvider(
        openIdConfig: await OpenIdConnectProvider.retrieveConfiguration(
          wellKnownOpenIdEndpoint,
          client: client,
        ),
        clientId: clientId,
        clientSecret: clientSecret,
        config: config,
        buttonStyles: buttonStyles,
      );

  @override
  List<GrantType> get supportedFlows => const [
        GrantType.authorizationCode,
        GrantType.refreshToken,
        // https://developers.google.com/identity/protocols/oauth2/limited-input-device#allowedscopes
        // The OAuth 2.0 flow for devices is supported only for the following scopes:
        // OpenID Connect,Google Sign-In "email openid profile"
        // Drive API "https://www.googleapis.com/auth/drive.appdata https://www.googleapis.com/auth/drive.file"
        // YouTube API "https://www.googleapis.com/auth/youtube https://www.googleapis.com/auth/youtube.readonly"
        GrantType.deviceCode,
        GrantType.jwtBearer,
      ];

  @override
  Future<Result<AuthUser<GoogleClaims>, GetUserError>> getUser(
    HttpClient client,
    TokenResponse token,
  ) async {
    final result = await OpenIdConnectProvider.getOpenIdConnectUser(
      token: token,
      clientId: clientId,
      jwksUri: openIdConfig.jwksUri,
      issuer: openIdConfig.issuer,
    );
    return result.map((claims) => parseUser(claims.toJson()));
  }

  @override
  AuthUser<GoogleClaims> parseUser(Map<String, Object?> userData) {
    final googleClaims = GoogleClaims.fromJson(userData);

    return AuthUser(
      emailIsVerified: googleClaims.email_verified == 'true',
      phoneIsVerified: false,
      providerId: providerId,
      providerUser: googleClaims,
      rawUserData: userData,
      providerUserId: googleClaims.sub,
      email: googleClaims.email,
      name: googleClaims.name,
      openIdClaims: OpenIdClaims.fromJson(userData),
      picture: googleClaims.picture,
    );
  }
}

class GoogleAuthParams implements OAuthProviderConfig {
  ///
  const GoogleAuthParams({
    required this.scope,
    // TODO: access_type for implicit flow?
    this.access_type = 'offline',
    this.display,
    this.hd,
    this.include_granted_scopes,
    this.login_hint,
    this.prompt,
  });

  /// The scope parameter must begin with the openid value and then
  /// include the profile value, the email value, or both.
  ///
  /// If the profile scope value is present, the ID token might
  /// (but is not guaranteed to) include the user's default profile claims.
  ///
  /// If the email scope value is present, the ID token includes email
  /// and email_verified claims.
  ///
  /// In addition to these OpenID-specific scopes, your scope argument can
  /// also include other scope values. All scope values must be space-separated.
  /// For example, if you wanted per-file access to a user's Google Drive,
  /// your scope parameter might be openid profile email https://www.googleapis.com/auth/drive.file.
  /// For information about available scopes, see OAuth 2.0 Scopes
  /// for Google APIs or the documentation for the Google API you would like to use.
  @override
  final String scope;

  /// The allowed values are offline and online. The effect is documented in
  /// Offline Access; if an access token is being requested, the client does
  /// not receive a refresh token unless a value of offline is specified.
  final String? access_type;

  /// An ASCII string value for specifying how the authorization server
  /// displays the authentication and consent user interface pages.
  /// The following values are specified, and accepted by the Google servers,
  /// but do not have any effect on its behavior: page, popup, touch, and wap.
  final String? display;

  /// Streamline the login process for accounts owned by a
  /// Google Cloud organization. By including the Google Cloud organization
  /// domain (for example, mycollege.edu), you can indicate that the account
  /// selection UI should be optimized for accounts at that domain.
  /// To optimize for Google Cloud organization accounts generally
  /// instead of just one Google Cloud organization domain, set a value of an asterisk (*): hd=*.
  /// Don't rely on this UI optimization to control who can access your app,
  /// as client-side requests can be modified. Be sure to validate that the
  /// returned ID token has an hd claim value that matches what you
  /// expect (e.g. mycolledge.edu). Unlike the request parameter,
  /// the ID token hd claim is contained within a security token from Google,
  /// so the value can be trusted.
  final String? hd;

  /// If this parameter is provided with the value true, and the authorization
  /// request is granted, the authorization will include any previous
  /// authorizations granted to this user/application combination for other scopes;
  /// see Incremental authorization.
  /// Note that you cannot do incremental authorization with the Installed App flow.
  final String? include_granted_scopes;

  /// When your app knows which user it is trying to authenticate, it can
  /// provide this parameter as a hint to the authentication server.
  /// Passing this hint suppresses the account chooser and either pre-fills the
  /// email box on the sign-in form, or selects the proper session (if the user
  /// is using multiple sign-in), which can help you avoid problems that occur
  /// if your app logs in the wrong user account. The value can be either an
  /// email address or the sub string, which is equivalent to the user's Google ID.
  final String? login_hint;

  /// A space-delimited list of string values that specifies whether the
  /// authorization server prompts the user for reauthentication and consent.
  ///
  /// The possible values are:
  /// - none: The authorization server does not display any authentication or user consent screens;
  /// it will return an error if the user is not already authenticated and has not
  /// pre-configured consent for the requested scopes. You can use none to check for
  /// existing authentication and/or consent.
  /// - consent: The authorization server prompts the user for consent before
  /// returning information to the client.
  /// - select_account: The authorization server prompts the user to select a
  /// user account. This allows a user who has multiple accounts at the
  /// authorization server to select amongst the multiple accounts that they
  /// may have current sessions for.
  ///
  /// If no value is specified and the user has not previously authorized access,
  /// then the user is shown a consent screen.
  final String? prompt;

  Map<String, String?> toJson() => {
        'scope': scope,
        'access_type': access_type,
        'display': display,
        'hd': hd,
        'include_granted_scopes': include_granted_scopes,
        'login_hint': login_hint,
        'prompt': prompt,
      };

  @override
  Map<String, String?>? baseAuthParams() => toJson();

  @override
  Map<String, String?>? baseTokenParams() => null;
}

/// - admin_policy_enforced
/// The Google Account is unable to authorize one or more scopes requested due
/// to the policies of their Google Workspace administrator.
/// See the Google Workspace Admin help article Control which third-party &
/// internal apps access Google Workspace data for more information about how
/// an administrator may restrict access to all scopes or sensitive and
/// restricted scopes until access is explicitly granted to your OAuth client ID.
/// - disallowed_useragent
/// The authorization endpoint is displayed inside an embedded user-agent
/// disallowed by Google's OAuth 2.0 Policies.
/// Android developers may encounter this error message when opening
/// authorization requests in android.webkit.WebView. Developers should instead
/// use Android libraries such as Google Sign-In for Android or
/// OpenID Foundation's AppAuth for Android.
/// Web developers may encounter this error when an Android app opens a general
/// web link in an embedded user-agent and a user navigates to
/// Google's OAuth 2.0 authorization endpoint from your site. Developers should
/// allow general links to open in the default link handler of the
/// operating system, which includes both Android App Links handlers
/// or the default browser app.
/// The Android Custom Tabs library is also a supported option.
/// iOS and macOS developers may encounter this error when
/// opening authorization requests in WKWebView. Developers should instead use
/// iOS libraries such as Google Sign-In for iOS or OpenID Foundation's AppAuth for iOS.
/// Web developers may encounter this error when an iOS or macOS app opens a
/// general web link in an embedded user-agent and a user navigates to
/// Google's OAuth 2.0 authorization endpoint from your site.
/// Developers should allow general links to open in the default link
/// handler of the operating system, which includes both Universal Links
/// handlers or the default browser app.
/// The SFSafariViewController library is also a supported option.
/// - org_internal
/// The OAuth client ID in the request is part of a project limiting access to
/// Google Accounts in a specific Google Cloud Organization.
/// For more information about this configuration option see the User type
/// section in the Setting up your OAuth consent screen help article.
/// - origin_mismatch
/// The scheme, domain, and/or port of the JavaScript originating the authorization
/// request may not match an authorized JavaScript origin URI registered
/// for the OAuth client ID. Review authorized JavaScript origins in the
/// Google API Console Credentials page.
/// - redirect_uri_mismatch
/// The redirect_uri passed in the authorization request does not match an
/// authorized redirect URI for the OAuth client ID.
/// Review authorized redirect URIs in the Google API Console Credentials page.
/// - unsupported_token_type:  The authorization server does not support
///  the revocation of the presented token type.  That is, the
///  client tried to revoke an access token on a server not
///  supporting this feature.
typedef GoogleAuthError = String;

class GoogleTokenParams {
  ///
  const GoogleTokenParams({
    required this.code,
    required this.client_id,
    required this.client_secret,
    required this.redirect_uri,
    required this.grant_type,
  });

  /// The authorization code that is returned from the initial request.
  final String code;

  /// The client ID that you obtain from the API Console Credentials page,
  /// as described in Obtain OAuth 2.0 credentials.
  final String client_id;

  /// The client secret that you obtain from the API Console Credentials page,
  /// as described in Obtain OAuth 2.0 credentials.
  final String client_secret;

  /// An authorized redirect URI for the given client_id specified in the
  /// API Console Credentials page, as described in Set a redirect URI.
  final String redirect_uri;

  /// This field must contain a value of authorization_code,
  /// as defined in the OAuth 2.0 specification.
  /// authorization_code, refresh_token or password
  final String grant_type;

  Map<String, String> toJson() => {
        'code': code,
        'client_id': client_id,
        'client_secret': client_secret,
        'redirect_uri': redirect_uri,
        'grant_type': grant_type,
      };
}

class GoogleClaims {
  ///
  GoogleClaims({
    required this.aud,
    required this.exp,
    required this.iat,
    required this.iss,
    required this.sub,
    this.at_hash,
    this.azp,
    this.email,
    this.email_verified,
    this.family_name,
    this.given_name,
    this.hd,
    this.locale,
    this.name,
    this.nonce,
    this.picture,
    this.profile,
  });

  ///
  factory GoogleClaims.fromJson(Map<dynamic, dynamic> map) {
    return GoogleClaims(
      aud: map['aud'] is String
          ? [map['aud'] as String]
          : (map['aud'] as Iterable).map((e) => e as String).toList(),
      exp: map['exp'] as int,
      iat: map['iat'] as int,
      iss: map['iss'] as String,
      sub: map['sub'] as String,
      at_hash: map['at_hash'] != null ? map['at_hash'] as String : null,
      azp: map['azp'] != null ? map['azp'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      email_verified: map['email_verified'] != null
          ? map['email_verified'] as String
          : null,
      family_name:
          map['family_name'] != null ? map['family_name'] as String : null,
      given_name:
          map['given_name'] != null ? map['given_name'] as String : null,
      hd: map['hd'] != null ? map['hd'] as String : null,
      locale: map['locale'] != null ? map['locale'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      nonce: map['nonce'] != null ? map['nonce'] as String : null,
      picture: map['picture'] != null ? map['picture'] as String : null,
      profile: map['profile'] != null ? map['profile'] as String : null,
    );
  }

  /// The audience that this ID token is intended for.
  /// It must be one of the OAuth 2.0 client IDs of your application.
  final List<String> aud;

  /// Expiration time on or after which the ID token must not be accepted.
  /// Represented in Unix time (integer seconds).
  final int exp;

  /// The time the ID token was issued.
  /// Represented in Unix time (integer seconds).
  final int iat;

  /// The Issuer Identifier for the Issuer of the response.
  /// Always https://accounts.google.com or accounts.google.com for Google ID tokens.
  final String iss;

  /// An identifier for the user, unique among all Google accounts and never reused.
  /// A Google account can have multiple email addresses at different points in time,
  /// but the sub value is never changed. Use sub within your application as the
  /// unique-identifier key for the user.
  /// Maximum length of 255 case-sensitive ASCII characters.
  final String sub;

  /// Access token hash. Provides validation that the access token is
  /// tied to the identity token. If the ID token is issued with an
  /// access_token value in the server flow, this claim is always included.
  /// This claim can be used as an alternate mechanism to protect against
  /// cross-site request forgery attacks, but if you follow Step 1 and Step 3
  /// it is not necessary to verify the access token.
  final String? at_hash;

  /// The client_id of the authorized presenter.
  /// This claim is only needed when the party requesting the ID token is not
  /// the same as the audience of the ID token. This may be the case at Google
  /// for hybrid apps where a web application and Android app have a different
  /// OAuth 2.0 client_id but share the same Google APIs project.
  final String? azp;

  /// The user's email address. This value may not be unique to this user
  /// and is not suitable for use as a primary key.
  /// Provided only if your scope included the email scope value.
  final String? email;

  /// True if the user's e-mail address has been verified; otherwise false.
  final String? email_verified;

  /// The user's surname(s) or last name(s). Might be provided when a name
  /// claim is present.
  final String? family_name;

  /// The user's given name(s) or first name(s). Might be provided when a name
  /// claim is present.
  final String? given_name;

  /// The domain associated with the Google Cloud organization of the user.
  /// Provided only if the user belongs to a Google Cloud organization.
  final String? hd;

  /// The user's locale, represented by a BCP 47 language tag.
  /// Might be provided when a name claim is present.
  final String? locale;

  /// The user's full name, in a displayable form.
  /// Might be provided when:
  /// - The request scope included the string "profile"
  /// - The ID token is returned from a token refresh
  ///
  /// When name claims are present, you can use them to update your app's user records.
  /// Note that this claim is never guaranteed to be present.
  final String? name;

  /// The value of the nonce supplied by your app in the authentication request.
  /// You should enforce protection against replay attacks by ensuring it is presented only once.
  final String? nonce;

  /// The URL of the user's profile picture.
  /// Might be provided when:
  /// - The request scope included the string "profile"
  /// - The ID token is returned from a token refresh
  ///
  /// When picture claims are present, you can use them to update your app's user records.
  /// Note that this claim is never guaranteed to be present.
  final String? picture;

  /// The URL of the user's profile page.
  /// Might be provided when:
  /// - The request scope included the string "profile"
  /// - The ID token is returned from a token refresh
  ///
  /// When profile claims are present, you can use them to update your app's user records.
  /// Note that this claim is never guaranteed to be present.
  final String? profile;

  Map<String, dynamic> toJson() {
    return {
      'aud': aud,
      'exp': exp,
      'iat': iat,
      'iss': iss,
      'sub': sub,
      'at_hash': at_hash,
      'azp': azp,
      'email': email,
      'email_verified': email_verified,
      'family_name': family_name,
      'given_name': given_name,
      'hd': hd,
      'locale': locale,
      'name': name,
      'nonce': nonce,
      'picture': picture,
      'profile': profile,
    };
  }
}
