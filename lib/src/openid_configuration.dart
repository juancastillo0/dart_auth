/// @example
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
class OpenIdConfiguration {
  factory OpenIdConfiguration.fromJson(Map json) {
    return OpenIdConfiguration(
      issuer: json["issuer"] as String,
      authorization_endpoint: json["authorization_endpoint"] as String,
      device_authorization_endpoint:
          json["device_authorization_endpoint"] as String,
      token_endpoint: json["token_endpoint"] as String,
      userinfo_endpoint: json["userinfo_endpoint"] as String,
      revocation_endpoint: json["revocation_endpoint"] as String,
      jwks_uri: json["jwks_uri"] as String,
      response_types_supported: (json["response_types_supported"] as Iterable)
          .map((v) => v as String)
          .toList(),
      subject_types_supported: (json["subject_types_supported"] as Iterable)
          .map((v) => v as String)
          .toList(),
      id_token_signing_alg_values_supported:
          (json["id_token_signing_alg_values_supported"] as Iterable)
              .map((v) => v as String)
              .toList(),
      scopes_supported: (json["scopes_supported"] as Iterable)
          .map((v) => v as String)
          .toList(),
      token_endpoint_auth_methods_supported:
          (json["token_endpoint_auth_methods_supported"] as Iterable)
              .map((v) => v as String)
              .toList(),
      claims_supported: (json["claims_supported"] as Iterable)
          .map((v) => v as String)
          .toList(),
      code_challenge_methods_supported:
          (json["code_challenge_methods_supported"] as Iterable)
              .map((v) => v as String)
              .toList(),
      grant_types_supported: (json["grant_types_supported"] as Iterable)
          .map((v) => v as String)
          .toList(),
    );
  }

  ///
  const OpenIdConfiguration({
    required this.issuer,
    required this.authorization_endpoint,
    required this.device_authorization_endpoint,
    required this.token_endpoint,
    required this.userinfo_endpoint,
    required this.revocation_endpoint,
    required this.jwks_uri,
    required this.response_types_supported,
    required this.subject_types_supported,
    required this.id_token_signing_alg_values_supported,
    required this.scopes_supported,
    required this.token_endpoint_auth_methods_supported,
    required this.claims_supported,
    required this.code_challenge_methods_supported,
    required this.grant_types_supported,
  });
  final String issuer;
  final String authorization_endpoint;
  final String device_authorization_endpoint;
  final String token_endpoint;
  final String userinfo_endpoint;
  final String revocation_endpoint;
  final String jwks_uri;
  final List<String> response_types_supported;
  final List<String> subject_types_supported;
  final List<String> id_token_signing_alg_values_supported;
  final List<String> scopes_supported;
  final List<String> token_endpoint_auth_methods_supported;
  final List<String> claims_supported;
  final List<String> code_challenge_methods_supported;
  final List<String> grant_types_supported;

  Map<String, Object?> toJson() {
    return {
      'issuer': issuer,
      'authorization_endpoint': authorization_endpoint,
      'device_authorization_endpoint': device_authorization_endpoint,
      'token_endpoint': token_endpoint,
      'userinfo_endpoint': userinfo_endpoint,
      'revocation_endpoint': revocation_endpoint,
      'jwks_uri': jwks_uri,
      'response_types_supported': response_types_supported,
      'subject_types_supported': subject_types_supported,
      'id_token_signing_alg_values_supported':
          id_token_signing_alg_values_supported,
      'scopes_supported': scopes_supported,
      'token_endpoint_auth_methods_supported':
          token_endpoint_auth_methods_supported,
      'claims_supported': claims_supported,
      'code_challenge_methods_supported': code_challenge_methods_supported,
      'grant_types_supported': grant_types_supported,
    };
  }

