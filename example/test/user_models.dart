// ignore_for_file: prefer_single_quotes

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

Map<String, Object?> _cycleJson(Object? object) {
  return jsonDecode(jsonEncode(object)) as Map<String, Object?>;
}

AuthUser<U> mockUser<U>(
  OAuthProvider<U> provider, {
  required String nonce,
  required GrantType grantType,
}) {
  final issuedAt = DateTime.parse('2024-02-26T01:11:25.319538');
  final id = 'id-${grantType.name}';
  final numId = grantType.hashCode;
  const name = 'name';
  const preferred_username = 'preferred_username';
  const username = 'username';
  final email = 'email-${provider.providerId}-${grantType.name}@example.com';
  final createdAt = issuedAt.subtract(const Duration(days: 2 * 356));
  final updatedAt = issuedAt.subtract(const Duration(days: 356));
  final iat = issuedAt.millisecondsSinceEpoch ~/ 1000;
  final expires = issuedAt.add(const Duration(days: 365));
  final exp = expires.millisecondsSinceEpoch ~/ 1000;
  const emailVerified = true;
  const picture =
      'https://i.scdn.co/image/ab67616d00001e02ff9ca10b55ce82ae553c8228';
  const locale = 'en-US';
  const profileUrl = '';

  return matchProvider(
    provider,
    other: (p) => throw Exception('unsupported ${p.providerId}'),
    discord: (p) => p.parseUser(
      _cycleJson(
        DiscordOAuth2Me(
          application: DiscordApplication(
            id: id,
            name: name,
            description: 'description',
            bot_public: false,
            bot_require_code_grant: true,
            verify_key: 'verify_key',
          ),
          expires: expires,
          scopes: provider.defaultScopes,
          user: DiscordUser(
            id: id,
            username: username,
            discriminator: 'disc',
            mfa_enabled: false,
            email: email,
            verified: emailVerified,
            locale: locale,
            premium_type: 0,
          ),
        ),
      ),
    ),
    facebook: (p) => p.parseUser(
      _cycleJson(
        FacebookUser(
          id: id,
          first_name: 'first_name',
          last_name: 'last_name',
          name: name,
          // TODO:
          name_format: 'name_format',
          short_name: name,
          picture: const FacebookPictureNode(
            data: FacebookPicture(
              height: 100,
              is_silhouette: true,
              url: picture,
              width: 100,
            ),
          ),
          email: email,
          profile_pic: picture,
        ),
      ),
    ),
    github: (p) => p.parseUser(
      _cycleJson(
        GithubToken(
          id: numId,
          url: 'url',
          token: 'token',
          expires_at: expires,
          app: GithubTokenApp(
            client_id: provider.clientId,
            name: name,
            url: 'url',
          ),
          updated_at: updatedAt,
          created_at: issuedAt,
          user: GithubTokenUser(
            login: username,
            id: numId,
            node_id: id, // MDQ6VXNlcjE=
            avatar_url:
                picture, // 'https://github.com/images/error/octocat_happy.gif',
            url: 'https://api.github.com/users/octocat',
            html_url: 'https://github.com/octocat',
            followers_url: 'https://api.github.com/users/octocat/followers',
            following_url:
                'https://api.github.com/users/octocat/following{/other_user}',
            gists_url: 'https://api.github.com/users/octocat/gists{/gist_id}',
            starred_url:
                'https://api.github.com/users/octocat/starred{/owner}{/repo}',
            subscriptions_url:
                'https://api.github.com/users/octocat/subscriptions',
            organizations_url: 'https://api.github.com/users/octocat/orgs',
            repos_url: 'https://api.github.com/users/octocat/repos',
            events_url: 'https://api.github.com/users/octocat/events{/privacy}',
            received_events_url:
                'https://api.github.com/users/octocat/received_events',
            type: 'User',
            site_admin: false,
            email: email,
            name: name,
          ),
        ),
      ),
    ),
    google: (p) => p.parseUser(
      _cycleJson(
        GoogleClaims(
          aud: [provider.clientId],
          exp: exp,
          iat: iat,
          iss: 'https://accounts.google.com',
          sub: id,
          nonce: nonce,
          email: email,
          name: name,
          picture: picture,
          email_verified: emailVerified.toString(),
          locale: locale,
          profile: profileUrl,
        ),
      ),
    ),
    microsoft: (p) => p.parseUser({
      'sub': id,
      'iss': p.openIdConfig.issuer.toString(),
      // TODO: azp is not natively supported by microsoft
      'azp': p.clientId,
      'aud': [p.clientId],
      'exp': exp,
      'iat': iat,
      'auth_time': iat,
      // "acr": "",
      'nonce': nonce,
      'preferred_username': preferred_username,
      'name': name,
      // "tid": "",
      // "ver": "",
      // "at_hash": "",
      // "c_hash": "",
      'email': email,
      //
      'cloud_instance_name': '',
      'cloud_instance_host_name': '',
      'cloud_graph_host_name': '',
      'msgraph_host': '',
    }),
    reddit: (p) => p.parseUser(
      RedditUser(
        name: name,
        id: id,
        hasVerifiedEmail: true,
        created: createdAt.microsecondsSinceEpoch,
        hasVerified: true,
        iconImg: picture,
      ).toJson(),
    ),
    spotify: (p) => p.parseUser(
      _cycleJson(
        SpotifyUser(
          country: 'US',
          display_name: name,
          email: email,
          explicit_content: const SpotifyExplicitContent(
            filter_enabled: true,
            filter_locked: true,
          ),
          external_urls: const SpotifyExternalUrls(spotify: profileUrl),
          followers: const SpotifyFollowers(total: 0, href: 'href'),
          href: profileUrl,
          id: id,
          images: [
            const SpotifyUserImage(
              url: picture,
              height: 100,
              width: 100,
            ),
          ],
          product: 'free',
          type: 'user',
          uri: profileUrl,
        ),
      ),
    ),
    twitch: (p) => p.parseUser(
      TwitchUser(
        sub: id,
        preferredUsername: preferred_username,
        picture: picture,
        email: email,
        emailVerified: emailVerified,
        updatedAt: updatedAt,
        issuedAt: issuedAt,
        expiresAt: expires,
      ).toJson()
        ..['nonce'] = nonce
        ..['azp'] = provider.clientId
        ..['aud'] = [provider.clientId]
        ..['iss'] = p.openIdConfig.issuer,
    ),
    twitter: (p) => p.parseUser(
      _cycleJson(
        TwitterUserData(
          user: TwitterUser(
            id: id,
            name: name,
            username: username,
            url: profileUrl,
            profile_image_url: picture,
            created_at: createdAt,
            verified: false,
            verified_type: TwitterVerifiedType.none,
          ),
          verifyCredentials: TwitterVerifyCredentials.fromJson({
            ...twitterVerifyCredentialsJson,
            'email': email,
          }),
        ),
      ),
    ),
  ) as AuthUser<U>;
}

