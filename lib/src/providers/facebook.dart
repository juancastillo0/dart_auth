import 'dart:convert' show jsonDecode;

import 'package:oauth/oauth.dart';
import 'package:oauth/src/providers/facebook_user.dart';

/// https://developers.facebook.com/docs/facebook-login/guides/advanced/manual-flow#confirm
class FacebookProvider extends OAuthProvider {
  /// https://developers.facebook.com/docs/facebook-login/guides/advanced/manual-flow#confirm
  const FacebookProvider({
    required super.clientIdentifier,
    required super.clientSecret,
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

  // S256 and plain and id_token for OpenID Connect
  // comma separated scopes
  String get scopes => 'openid,public_profile,email';

  // TODO: https://developers.facebook.com/docs/graph-api/securing-requests%20/

  // Cancellation webhook

  @override
  HttpAuthMethod get authMethod => HttpAuthMethod.formUrlencoded;

  @override
  List<GrantType> get supportedFlows => const [
        GrantType.authorization_code,
        GrantType.client_credentials,
        GrantType.device_code
      ];

  /// id,first_name,last_name,middle_name,name,name_format,picture,short_name,email,install_type,installed,is_guest_user
  static const defaultFields =
      'id,first_name,last_name,middle_name,name,name_format,picture,short_name,email';

  Future<Result<FacebookUser, GetUserError>> getUser(
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
      return Ok(FacebookUser.fromJson(jsonDecode(response.body) as Map));
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
}

/// https://www.facebook.com/v16.0/dialog/oauth?auth_type=rerequest&display=popup

/// https://developers.facebook.com/docs/permissions/reference
/// scope -> openid public_profile email
