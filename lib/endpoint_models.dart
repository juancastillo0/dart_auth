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

class AuthProvidersData implements SerializableToJson {
  final List<OAuthProviderData> providers;
  final List<CredentialsProviderData> credentialsProviders;

  ///
  AuthProvidersData(this.providers, this.credentialsProviders);

  factory AuthProvidersData.fromJson(Map<String, Object?> json) {
    return AuthProvidersData(
      (json['providers']! as Iterable)
          .cast<Map<String, Object?>>()
          .map(OAuthProviderData.fromJson)
          .toList(),
      (json['credentialsProviders']! as Iterable)
          .cast<Map<String, Object?>>()
          .map(CredentialsProviderData.fromJson)
          .toList(),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'providers': providers,
      'credentialsProviders': credentialsProviders,
    };
  }
}

class CredentialsProviderData implements SerializableToJson {
  final String providerId;
  final Map<String, ParamDescription>? paramDescriptions;

  ///
  CredentialsProviderData({
    required this.providerId,
    required this.paramDescriptions,
  });

  factory CredentialsProviderData.fromJson(Map<String, Object?> json) {
    return CredentialsProviderData(
      providerId: json['providerId']! as String,
      paramDescriptions: json['paramDescriptions'] == null
          ? null
          : (json['paramDescriptions']! as Map).map(
              (k, v) => MapEntry(
                k! as String,
                ParamDescription.fromJson((v as Map).cast()),
              ),
            ),
    );
  }

  factory CredentialsProviderData.fromProvider(
    CredentialsProvider<CredentialsData, Object?> e,
  ) {
    return CredentialsProviderData(
      providerId: e.providerId,
      paramDescriptions: e.paramDescriptions,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'providerId': providerId,
      'paramDescriptions': paramDescriptions,
    };
  }
}

class OAuthProviderData implements SerializableToJson {
  final String providerId;
  final List<String> defaultScopes;
  final bool openIdConnectSupported;
  final bool deviceCodeFlowSupported;
  final bool implicitFlowSupported;

  ///
  OAuthProviderData({
    required this.providerId,
    required this.defaultScopes,
    required this.openIdConnectSupported,
    required this.deviceCodeFlowSupported,
    required this.implicitFlowSupported,
  });

  factory OAuthProviderData.fromJson(Map<String, Object?> json) {
    return OAuthProviderData(
      providerId: json['providerId']! as String,
      defaultScopes: (json['defaultScopes']! as List).cast(),
      openIdConnectSupported: json['openIdConnectSupported']! as bool,
      deviceCodeFlowSupported: json['deviceCodeFlowSupported']! as bool,
      implicitFlowSupported: json['implicitFlowSupported']! as bool,
    );
  }

  factory OAuthProviderData.fromProvider(OAuthProvider<Object?> e) {
    return OAuthProviderData(
      providerId: e.providerId,
      defaultScopes: e.defaultScopes,
      openIdConnectSupported: e.defaultScopes.contains('openid'),
      deviceCodeFlowSupported: e.supportedFlows.contains(GrantType.deviceCode),
      implicitFlowSupported: e.supportedFlows.contains(GrantType.tokenImplicit),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'providerId': providerId,
      'defaultScopes': defaultScopes,
      'openIdConnectSupported': openIdConnectSupported,
      'deviceCodeFlowSupported': deviceCodeFlowSupported,
      'implicitFlowSupported': implicitFlowSupported,
    };
  }
}

/// Either [OAuthProviderUrl] or [OAuthProviderDevice]
abstract class OAuthProviderFlowData {
  String get accessToken;
}

class OAuthProviderUrl implements OAuthProviderFlowData {
  final String url;
  final String accessToken;

  ///
  OAuthProviderUrl(this.url, this.accessToken);

  factory OAuthProviderUrl.fromJson(Map<String, Object?> json) =>
      OAuthProviderUrl(
        json['url']! as String,
        json['accessToken']! as String,
      );
}

class OAuthProviderDevice implements OAuthProviderFlowData {
  final DeviceCodeResponse device;
  final String accessToken;

  ///
  OAuthProviderDevice(this.device, this.accessToken);

  factory OAuthProviderDevice.fromJson(Map<String, Object?> json) =>
      OAuthProviderDevice(
        DeviceCodeResponse.fromJson(json['device']! as Map),
        json['accessToken']! as String,
      );
}
