import 'dart:convert' show jsonDecode;

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

/// https://developer.spotify.com/documentation/general/guides/authorization/
class SpotifyProvider extends OAuthProvider<SpotifyUser> {
  /// https://developer.spotify.com/documentation/general/guides/authorization/
  const SpotifyProvider({
    super.providerId = ImplementedProviders.spotify,
    super.providerName = const Translation(
      key: '${ImplementedProviders.spotify}ProviderName',
      msg: 'Spotify',
    ),
    super.config = const SpotifyAuthParams(),
    required super.clientId,
    required super.clientSecret,
    super.buttonStyles = const OAuthButtonStyles(
      logo: 'spotify.svg',
      logoDark: 'spotify.svg',
      bg: 'FFFFFF',
      text: '2EBD59',
      bgDark: 'FFFFFF',
      textDark: '2EBD59',
    ),
  }) : super(
          authorizationEndpoint: 'https://accounts.spotify.com/authorize',
          tokenEndpoint: 'https://accounts.spotify.com/api/token',
          // https://developer.spotify.com/community/news/2016/07/25/app-ready-token-revoke/
          revokeTokenEndpoint: null,
        );

  @override
  List<GrantType> get supportedFlows => const [
        // TODO: code_challenge_method=S256
        GrantType.authorizationCode,
        GrantType.refreshToken,
        GrantType.tokenImplicit,
        GrantType.clientCredentials
      ];

  /// https://developer.spotify.com/documentation/web-api/reference/#/operations/get-current-users-profile
  @override
  Future<Result<AuthUser<SpotifyUser>, GetUserError>> getUser(
    HttpClient client,
    TokenResponse token,
  ) async {
    final response = await client.get(
      // Should we use https://discord.com/developers/docs/resources/user#get-current-user?
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: {Headers.accept: Headers.appJson},
    );
    if (response.statusCode != 200) {
      return Err(GetUserError(response: response, token: token));
    }
    final userData = jsonDecode(response.body) as Map<String, Object?>;
    return Ok(parseUser(userData));
  }

  @override
  AuthUser<SpotifyUser> parseUser(Map<String, Object?> userData) {
    final user = SpotifyUser.fromJson(userData);
    return AuthUser(
      emailIsVerified: true,
      phoneIsVerified: false,
      providerId: providerId,
      rawUserData: userData,
      providerUserId: user.id,
      email: user.email,
      name: user.display_name,
      providerUser: user,
      picture: user.images.isNotEmpty ? user.images[0].url : null,
    );
  }
}

class SpotifyAuthParams implements OAuthProviderConfig {
  ///
  const SpotifyAuthParams({
    this.showDialog,
    this.scope = 'user-read-private user-read-email',
  });

  @override
  final String scope;

  /// Whether or not to force the user to approve the app again
  /// if they’ve already done so. If false (default), a user who has
  /// already approved the application may be automatically redirected
  /// to the URI specified by redirect_uri. If true, the user will not be
  /// automatically redirected and will have to approve the app again.
  final String? showDialog;

  Map<String, String?> toJson() => {
        if (showDialog != null) 'show_dialog': showDialog,
      };

  @override
  Map<String, String?> baseAuthParams() => toJson();

  @override
  Map<String, String?>? baseTokenParams() => null;
}

// generated-dart-fixer-json{"from":"./spotify_user.json","kind":"document","md5Hash":"bwRgfxBCMZof20X38WRhcg=="}

/// A user
class SpotifyUser {
  /// The country of the user, as set in the user's account profile. An ISO 3166-1 alpha-2 country code. This field is only available when the current user has granted access to the user-read-private scope.
  final String country;

  /// The name displayed on the user's profile. null if not available.
  final String? display_name;

  /// The user's email address, as entered by the user when creating their account. Important! This email address is unverified; there is no proof that it actually belongs to the user. This field is only available when the current user has granted access to the user-read-email scope.
  final String email;

  /// The user's explicit content settings. This field is only available when the current user has granted access to the user-read-private scope.
  final SpotifyExplicitContent explicit_content;

  /// Known external URLs for this user.
  final SpotifyExternalUrls external_urls;

  /// Information about the followers of the user.
  final SpotifyFollowers followers;

  /// A link to the Web API endpoint for this user.
  final String href;

  /// The [Spotify user ID](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) for the user.
  final String id;

  /// The user's profile image.
  final List<SpotifyUserImage> images;

  /// The user's Spotify subscription level: "premium", "free", etc. (The subscription level "open" can be considered the same as "free".) This field is only available when the current user has granted access to the user-read-private scope.
  final String product;