// TwitterVerifyCredentials(
//   contributors_enabled: contributors_enabled,
//   created_at: createdAt.toIso8601String(),
//   default_profile: true,
//   default_profile_image: false,
//   description: 'description',
//   favourites_count: 0,
//   followers_count: 1,
//   friends_count: 2,
//   geo_enabled: false,
//   id: numId,
//   id_str: id,
//   is_translator: false,
//   lang: 'EN',
//   listed_count: 0,
//   location: 'location',
//   name: name,
//   profile_background_color: 'profile_background_color',
//   profile_background_image_url: 'profile_background_image_url',
//   profile_background_image_url_https:
//       'profile_background_image_url_https',
//   profile_background_tile: false,
//   profile_image_url: picture,
//   profile_image_url_https: picture,
//   profile_link_color: 'profile_link_color',
//   profile_sidebar_border_color: 'profile_sidebar_border_color',
//   profile_sidebar_fill_color: 'profile_sidebar_fill_color',
//   profile_text_color: 'profile_text_color',
//   profile_use_background_image: false,
//   protected: false,
//   screen_name: 'screen_name',
//   show_all_inline_media: show_all_inline_media,
//   status: VerifyCredentialsStatus,
//   statuses_count: 0,
//   time_zone: time_zone,
//   utc_offset: utc_offset,
//   verified: false,
// )
const twitterVerifyCredentialsJson = {
  "contributors_enabled": true,
  "created_at": "Sat May 09 17:58:22 +0000 2009",
  "default_profile": false,
  "default_profile_image": false,
  "description":
      "I taught your phone that thing you like.  The Mobile Partner Engineer @Twitter. ",
  "favourites_count": 588,
  "follow_request_sent": null,
  "followers_count": 10625,
  "following": null,
  "friends_count": 1181,
  "geo_enabled": true,
  "id": 38895958,
  "id_str": "38895958",
  "is_translator": false,
  "lang": "en",
  "listed_count": 190,
  "location": "San Francisco",
  "name": "Sean Cook",
  "notifications": null,
  "profile_background_color": "1A1B1F",
  "profile_background_image_url":
      "http://a0.twimg.com/profile_background_images/495742332/purty_wood.png",
  "profile_background_image_url_https":
      "https://si0.twimg.com/profile_background_images/495742332/purty_wood.png",
  "profile_background_tile": true,
  "profile_image_url":
      "http://a0.twimg.com/profile_images/1751506047/dead_sexy_normal.JPG",
  "profile_image_url_https":
      "https://si0.twimg.com/profile_images/1751506047/dead_sexy_normal.JPG",
  "profile_link_color": "2FC2EF",
  "profile_sidebar_border_color": "181A1E",
  "profile_sidebar_fill_color": "252429",
  "profile_text_color": "666666",
  "profile_use_background_image": true,
  "protected": false,
  "screen_name": "theSeanCook",
  "show_all_inline_media": true,
  "status": {
    "contributors": null,
    "coordinates": {
      "coordinates": [-122.45037293, 37.76484123],
      "type": "Point"
    },
    "created_at": "Tue Aug 28 05:44:24 +0000 2012",
    "favorited": false,
    "geo": {
      "coordinates": [37.76484123, -122.45037293],
      "type": "Point"
    },
    "id": 240323931419062272,
    "id_str": "240323931419062272",
    "in_reply_to_screen_name": "messl",
    "in_reply_to_status_id": 240316959173009410,
    "in_reply_to_status_id_str": "240316959173009410",
    "in_reply_to_user_id": 18707866,
    "in_reply_to_user_id_str": "18707866",
    "place": {
      "attributes": {},
      "bounding_box": {
        "coordinates": [
          [
            [-122.45778216, 37.75932999],
            [-122.44248216, 37.75932999],
            [-122.44248216, 37.76752899],
            [-122.45778216, 37.76752899]
          ]
        ],
        "type": "Polygon"
      },
      "country": "United States",
      "country_code": "US",
      "full_name": "Ashbury Heights, San Francisco",
      "id": "866269c983527d5a",
      "name": "Ashbury Heights",
      "place_type": "neighborhood",
      "url": "http://api.twitter.com/1/geo/id/866269c983527d5a.json"
    },
    "retweet_count": 0,
    "retweeted": false,
    "source": "Twitter for  iPhone",
    "text": "@messl congrats! So happy for all 3 of you.",
    "truncated": false
  },
  "statuses_count": 2609,
  "time_zone": "Pacific Time (US & Canada)",
  "url": null,
  "utc_offset": -28800,
  "verified": false
};