  OpenIdConfiguration copyWith({
    String? issuer,
    String? authorization_endpoint,
    String? device_authorization_endpoint,
    String? token_endpoint,
    String? userinfo_endpoint,
    String? revocation_endpoint,
    String? jwks_uri,
    List<String>? response_types_supported,
    List<String>? subject_types_supported,
    List<String>? id_token_signing_alg_values_supported,
    List<String>? scopes_supported,
    List<String>? token_endpoint_auth_methods_supported,
    List<String>? claims_supported,
    List<String>? code_challenge_methods_supported,
    List<String>? grant_types_supported,
  }) {
    return OpenIdConfiguration(
      issuer: issuer ?? this.issuer,
      authorization_endpoint:
          authorization_endpoint ?? this.authorization_endpoint,
      device_authorization_endpoint:
          device_authorization_endpoint ?? this.device_authorization_endpoint,
      token_endpoint: token_endpoint ?? this.token_endpoint,
      userinfo_endpoint: userinfo_endpoint ?? this.userinfo_endpoint,
      revocation_endpoint: revocation_endpoint ?? this.revocation_endpoint,
      jwks_uri: jwks_uri ?? this.jwks_uri,
      response_types_supported:
          response_types_supported ?? this.response_types_supported,
      subject_types_supported:
          subject_types_supported ?? this.subject_types_supported,
      id_token_signing_alg_values_supported:
          id_token_signing_alg_values_supported ??
              this.id_token_signing_alg_values_supported,
      scopes_supported: scopes_supported ?? this.scopes_supported,
      token_endpoint_auth_methods_supported:
          token_endpoint_auth_methods_supported ??
              this.token_endpoint_auth_methods_supported,
      claims_supported: claims_supported ?? this.claims_supported,
      code_challenge_methods_supported: code_challenge_methods_supported ??
          this.code_challenge_methods_supported,
      grant_types_supported:
          grant_types_supported ?? this.grant_types_supported,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is OpenIdConfiguration &&
            other.runtimeType == runtimeType &&
            other.issuer == issuer &&
            other.authorization_endpoint == authorization_endpoint &&
            other.device_authorization_endpoint ==
                device_authorization_endpoint &&
            other.token_endpoint == token_endpoint &&
            other.userinfo_endpoint == userinfo_endpoint &&
            other.revocation_endpoint == revocation_endpoint &&
            other.jwks_uri == jwks_uri &&
            other.response_types_supported == response_types_supported &&
            other.subject_types_supported == subject_types_supported &&
            other.id_token_signing_alg_values_supported ==
                id_token_signing_alg_values_supported &&
            other.scopes_supported == scopes_supported &&
            other.token_endpoint_auth_methods_supported ==
                token_endpoint_auth_methods_supported &&
            other.claims_supported == claims_supported &&
            other.code_challenge_methods_supported ==
                code_challenge_methods_supported &&
            other.grant_types_supported == grant_types_supported;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      issuer,
      authorization_endpoint,
      device_authorization_endpoint,
      token_endpoint,
      userinfo_endpoint,
      revocation_endpoint,
      jwks_uri,
      response_types_supported,
      subject_types_supported,
      id_token_signing_alg_values_supported,
      scopes_supported,
      token_endpoint_auth_methods_supported,
      claims_supported,
      code_challenge_methods_supported,
      grant_types_supported,
    ]);
  }

  @override
  String toString() {
    return "OpenIdConfiguration${{
      "issuer": issuer,
      "authorization_endpoint": authorization_endpoint,
      "device_authorization_endpoint": device_authorization_endpoint,
      "token_endpoint": token_endpoint,
      "userinfo_endpoint": userinfo_endpoint,
      "revocation_endpoint": revocation_endpoint,
      "jwks_uri": jwks_uri,
      "response_types_supported": response_types_supported,
      "subject_types_supported": subject_types_supported,
      "id_token_signing_alg_values_supported":
          id_token_signing_alg_values_supported,
      "scopes_supported": scopes_supported,
      "token_endpoint_auth_methods_supported":
          token_endpoint_auth_methods_supported,
      "claims_supported": claims_supported,
      "code_challenge_methods_supported": code_challenge_methods_supported,
      "grant_types_supported": grant_types_supported,
    }}";
  }

  List<Object?> get props => [
        issuer,
        authorization_endpoint,
        device_authorization_endpoint,
        token_endpoint,
        userinfo_endpoint,
        revocation_endpoint,
        jwks_uri,
        response_types_supported,
        subject_types_supported,
        id_token_signing_alg_values_supported,
        scopes_supported,
        token_endpoint_auth_methods_supported,
        claims_supported,
        code_challenge_methods_supported,
        grant_types_supported,
      ];
}
