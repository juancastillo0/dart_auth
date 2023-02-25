import 'dart:convert' show jsonDecode;

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

export 'package:oauth/src/providers/facebook_user.dart';

/// https://developers.facebook.com/docs/facebook-login/guides/advanced/manual-flow#confirm
class FacebookProvider extends OAuthProvider<FacebookUser> {
  /// https://developers.facebook.com/docs/facebook-login/guides/advanced/manual-flow#confirm
  const FacebookProvider({
    super.providerId = ImplementedProviders.facebook,
    // comma separated scopes
    super.config =
        const OAuthProviderConfig(scope: 'openid,public_profile,email'),
    required super.clientId,
    required super.clientSecret,
    // required for device code flow
    this.appId,
    this.clientToken,
  }) : super(
          authorizationEndpoint: 'https://www.facebook.com/v16.0/dialog/oauth',
          tokenEndpoint: 'https://graph.facebook.com/v16.0/oauth/access_token',
          // TODO: https://developers.facebook.com/docs/facebook-login/guides/permissions/request-revoke#revokelogin
          revokeTokenEndpoint: null,
          // https://developers.facebook.com/docs/facebook-login/for-devices
          // ask user to set to user_code https://www.facebook.com/device?user_code=DINWODM
          // poll https://graph.facebook.com/v16.0/device/login_status
          deviceAuthorizationEndpoint:
              'https://graph.facebook.com/v16.0/device/login',
        );

  final String? clientToken;
  final String? appId;

  @override
  Future<DeviceCodeResponse?> getDeviceCode(
    HttpClient client, {
    String? scope,
    String? redirectUri,
    Map<String, String?>? otherParams,
  }) async {
    if (appId == null ||
        clientToken == null ||
        deviceAuthorizationEndpoint == null) {
      return null;
    }
    final response = await client.post(
      Uri.parse(deviceAuthorizationEndpoint!),
      body: {
        'access_token': '$appId|$clientToken',
        'scope': scope ?? config.scope,
        if (redirectUri != null) 'redirect_uri': redirectUri,
        ...?otherParams,
      },
    );
    final jsonData = jsonDecode(response.body) as Map<String, Object?>;
    return DeviceCodeResponse.fromJson(jsonData);
  }