  /// The object type: "user"
  final String type;

  /// The Spotify URI for the user.
  final String uri;

  /// A user
  const SpotifyUser({
    required this.country,
    required this.display_name,
    required this.email,
    required this.explicit_content,
    required this.external_urls,
    required this.followers,
    required this.href,
    required this.id,
    required this.images,
    required this.product,
    required this.type,
    required this.uri,
  });
// generated-dart-fixer-start{"md5Hash":"bG0kr/dyJ/0CI24yV7TURQ=="}

  factory SpotifyUser.fromJson(Map json) {
    return SpotifyUser(
      country: json['country'] as String,
      display_name: json['display_name'] as String?,
      email: json['email'] as String,
      explicit_content: SpotifyExplicitContent.fromJson(
        (json['explicit_content'] as Map).cast(),
      ),
      external_urls:
          SpotifyExternalUrls.fromJson((json['external_urls'] as Map).cast()),
      followers: SpotifyFollowers.fromJson((json['followers'] as Map).cast()),
      href: json['href'] as String,
      id: json['id'] as String,
      images: (json['images'] as Iterable)
          .map((v) => SpotifyUserImage.fromJson((v as Map).cast()))
          .toList(),
      product: json['product'] as String,
      type: json['type'] as String,
      uri: json['uri'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'country': country,
      'display_name': display_name,
      'email': email,
      'explicit_content': explicit_content,
      'external_urls': external_urls,
      'followers': followers,
      'href': href,
      'id': id,
      'images': images.map((v) => v).toList(),
      'product': product,
      'type': type,
      'uri': uri,
    };
  }

  SpotifyUser copyWith({
    String? country,
    String? display_name,
    String? email,
    SpotifyExplicitContent? explicit_content,
    SpotifyExternalUrls? external_urls,
    SpotifyFollowers? followers,
    String? href,
    String? id,
    List<SpotifyUserImage>? images,
    String? product,
    String? type,
    String? uri,
  }) {
    return SpotifyUser(
      country: country ?? this.country,
      display_name: display_name ?? this.display_name,
      email: email ?? this.email,
      explicit_content: explicit_content ?? this.explicit_content,
      external_urls: external_urls ?? this.external_urls,
      followers: followers ?? this.followers,
      href: href ?? this.href,
      id: id ?? this.id,
      images: images ?? this.images,
      product: product ?? this.product,
      type: type ?? this.type,
      uri: uri ?? this.uri,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is SpotifyUser &&
            other.runtimeType == runtimeType &&
            other.country == country &&
            other.display_name == display_name &&
            other.email == email &&
            other.explicit_content == explicit_content &&
            other.external_urls == external_urls &&
            other.followers == followers &&
            other.href == href &&
            other.id == id &&
            other.images == images &&
            other.product == product &&
            other.type == type &&
            other.uri == uri;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      country,
      display_name,
      email,
      explicit_content,
      external_urls,
      followers,
      href,
      id,
      images,
      product,
      type,
      uri,
    ]);
  }

  @override
  String toString() {
    return "SpotifyUser${{
      "country": country,
      "display_name": display_name,
      "email": email,
      "explicit_content": explicit_content,
      "external_urls": external_urls,
      "followers": followers,
      "href": href,
      "id": id,
      "images": images,
      "product": product,
      "type": type,
      "uri": uri,
    }}";
  }

  List<Object?> get props => [
        country,
        display_name,
        email,
        explicit_content,
        external_urls,
        followers,
        href,
        id,
        images,
        product,
        type,
        uri,
      ];
}

// generated-dart-fixer-end{"md5Hash":"bG0kr/dyJ/0CI24yV7TURQ=="}

class SpotifyExplicitContent {
  /// When true, indicates that explicit content should not be played.
  final bool filter_enabled;

  /// When true, indicates that the explicit content setting is locked and can't be changed by the user.
  final bool filter_locked;

  ///
  const SpotifyExplicitContent({
    required this.filter_enabled,
    required this.filter_locked,
  });
// generated-dart-fixer-start{"md5Hash":"Rtgk68vcPJfwy7ZuhHvjzg=="}

  factory SpotifyExplicitContent.fromJson(Map json) {
    return SpotifyExplicitContent(
      filter_enabled: json['filter_enabled'] as bool,
      filter_locked: json['filter_locked'] as bool,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'filter_enabled': filter_enabled,
      'filter_locked': filter_locked,
    };
  }

