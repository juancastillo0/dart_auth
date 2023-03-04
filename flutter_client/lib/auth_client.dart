import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/foundation.dart';
import 'package:oauth/endpoint_models.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'endpoint.dart';

class AuthState {
  final client = ClientWithConfig(baseUrl: 'http://localhost:3000');

  final _errorController =
      StreamController<ResponseData<Object?, Object?>>.broadcast();
  Stream<ResponseData<Object?, Object?>> get errorStream =>
      _errorController.stream;

  final _authErrorController = StreamController<AuthResponse>.broadcast();
  Stream<AuthResponse> get authErrorStream => _authErrorController.stream;

  StreamSubscription<Object?>? _oauthSubscription;

  final isLoadingFlow = ValueNotifier<bool>(false);
  final currentFlow = ValueNotifier<OAuthProviderFlowData?>(null);
  final providersList = ValueNotifier<AuthProvidersData?>(null);
  final authenticatedClient = ValueNotifier<OAuthClient?>(null);
  final userInfo = ValueNotifier<UserInfoMe?>(null);

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
    final response = await getUserMeEndpoint.request(
      client.copyWith(client: authenticatedClient.value),
      null,
    );
    if (_isError(response)) return null;
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
  }

  Future<void> _processAuthResponse(AuthResponse response) async {
    final refreshToken = response.refreshToken;
    if (refreshToken != null) {
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
            accessToken: data.accessToken!,
            expiresAt: data.expiresAt!,
            refreshToken: data.refreshToken,
          );
        },
        accessToken: response.accessToken!,
        accessTokenExpiration: response.expiresAt,
        refreshToken: refreshToken,
        innerClient: client.client,
      );
      authenticatedClient.value = authClient;
      final userInfoResponse = await getUserInfoMe();
      if (userInfoResponse == null) {
        // TODO:
        authenticatedClient.value = null;
      } else {
        userInfo.value = userInfoResponse;
      }
      cancelCurrentFlow();
    } else if (response.error != null) {
      _authErrorController.add(response);
      cancelCurrentFlow();
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

  Future<void> signOut() async {
    if (authenticatedClient.value == null) return;
    final response = await revokeTokenEndpoint.request(
      client.copyWith(client: authenticatedClient.value),
      null,
    );
    if (_isError(response)) return;
    if (response.response!.statusCode == 200) {
      authenticatedClient.value = null;
      userInfo.value = null;
    }
  }

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

  static final refreshTokenEndpoint = Endpoint<void, AuthResponse>(
    path: 'jwt/refresh',
    method: 'POST',
    deserialize: AuthResponse.fromJson,
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
}

class CredentialsParams {
  final String providerId;
  final Map<String, Object?> params;

  CredentialsParams(this.providerId, this.params);

  ReqParams toParams() => ReqParams([providerId], params);
}
