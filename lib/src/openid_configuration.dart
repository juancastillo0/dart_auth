// generated-dart-fixer-json{"from":"./openid_provider_metadata.schema.json","kind":"schema","md5Hash":"1Be+WcB8cIGudITpoEf0/A=="}

/// https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata
/// https://openid.net/specs/openid-connect-session-1_0-17.html
///
/// #### Google
///
/// ```json
/// {
///   "issuer": "https://accounts.google.com",
///   "authorization_endpoint": "https://accounts.google.com/o/oauth2/v2/auth",
///   "device_authorization_endpoint": "https://oauth2.googleapis.com/device/code",
///   "token_endpoint": "https://oauth2.googleapis.com/token",
///   "userinfo_endpoint": "https://openidconnect.googleapis.com/v1/userinfo",
///   "revocation_endpoint": "https://oauth2.googleapis.com/revoke",
///   "jwks_uri": "https://www.googleapis.com/oauth2/v3/certs",
///   "response_types_supported": [
///     "code",
///     "token",
///     "id_token",
///     "code token",
///     "code id_token",
///     "token id_token",
///     "code token id_token",
///     "none"
///   ],
///   "subject_types_supported": ["public"],
///   "id_token_signing_alg_values_supported": ["RS256"],
///   "scopes_supported": ["openid", "email", "profile"],
///   "token_endpoint_auth_methods_supported": [
///     "client_secret_post",
///     "client_secret_basic"
///   ],
///   "claims_supported": [
///     "aud",
///     "email",
///     "email_verified",
///     "exp",
///     "family_name",
///     "given_name",
///     "iat",
///     "iss",
///     "locale",
///     "name",
///     "picture",
///     "sub"
///   ],
///   "code_challenge_methods_supported": ["plain", "S256"],
///   "grant_types_supported": [
///     "authorization_code",
///     "refresh_token",
///     "urn:ietf:params:oauth:grant-type:device_code",
///     "urn:ietf:params:oauth:grant-type:jwt-bearer"
///   ]
/// }
/// ```
///
/// #### Microsoft https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration
///
/// ```json
/// {
///   "token_endpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/token",
///   "token_endpoint_auth_methods_supported": [
///     "client_secret_post",
///     "private_key_jwt",
///     "client_secret_basic"
///   ],
///   "jwks_uri": "https://login.microsoftonline.com/common/discovery/v2.0/keys",
///   "response_modes_supported": ["query", "fragment", "form_post"],
///   "subject_types_supported": ["pairwise"],
///   "id_token_signing_alg_values_supported": ["RS256"],
///   "response_types_supported": [
///     "code",
///     "id_token",
///     "code id_token",
///     "id_token token"
///   ],
///   "scopes_supported": ["openid", "profile", "email", "offline_access"],
///   "issuer": "https://login.microsoftonline.com/{tenantid}/v2.0",
///   "request_uri_parameter_supported": false,
///   "userinfo_endpoint": "https://graph.microsoft.com/oidc/userinfo",
///   "authorization_endpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
///   "device_authorization_endpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/devicecode",
///   "http_logout_supported": true,
///   "frontchannel_logout_supported": true,
///   "end_session_endpoint": "https://login.microsoftonline.com/common/oauth2/v2.0/logout",
///   "claims_supported": [
///     "sub",
///     "iss",
///     "cloud_instance_name",
///     "cloud_instance_host_name",
///     "cloud_graph_host_name",
///     "msgraph_host",
///     "aud",
///     "exp",
///     "iat",
///     "auth_time",
///     "acr",
///     "nonce",
///     "preferred_username",
///     "name",
///     "tid",
///     "ver",
///     "at_hash",
///     "c_hash",
///     "email"
///   ],
///   "kerberos_endpoint": "https://login.microsoftonline.com/common/kerberos",
///   "tenant_region_scope": null,
///   "cloud_instance_name": "microsoftonline.com",
///   "cloud_graph_host_name": "graph.windows.net",
///   "msgraph_host": "graph.microsoft.com",
///   "rbac_url": "https://pas.windows.net"
/// }
/// ```
/// OpenID Providers have metadata describing their configuration. These
/// OpenID Provider Metadata values are used by OpenID Connect.
class OpenIdConfiguration {
  /// REQUIRED. URL using the https scheme with no query or fragment component
  /// that the OP asserts as its Issuer Identifier. If Issuer discovery is
  /// supported (see Section 2), this value MUST be identical to the issuer value
  /// returned by WebFinger. This also MUST be identical to the iss Claim value in
  /// ID Tokens issued from this Issuer.
  final String issuer;

  /// REQUIRED. URL of the OP's OAuth 2.0 Authorization Endpoint
  /// [OpenID.Core].
  final String authorizationEndpoint;

  /// URL of the OP's OAuth 2.0 Token Endpoint [OpenID.Core]. This is REQUIRED
  /// unless only the Implicit Flow is used.
  final String? tokenEndpoint;

  /// RECOMMENDED. URL of the OP's UserInfo Endpoint [OpenID.Core]. This URL
  /// MUST use the https scheme and MAY contain port, path, and query parameter
  /// components.
  final String? userinfoEndpoint;

  /// REQUIRED. URL of the OP's JSON Web Key Set [JWK] document. This contains
  /// the signing key(s) the RP uses to validate signatures from the OP. The JWK
  /// Set MAY also contain the Server's encryption key(s), which are used by RPs
  /// to encrypt requests to the Server. When both signing and encryption keys are
  /// made available, a use (Key Use) parameter value is REQUIRED for all keys in
  /// the referenced JWK Set to indicate each key's intended usage. Although some
  /// algorithms allow the same key to be used for both signatures and encryption,
  /// doing so is NOT RECOMMENDED, as it is less secure. The JWK x5c parameter MAY
  /// be used to provide X.509 representations of keys provided. When used, the
  /// bare key values MUST still be present and MUST match those in the
  /// certificate.
  final String? jwksUri;

