import 'dart:convert' show jsonDecode;

import 'package:meta/meta.dart';
import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth/src/backend_translation.dart';

abstract class Persistence {
  /// Retrieves a saved [AuthStateModel] associated with [key],
  /// persisted using [setState].
  Future<AuthStateModel?> getState(String key);

  /// Saves a [value] and associates it with [key].
  Future<void> setState(String key, AuthStateModel value);

  /// Saves a [session] when the user has signed in or registered.
  Future<void> saveSession(UserSession session);

  /// Returns any (valid or not valid) session with [sessionId].
  Future<UserSession?> getAnySession(String sessionId);

  /// Returns a valid session with [sessionId].
  Future<UserSession?> getValidSession(String sessionId) =>
      getAnySession(sessionId).then(
        (s) => s == null || !s.isValid ? null : s,
      );

  /// Returns user session for [userId].
  /// If [onlyValid] is true, only valid sessions will be returned.
  Future<List<UserSession>> getUserSessions(
    String userId, {
    required bool onlyValid,
  });

  /// Saves a [user] and associates it with a [userId]
  Future<AppUserComplete> saveUser(String userId, AuthUser<Object?> user);

  /// Updates the [user] information
  Future<void> updateUser(AppUser user);

  /// Retrieves users by [ids]. A user is null if it was not found
  /// for the id in the given index.
  /// The returned array should have the same length as [ids].
  Future<List<AppUserComplete?>> getUsersById(List<UserId> ids);

  /// Retrieves a user by [id].
  Future<AppUserComplete?> getUserById(UserId id) =>
      getUsersById([id]).then((value) => value.first);

  /// Deletes an user account
  Future<void> deleteAuthUser(String userId, AuthUser<Object?> authUser);
}

@immutable
class UserId {
  final String id;
  final UserIdKind kind;

  const UserId(this.id, this.kind);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserId && id == other.id && kind == other.kind;

  @override
  int get hashCode => Object.hash(id, kind);
}

enum UserIdKind {
  /// Global app id
  innerId,

  /// User id for the given provider
  providerId,

  /// Verified email address
  verifiedEmail,

  /// Verified phone number
  verifiedPhone,
}

class UserSessionBase implements SerializableToJson {
  final String sessionId;
  final String userId;
  final DateTime createdAt;
  final DateTime lastRefreshAt;
  final DateTime? endedAt;
  final String? deviceId;
  final SessionClientData? clientData;
  final List<ProviderUserId> mfa;

  /// A user session, persisted when the user is signed in.
  const UserSessionBase({
    required this.sessionId,
    required this.userId,
    required this.createdAt,
    required this.lastRefreshAt,
    required this.deviceId,
    required this.clientData,
    required this.mfa,
    this.endedAt,
  });

  /// Whether the session is valid
  bool get isValid => endedAt == null;

