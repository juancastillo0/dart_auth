import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:oauth/endpoint_models.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'endpoint.dart';
import 'main.dart';

abstract class ClientPersistence {
  FutureOr<String?> read(String key);
  FutureOr<void> write(String key, String value);
  FutureOr<void> delete(String key);
}

class AuthState {
  ///
  AuthState._({
    required this.baseUrl,
    required this.persistence,
    required this.globalState,
  }) {
    _setUpClient();
    authenticatedClient.addListener(_setUpClient);
  }

  static Future<AuthState> load({
    required ClientPersistence persistence,
    required GlobalState globalState,
    String baseUrl = 'http://localhost:3000',
  }) async {
    final token = await persistence.read(persistenceTokenKey);
    final state = AuthState._(
      globalState: globalState,
      baseUrl: baseUrl,
      persistence: persistence,
    );
    if (token != null) {
      await state._processAuthResponse(
        AuthResponse.fromJson(
          jsonDecode(token) as Map<String, Object?>,
        ),
      );
    }
    return state;
  }

  static const persistenceTokenKey = 'authStateTokenKey';

  final GlobalState globalState;
  final ClientPersistence persistence;
  late ClientWithConfig client;
  final String baseUrl;

  http.Request _mapRequest(http.Request request) {
    final t = globalState.translations.value;
    if (!request.headers.containsKey(Headers.acceptLanguage)) {
      final countrySuffix = t.countryCode == null ? '' : '-${t.countryCode}';
      final headerValue = '${t.languageCode}${countrySuffix}';
      request.headers[Headers.acceptLanguage] = headerValue;
    }
    return request;
  }

  void _setUpClient() {
    if (authenticatedClient.value == null) {
      client = ClientWithConfig(
        baseUrl: baseUrl,
        mapRequest: _mapRequest,
      );
    } else {
      // TODO: revert authenticated client on change of access token
      client = ClientWithConfig(
        baseUrl: baseUrl,
        client: authenticatedClient.value,
        mapRequest: _mapRequest,
      );
    }
  }

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
  final leftMfaItems = ValueNotifier<List<MFAItemWithFlow>?>(null);
  final isAddingMFAProvider = ValueNotifier<bool>(false);

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
    final refreshToken = response.refreshToken;
    // TODO: AuthResponse response.when/switch case/match
    if (refreshToken != null) {
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

        await persistence.delete(persistenceTokenKey);
      } else {
        userInfo.value = userInfoResponse;
      }
      cancelCurrentFlow();
    } else if (response.leftMfaItems != null) {
      if (isAddingMFAProvider.value) {
        // Successfully added a MFA. Go back to user info
        isAddingMFAProvider.value = false;
      } else {
        leftMfaItems.value = response.leftMfaItems;
        // TODO: revert authenticated client on change of access token
        final authClient = OAuthClient(
          accessToken: response.accessToken!,
          accessTokenExpiration: response.expiresAt,
          refreshAccessToken: null,
          refreshToken: null,
          innerClient: client.client,
        );
        authenticatedClient.value = authClient;
      }
    } else if (response.error != null) {
      _authErrorController.add(response);
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

  Future<UserInfoMe?> setUserMFA(MFAPostData data) async {
    if (authenticatedClient.value == null) return null;
    final response = await postUserMFAEndpoint.request(client, data);
    if (_isError(response)) return null;
    userInfo.value = response.data;
    return response.data;
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

  static final postUserMFAEndpoint = Endpoint<MFAPostData, UserInfoMe>(
    path: 'user/mfa',
    method: 'POST',
    deserialize: UserInfoMe.fromJson,
    serialize: (p) => ReqParams([], p.toJson()),
  );
}

class MFAPostData implements SerializableToJson {
  final MFAConfig mfa;

  MFAPostData(this.mfa);

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