  /// RECOMMENDED. URL of the OP's Dynamic Client Registration Endpoint
  /// [OpenID.Registration].
  final String? registrationEndpoint;

  /// RECOMMENDED. JSON array containing a list of the OAuth 2.0 [RFC6749]
  /// scope values that this server supports. The server MUST support the openid
  /// scope value. Servers MAY choose not to advertise some supported scope values
  /// even when this parameter is used, although those defined in [OpenID.Core]
  /// SHOULD be listed, if supported.
  final List<String>? scopesSupported;

  /// REQUIRED. JSON array containing a list of the OAuth 2.0 response_type
  /// values that this OP supports. Dynamic OpenID Providers MUST support the
  /// code, id_token, and the token id_token Response Type values.
  final List<String> responseTypesSupported;

  /// OPTIONAL. JSON array containing a list of the OAuth 2.0 response_mode
  /// values that this OP supports, as specified in OAuth 2.0 Multiple Response
  /// Type Encoding Practices [OAuth.Responses]. If omitted, the default for
  /// Dynamic OpenID Providers is ["query", "fragment"].
  final List<String>? responseModesSupported;

  /// OPTIONAL. JSON array containing a list of the OAuth 2.0 Grant Type
  /// values that this OP supports. Dynamic OpenID Providers MUST support the
  /// authorization_code and implicit Grant Type values and MAY support other
  /// Grant Types. If omitted, the default value is ["authorization_code",
  /// "implicit"].
  final List<String>? grantTypesSupported;

  /// OPTIONAL. JSON array containing a list of the Authentication Context
  /// Class References that this OP supports.
  final List<String>? acrValuesSupported;

  /// REQUIRED. JSON array containing a list of the Subject Identifier types
  /// that this OP supports. Valid types include pairwise and public.
  final List<String>? subjectTypesSupported;

  /// REQUIRED. JSON array containing a list of the JWS signing algorithms
  /// (alg values) supported by the OP for the ID Token to encode the Claims in a
  /// JWT [JWT]. The algorithm RS256 MUST be included. The value none MAY be
  /// supported, but MUST NOT be used unless the Response Type used returns no ID
  /// Token from the Authorization Endpoint (such as when using the Authorization
  /// Code Flow).
  final List<String> idTokenSigningAlgValuesSupported;

  /// OPTIONAL. JSON array containing a list of the JWE encryption algorithms
  /// (alg values) supported by the OP for the ID Token to encode the Claims in a
  /// JWT [JWT].
  final List<String>? idTokenEncryptionAlgValuesSupported;

  /// OPTIONAL. JSON array containing a list of the JWE encryption algorithms
  /// (enc values) supported by the OP for the ID Token to encode the Claims in a
  /// JWT [JWT].
  final List<String>? idTokenEncryptionEncValuesSupported;

  /// OPTIONAL. JSON array containing a list of the JWS [JWS] signing
  /// algorithms (alg values) [JWA] supported by the UserInfo Endpoint to encode
  /// the Claims in a JWT [JWT]. The value none MAY be included.
  final List<String>? userinfoSigningAlgValuesSupported;

  /// OPTIONAL. JSON array containing a list of the JWE [JWE] encryption
  /// algorithms (alg values) [JWA] supported by the UserInfo Endpoint to encode
  /// the Claims in a JWT [JWT].
  final List<String>? userinfoEncryptionAlgValuesSupported;

  /// OPTIONAL. JSON array containing a list of the JWE encryption algorithms
  /// (enc values) [JWA] supported by the UserInfo Endpoint to encode the Claims
  /// in a JWT [JWT].
  final List<String>? userinfoEncryptionEncValuesSupported;

  /// OPTIONAL. JSON array containing a list of the JWS signing algorithms
  /// (alg values) supported by the OP for Request Objects, which are described in
  /// Section 6.1 of OpenID Connect Core 1.0 [OpenID.Core]. These algorithms are
  /// used both when the Request Object is passed by value (using the request
  /// parameter) and when it is passed by reference (using the request_uri
  /// parameter). Servers SHOULD support none and RS256.
  final List<String>? requestObjectSigningAlgValuesSupported;

  /// OPTIONAL. JSON array containing a list of the JWE encryption algorithms
  /// (alg values) supported by the OP for Request Objects. These algorithms are
  /// used both when the Request Object is passed by value and when it is passed
  /// by reference.
  final List<String>? requestObjectEncryptionAlgValuesSupported;

  /// OPTIONAL. JSON array containing a list of the JWE encryption algorithms
  /// (enc values) supported by the OP for Request Objects. These algorithms are
  /// used both when the Request Object is passed by value and when it is passed
  /// by reference.
  final List<String>? requestObjectEncryptionEncValuesSupported;

  /// OPTIONAL. JSON array containing a list of Client Authentication methods
  /// supported by this Token Endpoint. The options are client_secret_post,
  /// client_secret_basic, client_secret_jwt, and private_key_jwt, as described in
  /// Section 9 of OpenID Connect Core 1.0 [OpenID.Core]. Other authentication
  /// methods MAY be defined by extensions. If omitted, the default is
  /// client_secret_basic -- the HTTP Basic Authentication Scheme specified in
  /// Section 2.3.1 of OAuth 2.0 [RFC6749].
  final List<String>? tokenEndpointAuthMethodsSupported;

  /// OPTIONAL. JSON array containing a list of the JWS signing algorithms
  /// (alg values) supported by the Token Endpoint for the signature on the JWT
  /// [JWT] used to authenticate the Client at the Token Endpoint for the
  /// private_key_jwt and client_secret_jwt authentication methods. Servers SHOULD
  /// support RS256. The value none MUST NOT be used.
  final List<String>? tokenEndpointAuthSigningAlgValuesSupported;

  /// OPTIONAL. JSON array containing a list of the display parameter values
  /// that the OpenID Provider supports. These values are described in Section
  /// 3.1.2.1 of OpenID Connect Core 1.0 [OpenID.Core].
  final List<String>? displayValuesSupported;

