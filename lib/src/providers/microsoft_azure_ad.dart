// https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc
// https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow
// https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app
// https://learn.microsoft.com/en-us/azure/active-directory-b2c/tutorial-create-tenant

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

export 'package:oauth/src/openid_claims.dart';

/// https://learn.microsoft.com/en-us/azure/active-directory/develop/scopes-oidc
/// https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app
class MicrosoftProvider extends OpenIdConnectProvider<OpenIdClaims> {
  /// https://learn.microsoft.com/en-us/azure/active-directory/develop/scopes-oidc
  /// TODO: https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc#send-a-sign-out-request
  MicrosoftProvider({
    super.providerId = ImplementedProviders.microsoft,
    super.config = const MicrosoftAuthParams(),
    required super.openIdConfig,
    required super.clientId,
    required super.clientSecret,
  });

  static String wellKnownOpenIdEndpoint({
    MicrosoftTenant tenant = MicrosoftTenant.common,
  }) =>
      'https://login.microsoftonline.com/${tenant.value}/v2.0/.well-known/openid-configuration';

  static Future<MicrosoftProvider> retrieve({
    required String clientId,
    required String clientSecret,
    OAuthProviderConfig config = const MicrosoftAuthParams(),

    /// The {tenant} value in the path of the request can be used to
    /// control who can sign into the application. Valid values are common,
    /// organizations, consumers, and tenant identifiers. For guest scenarios
    /// where you sign a user from one tenant into another tenant, you must
    /// provide the tenant identifier to sign them into the resource tenant.
    /// For more information, see Endpoints.
    MicrosoftTenant tenant = MicrosoftTenant.common,
    HttpClient? client,
  }) async =>
      MicrosoftProvider(
        config: config,
        openIdConfig: await OpenIdConnectProvider.retrieveConfiguration(
          wellKnownOpenIdEndpoint(tenant: tenant),
          client: client,
        ),
        clientId: clientId,
        clientSecret: clientSecret,
      );

  @override
  List<GrantType> get supportedFlows => const [
        // TODO: "response_type=id_token%20token"
        GrantType.authorizationCode,
        GrantType.refreshToken,
        GrantType.tokenImplicit,
        GrantType.clientCredentials,
        GrantType.deviceCode,
        GrantType.password,
      ];

  // plain and S256
  // Cancel url https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc#single-sign-out

  /// https://learn.microsoft.com/en-us/azure/active-directory/develop/userinfo
  @override
  Future<Result<AuthUser<OpenIdClaims>, GetUserError>> getUser(
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

  // Supported claims:
  // "sub",
  // "iss",
  // "cloud_instance_name",
  // "cloud_instance_host_name",
  // "cloud_graph_host_name",
  // "msgraph_host",
  // "aud",
  // "exp",
  // "iat",
  // "auth_time",
  // "acr",
  // "nonce",
  // "preferred_username",
  // "name",
  // "tid",
  // "ver",
  // "at_hash",
  // "c_hash",
  // "email"
  @override
  AuthUser<OpenIdClaims> parseUser(Map<String, Object?> userData) {
    return AuthUser.fromClaims(
      OpenIdClaims.fromJson(userData),
      providerId: providerId,
    );
  }
}

/// scopes https://learn.microsoft.com/en-us/azure/active-directory/develop/scopes-oidc
// openid, email, profile, and offline_access
class MicrosoftAuthParams implements OAuthProviderConfig {
  /// 	recommended	Specifies how the identity platform should return the
  /// requested token to your app.
  ///
  /// Supported values:
  /// - query: Default when requesting an access token. Provides the code as a
  /// query string parameter on your redirect URI. The query parameter is not
  /// supported when requesting an ID token by using the implicit flow.
  /// - fragment: Default when requesting an ID token by using the implicit flow.
  /// Also supported if requesting only a code.
  /// - form_post: Executes a POST containing the code to your redirect URI.
  /// Supported when requesting a code.
  final String? response_mode;

