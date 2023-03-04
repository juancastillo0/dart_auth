import 'package:meta/meta.dart';
import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';

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
  Future<void> saveUser(String userId, AuthUser<Object?> user);

  /// Retrieves users by [ids]. A user is null if it was not found
  /// for the id in the given index.
  /// The returned array should have the same length as [ids].
  Future<List<AppUserComplete?>> getUsersById(List<UserId> ids);

  /// Retrieves a user by [id].
  Future<AppUserComplete?> getUserById(UserId id) =>
      getUsersById([id]).then((value) => value.first);
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
  final DateTime? endedAt;

  /// A user session, persisted when the user is signed in.
  const UserSessionBase({
    required this.sessionId,
    required this.userId,
    required this.createdAt,
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
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory UserSessionBase.fromSession(UserSession session) {
    return UserSessionBase(
      sessionId: session.sessionId,
      userId: session.userId,
      endedAt: session.endedAt,
      createdAt: session.createdAt,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'endedAt': endedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// A user session, persisted when the user is signed in.
class UserSession implements SerializableToJson {
  final String sessionId;
  final String refreshToken;
  final String userId;
  final DateTime createdAt;
  final String? deviceId;
  final Map<String, Object?>? meta;
  final DateTime? endedAt;

  /// A user session, persisted when the user is signed in.
  const UserSession({
    required this.sessionId,
    required this.refreshToken,
    required this.userId,
    required this.createdAt,
    this.deviceId,
    this.meta,
    this.endedAt,
  });

  /// Whether the session is valid
  bool get isValid => endedAt == null;

// generated-dart-fixer-start{"md5Hash":"UR44W1AtB7vHXyyYToVCGQ=="}

  UserSession copyWith({
    String? refreshToken,
    String? deviceId,
    bool deviceIdToNull = false,
    Map<String, Object?>? meta,
    bool metaToNull = false,
    DateTime? endedAt,
    bool endedAtToNull = false,
  }) {
    return UserSession(
      refreshToken: refreshToken ?? this.refreshToken,
      sessionId: sessionId,
      userId: userId,
      createdAt: createdAt,
      deviceId: deviceId ?? (deviceIdToNull ? null : this.deviceId),
      endedAt: endedAt ?? (endedAtToNull ? null : this.endedAt),
      meta: meta ?? (metaToNull ? null : this.meta),
    );
  }

  factory UserSession.fromJson(Map json) {
    return UserSession(
      deviceId: json['deviceId'] as String?,
      sessionId: json['sessionId'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: json['userId'] as String,
      meta: json['meta'] == null
          ? null
          : (json['meta'] as Map).map((k, v) => MapEntry(k as String, v)),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
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
      'endedAt': endedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return "UserSession${{
      "deviceId": deviceId,
      "sessionId": sessionId,
      "refreshToken": refreshToken,
      "userId": userId,
      "meta": meta,
      "endedAt": endedAt,
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
      createdAt: DateTime.parse(json['createdAt']! as String),
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
      'createdAt': createdAt.toIso8601String(),
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
        return provider.parseUser(e);
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
  final List<AuthUser<void>> authUsers;
  final List<UserSessionBase>? sessions;

  ///
  UserInfoMe({
    required this.user,
    required this.authUsers,
    required this.sessions,
  });

  factory UserInfoMe.fromJson(Map<String, Object?> json) {
    return UserInfoMe(
      user: AppUser.fromJson((json['user']! as Map).cast()),
      authUsers: (json['authUsers']! as Iterable)
          .cast<Map<String, Object?>>()
          .map(AuthUser.fromJsonRaw)
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

class AuthUser<T> implements SerializableToJson {
  ///
  const AuthUser({
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
    OAuthProvider<U> provider,
  ) =>
      provider.parseUser(json);

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
      };
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