  /// OPTIONAL. JSON array containing a list of the Claim Types that the
  /// OpenID Provider supports. These Claim Types are described in Section 5.6 of
  /// OpenID Connect Core 1.0 [OpenID.Core]. Values defined by this specification
  /// are normal, aggregated, and distributed. If omitted, the implementation
  /// supports only normal Claims.
  final List<String>? claimTypesSupported;

  /// RECOMMENDED. JSON array containing a list of the Claim Names of the
  /// Claims that the OpenID Provider MAY be able to supply values for. Note that
  /// for privacy or other reasons, this might not be an exhaustive list.
  final List<String>? claimsSupported;

  /// OPTIONAL. URL of a page containing human-readable information that
  /// developers might want or need to know when using the OpenID Provider. In
  /// particular, if the OpenID Provider does not support Dynamic Client
  /// Registration, then information on how to register Clients needs to be
  /// provided in this documentation.
  final String? serviceDocumentation;

  /// OPTIONAL. Languages and scripts supported for values in Claims being
  /// returned, represented as a JSON array of BCP47 [RFC5646] language tag
  /// values. Not all languages and scripts are necessarily supported for all
  /// Claim values.
  final List<String>? claimsLocalesSupported;

  /// OPTIONAL. Languages and scripts supported for the user interface,
  /// represented as a JSON array of BCP47 [RFC5646] language tag values.
  final List<String>? uiLocalesSupported;

  /// OPTIONAL. Boolean value specifying whether the OP supports use of the
  /// claims parameter, with true indicating support. If omitted, the default
  /// value is false.
  final bool? claimsParameterSupported;

  /// OPTIONAL. Boolean value specifying whether the OP supports use of the
  /// request parameter, with true indicating support. If omitted, the default
  /// value is false.
  final bool? requestParameterSupported;

  /// OPTIONAL. Boolean value specifying whether the OP supports use of the
  /// request_uri parameter, with true indicating support. If omitted, the default
  /// value is true.
  final bool? requestUriParameterSupported;

  /// OPTIONAL. Boolean value specifying whether the OP requires any
  /// request_uri values used to be pre-registered using the request_uris
  /// registration parameter. Pre-registration is REQUIRED when the value is true.
  /// If omitted, the default value is false.
  final bool? requireRequestUriRegistration;

  /// OPTIONAL. URL that the OpenID Provider provides to the person
  /// registering the Client to read about the OP's requirements on how the
  /// Relying Party can use the data provided by the OP. The registration process
  /// SHOULD display this URL to the person registering the Client if it is given.
  final String? opPolicyUri;

  /// OPTIONAL. URL that the OpenID Provider provides to the person
  /// registering the Client to read about OpenID Provider's terms of service. The
  /// registration process SHOULD display this URL to the person registering the
  /// Client if it is given.
  final String? opTosUri;

  /// REQUIRED for openid-connect-session. URL of an OP iframe that supports
  /// cross-origin communications for session state information with the RP
  /// Client, using the HTML5 postMessage API. The page is loaded from an
  /// invisible iframe embedded in an RP page so that it can run in the OP's
  /// security context. It accepts postMessage requests from the relevant RP
  /// iframe and uses postMessage to post back the login status of the End-User at
  /// the OP.
  /// https://openid.net/specs/openid-connect-session-1_0.html
  final String? checkSessionIframe;

  /// REQUIRED for openid-connect-session. URL at the OP to which an RP can
  /// perform a redirect to request that the End-User be logged out at the OP.
  final String? endSessionEndpoint;

  /// The OAuth 2.0 device authorization grant endpoint URL.
  /// https://www.rfc-editor.org/rfc/rfc8628
  final String? deviceAuthorizationEndpoint;

  /// The OAuth 2.0 token revocation endpoint URL.
  final String? revocationEndpoint;

  /// List of the supported transformation methods by the authorization code
  /// verifier for Proof Key for Code Exchange (PKCE).
  final List<String>? codeChallengeMethodsSupported;

  /// A list of client authentication methods supported by the
  /// [revocation_endpoint].
  final List<String>? revocationEndpointAuthMethodsSupported;

  /// A list of the JWS signing algorithms (`alg` values) supported by the
  /// [revocation_endpoint] for the signature on the JWT used to authenticate the
  /// client at the revocation endpoint for the `private_key_jwt` and
  /// `client_secret_jwt` authentication methods.
  final List<String>? revocationEndpointAuthSigningAlgValuesSupported;

  ///  The OAuth 2.0 token introspection endpoint URL.
  final String? introspectionEndpoint;

  /// A list of client authentication methods supported by the
  /// [introspection_endpoint].
  final List<String>? introspectionEndpointAuthMethodsSupported;

  /// A list of the JWS signing algorithms (`alg` values) supported by the
  /// [introspection_endpoint] for the signature on the JWT used to authenticate
  /// the client at the introspection endpoint for the `private_key_jwt` and
  /// `client_secret_jwt` authentication methods.
  final List<String>? introspectionEndpointAuthSigningAlgValuesSupported;

  /// The OAuth 2.0 pushed authorisation request (PAR) endpoint URL.
  final String? pushedAuthorizationRequestEndpoint;

  /// List of the support OAuth 2.0 authorisation / OpenID authentication
  /// request prompt parameter values.
  final List<String>? promptValuesSupported;

  /// Indicates support for the iss authorisation response parameter. If
  /// omitted the default value is false.
  final bool? authorizationResponseIssParameterSupported;

  /// List of the supported JWS algorithms for signed authorisation responses
  /// (JARM).
  final List<String>? authorizationSigningAlgValuesSupported;

  /// List of the supported JWE algorithms for encrypted authorisation
  /// responses (JARM).
  final List<String>? authorizationEncryptionAlgValuesSupported;