  // /// 	recommended	A value included in the request that is also returned in the
  // /// token response. It can be a string of any content that you wish.
  // /// A randomly generated unique value is typically used for preventing
  // /// cross-site request forgery attacks. The value can also encode information
  // /// about the user's state in the app before the authentication request occurred.
  // /// For instance, it could encode the page or view they were on.
  // final String state;

  // /// 	Required	A value generated and sent by your app in its request for an ID
  // /// token. The same nonce value is included in the ID token returned to your
  // /// app by the Microsoft identity platform. To mitigate token replay attacks,
  // /// your app should verify the nonce value in the ID token is the same value
  // /// it sent when requesting the token. The value is typically a unique, random string.
  // final String nonce;

  /// 	optional	Indicates the type of user interaction that is required. Valid
  /// values are login, none, consent, and select_account.
  ///
  /// - prompt=login forces the user to enter their credentials on that request,
  /// negating single-sign on.
  /// - prompt=none is the opposite. It ensures that the user isn't presented
  /// with any interactive prompt. If the request can't be completed silently
  /// by using single-sign on, the Microsoft identity platform returns an
  /// interaction_required error.
  /// - prompt=consent triggers the OAuth consent dialog after the user signs in,
  /// asking the user to grant permissions to the app.
  /// - prompt=select_account interrupts single sign-on providing account
  /// selection experience listing all the accounts either in session or any
  /// remembered account or an option to choose to use a different account altogether.
  final String? prompt;

  /// 	optional	You can use this parameter to pre-fill the username and
  /// email address field of the sign-in page for the user.
  /// Apps can use this parameter during reauthentication, after already
  ///  extracting the login_hint optional claim from an earlier sign-in.
  final String? login_hint;

  /// 	optional	If included, the app skips the email-based discovery process
  /// that user goes through on the sign-in page, leading to a slightly more
  /// streamlined user experience. For example, sending them to their federated
  /// identity provider. Apps can use this parameter during reauthentication,
  /// by extracting the tid from a previous sign-in.
  final String? domain_hint;

  /// https://learn.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-expose-web-apis
  @override
  final String scope;

  ///
  const MicrosoftAuthParams({
    this.response_mode,
    this.prompt,
    this.login_hint,
    this.domain_hint,
    this.scope = 'openid email profile offline_access',
  });
// generated-dart-fixer-start{"md5Hash":"gqML1LJrqwodSSXvVzIaiA=="}

  factory MicrosoftAuthParams.fromJson(Map json) {
    return MicrosoftAuthParams(
      response_mode: json['response_mode'] as String?,
      prompt: json['prompt'] as String?,
      login_hint: json['login_hint'] as String?,
      domain_hint: json['domain_hint'] as String?,
    );
  }

  Map<String, String?> toJson() {
    return {
      'response_mode': response_mode,
      'prompt': prompt,
      'login_hint': login_hint,
      'domain_hint': domain_hint,
    };
  }

  @override
  String toString() {
    return "MicrosoftAuthParams${{
      "response_mode": response_mode,
      "prompt": prompt,
      "login_hint": login_hint,
      "domain_hint": domain_hint,
    }}";
  }

  @override
  Map<String, String?>? baseAuthParams() => toJson();

  @override
  Map<String, String?>? baseTokenParams() => null;
}

// generated-dart-fixer-end{"md5Hash":"gqML1LJrqwodSSXvVzIaiA=="}

class MicrosoftAuthCodeError {
  /// 	An error code string that can be used to classify types of errors,
  /// and to react to errors. This part of the error is provided so that the
  /// app can react appropriately to the error, but does not explain in depth
  /// why an error occurred.
  final String error;

  /// 	A specific error message that can help a developer identify the cause of
  /// an authentication error. This part of the error contains most of the useful
  /// information about why the error occurred.
  final String error_description;