  @override
  Future<Result<TokenResponse, FacebookDeviceError>> pollDeviceCodeToken(
    HttpClient client, {
    required String deviceCode,
    Map<String, String?>? otherParams,
  }) async {
    final response = await client.post(
      Uri.parse('https://graph.facebook.com/v16.0/device/login_status'),
      body: {
        'access_token': '$appId|$clientToken',
        'code': deviceCode,
        ...?otherParams,
      },
    );
    final jsonData = jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode == 200) {
      return Ok(TokenResponse.fromJson(jsonData));
    } else {
      return Err(FacebookDeviceError.fromJson(jsonData));
    }
  }

  // S256 and plain and id_token for OpenID Connect

  // TODO: https://developers.facebook.com/docs/graph-api/securing-requests%20/

  // Cancellation webhook

  @override
  HttpAuthMethod get authMethod => HttpAuthMethod.formUrlencodedBody;

  @override
  List<GrantType> get supportedFlows => [
        GrantType.authorizationCode,
        GrantType.clientCredentials,
        if (appId != null && clientToken != null) GrantType.deviceCode
      ];

  /// id,first_name,last_name,middle_name,name,name_format,picture,short_name,email,install_type,installed,is_guest_user
  static const defaultFields =
      'id,first_name,last_name,middle_name,name,name_format,picture,short_name,email';

  @override
  Future<Result<AuthUser<FacebookUser>, GetUserError>> getUser(
    HttpClient client,
    TokenResponse token, {
    String fields = defaultFields,
  }) async {
    // TODO: should we use https://developers.facebook.com/docs/facebook-login/guides/advanced/oidc-token?
    final response = await client.get(
      Uri.parse('https://graph.facebook.com/v16.0/me?fields=$fields'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.access_token}',
      },
    );
    if (response.statusCode != 200) {
      return Err(GetUserError(token: token, response: response));
    }

    try {
      final userData = jsonDecode(response.body) as Map<String, Object?>;
      return Ok(parseUser(userData));
    } catch (e, s) {
      return Err(
        GetUserError(
          token: token,
          response: response,
          sourceError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  AuthUser<FacebookUser> parseUser(Map<String, Object?> userData) {
    final user = FacebookUser.fromJson(userData);
    return AuthUser(
      emailIsVerified: true,
      phoneIsVerified: false,
      providerId: providerId,
      providerUser: user,
      rawUserData: userData,
      providerUserId: user.id,
      email: user.email,
      name: user.name,
      profilePicture: user.profile_pic ?? user.picture.data.url,
    );
  }
}

/// https://www.facebook.com/v16.0/dialog/oauth?auth_type=rerequest&display=popup

/// https://developers.facebook.com/docs/permissions/reference
/// scope -> openid public_profile email

class FacebookDeviceError implements OAuthErrorResponse {
  final String message;
  final String errorUserTitle;
  final String errorUserMsg;
  final int code;
  final int errorSubcode;
  @override
  final Map<String, Object?>? jsonData;

  ///
  const FacebookDeviceError({
    required this.message,
    required this.errorUserTitle,
    required this.errorUserMsg,
    required this.code,
    required this.errorSubcode,
    this.jsonData,
  });

// generated-dart-fixer-start{"md5Hash":"CAq8hN4ZjTsahS+sBdQs1w==","jsonKeyCase":"snake_case"}

  factory FacebookDeviceError.fromJson(Map json) {
    return FacebookDeviceError(
      message: json['message'] as String,
      errorUserTitle: json['error_user_title'] as String,
      errorUserMsg: json['error_user_msg'] as String,
      code: json['code'] as int,
      errorSubcode: json['error_subcode'] as int,
      jsonData: json.cast(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'message': message,
      'error_user_title': errorUserTitle,
      'error_user_msg': errorUserMsg,
      'code': code,
      'error_subcode': errorSubcode,
      ...?jsonData,
    };
  }

  @override
  String toString() {
    return "FacebookDeviceError${{
      "message": message,
      "errorUserTitle": errorUserTitle,
      "errorUserMsg": errorUserMsg,
      "code": code,
      "errorSubcode": errorSubcode,
      "jsonData": jsonData,
    }}";
  }

// generated-dart-fixer-end{"md5Hash":"CAq8hN4ZjTsahS+sBdQs1w==","jsonKeyCase":"snake_case"}

  /// {"error":{"message":"This request requires the user to take a pending action","code":31,"error_subcode":1349174,"error_user_title":"Device Login Authorization Pending","error_user_msg":"User has not yet authorized your application. Continue polling."}}
  /// El usuario aún no concede autorización a la aplicación. Sigue consultando con la frecuencia especificada en la respuesta del paso 1.
  static const authorization_pending = 1349174;

  /// {"error":{"message":"User request limit reached","code":17,"error_subcode":1349172,"error_user_title":"OAuth Device Excessive Polling","error_user_msg":"Your device is polling too frequently. Space your requests with a minium interval of 5 seconds."}}
  /// El dispositivo consulta con demasiada frecuencia. Reduce las consultas hasta el intervalo especificado en la primera llamada a la API.
  static const slow_down = 1349172;

  /// {"error":{"message":"The session has expired""code":463,"error_subcode":1349152, "error_user_title":"Activation Code Expired","error_user_msg":"The code you entered has expired. Please go back to your device for a new code and try again."}}
  /// El código del dispositivo caducó. Cancela el proceso de inicio de sesión para dispositivos y dirige al usuario a la pantalla inicial.
  static const expired_token = 1349152;

  @override
  String? get error => const {
        authorization_pending: DeviceFlowError.authorization_pending,
        slow_down: DeviceFlowError.slow_down,
        expired_token: DeviceFlowError.expired_token,
      }[errorSubcode]
          ?.name;

  @override
  String? get errorDescription => '$errorUserTitle. $errorUserMsg';

  @override
  String? get errorUri => null;
}