  /// List of the supported JWE content encryption methods for encrypted
  /// authorisation responses (JARM).
  final List<String>? authorizationEncryptionEncValuesSupported;

  /// Indicates the maximum number of request_uris that can be registered for
  /// a client (custom Connect2id server specific parameter).
  final int? requestUriQuota;

  /// Indicates whether authorisation requests must be pushed via the PAR
  /// endpoint. If omitted the default value is false.
  final bool? requirePushedAuthorizationRequests;

  /// Indicates support for issuing client X.509 certificate bound access
  /// tokens. If omitted the default value is false.
  final bool? tlsClientCertificateBoundAccessTokens;

  /// List of the supported JWS algorithms for DPoP proof JWTs, omitted or
  /// empty if none.
  final List<String>? dpopSigningAlgValuesSupported;

  /// Indicates support for OpenID Connect front-channel logout. If omitted
  /// the default value is false.
  final bool? frontchannelLogoutSupported;

  /// Indicates whether the session ID (sid) will be included in OpenID
  /// Connect front-channel logout notifications. If omitted the default value is
  /// false.
  final bool? frontchannelLogoutSessionSupported;

  /// Indicates support for OpenID Connect back-channel logout. If omitted the
  /// default value is false.
  final bool? backchannelLogoutSupported;

  /// Indicates whether the session ID (sid) will be included in OpenID
  /// Connect back-channel logout notifications. If omitted the default value is
  /// false.
  final bool? backchannelLogoutSessionSupported;

  /// List of the supported OpenID Connect Federation 1.0 client registration
  /// types, omitted if the federation protocol is disabled.
  final List<String>? clientRegistrationTypesSupported;

  /// The name of the organisation in the OpenID Connect Federation 1.0
  /// deployment, omitted if the federation protocol is disabled or a name isn't
  /// specified.
  final String? organizationName;

  /// The OpenID Connect Federation 1.0 registration endpoint URL, omitted if
  /// the federation protocol is disabled.
  final String? federationRegistrationEndpoint;

  /// The supported authentication methods for automatic registration requests
  /// in OpenID Connect Federation, omitted if the federation protocol is
  /// disabled.
  final Map<String, Object?>? clientRegistrationAuthnMethodsSupported;

  /// Indicates support for OpenID Connect for Identity Assurance 1.0. If
  /// omitted the default value is false.
  final bool? verifiedClaimsSupported;

  /// List of the supported trust frameworks if OpenID Connect for Identity
  /// Assurance 1.0 is supported, omitted or empty if none.
  final List<String>? trustFrameworksSupported;

  /// List of the evidence types if OpenID Connect Identity for Assurance 1.0
  /// is supported, omitted or empty if none.
  final List<String>? evidenceSupported;

  /// List of the document types if OpenID Connect for Identity Assurance 1.0
  /// is supported, omitted or empty if none.
  final List<String>? documentsSupported;

  /// List of the identity document types if OpenID Connect for Identity
  /// Assurance 1.0 is supported, omitted or empty if none. Deprecated.
  final List<String>? idDocumentsSupported;

  /// List of the supported coarse identity verification methods for evidences
  /// of type document if OpenID Connect for Identity Assurance 1.0 is supported,
  /// omitted or empty if none.
  final List<String>? documentsMethodsSupported;

  /// List of the supported validation methods for evidences of type document
  /// if OpenID Connect for Identity Assurance 1.0 is supported, omitted or empty
  /// if none.
  final List<String>? documentsValidationMethodsSupported;

  /// List of the supported person verification methods for evidences of type
  /// document if OpenID Connect for Identity Assurance 1.0 is supported, omitted
  /// or empty if none.
  final List<String>? documentsVerificationMethodsSupported;

  /// List of the identity document verification methods if OpenID Connect for
  /// Identity Assurance 1.0 is supported, omitted or empty if none. Deprecated.
  final List<String>? idDocumentsVerificationMethodsSupported;

  /// List of the supported electronic record types if OpenID Connect for
  /// Identity Assurance 1.0 is supported, omitted or empty if none.
  final List<String>? electronicRecordsSupported;

  /// List of the supported verified claims if OpenID Connect for Identity
  /// Assurance 1.0 is supported, omitted or empty if none.
  final List<String>? claimsInVerifiedClaimsSupported;

  /// List of the supported attachment types (embedded, external) if OpenID
  /// Connect for Identity Assurance 1.0 is supported, empty if none.
  final List<String>? attachmentsSupported;

  /// List of the the supported digest algorithms for external attachments if
  /// OpenID Connect for Identity Assurance 1.0 is supported, omitted or empty if
  /// none. The "sha-256" algorithm is always supported for external external
  /// attachments.
  final List<String>? digestAlgorithmsSupported;

  /// A JSON Map of additional values not supported in the constructor,
  /// or the raw json Map passed as argument in [OpenIdConfiguration.fromJson].
  final Map<String, Object?>? baseMap;