  const MicrosoftAuthCodeError({
    required this.error,
    required this.error_description,
  });
// generated-dart-fixer-start{"md5Hash":"PnAE9MH3Uo2Rd5JOOyWG/A=="}

  factory MicrosoftAuthCodeError.fromJson(Map json) {
    return MicrosoftAuthCodeError(
      error: json['error'] as String,
      error_description: json['error_description'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'error': error,
      'error_description': error_description,
    };
  }

  @override
  String toString() {
    return "MicrosoftAuthCodeError${{
      "error": error,
      "error_description": error_description,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"PnAE9MH3Uo2Rd5JOOyWG/A=="}

class MicrosoftAuthCodeErrorCode {
  /// 	Protocol error, such as a missing required parameter.
  /// Fix and resubmit the request. This error is a development error
  /// typically caught during initial testing.
  static const invalid_request = 'invalid_request';

  /// 	The client application isn't permitted to request an authorization code.
  /// This error usually occurs when the client application isn't registered in
  /// Azure AD or isn't added to the user's Azure AD tenant.
  /// The application can prompt the user with instruction for installing the
  /// application and adding it to Azure AD.
  static const unauthorized_client = 'unauthorized_client';

  /// 	Resource owner denied consent	The client application can notify the user
  /// that it can't continue unless the user consents.
  static const access_denied = 'access_denied';

  /// 	The authorization server doesn't support the response type in the request.
  /// Fix and resubmit the request. This error is a development error typically
  /// caught during initial testing. In the hybrid flow, this error signals that
  /// you must enable the ID token implicit grant setting on the client app registration.
  static const unsupported_response_type = 'unsupported_response_type';

  /// 	The server encountered an unexpected error.	Retry the request.
  /// These errors can result from temporary conditions. The client application
  /// might explain to the user that its response is delayed to a temporary error.
  static const server_error = 'server_error';

  /// 	The server is temporarily too busy to handle the request.	Retry the request.
  /// The client application might explain to the user that its response is
  /// delayed because of a temporary condition.
  static const temporarily_unavailable = 'temporarily_unavailable';

  /// 	The target resource is invalid because it does not exist, Azure AD can't
  /// find it, or it's not correctly configured.	This error indicates the resource,
  /// if it exists, hasn't been configured in the tenant. The application can
  /// prompt the user with instruction for installing the application and adding it to Azure AD.
  static const invalid_resource = 'invalid_resource';

  /// 	Too many or no users found.	The client requested
  /// silent authentication (prompt=none), but a single user couldn't be found.
  /// This error may mean there are multiple users active in the session, or no users.
  /// This error takes into account the tenant chosen.
  /// For example, if there are two Azure AD accounts active and one Microsoft account,
  /// and consumers is chosen, silent authentication works.
  static const login_required = 'login_required';

  /// 	The request requires user interaction.	Another authentication step or
  /// consent is required. Retry the request without prompt=none.
  static const interaction_required = 'interaction_required';
}

class MicrosoftTenant {
  /// Users with both a personal Microsoft account and a work or school account
  /// from Azure AD can sign in to the application.
  static const common = MicrosoftTenant('common');

  /// Only users with work or school accounts from Azure AD can sign in to the application.
  static const organizations = MicrosoftTenant('organizations');

  /// Only users with a personal Microsoft account can sign in to the application.
  static const consumers = MicrosoftTenant('consumers');

  /// or 8eaef023-2b34-4da1-9baa-8bc8c9d6a490 Only users from a
  /// specific Azure AD tenant (directory members with a work or school
  /// account or directory guests with a personal Microsoft account)
  /// can sign in to the application.
  /// The value can be the domain name of the Azure AD tenant or the tenant ID
  /// in GUID format. You can also use the consumer tenant GUID,
  /// 9188040d-6c67-4c5b-b112-36a304b66dad, in place of consumers.
  static const contosoOnmicrosoftCom =
      MicrosoftTenant('contoso.onmicrosoft.com');

  const MicrosoftTenant(this.value);
  final String value;
}
