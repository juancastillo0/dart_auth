import 'package:oauth/providers.dart';

export './endpoint_models.dart' show AuthError;
export './src/email_phone_identifier_provider.dart';
export './src/providers/apple.dart';
export './src/providers/discord.dart';
export './src/providers/facebook.dart';
export './src/providers/github.dart';
export './src/providers/google.dart';
export './src/providers/linkedin.dart';
export './src/providers/microsoft_azure_ad.dart';
export './src/providers/reddit.dart';
export './src/providers/spotify.dart';
export './src/providers/steam.dart';
export './src/providers/twitch.dart';
export './src/providers/twitter.dart';
export './src/time_otp_provider.dart';
export './src/username_password_provider.dart';

class ImplementedProviders {
  const ImplementedProviders._();

  /// Provider id for [UsernamePasswordProvider]
  static const username = 'username';

  /// Provider id for [IdentifierPasswordProvider.email]
  static const email = 'email';

  /// Provider id for [IdentifierPasswordProvider.phone]
  static const phone = 'phone';

  /// Provider id for [TimeOneTimePasswordProvider]
  static const totp = 'totp';

  /// Provider id for [AppleProvider]
  static const apple = 'apple';

  /// Provider id for [DiscordProvider]
  static const discord = 'discord';

  /// Provider id for [FacebookProvider]
  static const facebook = 'facebook';

  /// Provider id for [GithubProvider]
  static const github = 'github';

  /// Provider id for [GoogleProvider]
  static const google = 'google';

  /// Provider id for [LinkedinProvider]
  static const linkedin = 'linkedin';

  /// Provider id for [MicrosoftProvider]
  static const microsoft = 'microsoft';

  /// Provider id for [RedditProvider]
  static const reddit = 'reddit';

  /// Provider id for [SpotifyProvider]
  static const spotify = 'spotify';

  /// Provider id for [SteamProvider]
  static const steam = 'steam';

  /// Provider id for [TwitchProvider]
  static const twitch = 'twitch';

  /// Provider id for [TwitterProvider]
  static const twitter = 'twitter';

  /// All implemented provider ids
  static const values = [
    apple,
    discord,
    facebook,
    github,
    google,
    linkedin,
    microsoft,
    reddit,
    spotify,
    steam,
    twitch,
    twitter,
    username,
    email,
    phone,
    totp,
  ];
}
