/// https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration
// ignore_for_file: prefer_single_quotes

const microsoftConfig = {
  "token_endpoint":
      "https://login.microsoftonline.com/common/oauth2/v2.0/token",
  "token_endpoint_auth_methods_supported": [
    "client_secret_post",
    "private_key_jwt",
    "client_secret_basic"
  ],
  "jwks_uri": "https://login.microsoftonline.com/common/discovery/v2.0/keys",
  "response_modes_supported": ["query", "fragment", "form_post"],
  "subject_types_supported": ["pairwise"],
  "id_token_signing_alg_values_supported": ["RS256"],
  "response_types_supported": [
    "code",
    "id_token",
    "code id_token",
    "id_token token"
  ],
  "scopes_supported": ["openid", "profile", "email", "offline_access"],
  "issuer": "https://login.microsoftonline.com/{tenantid}/v2.0",
  "request_uri_parameter_supported": false,
  "userinfo_endpoint": "https://graph.microsoft.com/oidc/userinfo",
  "authorization_endpoint":
      "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
  "device_authorization_endpoint":
      "https://login.microsoftonline.com/common/oauth2/v2.0/devicecode",
  "http_logout_supported": true,
  "frontchannel_logout_supported": true,
  "end_session_endpoint":
      "https://login.microsoftonline.com/common/oauth2/v2.0/logout",
  "claims_supported": [
    "sub",
    "iss",
    "cloud_instance_name",
    "cloud_instance_host_name",
    "cloud_graph_host_name",
    "msgraph_host",
    "aud",
    "exp",
    "iat",
    "auth_time",
    "acr",
    "nonce",
    "preferred_username",
    "name",
    "tid",
    "ver",
    "at_hash",
    "c_hash",
    "email"
  ],
  "kerberos_endpoint": "https://login.microsoftonline.com/common/kerberos",
  "tenant_region_scope": null,
  "cloud_instance_name": "microsoftonline.com",
  "cloud_graph_host_name": "graph.windows.net",
  "msgraph_host": "graph.microsoft.com",
  "rbac_url": "https://pas.windows.net"
};

/// https://accounts.google.com/.well-known/openid-configuration
const googleConfig = {
  "issuer": "https://accounts.google.com",
  "authorization_endpoint": "https://accounts.google.com/o/oauth2/v2/auth",
  "device_authorization_endpoint": "https://oauth2.googleapis.com/device/code",
  "token_endpoint": "https://oauth2.googleapis.com/token",
  "userinfo_endpoint": "https://openidconnect.googleapis.com/v1/userinfo",
  "revocation_endpoint": "https://oauth2.googleapis.com/revoke",
  "jwks_uri": "https://www.googleapis.com/oauth2/v3/certs",
  "response_types_supported": [
    "code",
    "token",
    "id_token",
    "code token",
    "code id_token",
    "token id_token",
    "code token id_token",
    "none"
  ],
  "subject_types_supported": ["public"],
  "id_token_signing_alg_values_supported": ["RS256"],
  "scopes_supported": ["openid", "email", "profile"],
  "token_endpoint_auth_methods_supported": [
    "client_secret_post",
    "client_secret_basic"
  ],
  "claims_supported": [
    "aud",
    "email",
    "email_verified",
    "exp",
    "family_name",
    "given_name",
    "iat",
    "iss",
    "locale",
    "name",
    "picture",
    "sub"
  ],
  "code_challenge_methods_supported": ["plain", "S256"],
  "grant_types_supported": [
    "authorization_code",
    "refresh_token",
    "urn:ietf:params:oauth:grant-type:device_code",
    "urn:ietf:params:oauth:grant-type:jwt-bearer"
  ]
};

/// https://id.twitch.tv/oauth2/.well-known/openid-configuration
const twitchConfig = {
  "authorization_endpoint": "https://id.twitch.tv/oauth2/authorize",
  "claims_parameter_supported": true,
  "claims_supported": [
    "azp",
    "picture",
    "preferred_username",
    "aud",
    "exp",
    "iss",
    "sub",
    "iat",
    "email",
    "email_verified",
    "updated_at"
  ],
  "id_token_signing_alg_values_supported": ["RS256"],
  "issuer": "https://id.twitch.tv/oauth2",
  "jwks_uri": "https://id.twitch.tv/oauth2/keys",
  "response_types_supported": [
    "id_token",
    "code",
    "token",
    "code id_token",
    "token id_token"
  ],
  "scopes_supported": ["openid"],
  "subject_types_supported": ["public"],
  "token_endpoint": "https://id.twitch.tv/oauth2/token",
  "token_endpoint_auth_methods_supported": ["client_secret_post"],
  "userinfo_endpoint": "https://id.twitch.tv/oauth2/userinfo"
};

/// https://appleid.apple.com/.well-known/openid-configuration
const appleConfig = {
  "issuer": "https://appleid.apple.com",
  "authorization_endpoint": "https://appleid.apple.com/auth/authorize",
  "token_endpoint": "https://appleid.apple.com/auth/token",
  "revocation_endpoint": "https://appleid.apple.com/auth/revoke",
  "jwks_uri": "https://appleid.apple.com/auth/keys",
  "response_types_supported": ["code"],
  "response_modes_supported": ["query", "fragment", "form_post"],
  "subject_types_supported": ["pairwise"],
  "id_token_signing_alg_values_supported": ["RS256"],
  "scopes_supported": ["openid", "email", "name"],
  "token_endpoint_auth_methods_supported": ["client_secret_post"],
  "claims_supported": [
    "aud",
    "email",
    "email_verified",
    "exp",
    "iat",
    "is_private_email",
    "iss",
    "nonce",
    "nonce_supported",
    "real_user_status",
    "sub",
    "transfer_sub"
  ]
};

/// https://www.facebook.com/.well-known/openid-configuration/
const facebookConfig = {
  "issuer": "https://www.facebook.com",
  "authorization_endpoint": "https://facebook.com/dialog/oauth/",
  "jwks_uri": "https://www.facebook.com/.well-known/oauth/openid/jwks/",
  "response_types_supported": ["id_token", "token id_token"],
  "subject_types_supported": ["pairwise"],
  "id_token_signing_alg_values_supported": ["RS256"],
  "claims_supported": [
    "iss",
    "aud",
    "sub",
    "iat",
    "exp",
    "jti",
    "nonce",
    "at_hash",
    "name",
    "given_name",
    "middle_name",
    "family_name",
    "email",
    "picture",
    "user_friends",
    "user_birthday",
    "user_age_range",
    "user_link",
    "user_hometown",
    "user_location",
    "user_gender"
  ]
};
