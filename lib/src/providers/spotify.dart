import 'package:oauth/oauth.dart';

/// https://developer.spotify.com/documentation/general/guides/authorization/
class SpotifyProvider extends OAuthProvider {
  /// https://developer.spotify.com/documentation/general/guides/authorization/
  const SpotifyProvider({
    required super.clientIdentifier,
    required super.clientSecret,
  }) : super(
          authorizationEndpoint: 'https://accounts.spotify.com/authorize',
          tokenEndpoint: 'https://accounts.spotify.com/api/token',
          // https://developer.spotify.com/community/news/2016/07/25/app-ready-token-revoke/
          revokeTokenEndpoint: null,
        );

  /// https://developer.spotify.com/documentation/general/guides/authorization/scopes/
  /// scopes -> user-read-private user-read-email
}

/// https://developer.spotify.com/documentation/web-api/reference/#/operations/get-users-profile

class SpotifyAuthParams with AuthParamsBaseMixin {
  ///
  SpotifyAuthParams({
    required this.show_dialog,
    required this.baseAuthParams,
  });

  /// Whether or not to force the user to approve the app again
  /// if they’ve already done so. If false (default), a user who has
  /// already approved the application may be automatically redirected
  /// to the URI specified by redirect_uri. If true, the user will not be
  /// automatically redirected and will have to approve the app again.
  final String? show_dialog;

  @override
  final AuthParams baseAuthParams;

  @override
  Map<String, String?> toJson() => {
        ...baseAuthParams.toJson(),
        if (show_dialog != null) 'show_dialog': show_dialog,
      };
}
