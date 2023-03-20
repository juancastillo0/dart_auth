import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

export 'src/backend_translation.dart';

// TODO maybe split AuthResponseSuccess and AuthResponseError?
class AuthResponse implements SerializableToJson {
  final String? refreshToken;
  final String? accessToken;
  final DateTime? expiresAt;
  final String? error;
  final String? message;
  final Map<String, Translation>? fieldErrors;
  final ResponseContinueFlow? credentials;
  final List<MFAItemWithFlow>? leftMfaItems;

  ///
  AuthResponse({
    required this.refreshToken,
    required this.accessToken,
    required this.expiresAt,
    required this.error,
    required this.message,
    this.credentials,
    this.fieldErrors,
    this.leftMfaItems,
  });

  factory AuthResponse.fromJson(Map<String, Object?> json) {
    final credentials =
        json['state'] is String ? ResponseContinueFlow.fromJson(json) : null;
    return AuthResponse(
      refreshToken: json['refreshToken'] as String?,
      accessToken: json['accessToken'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt']! as String),
      error: json['error'] as String?,
      message: json['message'] as String?,
      credentials: credentials,
      fieldErrors: (json['fieldErrors'] as Map?)
          ?.map((k, v) => MapEntry(k as String, Translation.fromJson(v))),
      leftMfaItems: json['leftMfaItems'] == null
          ? null
          : (json['leftMfaItems']! as Iterable)
              .cast<Map<String, Object?>>()
              .map(MFAItemWithFlow.fromJson)
              .toList(),
    );
  }

  factory AuthResponse.error(
    String error, {
    String? message,
    Map<String, Translation>? fieldErrors,
  }) {
    return AuthResponse(
      refreshToken: null,
      accessToken: null,
      expiresAt: null,
      error: error,
      message: message,
      fieldErrors: fieldErrors,
    );
  }

  factory AuthResponse.fromError(AuthError error) {
    return AuthResponse.error(error.error, message: error.message);
  }

  factory AuthResponse.success({
    required String? refreshToken,
    required String? accessToken,
    required DateTime? expiresAt,
    List<MFAItemWithFlow>? leftMfaItems,
  }) {
    return AuthResponse(
      refreshToken: refreshToken,
      accessToken: accessToken,
      expiresAt: expiresAt,
      leftMfaItems: leftMfaItems,
      error: null,
      message: null,
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
      'fieldErrors': fieldErrors,
      'leftMfaItems': leftMfaItems,
    }..removeWhere((key, value) => value == null);
  }

  @override
  String toString() {
    return 'AuthResponse${toJson()}';
  }
}

class MFAItemWithFlow implements SerializableToJson {
  final ProviderUserId mfa;
  final ResponseContinueFlow? credentialsInfo;

  const MFAItemWithFlow(this.mfa, this.credentialsInfo);

  @override
  Map<String, Object?> toJson() {
    return {
      'mfa': mfa,
      'credentialsInfo': credentialsInfo,
    }..removeWhere((key, value) => value == null);
  }

  factory MFAItemWithFlow.fromJson(Map<String, Object?> json) {
    return MFAItemWithFlow(
      ProviderUserId.fromJson((json['mfa']! as Map).cast()),
      json['credentialsInfo'] == null
          ? null
          : ResponseContinueFlow.fromJson(
              (json['credentialsInfo']! as Map).cast(),
            ),
    );
  }
}

/// Either [OAuthProviderData] or [CredentialsProviderData]
abstract class AuthProviderData {
  /// The identifier of this provider
  String get providerId;

  /// The name of this provider
  Translation get providerName;
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
  Map<String, Object?> toJson({String? basePath}) {
    return {
      'providers': providers.map((e) => e.toJson(basePath: basePath)).toList(),
      'credentialsProviders': credentialsProviders,
    };
  }
}

class CredentialsProviderData implements SerializableToJson, AuthProviderData {
  @override
  final String providerId;
  @override
  final Translation providerName;
  final Map<String, ParamDescription>? paramDescriptions;

  ///
  CredentialsProviderData({
    required this.providerId,
    required this.providerName,
    required this.paramDescriptions,
  });

