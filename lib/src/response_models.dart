class OAuthErrorResponse {
  ///
  OAuthErrorResponse({
    this.error,
    this.errorDescription,
    this.errorUri,
    this.jsonData,
  });

  factory OAuthErrorResponse.fromJson(Map<dynamic, dynamic> json) =>
      OAuthErrorResponse(
        jsonData: json.cast(),
        error: json['error'] as String?,
        errorDescription: json['error_description'] as String?,
        errorUri: json['error_uri'] as String?,
      );

  /// See error code.
  final String? error;

  /// A specific error message that can help a developer identify the cause of
  /// an authentication error. This part of the error contains most of the useful
  /// information about why the error occurred.
  final String? errorDescription;

  /// A specific error message that can help a developer identify the cause of
  /// an authentication error. This part of the error contains most of the useful
  /// information about why the error occurred.
  final String? errorUri;

  /// The raw JSON object or additional data for the error.
  final Map<String, Object?>? jsonData;

  /// The request is missing a required parameter, includes an
  /// unsupported parameter value (other than grant type),
  /// repeats a parameter, includes multiple credentials,
  /// utilizes more than one mechanism for authenticating the
  /// client, or is otherwise malformed.
  static const errorInvalidRequest = 'invalid_request';

  /// Client authentication failed (e.g., unknown client, no
  /// client authentication included, or unsupported
  /// authentication method).  The authorization server MAY
  /// return an HTTP 401 (Unauthorized) status code to indicate
  /// which HTTP authentication schemes are supported.  If the
  /// client attempted to authenticate via the "Authorization"
  /// request header field, the authorization server MUST
  /// respond with an HTTP 401 (Unauthorized) status code and
  /// include the "WWW-Authenticate" response header field
  /// matching the authentication scheme used by the client.
  static const errorInvalidClient = 'invalid_client';

  /// The provided authorization grant (e.g., authorization
  /// code, resource owner credentials) or refresh token is
  /// invalid, expired, revoked, does not match the redirection
  /// URI used in the authorization request, or was issued to
  /// another client.
  static const errorInvalidGrant = 'invalid_grant';

  /// The authenticated client is not authorized to use this
  /// authorization grant type.
  static const errorUnauthorizedClient = 'unauthorized_client';

  /// The authorization grant type is not supported by the
  /// authorization server.
  static const errorUnsupportedGrantType = 'unsupported_grant_type';

  /// The requested scope is invalid, unknown, malformed, or
  /// exceeds the scope granted by the resource owner.
  static const errorInvalidScope = 'invalid_scope';
}

class AuthRedirectResponse implements OAuthErrorResponse {
  ///
  AuthRedirectResponse({
    this.code,
    this.state,
    this.error,
    this.errorDescription,
    this.errorUri,
    this.jsonData,
  });

  factory AuthRedirectResponse.fromJson(Map<dynamic, dynamic> json) =>
      AuthRedirectResponse(
        jsonData: json.cast(),
        code: json['code'] as String?,
        state: json['state'] as String?,
        error: json['error'] as String?,
        errorDescription: json['error_description'] as String?,
        errorUri: json['error_uri'] as String?,
      );

  /// See error code.
  @override
  final String? error;

  /// A specific error message that can help a developer identify the cause of
  /// an authentication error. This part of the error contains most of the useful
  /// information about why the error occurred.
  @override
  final String? errorDescription;

  /// A specific error message that can help a developer identify the cause of
  /// an authentication error. This part of the error contains most of the useful
  /// information about why the error occurred.
  @override
  final String? errorUri;

  /// A one-time use code that may be exchanged for a bearer token.
  final String? code;

  /// This value should be the same as the one sent in the initial
  /// authorization request, and your app should verify that it is, in fact,
  /// the same. Your app may also do anything else it wishes with
  /// the state info, such as parse a portion of it to determine
  /// what action to perform on behalf of the user.
  final String? state;

  /// Other JSON data
  @override
  final Map<String, Object?>? jsonData;
}