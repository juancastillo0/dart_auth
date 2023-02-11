// ignore_for_file: non_constant_identifier_names

import 'package:oauth/oauth.dart';

/// https://developers.google.com/identity/openid-connect/openid-connect
/// https://developers.google.com/identity/protocols/oauth2/web-server
class GoogleProvider extends OAuthProvider {
  /// https://developers.google.com/identity/openid-connect/openid-connect
  /// https://developers.google.com/identity/protocols/oauth2/web-server
  const GoogleProvider({
    required super.clientIdentifier,
    required super.clientSecret,
  }) : super(
          wellKnownOpenIdEndpoint:
              'https://accounts.google.com/.well-known/openid-configuration',
          authorizationEndpoint: 'https://accounts.google.com/o/oauth2/auth',
          tokenEndpoint: 'https://oauth2.googleapis.com/token',
          revokeTokenEndpoint: 'https://oauth2.googleapis.com/revoke',
        );

  @override
  HttpAuthMethod get authMethod => HttpAuthMethod.formUrlencoded;
}
// scope -> openid email profile https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile

class GoogleAuthParams implements AuthParams {
  ///
  const GoogleAuthParams({
    required this.client_id,
    required this.nonce,
    required this.response_type,
    required this.redirect_uri,
    required this.scope,
    required this.state,
    this.access_type,
    this.display,
    this.hd,
    this.include_granted_scopes,
    this.login_hint,
    this.prompt,
  });

  /// The client ID string that you obtain from the API Console Credentials
  /// page, as described in Obtain OAuth 2.0 credentials.
  @override
  final String client_id;

  /// A random value generated by your app that enables replay protection.
  final String nonce;

  /// If the value is code, launches a Basic authorization code flow,
  /// requiring a POST to the token endpoint to obtain the tokens.
  /// If the value is token id_token or id_token token,
  /// launches an Implicit flow, requiring the use of JavaScript at the
  /// redirect URI to retrieve tokens from the URI #fragment identifier.
  @override
  final String response_type;

  /// Determines where the response is sent. The value of this parameter must
  /// exactly match one of the authorized redirect values that you set in the
  /// API Console Credentials page (including the HTTP or HTTPS scheme, case,
  /// and trailing '/', if any).
  @override
  final String redirect_uri;

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

  /// (Optional, but strongly recommended)
  /// An opaque string that is round-tripped in the protocol; that is to say,
  /// it is returned as a URI parameter in the Basic flow,
  /// and in the URI #fragment identifier in the Implicit flow.
  /// The state can be useful for correlating requests and responses.
  /// Because your redirect_uri can be guessed, using a state value can
  /// increase your assurance that an incoming connection is the result
  /// of an authentication request initiated by your app.
  /// If you generate a random string or encode the hash of some
  /// client state (e.g., a cookie) in this state variable, you can
  /// validate the response to additionally ensure that the request and
  /// response originated in the same browser. This provides protection
  /// against attacks such as cross-site request forgery.
  @override
  final String state;

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

  @override
  Map<String, String?> toJson() => {
        'client_id': client_id,
        'nonce': nonce,
        'response_type': response_type,
        'redirect_uri': redirect_uri,
        'scope': scope,
        'state': state,
        'access_type': access_type,
        'display': display,
        'hd': hd,
        'include_granted_scopes': include_granted_scopes,
        'login_hint': login_hint,
        'prompt': prompt,
      };
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
/// - redirect_uri_mismatch
/// The redirect_uri passed in the authorization request does not match an
/// authorized redirect URI for the OAuth client ID.
/// Review authorized redirect URIs in the Google API Console Credentials page.
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

class GoogleSuccessAuth {
  ///
  const GoogleSuccessAuth({
    required this.token,
    required this.claims,
  });
  final GoogleTokenResponse token;
  final GoogleClaims claims;
}

class GoogleTokenResponse implements TokenResponse {
  ///
  const GoogleTokenResponse({
    required this.access_token,
    required this.expires_in,
    required this.id_token,
    required this.scope,
    required this.token_type,
    this.refresh_token,
  });

  ///
  factory GoogleTokenResponse.fromJson(Map<dynamic, dynamic> json) =>
      GoogleTokenResponse(
        access_token: json['access_token'] as String,
        expires_in: json['expires_in'] as int,
        id_token: json['id_token'] as String,
        scope: json['scope'] as String,
        token_type: json['token_type'] as String,
        refresh_token: json['refresh_token'] as String?,
      );

  /// A token that can be sent to a Google API.
  @override
  final String access_token;

  /// The remaining lifetime of the access token in seconds.
  @override
  final int expires_in;

  /// A JWT that contains identity information about the user
  /// that is digitally signed by Google.
  @override
  final String id_token;

  /// The scopes of access granted by the access_token expressed as a
  /// list of space-delimited, case-sensitive strings.
  @override
  final String scope;

  /// Identifies the type of token returned.
  /// At this time, this field always has the value "Bearer".
  @override
  final String token_type;

  /// This field is only present if the access_type parameter was set to
  /// offline in the authentication request. For details, see Refresh tokens.
  @override
  final String? refresh_token;
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
      aud: map['aud'] as String,
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
  final String aud;

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