  factory UserSessionBase.fromJson(Map json) {
    return UserSessionBase(
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      lastRefreshAt: DateTime.parse(json['lastRefreshAt'] as String),
      deviceId: json['deviceId'] as String,
      clientData: json['clientData'] == null
          ? null
          : SessionClientData.fromJson(
              json['clientData']! as Map<String, Object?>,
            ),
      mfa: (json['mfa'] as Iterable)
          .cast<Map<String, Object?>>()
          .map(ProviderUserId.fromJson)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory UserSessionBase.fromSession(UserSession session) {
    return UserSessionBase(
      sessionId: session.sessionId,
      userId: session.userId,
      endedAt: session.endedAt,
      createdAt: session.createdAt,
      lastRefreshAt: session.lastRefreshAt,
      deviceId: session.deviceId,
      clientData: session.clientData,
      mfa: session.mfa,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'endedAt': endedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'lastRefreshAt': lastRefreshAt.toIso8601String(),
      'deviceId': deviceId,
      'clientData': clientData,
      'mfa': mfa,
    };
  }
}

class UserSessionOrPartial {
  final UserSession session;
  final List<ProviderUserId>? leftMfa;

  ///
  UserSessionOrPartial(this.session, {required this.leftMfa});
}

class SessionClientData implements SerializableToJson {
  final String? deviceId;
  final String? platform;
  final String? userAgent;
  final String? country;
  final String? ipAddress;
  final String? apiVersion;

  ///
  SessionClientData({
    this.deviceId,
    this.platform,
    this.userAgent,
    this.country,
    this.ipAddress,
    this.apiVersion,
  });

  factory SessionClientData.fromJson(Map<String, Object?> json) {
    return SessionClientData(
      deviceId: json['deviceId'] as String?,
      platform: json['platform'] as String?,
      userAgent: json['userAgent'] as String?,
      country: json['country'] as String?,
      ipAddress: json['ipAddress'] as String?,
      apiVersion: json['apiVersion'] as String?,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'deviceId': deviceId,
      'platform': platform,
      'userAgent': userAgent,
      'country': country,
      'ipAddress': ipAddress,
      'apiVersion': apiVersion,
    }..removeWhere((key, value) => value == null);
  }

  bool requiresVerification(SessionClientData other) {
    return deviceId != other.deviceId ||
        platform != other.platform ||
        userAgent != other.userAgent ||
        country != other.country ||
        ipAddress != other.ipAddress;
  }
}

/// A user session, persisted when the user is signed in.
class UserSession implements SerializableToJson {
  final String sessionId;
  final String? refreshToken;
  final String userId;
  final DateTime createdAt;
  final String? deviceId;
  final Map<String, Object?>? meta;
  final DateTime? endedAt;
  final DateTime lastRefreshAt;
  final SessionClientData? clientData;
  final List<ProviderUserId> mfa;

  /// A user session, persisted when the user is signed in.
  const UserSession({
    required this.sessionId,
    required this.refreshToken,
    required this.userId,
    required this.createdAt,
    required this.lastRefreshAt,
    required this.mfa,
    this.deviceId,
    this.meta,
    this.clientData,
    this.endedAt,
  });

  /// Whether the session is valid
  bool get isValid => endedAt == null;

  /// Whether the session is in multi-factor authentication
  bool get isInMFA => isValid && refreshToken == null && mfa.isNotEmpty;

  bool requiresVerification(
    UserSession other, {
    required Duration minLastRefreshAtDiff,
  }) {
    return deviceId != other.deviceId ||
        other.lastRefreshAt.difference(lastRefreshAt) > minLastRefreshAtDiff ||
        clientData != other.clientData &&
            (other.clientData == null ||
                clientData == null ||
                clientData!.requiresVerification(other.clientData!));
  }

// generated-dart-fixer-start{"md5Hash":"UR44W1AtB7vHXyyYToVCGQ=="}

  UserSession copyWith({
    String? refreshToken,
    bool refreshTokenToNull = false,
    String? deviceId,
    bool deviceIdToNull = false,
    Map<String, Object?>? meta,
    bool metaToNull = false,
    DateTime? endedAt,
    bool endedAtToNull = false,
    List<ProviderUserId>? mfa,
    DateTime? lastRefreshAt,
    SessionClientData? clientData,
    bool clientDataToNull = false,
  }) {
    return UserSession(
      refreshToken:
          refreshToken ?? (refreshTokenToNull ? null : this.refreshToken),
      sessionId: sessionId,
      userId: userId,
      createdAt: createdAt,
      deviceId: deviceId ?? (deviceIdToNull ? null : this.deviceId),
      endedAt: endedAt ?? (endedAtToNull ? null : this.endedAt),
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      meta: meta ?? (metaToNull ? null : this.meta),
      mfa: mfa ?? this.mfa,
      clientData: clientData ?? (clientDataToNull ? null : this.clientData),
    );
  }

  factory UserSession.fromJson(Map json) {
    return UserSession(
      deviceId: json['deviceId'] as String?,
      sessionId: json['sessionId'] as String,
      refreshToken: json['refreshToken'] as String?,
      userId: json['userId'] as String,
      meta: json['meta'] == null
          ? null
          : ((json['meta'] is String
                  ? jsonDecode(json['meta'] as String)
                  : json['meta']) as Map)
              .map((k, v) => MapEntry(k as String, v)),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      lastRefreshAt: DateTime.parse(json['lastRefreshAt'] as String),
      mfa: ((json['mfa'] is String
              ? jsonDecode(json['mfa'] as String)
              : json['mfa']) as Iterable)
          .cast<Map<String, Object?>>()
          .map(ProviderUserId.fromJson)
          .toList(),
      clientData: json['clientData'] == null
          ? null
          : SessionClientData.fromJson(
              (json['clientData'] is String
                  ? jsonDecode(json['clientData'] as String)
                  : json['clientData']) as Map<String, Object?>,
            ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'deviceId': deviceId,
      'sessionId': sessionId,
      'refreshToken': refreshToken,
      'userId': userId,
      'meta': meta,
      'mfa': mfa,
      'endedAt': endedAt?.toIso8601String(),
      'lastRefreshAt': lastRefreshAt.toIso8601String(),
      'clientData': clientData,
      'createdAt': createdAt.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  @override
  String toString() {
    return "UserSession${{
      "deviceId": deviceId,
      "sessionId": sessionId,
      "refreshToken": refreshToken,
      "userId": userId,
      "meta": meta,
      "mfa": mfa,
      "endedAt": endedAt,
      "lastRefreshAt": lastRefreshAt,
      "clientData": clientData,
      "createdAt": createdAt,
    }}";
  }
}

// generated-dart-fixer-end{"md5Hash":"UR44W1AtB7vHXyyYToVCGQ=="}

T matchProvider<T>(
  OAuthProvider provider, {
  required T Function(OAuthProvider) other,
  T Function(AppleProvider)? apple,
  T Function(DiscordProvider)? discord,
  T Function(FacebookProvider)? facebook,
  T Function(GithubProvider)? github,
  T Function(GoogleProvider)? google,
  // T Function(linkedinProvider)? linkedin,
  T Function(MicrosoftProvider)? microsoft,
  T Function(RedditProvider)? reddit,
  T Function(SpotifyProvider)? spotify,
  // T Function(SteamProvider)? steam,
  T Function(TwitchProvider)? twitch,
  T Function(TwitterProvider)? twitter,
}) {
  if (provider is AppleProvider) {
    return (apple ?? other)(provider);
  } else if (provider is DiscordProvider) {
    return (discord ?? other)(provider);
  } else if (provider is FacebookProvider) {
    return (facebook ?? other)(provider);
  } else if (provider is GithubProvider) {
    return (github ?? other)(provider);
  } else if (provider is GoogleProvider) {
    return (google ?? other)(provider);
    // } else if (provider is linkedinProvider) {
    // return (linkedin ?? other)(provider);
  } else if (provider is MicrosoftProvider) {
    return (microsoft ?? other)(provider);
  } else if (provider is RedditProvider) {
    return (reddit ?? other)(provider);
  } else if (provider is SpotifyProvider) {
    return (spotify ?? other)(provider);
  }
  //  else if (provider is SteamProvider) {
  // return (steam ?? other)(provider);
  else if (provider is TwitchProvider) {
    return (twitch ?? other)(provider);
  } else if (provider is TwitterProvider) {
    return (twitter ?? other)(provider);
  }
  return other(provider);
}

class AppUser implements SerializableToJson {
  final String userId;
  final String? name;
  final String? picture;
  final String? email;
  final bool emailIsVerified;
  final String? phone;
  final bool phoneIsVerified;
  final MFAConfig multiFactorAuth;
  final DateTime createdAt;
  // TODO: rename to emailIsVerified->emailVerified

  ///
  const AppUser({
    required this.userId,
    this.name,
    this.picture,
    this.email,
    required this.emailIsVerified,
    this.phone,
    required this.phoneIsVerified,
    required this.multiFactorAuth,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, Object?> json) {
    return AppUser(
      userId: json['userId']! as String,
      emailIsVerified: json['emailIsVerified']! as bool,
      phoneIsVerified: json['phoneIsVerified']! as bool,
      name: json['name'] as String?,
      picture: json['picture'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      multiFactorAuth:
          MFAConfig.fromJson(json['multiFactorAuth']! as Map<String, Object?>),
      createdAt: DateTime.parse(json['createdAt']! as String),
    );
  }

  AppUser copyWith({
    String? userId,
    String? name,
    bool nameToNull = false,
    String? picture,
    bool pictureToNull = false,
    String? email,
    bool emailToNull = false,
    bool? emailIsVerified,
    String? phone,
    bool phoneToNull = false,
    bool? phoneIsVerified,
    MFAConfig? multiFactorAuth,
    DateTime? createdAt,
  }) {
    return AppUser(
      userId: userId ?? this.userId,
      emailIsVerified: emailIsVerified ?? this.emailIsVerified,
      phoneIsVerified: phoneIsVerified ?? this.phoneIsVerified,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? (emailToNull ? null : this.email),
      multiFactorAuth: multiFactorAuth ?? this.multiFactorAuth,
      name: name ?? (nameToNull ? null : this.name),
      phone: phone ?? (phoneToNull ? null : this.phone),
      picture: picture ?? (pictureToNull ? null : this.picture),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'name': name,
      'picture': picture,
      'email': email,
      'emailIsVerified': emailIsVerified,
      'phone': phone,
      'phoneIsVerified': phoneIsVerified,
      'multiFactorAuth': multiFactorAuth,
      'createdAt': createdAt.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }
}

@immutable
class ProviderUserId implements SerializableToJson {
  final String providerId;
  final String providerUserId;

  ///
  const ProviderUserId({
    required this.providerId,
    required this.providerUserId,
  });

  factory ProviderUserId.fromJson(Map<String, Object?> json) {
    return ProviderUserId(
      providerId: json['providerId']! as String,
      providerUserId: json['providerUserId']! as String,
    );
  }

  UserId get userId =>
      UserId('$providerId:$providerUserId', UserIdKind.providerId);

  @override
  bool operator ==(Object other) =>
      other is ProviderUserId &&
      providerId == other.providerId &&
      providerUserId == other.providerUserId;

  @override
  int get hashCode => Object.hash(providerId, providerUserId);

  @override
  Map<String, Object?> toJson() {
    return {
      'providerId': providerId,
      'providerUserId': providerUserId,
    };
  }
}

enum MFAProviderKind {
  required,
  optional,
  none,
}

enum MFAConfigError {
  optionalCountNegative,
  optionalCountZeroWithItems,
  optionalCountMoreThanItems,
  duplicateRequiredAndOptional;

  Translation get translation {
    switch (this) {
      case optionalCountNegative:
        return const Translation(
          key: Translations.mfaEditOptionalCountNegativeKey,
        );
      case optionalCountZeroWithItems:
        return const Translation(
          key: Translations.mfaEditOptionalCountZeroWithItemsKey,
        );
      case optionalCountMoreThanItems:
        return const Translation(
          key: Translations.mfaEditOptionalCountMoreThanItemsKey,
        );
      case duplicateRequiredAndOptional:
        return const Translation(
          key: Translations.mfaEditDuplicateRequiredAndOptionalKey,
        );
    }
  }
}

class MFAConfig implements SerializableToJson {
  final Set<ProviderUserId> requiredItems;
  final int optionalCount;
  final Set<ProviderUserId> optionalItems;

  ///
  const MFAConfig({
    required this.requiredItems,
    required this.optionalCount,
    required this.optionalItems,
  });

  static const empty =
      MFAConfig(optionalCount: 0, requiredItems: {}, optionalItems: {});

  bool get isEmpty =>
      requiredItems.isEmpty && optionalItems.isEmpty && optionalCount == 0;
  bool get isValid => validationErrors.isEmpty;

  List<MFAConfigError> get validationErrors {
    return [
      // if (!(optionalCount == 0 && optionalItems.isEmpty ||
      //     optionalCount > 0 && optionalCount < optionalItems.length))
      //   MFAConfigError.optionalCountMoreThanItems,
      if (optionalCount < 0) MFAConfigError.optionalCountNegative,
      if (optionalCount == 0 && optionalItems.isNotEmpty)
        MFAConfigError.optionalCountZeroWithItems,
      if (optionalCount > 0 && optionalCount >= optionalItems.length)
        MFAConfigError.optionalCountMoreThanItems,
      // TODO: allow this? what about single optional? Should we delete the What happen
      // (requiredItems.length != 1 || optionalCount > 0) &&
      if (optionalItems.intersection(requiredItems).isNotEmpty)
        MFAConfigError.duplicateRequiredAndOptional,
    ];
  }

  factory MFAConfig.fromJson(Map<String, Object?> json) {
    return MFAConfig(
      requiredItems: (json['requiredItems']! as Iterable)
          .cast<Map<String, Object?>>()
          .map(ProviderUserId.fromJson)
          .toSet(),
      optionalCount: json['optionalCount']! as int,
      optionalItems: (json['optionalItems']! as Iterable)
          .cast<Map<String, Object?>>()
          .map(ProviderUserId.fromJson)
          .toSet(),
    );
  }

  List<ProviderUserId> itemsLeft(Iterable<ProviderUserId> doneItems) {
    final reqLeft =
        requiredItems.where((item) => !doneItems.contains(item)).toList();
    final optLeft =
        optionalItems.where((item) => !doneItems.contains(item)).toList();
    if (optLeft.isEmpty ||
        optionalItems.length - optLeft.length >= optionalCount) {
      // done with optional
      return reqLeft;
    }
    return reqLeft.followedBy(optLeft).toList();
  }

  MFAProviderKind kind(ProviderUserId item) {
    if (requiredItems.contains(item)) {
      return MFAProviderKind.required;
    } else if (optionalItems.contains(item)) {
      return MFAProviderKind.optional;
    } else {
      return MFAProviderKind.none;
    }
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'requiredItems': requiredItems.toList(),
      'optionalCount': optionalCount,
      'optionalItems': optionalItems.toList(),
    };
  }
}

class AppUserComplete implements SerializableToJson {
  final AppUser user;
  final List<AuthUser<Object?>> authUsers;

  String get userId => user.userId;

  Iterable<UserId> userIds() => [UserId(user.userId, UserIdKind.innerId)]
      .followedBy(authUsers.expand((auth) => auth.userIds()));

  ///
  AppUserComplete({
    required this.user,
    required this.authUsers,
  });

  factory AppUserComplete.merge(
    String userId,
    List<AuthUser<dynamic>> authUsers, {
    AppUser? base,
  }) {
    final list = authUsers.cast<AuthUser<dynamic>?>();
    final email = list.firstWhere(
      (auth) => auth!.emailIsVerified && auth.email != null,
      orElse: () => null,
    );
    final phone = list.firstWhere(
      (auth) => auth!.phoneIsVerified && auth.phone != null,
      orElse: () => null,
    );
    final name = list.firstWhere(
      (auth) => auth!.name != null,
      orElse: () => null,
    );
    final picture = list.firstWhere(
      (auth) => auth!.picture != null,
      orElse: () => null,
    );
    return AppUserComplete(
      user: AppUser(
        userId: userId,
        createdAt: base?.createdAt ?? DateTime.now(),
        emailIsVerified: base != null && base.emailIsVerified || email != null,
        phoneIsVerified: base != null && base.phoneIsVerified || phone != null,
        email: base == null
            ? email?.email
            : (base.emailIsVerified ? base.email : email?.email ?? base.email),
        phone: base == null
            ? phone?.phone
            : (base.phoneIsVerified ? base.phone : phone?.phone ?? base.phone),
        name: base?.name ?? name?.name,
        picture: base?.picture ?? picture?.picture,
        multiFactorAuth: base?.multiFactorAuth ?? MFAConfig.empty,
      ),
      authUsers: authUsers,
    );
  }

  factory AppUserComplete.fromJson(
    Map<String, Object?> json,
    Map<String, OAuthProvider<dynamic>> providers,
  ) {
    return AppUserComplete(
      user: AppUser.fromJson((json['user']! as Map).cast()),
      authUsers: (json['authUsers']! as Iterable)
          .cast<Map<String, Object?>>()
          .map((e) {
        final provider = providers[e['providerId']];
        if (provider == null) {
          throw FormatException(
            e['providerId'] == null
                ? 'No "providerId" in ${AuthUser} json payload.'
                : 'Provider id "${e['providerId']}" not found.',
          );
        }
        return AuthUser.fromJson(json, provider);
      }).toList(),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {'user': user, 'authUsers': authUsers};
  }
}

class UserInfoMe implements SerializableToJson {
  final AppUser user;
  final List<AuthUserData> authUsers;
  final List<UserSessionBase>? sessions;

  ///
  UserInfoMe({
    required this.user,
    required this.authUsers,
    required this.sessions,
  });

  factory UserInfoMe.fromComplete(
    AppUserComplete user,
    Map<String, AuthenticationProvider<dynamic>> allProviders, {
    List<UserSessionBase>? sessions,
  }) {
    final authUsers = user.authUsers.map((e) {
      final p = allProviders[e.providerId];
      return AuthUserData(
        authUser: e,
        providerName: p?.providerName ??
            Translation(
              key: '${e.providerId}ProviderName',
              msg: e.providerId,
            ),
        updateParams: p is CredentialsProvider
            ? p.updateCredentialsParams(e.providerUser)
            : null,
      );
    }).toList();
    return UserInfoMe(
      user: user.user,
      authUsers: authUsers,
      sessions: sessions,
    );
  }

  factory UserInfoMe.fromJson(Map<String, Object?> json) {
    return UserInfoMe(
      user: AppUser.fromJson((json['user']! as Map).cast()),
      authUsers: (json['authUsers']! as Iterable)
          .cast<Map<String, Object?>>()
          .map(AuthUserData.fromJson)
          .toList(),
      sessions: json['sessions'] == null
          ? null
          : (json['sessions']! as Iterable)
              .cast<Map<String, Object?>>()
              .map(UserSessionBase.fromJson)
              .toList(),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'user': user,
      'authUsers': authUsers,
      'sessions': sessions,
    }..removeWhere((key, value) => value == null);
  }
}

class AuthUserData implements SerializableToJson {
  final AuthUser<void> authUser;
  final Translation providerName;
  final ResponseContinueFlow? updateParams;

  ///
  AuthUserData({
    required this.authUser,
    required this.providerName,
    required this.updateParams,
  });

  factory AuthUserData.fromJson(Map<String, Object?> json) {
    return AuthUserData(
      authUser: AuthUser.fromJsonRaw(json['authUser']! as Map<String, Object?>),
      providerName: Translation.fromJson(json['providerName']),
      updateParams: json['updateParams'] == null
          ? null
          : ResponseContinueFlow.fromJson(
              json['updateParams']! as Map<String, Object?>,
            ),
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'authUser': authUser,
      'providerName': providerName,
      'updateParams': updateParams,
    }..removeWhere((key, value) => value == null);
  }
}

class AuthUser<T> implements SerializableToJson {
  ///
  AuthUser({
    required this.providerId,
    required this.providerUserId,
    this.name,
    this.picture,
    this.email,
    required this.emailIsVerified,
    this.phone,
    required this.phoneIsVerified,
    required this.rawUserData,
    this.openIdClaims,
    required this.providerUser,
  });

  final String providerId;
  final String providerUserId;
  final String? name;
  final String? picture;
  final String? email;
  final bool emailIsVerified;
  final String? phone;
  final bool phoneIsVerified;
  final Map<String, Object?> rawUserData;
  final OpenIdClaims? openIdClaims;
  final T providerUser;
  // TODO: created at

  /// A global unique key for the user
  String get key => '$providerId:$providerUserId';

  List<UserId> userIds() {
    return [
      UserId(key, UserIdKind.providerId),
      if (emailIsVerified && email != null)
        UserId(email!, UserIdKind.verifiedEmail),
      if (phoneIsVerified && phone != null)
        UserId(phone!, UserIdKind.verifiedPhone),
    ];
  }

  static AuthUser<OpenIdClaims> fromClaims(
    OpenIdClaims claims, {
    required String providerId,
  }) =>
      AuthUser(
        emailIsVerified: claims.emailVerified ?? false,
        phoneIsVerified: claims.phoneNumberVerified ?? false,
        providerId: providerId,
        providerUser: claims,
        rawUserData: claims.toJson(),
        providerUserId: claims.subject,
        email: claims.email,
        name: claims.name,
        openIdClaims: claims,
        phone: claims.phoneNumber,
        picture: claims.picture?.toString(),
      );

  static AuthUser<void> fromJsonRaw(Map<String, Object?> json) {
    return AuthUser(
      providerId: json['providerId']! as String,
      providerUserId: json['providerUserId']! as String,
      name: json['name'] as String?,
      picture: json['picture'] as String?,
      email: json['email'] as String?,
      emailIsVerified: json['emailIsVerified']! as bool,
      phone: json['phone'] as String?,
      phoneIsVerified: json['phoneIsVerified']! as bool,
      rawUserData: json,
      openIdClaims: null,
      providerUser: null,
    );
  }

  static AuthUser<U> fromJson<U>(
    Map<String, Object?> json,
    AuthenticationProvider<U> provider,
  ) {
    final param = json['rawUserData'] is String
        ? (jsonDecode(json['rawUserData']! as String) as Map)
        : json['rawUserData'] is Map
            ? (json['rawUserData']! as Map)
            : json;
    return provider.parseUser(param.cast());
  }

  @override
  Map<String, Object?> toJson() => {
        'providerId': providerId,
        'providerUserId': providerUserId,
        'name': name,
        'picture': picture,
        'email': email,
        'emailIsVerified': emailIsVerified,
        'phone': phone,
        'phoneIsVerified': phoneIsVerified,
        ...rawUserData,
      }..removeWhere((key, value) => value == null);
}

/// An error found when getting the user's data
class GetUserError implements Exception {
  /// The response that contains the error or that was received before the error
  final HttpResponse? response;

  /// A generic message about the error
  final String? message;

  /// The [sourceError]'s [StackTrace] or the [StackTrace] where this was created
  final StackTrace stackTrace;

  /// The source error, if any
  final Object? sourceError;

  /// The token used to create the response
  final TokenResponse token;

  /// An error found when getting the user's data
  GetUserError({
    required this.token,
    required this.response,
    this.message,
    this.sourceError,
    StackTrace? stackTrace,
  }) : stackTrace = stackTrace ?? StackTrace.current;

  @override
  String toString() {
    return 'GetUserError${{
      "response": response,
      "message": message,
      "sourceError": sourceError,
      "stackTrace": stackTrace,
    }}';
  }
}

/// Tries to execute [tryFunction] and returns an [Ok] with its returned value.
/// If [tryFunction] throws an exception, the [catchFunction] will be used to
/// map the error and [StackTrace] and return an [Err].
Result<T, E> tryCatch<T extends Object, E extends Object>(
  T Function() tryFunction,
  E Function(Object sourceError, StackTrace stackTrace) catchFunction,
) {
  try {
    return Ok(tryFunction());
  } catch (e, s) {
    return Err(catchFunction(e, s));
  }
}

Result<T, ErrorWithStackTrace> Function(P) tryCatchWrap<P, T extends Object>(
  T Function(P) tryFunction,
) {
  return (P param) {
    try {
      return Ok(tryFunction(param));
    } catch (e, s) {
      return Err(ErrorWithStackTrace(e, s));
    }
  };
}

class ErrorWithStackTrace {
  final Object error;
  final StackTrace stackTrace;

  const ErrorWithStackTrace(this.error, this.stackTrace);

  @override
  String toString() {
    return '$error $stackTrace';
  }
}

/// A class that implements this can be serialized
/// into Json with the [toJson] method
abstract class SerializableToJson {
  /// Returns this represented as a Json map
  Map<String, Object?> toJson();

  /// Executes [toJson] from [instance]
  static Map<String, Object?> staticToJson(SerializableToJson instance) =>
      instance.toJson();
}