  const OpenIdConfiguration({
    required this.issuer,
    required this.authorizationEndpoint,
    this.tokenEndpoint,
    this.userinfoEndpoint,
    required this.jwksUri,
    this.registrationEndpoint,
    this.scopesSupported,
    required this.responseTypesSupported,
    this.responseModesSupported,
    this.grantTypesSupported,
    this.acrValuesSupported,
    this.subjectTypesSupported,
    required this.idTokenSigningAlgValuesSupported,
    this.idTokenEncryptionAlgValuesSupported,
    this.idTokenEncryptionEncValuesSupported,
    this.userinfoSigningAlgValuesSupported,
    this.userinfoEncryptionAlgValuesSupported,
    this.userinfoEncryptionEncValuesSupported,
    this.requestObjectSigningAlgValuesSupported,
    this.requestObjectEncryptionAlgValuesSupported,
    this.requestObjectEncryptionEncValuesSupported,
    this.tokenEndpointAuthMethodsSupported,
    this.tokenEndpointAuthSigningAlgValuesSupported,
    this.displayValuesSupported,
    this.claimTypesSupported,
    this.claimsSupported,
    this.serviceDocumentation,
    this.claimsLocalesSupported,
    this.uiLocalesSupported,
    this.claimsParameterSupported,
    this.requestParameterSupported,
    this.requestUriParameterSupported,
    this.requireRequestUriRegistration,
    this.opPolicyUri,
    this.opTosUri,
    this.checkSessionIframe,
    this.endSessionEndpoint,
    this.deviceAuthorizationEndpoint,
    this.revocationEndpoint,
    this.codeChallengeMethodsSupported,
    this.revocationEndpointAuthMethodsSupported,
    this.revocationEndpointAuthSigningAlgValuesSupported,
    this.introspectionEndpoint,
    this.introspectionEndpointAuthMethodsSupported,
    this.introspectionEndpointAuthSigningAlgValuesSupported,
    this.pushedAuthorizationRequestEndpoint,
    this.promptValuesSupported,
    this.authorizationResponseIssParameterSupported,
    this.authorizationSigningAlgValuesSupported,
    this.authorizationEncryptionAlgValuesSupported,
    this.authorizationEncryptionEncValuesSupported,
    this.requestUriQuota,
    this.requirePushedAuthorizationRequests,
    this.tlsClientCertificateBoundAccessTokens,
    this.dpopSigningAlgValuesSupported,
    this.frontchannelLogoutSupported,
    this.frontchannelLogoutSessionSupported,
    this.backchannelLogoutSupported,
    this.backchannelLogoutSessionSupported,
    this.clientRegistrationTypesSupported,
    this.organizationName,
    this.federationRegistrationEndpoint,
    this.clientRegistrationAuthnMethodsSupported,
    this.verifiedClaimsSupported,
    this.trustFrameworksSupported,
    this.evidenceSupported,
    this.documentsSupported,
    this.idDocumentsSupported,
    this.documentsMethodsSupported,
    this.documentsValidationMethodsSupported,
    this.documentsVerificationMethodsSupported,
    this.idDocumentsVerificationMethodsSupported,
    this.electronicRecordsSupported,
    this.claimsInVerifiedClaimsSupported,
    this.attachmentsSupported,
    this.digestAlgorithmsSupported,
    this.baseMap,
  });

// generated-dart-fixer-start{"jsonKeyCase":"snake_case","md5Hash":"TzAbcW7IQ9emgw5KBR27oQ=="}

