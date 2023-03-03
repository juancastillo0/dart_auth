import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

class AuthResponse implements SerializableToJson {
  final String? refreshToken;
  final String? accessToken;
  final DateTime? expiresAt;
  final String? error;
  final String? message;
  final String? code;
  final Map<String, String>? fieldErrors;

  /// TODO: make it not generic. Maybe create a CredentialsResponseContinueFlow
  final CredentialsResponse<Object?>? credentials;
  // TODO: 2FA Second factor

  ///
  AuthResponse({
    required this.refreshToken,
    required this.accessToken,
    required this.expiresAt,
    required this.error,
    required this.message,
    required this.code,
    this.credentials,
    this.fieldErrors,
  });

  factory AuthResponse.fromJson(Map<String, Object?> json) {
    // TODO: improve typing
    final credentials = json['state'] is String
        ? CredentialsResponse<Object?>.fromJson(json)
        : null;
    return AuthResponse(
      refreshToken: json['refreshToken'] as String?,
      accessToken: json['accessToken'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt']! as String),
      error: json['error'] as String?,
      message: json['message'] as String?,
      code: json['code'] as String?,
      credentials: credentials,
      fieldErrors: (json['fieldErrors'] as Map?)?.cast(),
    );
  }

  factory AuthResponse.error(
    String error, {
    String? message,
    String? code,
  }) {
    return AuthResponse(
      refreshToken: null,
      accessToken: null,
      expiresAt: null,
      error: error,
      message: message,
      code: code,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      ...?credentials?.toJson(),
      'refreshToken': refreshToken,
      'accessToken': accessToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'error': error,
      'message': message,
      'code': code,
      'fieldErrors': fieldErrors,
    }..removeWhere((key, value) => value == null);
  }

  @override
  String toString() {
    return 'AuthResponse${toJson()}';
  }
}