  SpotifyExplicitContent copyWith({
    bool? filter_enabled,
    bool? filter_locked,
  }) {
    return SpotifyExplicitContent(
      filter_enabled: filter_enabled ?? this.filter_enabled,
      filter_locked: filter_locked ?? this.filter_locked,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is SpotifyExplicitContent &&
            other.runtimeType == runtimeType &&
            other.filter_enabled == filter_enabled &&
            other.filter_locked == filter_locked;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      filter_enabled,
      filter_locked,
    ]);
  }

  @override
  String toString() {
    return "SpotifyExplicitContent${{
      "filter_enabled": filter_enabled,
      "filter_locked": filter_locked,
    }}";
  }

  List<Object?> get props => [
        filter_enabled,
        filter_locked,
      ];
}

// generated-dart-fixer-end{"md5Hash":"Rtgk68vcPJfwy7ZuhHvjzg=="}

class SpotifyExternalUrls {
  /// The [Spotify URL](https://developer.spotify.com/documentation/web-api/#spotify-uris-and-ids) for the object.
  final String spotify;

  ///
  const SpotifyExternalUrls({required this.spotify});
// generated-dart-fixer-start{"md5Hash":"225UBXxxm7qLKLW9FtxIvw=="}

  factory SpotifyExternalUrls.fromJson(Map json) {
    return SpotifyExternalUrls(
      spotify: json['spotify'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'spotify': spotify,
    };
  }

  SpotifyExternalUrls copyWith({
    String? spotify,
  }) {
    return SpotifyExternalUrls(
      spotify: spotify ?? this.spotify,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is SpotifyExternalUrls &&
            other.runtimeType == runtimeType &&
            other.spotify == spotify;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      spotify,
    ]);
  }

  @override
  String toString() {
    return "SpotifyExternalUrls${{
      "spotify": spotify,
    }}";
  }

  List<Object?> get props => [
        spotify,
      ];
}

// generated-dart-fixer-end{"md5Hash":"225UBXxxm7qLKLW9FtxIvw=="}

class SpotifyFollowers {
  /// This will always be set to null, as the Web API does not support it at the moment.
  final String? href;

  /// The total number of followers.
  final int total;

  ///
  const SpotifyFollowers({
    this.href,
    required this.total,
  });
// generated-dart-fixer-start{"md5Hash":"T13iwxFCGmmex6oW7MHoGg=="}

  factory SpotifyFollowers.fromJson(Map json) {
    return SpotifyFollowers(
      href: json['href'] as String?,
      total: json['total'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'href': href,
      'total': total,
    };
  }

  SpotifyFollowers copyWith({
    String? href,
    int? total,
  }) {
    return SpotifyFollowers(
      href: href ?? this.href,
      total: total ?? this.total,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is SpotifyFollowers &&
            other.runtimeType == runtimeType &&
            other.href == href &&
            other.total == total;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      href,
      total,
    ]);
  }

  @override
  String toString() {
    return "SpotifyFollowers${{
      "href": href,
      "total": total,
    }}";
  }

  List<Object?> get props => [
        href,
        total,
      ];
}

// generated-dart-fixer-end{"md5Hash":"T13iwxFCGmmex6oW7MHoGg=="}

/// A user's profile image.
class SpotifyUserImage {
  /// The source URL of the image.
  final String url;

  /// The image height in pixels.
  final int height;

  /// The image width in pixels.
  final int width;

  /// A user's profile image.
  const SpotifyUserImage({
    required this.url,
    required this.height,
    required this.width,
  });
// generated-dart-fixer-start{"md5Hash":"ayilY2XiDNd0nqUpQrmNvQ=="}

  factory SpotifyUserImage.fromJson(Map json) {
    return SpotifyUserImage(
      url: json['url'] as String,
      height: json['height'] as int,
      width: json['width'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'url': url,
      'height': height,
      'width': width,
    };
  }

  SpotifyUserImage copyWith({
    String? url,
    int? height,
    int? width,
  }) {
    return SpotifyUserImage(
      url: url ?? this.url,
      height: height ?? this.height,
      width: width ?? this.width,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(other, this) ||
        other is SpotifyUserImage &&
            other.runtimeType == runtimeType &&
            other.url == url &&
            other.height == height &&
            other.width == width;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      runtimeType,
      url,
      height,
      width,
    ]);
  }

  @override
  String toString() {
    return "SpotifyUserImage${{
      "url": url,
      "height": height,
      "width": width,
    }}";
  }

  List<Object?> get props => [
        url,
        height,
        width,
      ];
}

// generated-dart-fixer-end{"md5Hash":"ayilY2XiDNd0nqUpQrmNvQ=="}