  factory OpenIdConfiguration.fromJson(Map json) {
    return OpenIdConfiguration(
      baseMap: json.cast(),
      issuer: json['issuer'] as String,
      authorizationEndpoint: json['authorization_endpoint'] as String,
      tokenEndpoint: json['token_endpoint'] as String?,
      userinfoEndpoint: json['userinfo_endpoint'] as String?,
      jwksUri: json['jwks_uri'] as String?,
      registrationEndpoint: json['registration_endpoint'] as String?,
      scopesSupported: json['scopes_supported'] == null
          ? null
          : (json['scopes_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      responseTypesSupported: (json['response_types_supported'] as Iterable)
          .map((v) => v as String)
          .toList(),
      responseModesSupported: json['response_modes_supported'] == null
          ? null
          : (json['response_modes_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      grantTypesSupported: json['grant_types_supported'] == null
          ? null
          : (json['grant_types_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      acrValuesSupported: json['acr_values_supported'] == null
          ? null
          : (json['acr_values_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      subjectTypesSupported: json['subject_types_supported'] == null
          ? null
          : (json['subject_types_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      idTokenSigningAlgValuesSupported:
          (json['id_token_signing_alg_values_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      idTokenEncryptionAlgValuesSupported:
          json['id_token_encryption_alg_values_supported'] == null
              ? null
              : (json['id_token_encryption_alg_values_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      idTokenEncryptionEncValuesSupported:
          json['id_token_encryption_enc_values_supported'] == null
              ? null
              : (json['id_token_encryption_enc_values_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      userinfoSigningAlgValuesSupported:
          json['userinfo_signing_alg_values_supported'] == null
              ? null
              : (json['userinfo_signing_alg_values_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      userinfoEncryptionAlgValuesSupported:
          json['userinfo_encryption_alg_values_supported'] == null
              ? null
              : (json['userinfo_encryption_alg_values_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      userinfoEncryptionEncValuesSupported:
          json['userinfo_encryption_enc_values_supported'] == null
              ? null
              : (json['userinfo_encryption_enc_values_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      requestObjectSigningAlgValuesSupported:
          json['request_object_signing_alg_values_supported'] == null
              ? null
              : (json['request_object_signing_alg_values_supported']
                      as Iterable)
                  .map((v) => v as String)
                  .toList(),
      requestObjectEncryptionAlgValuesSupported:
          json['request_object_encryption_alg_values_supported'] == null
              ? null
              : (json['request_object_encryption_alg_values_supported']
                      as Iterable)
                  .map((v) => v as String)
                  .toList(),
      requestObjectEncryptionEncValuesSupported:
          json['request_object_encryption_enc_values_supported'] == null
              ? null
              : (json['request_object_encryption_enc_values_supported']
                      as Iterable)
                  .map((v) => v as String)
                  .toList(),
      tokenEndpointAuthMethodsSupported:
          json['token_endpoint_auth_methods_supported'] == null
              ? null
              : (json['token_endpoint_auth_methods_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      tokenEndpointAuthSigningAlgValuesSupported:
          json['token_endpoint_auth_signing_alg_values_supported'] == null
              ? null
              : (json['token_endpoint_auth_signing_alg_values_supported']
                      as Iterable)
                  .map((v) => v as String)
                  .toList(),
      displayValuesSupported: json['display_values_supported'] == null
          ? null
          : (json['display_values_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      claimTypesSupported: json['claim_types_supported'] == null
          ? null
          : (json['claim_types_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      claimsSupported: json['claims_supported'] == null
          ? null
          : (json['claims_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      serviceDocumentation: json['service_documentation'] as String?,
      claimsLocalesSupported: json['claims_locales_supported'] == null
          ? null
          : (json['claims_locales_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      uiLocalesSupported: json['ui_locales_supported'] == null
          ? null
          : (json['ui_locales_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      claimsParameterSupported: json['claims_parameter_supported'] as bool?,
      requestParameterSupported: json['request_parameter_supported'] as bool?,
      requestUriParameterSupported:
          json['request_uri_parameter_supported'] as bool?,
      requireRequestUriRegistration:
          json['require_request_uri_registration'] as bool?,
      opPolicyUri: json['op_policy_uri'] as String?,
      opTosUri: json['op_tos_uri'] as String?,
      checkSessionIframe: json['check_session_iframe'] as String?,
      endSessionEndpoint: json['end_session_endpoint'] as String?,
      deviceAuthorizationEndpoint:
          json['device_authorization_endpoint'] as String?,
      revocationEndpoint: json['revocation_endpoint'] as String?,
      codeChallengeMethodsSupported:
          json['code_challenge_methods_supported'] == null
              ? null
              : (json['code_challenge_methods_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      revocationEndpointAuthMethodsSupported:
          json['revocation_endpoint_auth_methods_supported'] == null
              ? null
              : (json['revocation_endpoint_auth_methods_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      revocationEndpointAuthSigningAlgValuesSupported:
          json['revocation_endpoint_auth_signing_alg_values_supported'] == null
              ? null
              : (json['revocation_endpoint_auth_signing_alg_values_supported']
                      as Iterable)
                  .map((v) => v as String)
                  .toList(),
      introspectionEndpoint: json['introspection_endpoint'] as String?,
      introspectionEndpointAuthMethodsSupported:
          json['introspection_endpoint_auth_methods_supported'] == null
              ? null
              : (json['introspection_endpoint_auth_methods_supported']
                      as Iterable)
                  .map((v) => v as String)
                  .toList(),
      introspectionEndpointAuthSigningAlgValuesSupported: json[
                  'introspection_endpoint_auth_signing_alg_values_supported'] ==
              null
          ? null
          : (json['introspection_endpoint_auth_signing_alg_values_supported']
                  as Iterable)
              .map((v) => v as String)
              .toList(),
      pushedAuthorizationRequestEndpoint:
          json['pushed_authorization_request_endpoint'] as String?,
      promptValuesSupported: json['prompt_values_supported'] == null
          ? null
          : (json['prompt_values_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      authorizationResponseIssParameterSupported:
          json['authorization_response_iss_parameter_supported'] as bool?,
      authorizationSigningAlgValuesSupported:
          json['authorization_signing_alg_values_supported'] == null
              ? null
              : (json['authorization_signing_alg_values_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      authorizationEncryptionAlgValuesSupported:
          json['authorization_encryption_alg_values_supported'] == null
              ? null
              : (json['authorization_encryption_alg_values_supported']
                      as Iterable)
                  .map((v) => v as String)
                  .toList(),
      authorizationEncryptionEncValuesSupported:
          json['authorization_encryption_enc_values_supported'] == null
              ? null
              : (json['authorization_encryption_enc_values_supported']
                      as Iterable)
                  .map((v) => v as String)
                  .toList(),
      requestUriQuota: json['request_uri_quota'] as int?,
      requirePushedAuthorizationRequests:
          json['require_pushed_authorization_requests'] as bool?,
      tlsClientCertificateBoundAccessTokens:
          json['tls_client_certificate_bound_access_tokens'] as bool?,
      dpopSigningAlgValuesSupported:
          json['dpop_signing_alg_values_supported'] == null
              ? null
              : (json['dpop_signing_alg_values_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      frontchannelLogoutSupported:
          json['frontchannel_logout_supported'] as bool?,
      frontchannelLogoutSessionSupported:
          json['frontchannel_logout_session_supported'] as bool?,
      backchannelLogoutSupported: json['backchannel_logout_supported'] as bool?,
      backchannelLogoutSessionSupported:
          json['backchannel_logout_session_supported'] as bool?,
      clientRegistrationTypesSupported:
          json['client_registration_types_supported'] == null
              ? null
              : (json['client_registration_types_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      organizationName: json['organization_name'] as String?,
      federationRegistrationEndpoint:
          json['federation_registration_endpoint'] as String?,
      clientRegistrationAuthnMethodsSupported:
          json['client_registration_authn_methods_supported'] == null
              ? null
              : (json['client_registration_authn_methods_supported'] as Map)
                  .map((k, v) => MapEntry(k as String, v)),
      verifiedClaimsSupported: json['verified_claims_supported'] as bool?,
      trustFrameworksSupported: json['trust_frameworks_supported'] == null
          ? null
          : (json['trust_frameworks_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      evidenceSupported: json['evidence_supported'] == null
          ? null
          : (json['evidence_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      documentsSupported: json['documents_supported'] == null
          ? null
          : (json['documents_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      idDocumentsSupported: json['id_documents_supported'] == null
          ? null
          : (json['id_documents_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      documentsMethodsSupported: json['documents_methods_supported'] == null
          ? null
          : (json['documents_methods_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      documentsValidationMethodsSupported:
          json['documents_validation_methods_supported'] == null
              ? null
              : (json['documents_validation_methods_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      documentsVerificationMethodsSupported:
          json['documents_verification_methods_supported'] == null
              ? null
              : (json['documents_verification_methods_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      idDocumentsVerificationMethodsSupported:
          json['id_documents_verification_methods_supported'] == null
              ? null
              : (json['id_documents_verification_methods_supported']
                      as Iterable)
                  .map((v) => v as String)
                  .toList(),
      electronicRecordsSupported: json['electronic_records_supported'] == null
          ? null
          : (json['electronic_records_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      claimsInVerifiedClaimsSupported:
          json['claims_in_verified_claims_supported'] == null
              ? null
              : (json['claims_in_verified_claims_supported'] as Iterable)
                  .map((v) => v as String)
                  .toList(),
      attachmentsSupported: json['attachments_supported'] == null
          ? null
          : (json['attachments_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
      digestAlgorithmsSupported: json['digest_algorithms_supported'] == null
          ? null
          : (json['digest_algorithms_supported'] as Iterable)
              .map((v) => v as String)
              .toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'issuer': issuer,
      'authorization_endpoint': authorizationEndpoint,
      'token_endpoint': tokenEndpoint,
      'userinfo_endpoint': userinfoEndpoint,
      'jwks_uri': jwksUri,
      'registration_endpoint': registrationEndpoint,
      'scopes_supported': scopesSupported,
      'response_types_supported': responseTypesSupported,
      'response_modes_supported': responseModesSupported,
      'grant_types_supported': grantTypesSupported,
      'acr_values_supported': acrValuesSupported,
      'subject_types_supported': subjectTypesSupported,
      'id_token_signing_alg_values_supported': idTokenSigningAlgValuesSupported,
      'id_token_encryption_alg_values_supported':
          idTokenEncryptionAlgValuesSupported,
      'id_token_encryption_enc_values_supported':
          idTokenEncryptionEncValuesSupported,
      'userinfo_signing_alg_values_supported':
          userinfoSigningAlgValuesSupported,
      'userinfo_encryption_alg_values_supported':
          userinfoEncryptionAlgValuesSupported,
      'userinfo_encryption_enc_values_supported':
          userinfoEncryptionEncValuesSupported,
      'request_object_signing_alg_values_supported':
          requestObjectSigningAlgValuesSupported,
      'request_object_encryption_alg_values_supported':
          requestObjectEncryptionAlgValuesSupported,
      'request_object_encryption_enc_values_supported':
          requestObjectEncryptionEncValuesSupported,
      'token_endpoint_auth_methods_supported':
          tokenEndpointAuthMethodsSupported,
      'token_endpoint_auth_signing_alg_values_supported':
          tokenEndpointAuthSigningAlgValuesSupported,
      'display_values_supported': displayValuesSupported,
      'claim_types_supported': claimTypesSupported,
      'claims_supported': claimsSupported,
      'service_documentation': serviceDocumentation,
      'claims_locales_supported': claimsLocalesSupported,
      'ui_locales_supported': uiLocalesSupported,
      'claims_parameter_supported': claimsParameterSupported,
      'request_parameter_supported': requestParameterSupported,
      'request_uri_parameter_supported': requestUriParameterSupported,
      'require_request_uri_registration': requireRequestUriRegistration,
      'op_policy_uri': opPolicyUri,
      'op_tos_uri': opTosUri,
      'check_session_iframe': checkSessionIframe,
      'end_session_endpoint': endSessionEndpoint,
      'device_authorization_endpoint': deviceAuthorizationEndpoint,
      'revocation_endpoint': revocationEndpoint,
      'code_challenge_methods_supported': codeChallengeMethodsSupported,
      'revocation_endpoint_auth_methods_supported':
          revocationEndpointAuthMethodsSupported,
      'revocation_endpoint_auth_signing_alg_values_supported':
          revocationEndpointAuthSigningAlgValuesSupported,
      'introspection_endpoint': introspectionEndpoint,
      'introspection_endpoint_auth_methods_supported':
          introspectionEndpointAuthMethodsSupported,
      'introspection_endpoint_auth_signing_alg_values_supported':
          introspectionEndpointAuthSigningAlgValuesSupported,
      'pushed_authorization_request_endpoint':
          pushedAuthorizationRequestEndpoint,
      'prompt_values_supported': promptValuesSupported,
      'authorization_response_iss_parameter_supported':
          authorizationResponseIssParameterSupported,
      'authorization_signing_alg_values_supported':
          authorizationSigningAlgValuesSupported,
      'authorization_encryption_alg_values_supported':
          authorizationEncryptionAlgValuesSupported,
      'authorization_encryption_enc_values_supported':
          authorizationEncryptionEncValuesSupported,
      'request_uri_quota': requestUriQuota,
      'require_pushed_authorization_requests':
          requirePushedAuthorizationRequests,
      'tls_client_certificate_bound_access_tokens':
          tlsClientCertificateBoundAccessTokens,
      'dpop_signing_alg_values_supported': dpopSigningAlgValuesSupported,
      'frontchannel_logout_supported': frontchannelLogoutSupported,
      'frontchannel_logout_session_supported':
          frontchannelLogoutSessionSupported,
      'backchannel_logout_supported': backchannelLogoutSupported,
      'backchannel_logout_session_supported': backchannelLogoutSessionSupported,
      'client_registration_types_supported': clientRegistrationTypesSupported,
      'organization_name': organizationName,
      'federation_registration_endpoint': federationRegistrationEndpoint,
      'client_registration_authn_methods_supported':
          clientRegistrationAuthnMethodsSupported,
      'verified_claims_supported': verifiedClaimsSupported,
      'trust_frameworks_supported': trustFrameworksSupported,
      'evidence_supported': evidenceSupported,
      'documents_supported': documentsSupported,
      'id_documents_supported': idDocumentsSupported,
      'documents_methods_supported': documentsMethodsSupported,
      'documents_validation_methods_supported':
          documentsValidationMethodsSupported,
      'documents_verification_methods_supported':
          documentsVerificationMethodsSupported,
      'id_documents_verification_methods_supported':
          idDocumentsVerificationMethodsSupported,
      'electronic_records_supported': electronicRecordsSupported,
      'claims_in_verified_claims_supported': claimsInVerifiedClaimsSupported,
      'attachments_supported': attachmentsSupported,
      'digest_algorithms_supported': digestAlgorithmsSupported,
      ...?baseMap,
    }..removeWhere((key, value) => value == null);
  }

  @override
  String toString() {
    return "OpenIdConfiguration${{
      "issuer": issuer,
      "authorizationEndpoint": authorizationEndpoint,
      "tokenEndpoint": tokenEndpoint,
      "userinfoEndpoint": userinfoEndpoint,
      "jwksUri": jwksUri,
      "registrationEndpoint": registrationEndpoint,
      "scopesSupported": scopesSupported,
      "responseTypesSupported": responseTypesSupported,
      "responseModesSupported": responseModesSupported,
      "grantTypesSupported": grantTypesSupported,
      "acrValuesSupported": acrValuesSupported,
      "subjectTypesSupported": subjectTypesSupported,
      "idTokenSigningAlgValuesSupported": idTokenSigningAlgValuesSupported,
      "idTokenEncryptionAlgValuesSupported":
          idTokenEncryptionAlgValuesSupported,
      "idTokenEncryptionEncValuesSupported":
          idTokenEncryptionEncValuesSupported,
      "userinfoSigningAlgValuesSupported": userinfoSigningAlgValuesSupported,
      "userinfoEncryptionAlgValuesSupported":
          userinfoEncryptionAlgValuesSupported,
      "userinfoEncryptionEncValuesSupported":
          userinfoEncryptionEncValuesSupported,
      "requestObjectSigningAlgValuesSupported":
          requestObjectSigningAlgValuesSupported,
      "requestObjectEncryptionAlgValuesSupported":
          requestObjectEncryptionAlgValuesSupported,
      "requestObjectEncryptionEncValuesSupported":
          requestObjectEncryptionEncValuesSupported,
      "tokenEndpointAuthMethodsSupported": tokenEndpointAuthMethodsSupported,
      "tokenEndpointAuthSigningAlgValuesSupported":
          tokenEndpointAuthSigningAlgValuesSupported,
      "displayValuesSupported": displayValuesSupported,
      "claimTypesSupported": claimTypesSupported,
      "claimsSupported": claimsSupported,
      "serviceDocumentation": serviceDocumentation,
      "claimsLocalesSupported": claimsLocalesSupported,
      "uiLocalesSupported": uiLocalesSupported,
      "claimsParameterSupported": claimsParameterSupported,
      "requestParameterSupported": requestParameterSupported,
      "requestUriParameterSupported": requestUriParameterSupported,
      "requireRequestUriRegistration": requireRequestUriRegistration,
      "opPolicyUri": opPolicyUri,
      "opTosUri": opTosUri,
      "checkSessionIframe": checkSessionIframe,
      "endSessionEndpoint": endSessionEndpoint,
      "deviceAuthorizationEndpoint": deviceAuthorizationEndpoint,
      "revocationEndpoint": revocationEndpoint,
      "codeChallengeMethodsSupported": codeChallengeMethodsSupported,
      "revocationEndpointAuthMethodsSupported":
          revocationEndpointAuthMethodsSupported,
      "revocationEndpointAuthSigningAlgValuesSupported":
          revocationEndpointAuthSigningAlgValuesSupported,
      "introspectionEndpoint": introspectionEndpoint,
      "introspectionEndpointAuthMethodsSupported":
          introspectionEndpointAuthMethodsSupported,
      "introspectionEndpointAuthSigningAlgValuesSupported":
          introspectionEndpointAuthSigningAlgValuesSupported,
      "pushedAuthorizationRequestEndpoint": pushedAuthorizationRequestEndpoint,
      "promptValuesSupported": promptValuesSupported,
      "authorizationResponseIssParameterSupported":
          authorizationResponseIssParameterSupported,
      "authorizationSigningAlgValuesSupported":
          authorizationSigningAlgValuesSupported,
      "authorizationEncryptionAlgValuesSupported":
          authorizationEncryptionAlgValuesSupported,
      "authorizationEncryptionEncValuesSupported":
          authorizationEncryptionEncValuesSupported,
      "requestUriQuota": requestUriQuota,
      "requirePushedAuthorizationRequests": requirePushedAuthorizationRequests,
      "tlsClientCertificateBoundAccessTokens":
          tlsClientCertificateBoundAccessTokens,
      "dpopSigningAlgValuesSupported": dpopSigningAlgValuesSupported,
      "frontchannelLogoutSupported": frontchannelLogoutSupported,
      "frontchannelLogoutSessionSupported": frontchannelLogoutSessionSupported,
      "backchannelLogoutSupported": backchannelLogoutSupported,
      "backchannelLogoutSessionSupported": backchannelLogoutSessionSupported,
      "clientRegistrationTypesSupported": clientRegistrationTypesSupported,
      "organizationName": organizationName,
      "federationRegistrationEndpoint": federationRegistrationEndpoint,
      "clientRegistrationAuthnMethodsSupported":
          clientRegistrationAuthnMethodsSupported,
      "verifiedClaimsSupported": verifiedClaimsSupported,
      "trustFrameworksSupported": trustFrameworksSupported,
      "evidenceSupported": evidenceSupported,
      "documentsSupported": documentsSupported,
      "idDocumentsSupported": idDocumentsSupported,
      "documentsMethodsSupported": documentsMethodsSupported,
      "documentsValidationMethodsSupported":
          documentsValidationMethodsSupported,
      "documentsVerificationMethodsSupported":
          documentsVerificationMethodsSupported,
      "idDocumentsVerificationMethodsSupported":
          idDocumentsVerificationMethodsSupported,
      "electronicRecordsSupported": electronicRecordsSupported,
      "claimsInVerifiedClaimsSupported": claimsInVerifiedClaimsSupported,
      "attachmentsSupported": attachmentsSupported,
      "digestAlgorithmsSupported": digestAlgorithmsSupported,
      "baseMap": baseMap,
    }..removeWhere((key, value) => value == null)}";
  }
}

// generated-dart-fixer-end{"jsonKeyCase":"snake_case","md5Hash":"TzAbcW7IQ9emgw5KBR27oQ=="}
