import 'dart:convert' show jsonDecode;

import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

/// https://discord.com/developers/docs/topics/oauth2
/// https://discord.com/developers/applications
class DiscordProvider extends OAuthProvider<DiscordOAuth2Me> {
  /// https://discord.com/developers/docs/topics/oauth2
  /// https://discord.com/developers/applications
  const DiscordProvider({
    super.providerId = ImplementedProviders.discord,
    required super.clientId,
    required super.clientSecret,

    /// https://discord.com/developers/docs/topics/oauth2#webhooks Send messages to a channel
    /// scopes -> webhook.incoming
    /// https://discord.com/developers/docs/topics/oauth2#shared-resources-oauth2-scopes
    super.config = const OAuthProviderConfig(scope: 'identify email'),
  }) : super(
          authorizationEndpoint: 'https://discord.com/oauth2/authorize',
          tokenEndpoint: 'https://discord.com/api/oauth2/token',
          revokeTokenEndpoint: 'https://discord.com/api/oauth2/token/revoke',
        );

  @override
  List<GrantType> get supportedFlows => const [
        GrantType.authorizationCode,
        GrantType.refreshToken,
        GrantType.tokenImplicit,
        GrantType.clientCredentials
      ];

  @override
  Future<Result<AuthUser<DiscordOAuth2Me>, GetUserError>> getUser(
    HttpClient client,
    TokenResponse token,
  ) async {
    final response = await client.get(
      // Should we use https://discord.com/developers/docs/resources/user#get-current-user?
      Uri.parse('https://discord.com/api/oauth2/@me'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.access_token}',
      },
    );
    if (response.statusCode != 200) {
      return Err(GetUserError(response: response, token: token));
    }
    final data = jsonDecode(response.body) as Map<String, Object?>;
    return Ok(parseUser(data));
  }

  @override
  AuthUser<DiscordOAuth2Me> parseUser(Map<String, Object?> userData) {
    final discordData = DiscordOAuth2Me.fromJson(userData);
    final discordUser = discordData.user!;
    return AuthUser(
      emailIsVerified: discordUser.verified ?? false,
      phoneIsVerified: false,
      providerId: providerId,
      rawUserData: userData,
      providerUserId: discordUser.id,
      email: discordUser.email,
      name: discordUser.username,
      providerUser: discordData,
    );
  }
}

/// https://discord.com/api/oauth2/@me
class DiscordOAuth2Me {
  /// the current application
  final DiscordApplication application;

  /// the scopes the user has authorized the application for
  final List<String> scopes;

  /// when the access token expires
  final DateTime expires;

  /// object	the user who has authorized, if the user has authorized with the identify scope
  final DiscordUser? user;

  /// https://discord.com/api/oauth2/@me
  const DiscordOAuth2Me({
    required this.application,
    required this.scopes,
    required this.expires,
    this.user,
  });

// generated-dart-fixer-start{"md5Hash":"7yFUw1g2SNHHgKiM2zY0xQ=="}

  factory DiscordOAuth2Me.fromJson(Map json) {
    return DiscordOAuth2Me(
      application:
          DiscordApplication.fromJson((json['application'] as Map).cast()),
      scopes: (json['scopes'] as Iterable).map((v) => v as String).toList(),
      expires: DateTime.parse(json['expires'] as String),
      user: json['user'] == null
          ? null
          : DiscordUser.fromJson((json['user'] as Map).cast()),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'application': application,
      'scopes': scopes,
      'expires': expires.toIso8601String(),
      'user': user,
    };
  }

  @override
  String toString() {
    return "DiscordOAuth2Me${{
      "application": application,
      "scopes": scopes,
      "expires": expires,
      "user": user,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"7yFUw1g2SNHHgKiM2zY0xQ=="}

typedef DiscordSnowflake = String;

class DiscordUser {
  /// the user's id	identify
  final DiscordSnowflake id;

  /// the user's username, not unique across the platform	identify
  final String username;

  /// the user's 4-digit discord-tag	identify
  final String discriminator;

  /// the user's avatar hash	identify
  final String? avatar;

  /// whether the user belongs to an OAuth2 application	identify
  final bool? bot;

  /// whether the user is an Official Discord System user (part of the urgent message system)	identify
  final bool? system;

  /// whether the user has two factor enabled on their account	identify
  final bool? mfa_enabled;

  /// the user's banner hash	identify
  final String? banner /*?*/;

  /// the user's banner color encoded as an integer representation of hexadecimal color code	identify
  final int? accent_color /*?*/;

  /// the user's chosen language option	identify
  final String? locale;

  /// whether the email on this account has been verified	email
  final bool? verified;

  /// the user's email	email
  final String? email /*?*/;

  /// the flags on a user's account	identify
  final DiscordUserFlags? flags;

