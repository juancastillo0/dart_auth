import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:http/http.dart' as http;
import 'package:oauth/endpoint_models.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth/src/frontend/endpoint.dart';
import 'package:oauth/src/frontend/frontend_translations.dart';
import 'package:oauth/src/frontend/global_client_state.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AuthState {
  ///
  AuthState._({
    required this.baseUrl,
    required this.persistence,
    required this.globalState,
    required this.deviceId,
  }) {
    _setUpClient(authenticatedClient.value);
    authenticatedClient.listen(_setUpClient);
    globalState.translations.listen(_refetchOnLanguageChange);
  }

  static Future<AuthState> load({
    required ClientPersistence persistence,
    required GlobalState globalState,
    required String baseUrl,
  }) async {
    String? deviceId = await persistence.read(persistenceDeviceIdKey);
    if (deviceId == null) {
      deviceId = generateStateToken();
      await persistence.write(persistenceDeviceIdKey, deviceId);
    }
    final state = AuthState._(
      globalState: globalState,
      baseUrl: baseUrl,
      persistence: persistence,
      deviceId: deviceId,
    );
    final token = await persistence.read(persistenceTokenKey);
    if (token != null) {
      await state._processAuthResponse(
        AuthResponse.fromJson(
          jsonDecode(token) as Map<String, Object?>,
        ),
      );
    }
    return state;
  }

  static const persistenceTokenKey = 'authStateToken';
  static const persistenceDeviceIdKey = 'authStateDeviceId';

  final GlobalState globalState;
  final ClientPersistence persistence;
  late ClientWithConfig client;
  final String baseUrl;
  final String deviceId;

  late final baseHeaders = <String, String>{
    'auth-api-v': '0.0.1',
    'device-id': deviceId,
    'platform': AppPlatform.current.name,
    // 'da-locale': Platform.localeName,
    // 'da-os-v': Platform.operatingSystemVersion,
    // 'da-os': Platform.operatingSystem,
    // 'da-n-processors': Platform.numberOfProcessors.toString(),
    // 'da-dart-v': Platform.version,
  };

  http.Request _mapRequest(http.Request request) {
    baseHeaders.forEach((key, value) {
      if (!request.headers.containsKey(key)) request.headers[key] = value;
    });
    if (!request.headers.containsKey(Headers.acceptLanguage)) {
      final t = globalState.translations.value;
      final countrySuffix = t.countryCode == null ? '' : '-${t.countryCode}';
      final headerValue = '${t.languageCode}${countrySuffix}';
      request.headers[Headers.acceptLanguage] = headerValue;
    }
    if (!request.headers.containsKey('timezone')) {
      request.headers['timezone'] = DateTime.now().timeZoneName;
    }

    return request;
  }

  ResponseData<P, O> _mapResponse<P, O>(ResponseData<P, O> response) {
    if (_isError(response)) {
      _errorController.add(response);
    }
    final data = response.data;
    if (data is AuthError) {
      _authErrorController.add(data);
    } else if (data is AuthResponse && data.error != null) {
      _authErrorController.add(data.error!);
    } else if (data is UserMeOrResponse && data.response?.error != null) {
      _authErrorController.add(data.response!.error!);
    }
    return response;
  }

  void _setUpClient(OAuthClient? value) {
    if (value == null) {
      client = ClientWithConfig(
        baseUrl: baseUrl,
        mapRequest: _mapRequest,
        mapResponse: _mapResponse,
      );
    } else {
      // TODO: revert authenticated client on change of access token
      client = ClientWithConfig(
        baseUrl: baseUrl,
        client: value,
        mapRequest: _mapRequest,
        mapResponse: _mapResponse,
      );
    }
  }

  void _refetchOnLanguageChange(FrontEndTranslations _) {
    getProviders();
    if (userInfo.value != null) {
      getUserInfoMe();
    }
  }

  final _errorController =
      StreamController<ResponseData<Object?, Object?>>.broadcast();
  Stream<ResponseData<Object?, Object?>> get errorStream =>
      _errorController.stream;

  final _authErrorController = StreamController<AuthError>.broadcast();
  Stream<AuthError> get authErrorStream => _authErrorController.stream;

  StreamSubscription<Object?>? _oauthSubscription;

  final isLoadingFlow = ValueNotifierStream<bool>(false);
  final currentFlow = ValueNotifierStream<OAuthProviderFlowData?>(null);
  final providersList = ValueNotifierStream<AuthProvidersData?>(null);
  final authenticatedClient = ValueNotifierStream<OAuthClient?>(null);
  final userInfo = ValueNotifierStream<UserInfoMe?>(null);
  final leftMfaItems = ValueNotifierStream<List<MFAItemWithFlow>?>(null);
  final isAddingMFAProvider = ValueNotifierStream<bool>(false);

  bool get isInFlow => isLoadingFlow.value || currentFlow.value != null;

  bool _isError(ResponseData<Object?, Object?> response) {
    if (!response.didParseBody) {
      _errorController.add(response);
    }
    return !response.didParseBody;
  }

  Future<AuthProvidersData?> getProviders() async {
    final response = await providers.request(client, null);
    if (_isError(response)) return null;
    providersList.value = response.data;
    return response.data;
  }

  Future<String?> getProviderUrl(String providerId) async {
    if (isInFlow) return null;
    isLoadingFlow.value = true;
    final response = await providerOAuthUrl.request(client, providerId);
    isLoadingFlow.value = false;
    if (_isError(response)) return null;

    final data = response.data!;
    _initFlow(data);
    return data.url;
  }

  Future<DeviceCodeResponse?> getProviderDeviceCode(String providerId) async {
    if (isInFlow) return null;
    isLoadingFlow.value = true;
    final response = await providerOAuthDeviceCode.request(client, providerId);
    isLoadingFlow.value = false;
    if (_isError(response)) return null;

    final data = response.data!;
    _initFlow(data);
    return data.device;
  }

  Future<UserInfoMe?> getUserInfoMe() async {
    if (authenticatedClient.value == null) return null;
    final response = await getUserMeEndpoint.request(client, null);
    if (_isError(response)) return null;
    if (response.data != null) {
      userInfo.value = response.data;
    }
    return response.data;
  }

  void _initFlow(OAuthProviderFlowData data) {
    currentFlow.value = data;
    final ws = WebSocketChannel.connect(
      Uri.parse(client.baseUrl).replace(
        path: 'oauth/subscribe',
        scheme: client.baseUrl.startsWith('https') ? 'wss' : 'ws',
      ),
    );
    ws.sink.add(jsonEncode({'accessToken': data.accessToken}));
    _oauthSubscription = ws.stream
        .cast<String>()
        .map(jsonDecode)
        .cast<Map<String, Object?>>()
        .map(AuthResponse.fromJson)
        .listen(_processAuthResponse);
  }

  void cancelCurrentFlow() {
    _oauthSubscription?.cancel();
    currentFlow.value = null;
    leftMfaItems.value = null;
    isAddingMFAProvider.value = false;
  }

  void addMFAProvider() {
    assert(userInfo.value != null, 'Should only add MFA when logged in.');
    isAddingMFAProvider.value = true;
  }

  Future<void> _processAuthResponse(AuthResponse response) async {
    final responseSuccess = response.success;
    // TODO: AuthResponse response.when/switch case/match
    if (responseSuccess?.refreshToken != null) {
      // TODO: save on refresh
      await persistence.write(persistenceTokenKey, jsonEncode(response));

      final authClient = OAuthClient(
        refreshAccessToken: (client, refreshToken) async {
          final response = await refreshTokenEndpoint.request(
            this.client.copyWith(client: client),
            null,
            headers: {'authorization': refreshToken},
          );
          if (!response.didParseBody) throw response;
          final data = response.data!;

          return RefreshTokenResponse(
            accessToken: data.accessToken,
            expiresAt: data.expiresAt,
            refreshToken: data.refreshToken,
          );
        },
        accessToken: responseSuccess!.accessToken,
        accessTokenExpiration: responseSuccess.expiresAt,
        refreshToken: responseSuccess.refreshToken,
        innerClient: client.client,
      );
      authenticatedClient.value = authClient;
      final userInfoResponse = await getUserInfoMe();
      if (userInfoResponse == null) {
        // TODO:
        authenticatedClient.value = null;

        await persistence.delete(persistenceTokenKey);
      }
      cancelCurrentFlow();
    } else if (responseSuccess?.leftMfaItems != null) {
      if (isAddingMFAProvider.value) {
        // Successfully added a MFA. Go back to user info
        isAddingMFAProvider.value = false;
      } else {
        leftMfaItems.value = responseSuccess!.leftMfaItems;
        // TODO: revert authenticated client on change of access token
        final authClient = OAuthClient(
          accessToken: responseSuccess.accessToken,
          accessTokenExpiration: responseSuccess.expiresAt,
          refreshAccessToken: null,
          refreshToken: null,
          innerClient: client.client,
        );
        authenticatedClient.value = authClient;
      }
    } else if (response.error != null) {
      _authErrorController.add(response.error!);
      if (leftMfaItems.value == null && !isAddingMFAProvider.value) {
        // Only cancel if its a single error in flow.
        // The user can go back for MFA flows
        cancelCurrentFlow();
      }
    }
  }

  Future<AuthResponse?> signUpWithCredentials(
    CredentialsParams params,
  ) async {
    final response = await credentialsProviderSignUp.request(client, params);
    if (_isError(response)) return null;
    await _processAuthResponse(response.data!);
    return response.data;
  }

  Future<AuthResponse?> signInWithCredentials(
    CredentialsParams params,
  ) async {
    final response = await credentialsProviderSignIn.request(client, params);
    if (_isError(response)) return null;
    await _processAuthResponse(response.data!);
    return response.data;
  }

  Future<UserMeOrResponse?> updateCredentials(CredentialsParams params) async {
    final response = await credentialsProviderUpdate.request(client, params);
    if (_isError(response)) return null;
    if (response.data?.user != null) {
      userInfo.value = response.data!.user;
    }
    return response.data;
  }

  Future<UserMeOrResponse?> deleteAuthProvider(ProviderUserId params) async {
    final response = await authenticationProviderDelete.request(client, params);
    if (_isError(response)) return null;
    if (response.data?.user != null) {
      userInfo.value = response.data!.user;
    }
    return response.data;
  }

  Future<void> signOut() async {
    if (authenticatedClient.value == null) return;
    final response = await revokeTokenEndpoint.request(client, null);
    if (_isError(response)) return;
    if (response.response!.statusCode == 200) {
      await persistence.delete(persistenceTokenKey);

      authenticatedClient.value = null;
      userInfo.value = null;
    }
  }

  // TODO: standardize set/update/edit naming
  Future<UserMeOrResponse?> setUserMFA(MFAPostData data) async {
    if (authenticatedClient.value == null) return null;
    final response = await postUserMFAEndpoint.request(client, data);
    if (_isError(response)) return null;
    if (response.data?.user != null) {
      userInfo.value = response.data!.user;
    }
    return response.data;
  }

  // TODO: standardize endpointSuffix naming
  static final providers = Endpoint<void, AuthProvidersData>(
    path: 'oauth/providers',
    method: 'GET',
    deserialize: AuthProvidersData.fromJson,
    serialize: (_) => ReqParams.empty,
  );

  // TODO: implicit flow
  static final providerOAuthUrl = Endpoint<String, OAuthProviderUrl>(
    path: 'oauth/url',
    method: 'GET',
    deserialize: OAuthProviderUrl.fromJson,
    serialize: (providerId) => ReqParams([providerId], null),
  );

  static final providerOAuthDeviceCode = Endpoint<String, OAuthProviderDevice>(
    path: 'oauth/device',
    method: 'GET',
    deserialize: OAuthProviderDevice.fromJson,
    serialize: (providerId) => ReqParams([providerId], null),
  );

  static final credentialsProviderSignUp =
      Endpoint<CredentialsParams, AuthResponse>(
    path: 'credentials/signup',
    method: 'POST',
    deserialize: AuthResponse.fromJson,
    serialize: (params) => params.toParams(),
  );

  static final credentialsProviderSignIn =
      Endpoint<CredentialsParams, AuthResponse>(
    path: 'credentials/signin',
    method: 'POST',
    deserialize: AuthResponse.fromJson,
    serialize: (params) => params.toParams(),
  );

  static final credentialsProviderUpdate =
      Endpoint<CredentialsParams, UserMeOrResponse>(
    path: 'credentials/update',
    method: 'PUT',
    deserialize: UserMeOrResponse.fromJson,
    serialize: (params) => params.toParams(),
  );

  static final authenticationProviderDelete =
      Endpoint<ProviderUserId, UserMeOrResponse>(
    path: 'providers/delete',
    method: 'DELETE',
    deserialize: UserMeOrResponse.fromJson,
    serialize: (params) => ReqParams([params.providerId], params.toJson()),
  );

  static final refreshTokenEndpoint = Endpoint<void, AuthResponseSuccess>(
    path: 'jwt/refresh',
    method: 'POST',
    deserialize: AuthResponseSuccess.fromJson,
    serialize: (_) => ReqParams.empty,
  );

  static final revokeTokenEndpoint = Endpoint<void, void>(
    path: 'jwt/revoke',
    method: 'POST',
    deserialize: (_) {},
    serialize: (_) => ReqParams.empty,
  );

  static final getUserMeEndpoint = Endpoint<void, UserInfoMe>(
    path: 'user/me',
    method: 'GET',
    deserialize: UserInfoMe.fromJson,
    serialize: (_) => ReqParams.empty,
  );

  static final postUserMFAEndpoint = Endpoint<MFAPostData, UserMeOrResponse>(
    path: 'user/mfa',
    method: 'POST',
    deserialize: UserMeOrResponse.fromJson,
    serialize: (p) => ReqParams([], p.toJson()),
  );
}

class MFAPostData implements SerializableToJson {
  final MFAConfig mfa;

  const MFAPostData(this.mfa);

  @override
  Map<String, Object?> toJson() {
    return {'mfa': mfa};
  }
}

class CredentialsParams {
  final String providerId;
  final Map<String, Object?> params;

  CredentialsParams(this.providerId, this.params);

  ReqParams toParams() => ReqParams([providerId], params);
}
