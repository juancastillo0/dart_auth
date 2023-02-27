import 'dart:convert' show base64Decode, jsonDecode, utf8;
import 'dart:io';

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth_example/cypher.dart';

class AppCredentialsConfig {
  final AppCredentialsItem? discord;
  final AppCredentialsItem? facebook;
  final AppCredentialsItem? github;
  final AppCredentialsItem? google;
  final AppCredentialsItem? microsoft;
  final AppCredentialsItem? reddit;
  final AppCredentialsItem? spotify;
  final AppCredentialsItem? twitch;
  final AppCredentialsItem? twitter;
  // apple,
  // linkedin,
  // steam,

  AppCredentialsConfig({
    this.discord,
    this.facebook,
    this.github,
    this.google,
    this.microsoft,
    this.reddit,
    this.spotify,
    this.twitch,
    this.twitter,
  });

  factory AppCredentialsConfig.fromEnvironment() {
    final decryptedKey = AES_GCM(
      secretKey: base64Decode(const String.fromEnvironment('CREDENTIALS_KEY')),
    ).decrypt(
      utf8.decode(base64Decode(Platform.environment['APP_CREDENTIALS_KEY']!)),
    );
    final decryptedJson = AES_GCM(
      secretKey: base64Decode(decryptedKey.data),
    ).decrypt(
      utf8.decode(base64Decode(Platform.environment['APP_CREDENTIALS']!)),
    );

    final credentials = AppCredentialsConfig.fromJson(
      jsonDecode(decryptedJson.data) as Map<String, Object?>,
    );
    return credentials;
  }

  factory AppCredentialsConfig.fromJson(Map<String, Object?> json) {
    return AppCredentialsConfig(
      discord: json['discord'] == null
          ? null
          : AppCredentialsItem.fromString(json['discord'] as String),
      facebook: json['facebook'] == null
          ? null
          : AppCredentialsItem.fromString(json['facebook'] as String),
      github: json['github'] == null
          ? null
          : AppCredentialsItem.fromString(json['github'] as String),
      google: json['google'] == null
          ? null
          : AppCredentialsItem.fromString(json['google'] as String),
      microsoft: json['microsoft'] == null
          ? null
          : AppCredentialsItem.fromString(json['microsoft'] as String),
      reddit: json['reddit'] == null
          ? null
          : AppCredentialsItem.fromString(json['reddit'] as String),
      spotify: json['spotify'] == null
          ? null
          : AppCredentialsItem.fromString(json['spotify'] as String),
      twitch: json['twitch'] == null
          ? null
          : AppCredentialsItem.fromString(json['twitch'] as String),
      twitter: json['twitter'] == null
          ? null
          : AppCredentialsItem.fromString(json['twitter'] as String),
    );
  }

  Future<Map<String, OAuthProvider>> providersMap({HttpClient? client}) async {
    final providerList = <OAuthProvider>[
      if (discord != null)
        DiscordProvider(
          clientId: discord!.clientId,
          clientSecret: discord!.clientSecret,
        ),
      if (facebook != null)
        FacebookProvider(
          clientId: facebook!.clientId,
          clientSecret: facebook!.clientSecret,
          clientToken: facebook!.clientToken,
        ),
      if (github != null)
        GithubProvider(
          clientId: github!.clientId,
          clientSecret: github!.clientSecret,
        ),
      if (google != null)
        await GoogleProvider.retrieve(
          clientId: google!.clientId,
          clientSecret: google!.clientSecret,
          client: client,
        ),
      if (microsoft != null)
        await MicrosoftProvider.retrieve(
          clientId: microsoft!.clientId,
          clientSecret: microsoft!.clientSecret,
          client: client,
        ),
      if (reddit != null)
        RedditProvider(
          clientId: reddit!.clientId,
          clientSecret: reddit!.clientSecret,
        ),
      if (spotify != null)
        SpotifyProvider(
          clientId: spotify!.clientId,
          clientSecret: spotify!.clientSecret,
        ),
      if (twitch != null)
        TwitchProvider(
          // TODO: TwitchProvider.retrieve?
          openIdConfig: await OpenIdConnectProvider.retrieveConfiguration(
            TwitchProvider.wellKnownOpenIdEndpoint,
            client: client,
          ),
          clientId: twitch!.clientId,
          clientSecret: twitch!.clientSecret,
        ),
      if (twitter != null)
        TwitterProvider(
          clientId: twitter!.clientId,
          clientSecret: twitter!.clientSecret,
        ),
    ];

    final allProviders = Map.fromIterables(
      providerList.map((e) => e.providerId),
      providerList,
    );

    return allProviders;
  }
}

class AppCredentialsItem {
  final String clientId;
  final String clientSecret;

  /// For facebook device code flow
  final String? clientToken;

  AppCredentialsItem(
    this.clientId,
    this.clientSecret, {
    this.clientToken,
  });

  factory AppCredentialsItem.fromString(String data) {
    final split = data.split(':');
    return AppCredentialsItem(
      split[0],
      split[1],
      clientToken: split.length > 2 ? split[2] : null,
    );
  }
}