  /// the type of Nitro subscription on a user's account	identify
  final DiscordPremiumTypes? premium_type;

  /// the public flags on a user's account	identify
  final DiscordUserFlags? public_flags;

  ///
  const DiscordUser({
    required this.id,
    required this.username,
    required this.discriminator,
    this.avatar,
    this.bot,
    this.system,
    this.mfa_enabled,
    this.banner,
    this.accent_color,
    this.locale,
    this.verified,
    this.email,
    this.flags,
    this.premium_type,
    this.public_flags,
  });
// generated-dart-fixer-start{"md5Hash":"f7MxdTXrxqBYmDgUqFbyqA=="}

  factory DiscordUser.fromJson(Map json) {
    return DiscordUser(
      id: json['id'] as String,
      username: json['username'] as String,
      discriminator: json['discriminator'] as String,
      avatar: json['avatar'] as String?,
      bot: json['bot'] as bool?,
      system: json['system'] as bool?,
      mfa_enabled: json['mfa_enabled'] as bool?,
      banner: json['banner'] as String?,
      accent_color: json['accent_color'] as int?,
      locale: json['locale'] as String?,
      verified: json['verified'] as bool?,
      email: json['email'] as String?,
      flags: json['flags'] as int,
      premium_type: json['premium_type'] as int,
      public_flags: json['public_flags'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'username': username,
      'discriminator': discriminator,
      'avatar': avatar,
      'bot': bot,
      'system': system,
      'mfa_enabled': mfa_enabled,
      'banner': banner,
      'accent_color': accent_color,
      'locale': locale,
      'verified': verified,
      'email': email,
      'flags': flags,
      'premium_type': premium_type,
      'public_flags': public_flags,
    };
  }

  @override
  String toString() {
    return "DiscordUser${{
      "id": id,
      "username": username,
      "discriminator": discriminator,
      "avatar": avatar,
      "bot": bot,
      "system": system,
      "mfa_enabled": mfa_enabled,
      "banner": banner,
      "accent_color": accent_color,
      "locale": locale,
      "verified": verified,
      "email": email,
      "flags": flags,
      "premium_type": premium_type,
      "public_flags": public_flags,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"f7MxdTXrxqBYmDgUqFbyqA=="}

class DiscordApplication {
  /// the id of the app
  final DiscordSnowflake id;

  /// the name of the app
  final String name;

  /// the icon hash of the app
  final String? icon;

  /// the description of the app
  final String description;

  /// array of strings	an array of rpc origin urls, if rpc is enabled
  final List<String>? rpc_origins;

  /// when false only app owner can join the app's bot to guilds
  final bool bot_public;

  /// when true the app's bot will only join upon completion of the full oauth2 code grant flow
  final bool bot_require_code_grant;

  /// the url of the app's terms of service
  final String? terms_of_service_url;

  /// the url of the app's privacy policy
  final String? privacy_policy_url;

  /// user object	partial user object containing info on the owner of the application
  final DiscordUser? owner;

  /// the hex encoded key for verification in interactions and the GameSDK's GetTicket
  final String verify_key;

  /// object	if the application belongs to a team, this will be a list of the members of that team
  final DiscordTeam? team;

  /// if this application is a game sold on Discord, this field will be the guild to which it has been linked
  final DiscordSnowflake? guild_id;

  /// if this application is a game sold on Discord, this field will be the id of the "Game SKU" that is created, if exists
  final DiscordSnowflake? primary_sku_id;

  /// if this application is a game sold on Discord, this field will be the URL slug that links to the store page
  final String? slug;

  /// the application's default rich presence invite cover image hash
  final String? cover_image;

  /// the application's public flags
  final DiscordApplicationFlags? flags;

  /// array of strings	up to 5 tags describing the content and functionality of the application
  final List<String>? tags;

  /// params object	settings for the application's default in-app authorization link, if enabled
  final DiscordInstallParams? install_params;

  /// the application's default custom authorization link, if enabled
  final String? custom_install_url;

  /// the application's role connection verification entry point, which when configured will render the app as a verification method in the guild role verification configuration
  final String? role_connections_verification_url;

  ///
  const DiscordApplication({
    required this.id,
    required this.name,
    this.icon,
    required this.description,
    this.rpc_origins,
    required this.bot_public,
    required this.bot_require_code_grant,
    this.terms_of_service_url,
    this.privacy_policy_url,
    this.owner,
    required this.verify_key,
    this.team,
    this.guild_id,
    this.primary_sku_id,
    this.slug,
    this.cover_image,
    this.flags,
    this.tags,
    this.install_params,
    this.custom_install_url,
    this.role_connections_verification_url,
  });

// generated-dart-fixer-start{"md5Hash":"qoHKOtAqe7MQ96SOVq8ROQ=="}

  factory DiscordApplication.fromJson(Map json) {
    return DiscordApplication(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String,
      rpc_origins: json['rpc_origins'] == null
          ? null
          : (json['rpc_origins'] as Iterable).map((v) => v as String).toList(),
      bot_public: json['bot_public'] as bool,
      bot_require_code_grant: json['bot_require_code_grant'] as bool,
      terms_of_service_url: json['terms_of_service_url'] as String?,
      privacy_policy_url: json['privacy_policy_url'] as String?,
      owner: json['owner'] == null
          ? null
          : DiscordUser.fromJson((json['owner'] as Map).cast()),
      verify_key: json['verify_key'] as String,
      team: json['team'] == null
          ? null
          : DiscordTeam.fromJson((json['team'] as Map).cast()),
      guild_id: json['guild_id'] as String,
      primary_sku_id: json['primary_sku_id'] as String,
      slug: json['slug'] as String?,
      cover_image: json['cover_image'] as String?,
      flags: json['flags'] as int,
      tags: json['tags'] == null
          ? null
          : (json['tags'] as Iterable).map((v) => v as String).toList(),
      install_params: json['install_params'] == null
          ? null
          : DiscordInstallParams.fromJson(
              (json['install_params'] as Map).cast(),
            ),
      custom_install_url: json['custom_install_url'] as String?,
      role_connections_verification_url:
          json['role_connections_verification_url'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'rpc_origins': rpc_origins,
      'bot_public': bot_public,
      'bot_require_code_grant': bot_require_code_grant,
      'terms_of_service_url': terms_of_service_url,
      'privacy_policy_url': privacy_policy_url,
      'owner': owner,
      'verify_key': verify_key,
      'team': team,
      'guild_id': guild_id,
      'primary_sku_id': primary_sku_id,
      'slug': slug,
      'cover_image': cover_image,
      'flags': flags,
      'tags': tags,
      'install_params': install_params,
      'custom_install_url': custom_install_url,
      'role_connections_verification_url': role_connections_verification_url,
    };
  }

  @override
  String toString() {
    return "DiscordApplication${{
      "id": id,
      "name": name,
      "icon": icon,
      "description": description,
      "rpc_origins": rpc_origins,
      "bot_public": bot_public,
      "bot_require_code_grant": bot_require_code_grant,
      "terms_of_service_url": terms_of_service_url,
      "privacy_policy_url": privacy_policy_url,
      "owner": owner,
      "verify_key": verify_key,
      "team": team,
      "guild_id": guild_id,
      "primary_sku_id": primary_sku_id,
      "slug": slug,
      "cover_image": cover_image,
      "flags": flags,
      "tags": tags,
      "install_params": install_params,
      "custom_install_url": custom_install_url,
      "role_connections_verification_url": role_connections_verification_url,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"qoHKOtAqe7MQ96SOVq8ROQ=="}

class DiscordInstallParams {
  /// array of strings	the scopes to add the application to the server with
  final List<String> scopes;

  /// string	the permissions to request for the bot role
  final List<String> permissions;

  ///
  const DiscordInstallParams({
    required this.scopes,
    required this.permissions,
  });
// generated-dart-fixer-start{"md5Hash":"RtYnNVS1nP3V2THLUqSOuw=="}

  factory DiscordInstallParams.fromJson(Map json) {
    return DiscordInstallParams(
      scopes: (json['scopes'] as Iterable).map((v) => v as String).toList(),
      permissions:
          (json['permissions'] as Iterable).map((v) => v as String).toList(),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'scopes': scopes,
      'permissions': permissions,
    };
  }

  @override
  String toString() {
    return "DiscordInstallParams${{
      "scopes": scopes,
      "permissions": permissions,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"RtYnNVS1nP3V2THLUqSOuw=="}

class DiscordTeam {
  /// a hash of the image of the team's icon
  final String? icon;

  /// the unique id of the team
  final DiscordSnowflake id;

  /// array of team member objects	the members of the team
  final List<DiscordTeamMember> members;

  /// the name of the team
  final String name;

  /// the user id of the current team owner
  final DiscordSnowflake owner_user_id;

  ///
  const DiscordTeam({
    this.icon,
    required this.id,
    required this.members,
    required this.name,
    required this.owner_user_id,
  });

// generated-dart-fixer-start{"md5Hash":"+yPXs2PuRR4O8RWlUUXGyA=="}

  factory DiscordTeam.fromJson(Map json) {
    return DiscordTeam(
      icon: json['icon'] as String?,
      id: json['id'] as String,
      members: (json['members'] as Iterable)
          .map((v) => DiscordTeamMember.fromJson((v as Map).cast()))
          .toList(),
      name: json['name'] as String,
      owner_user_id: json['owner_user_id'] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'icon': icon,
      'id': id,
      'members': members.map((v) => v).toList(),
      'name': name,
      'owner_user_id': owner_user_id,
    };
  }

  @override
  String toString() {
    return "DiscordTeam${{
      "icon": icon,
      "id": id,
      "members": members,
      "name": name,
      "owner_user_id": owner_user_id,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"+yPXs2PuRR4O8RWlUUXGyA=="}

class DiscordTeamMember {
  /// the user's membership state on the team
  final DiscordTeamMembershipState membership_state;

  /// array of strings	will always be ["*"]
  final List<String> permissions;

  /// the id of the parent team of which they are a member
  final DiscordSnowflake team_id;

  /// partial user object	the avatar, discriminator, id, and username of the user
  final DiscordUser user;

  ///
  const DiscordTeamMember({
    required this.membership_state,
    required this.permissions,
    required this.team_id,
    required this.user,
  });
// generated-dart-fixer-start{"md5Hash":"2iVwvHIUHZrV9X1uddRspg=="}

  factory DiscordTeamMember.fromJson(Map json) {
    return DiscordTeamMember(
      membership_state: json['membership_state'] as int,
      permissions:
          (json['permissions'] as Iterable).map((v) => v as String).toList(),
      team_id: json['team_id'] as String,
      user: DiscordUser.fromJson((json['user'] as Map).cast()),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'membership_state': membership_state,
      'permissions': permissions,
      'team_id': team_id,
      'user': user,
    };
  }

  @override
  String toString() {
    return "DiscordTeamMember${{
      "membership_state": membership_state,
      "permissions": permissions,
      "team_id": team_id,
      "user": user,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"2iVwvHIUHZrV9X1uddRspg=="}

/// INVITED = 1
/// ACCEPTED = 2
typedef DiscordTeamMembershipState = int;

/// 1 << 12	GATEWAY_PRESENCE	Intent required for bots in 100 or more servers to receive presence_update events
/// 1 << 13	GATEWAY_PRESENCE_LIMITED	Intent required for bots in under 100 servers to receive presence_update events, found in Bot Settings
/// 1 << 14	GATEWAY_GUILD_MEMBERS	Intent required for bots in 100 or more servers to receive member-related events like guild_member_add. See list of member-related events under GUILD_MEMBERS
/// 1 << 15	GATEWAY_GUILD_MEMBERS_LIMITED	Intent required for bots in under 100 servers to receive member-related events like guild_member_add, found in Bot Settings. See list of member-related events under GUILD_MEMBERS
/// 1 << 16	VERIFICATION_PENDING_GUILD_LIMIT	Indicates unusual growth of an app that prevents verification
/// 1 << 17	EMBEDDED	Indicates if an app is embedded within the Discord client (currently unavailable publicly)
/// 1 << 18	GATEWAY_MESSAGE_CONTENT	Intent required for bots in 100 or more servers to receive message content
/// 1 << 19	GATEWAY_MESSAGE_CONTENT_LIMITED	Intent required for bots in under 100 servers to receive message content, found in Bot Settings
/// 1 << 23	APPLICATION_COMMAND_BADGE	Indicates if an app has registered global application commands
typedef DiscordApplicationFlags = int;

/// 1 << 0	STAFF	Discord Employee
/// 1 << 1	PARTNER	Partnered Server Owner
/// 1 << 2	HYPESQUAD	HypeSquad Events Member
/// 1 << 3	BUG_HUNTER_LEVEL_1	Bug Hunter Level 1
/// 1 << 6	HYPESQUAD_ONLINE_HOUSE_1	House Bravery Member
/// 1 << 7	HYPESQUAD_ONLINE_HOUSE_2	House Brilliance Member
/// 1 << 8	HYPESQUAD_ONLINE_HOUSE_3	House Balance Member
/// 1 << 9	PREMIUM_EARLY_SUPPORTER	Early Nitro Supporter
/// 1 << 10	TEAM_PSEUDO_USER	User is a team
/// 1 << 14	BUG_HUNTER_LEVEL_2	Bug Hunter Level 2
/// 1 << 16	VERIFIED_BOT	Verified Bot
/// 1 << 17	VERIFIED_DEVELOPER	Early Verified Bot Developer
/// 1 << 18	CERTIFIED_MODERATOR	Moderator Programs Alumni
/// 1 << 19	BOT_HTTP_INTERACTIONS	Bot uses only HTTP interactions and is shown in the online member list
/// 1 << 22	ACTIVE_DEVELOPER	User is an Active Developer
typedef DiscordUserFlags = int;

/// 0	None
/// 1	Nitro Classic
/// 2	Nitro
/// 3	Nitro Basic
typedef DiscordPremiumTypes = int;