  factory CredentialsProviderData.fromJson(Map<String, Object?> json) {
    return CredentialsProviderData(
      providerId: json['providerId']! as String,
      providerName: Translation.fromJson(json['providerName']),
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
      providerName: e.providerName,
      paramDescriptions: e.paramDescriptions,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'providerId': providerId,
      'providerName': providerName,
      'paramDescriptions': paramDescriptions,
    };
  }
}

class OAuthProviderData implements SerializableToJson, AuthProviderData {
  @override
  final String providerId;
  @override
  final Translation providerName;
  final List<String> defaultScopes;
  final OAuthButtonStyles buttonStyles;
  final bool openIdConnectSupported;
  final bool deviceCodeFlowSupported;
  final bool implicitFlowSupported;

  ///
  OAuthProviderData({
    required this.providerId,
    required this.providerName,
    required this.defaultScopes,
    required this.buttonStyles,
    required this.openIdConnectSupported,
    required this.deviceCodeFlowSupported,
    required this.implicitFlowSupported,
  });

  factory OAuthProviderData.fromJson(Map<String, Object?> json) {
    return OAuthProviderData(
      providerId: json['providerId']! as String,
      providerName: Translation.fromJson(json['providerName']),
      defaultScopes: (json['defaultScopes']! as List).cast(),
      buttonStyles:
          OAuthButtonStyles.fromJson((json['buttonStyles']! as Map).cast()),
      openIdConnectSupported: json['openIdConnectSupported']! as bool,
      deviceCodeFlowSupported: json['deviceCodeFlowSupported']! as bool,
      implicitFlowSupported: json['implicitFlowSupported']! as bool,
    );
  }

  factory OAuthProviderData.fromProvider(OAuthProvider<Object?> e) {
    return OAuthProviderData(
      providerId: e.providerId,
      providerName: e.providerName,
      defaultScopes: e.defaultScopes,
      buttonStyles: e.buttonStyles,
      openIdConnectSupported: e.defaultScopes.contains('openid'),
      deviceCodeFlowSupported: e.supportedFlows.contains(GrantType.deviceCode),
      implicitFlowSupported: e.supportedFlows.contains(GrantType.tokenImplicit),
    );
  }

  @override
  Map<String, Object?> toJson({String? basePath}) {
    return {
      'providerId': providerId,
      'providerName': providerName,
      'defaultScopes': defaultScopes,
      'buttonStyles': buttonStyles.toJson(basePath: basePath),
      'openIdConnectSupported': openIdConnectSupported,
      'deviceCodeFlowSupported': deviceCodeFlowSupported,
      'implicitFlowSupported': implicitFlowSupported,
    };
  }
}

/// Either [OAuthProviderUrl] or [OAuthProviderDevice]
abstract class OAuthProviderFlowData {
  /// The JWT token to be used for this flow
  String get accessToken;
}

class OAuthProviderUrl implements OAuthProviderFlowData, SerializableToJson {
  final String url;
  @override
  final String accessToken;

  ///
  OAuthProviderUrl({
    required this.url,
    required this.accessToken,
  });

  factory OAuthProviderUrl.fromJson(Map<String, Object?> json) =>
      OAuthProviderUrl(
        url: json['url']! as String,
        accessToken: json['accessToken']! as String,
      );

  @override
  Map<String, Object?> toJson() {
    return {
      'url': url,
      'accessToken': accessToken,
    };
  }
}

class OAuthProviderDevice implements OAuthProviderFlowData, SerializableToJson {
  final DeviceCodeResponse device;
  @override
  final String accessToken;

  ///
  OAuthProviderDevice({
    required this.device,
    required this.accessToken,
  });

  factory OAuthProviderDevice.fromJson(Map<String, Object?> json) =>
      OAuthProviderDevice(
        device: DeviceCodeResponse.fromJson(json['device']! as Map),
        accessToken: json['accessToken']! as String,
      );

  @override
  Map<String, Object?> toJson() {
    return {
      'device': device,
      'accessToken': accessToken,
    };
  }
}

class UserMeOrResponse implements SerializableToJson {
  final UserInfoMe? user;
  final AuthResponse? response;

  UserMeOrResponse.user(UserInfoMe this.user) : response = null;
  UserMeOrResponse.response(AuthResponse this.response) : user = null;

  factory UserMeOrResponse.fromJson(Map<String, Object?> json) {
    final isUser = json['user'] is Map;
    return isUser
        ? UserMeOrResponse.user(UserInfoMe.fromJson(json))
        : UserMeOrResponse.response(AuthResponse.fromJson(json));
  }

  @override
  Map<String, Object?> toJson() {
    return user == null ? response!.toJson() : user!.toJson();
  }
}
