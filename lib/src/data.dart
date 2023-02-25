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

  /// Returns a any (valid or not valid) session with [sessionId].
  Future<UserSession?> getAnySession(String sessionId);

  /// Returns a valid session with [sessionId].
  Future<UserSession?> getValidSession(String sessionId) =>
      getAnySession(sessionId)
          .then((value) => value?.endedAt == null ? value : null);

  /// Saves a [user] and associates it with a [userId]
  Future<void> saveUser(String userId, AuthUser user);

  /// Retrieves users by ids. The array should have the same length.
  Future<List<AppUser?>> getUsersById(List<UserId> ids);
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

  /// Verifier email address
  verifiedEmail,

  /// Verifier phone number
  verifiedPhone,
}

/// A user session, persisted when the user is signed in.
class UserSession {
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
// generated-dart-fixer-start{"md5Hash":"UR44W1AtB7vHXyyYToVCGQ=="}

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

class AppUser {
  final String userId;
  final String? name;
  final String? profilePicture;
  final String? email;
  final bool emailIsVerified;
  final String? phone;
  final bool phoneIsVerified;
  final List<AuthUser<dynamic>> authUsers;

  ///
  const AppUser({
    required this.userId,
    this.name,
    this.profilePicture,
    this.email,
    required this.emailIsVerified,
    this.phone,
    required this.phoneIsVerified,
    required this.authUsers,
  });

  factory AppUser.merge(
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
    final profilePicture = list.firstWhere(
      (auth) => auth!.profilePicture != null,
      orElse: () => null,
    );
    return AppUser(
      userId: userId,
      emailIsVerified: base != null && base.emailIsVerified || email != null,
      phoneIsVerified: base != null && base.phoneIsVerified || phone != null,
      email: base == null
          ? email?.email
          : (base.emailIsVerified ? base.email : email?.email ?? base.email),
      phone: base == null
          ? phone?.phone
          : (base.phoneIsVerified ? base.phone : phone?.phone ?? base.phone),
      name: base?.name ?? name?.name,
      profilePicture: base?.profilePicture ?? profilePicture?.profilePicture,
      authUsers: authUsers,
    );
  }

  factory AppUser.fromJson(
    Map<String, Object?> json,
    Map<String, OAuthProvider<dynamic>> providers,
  ) {
    return AppUser(
      userId: json['userId']! as String,
      emailIsVerified: json['emailIsVerified']! as bool,
      phoneIsVerified: json['phoneIsVerified']! as bool,
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
      name: json['name'] as String?,
      profilePicture: json['profilePicture'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Iterable<UserId> userIds() => [UserId(userId, UserIdKind.innerId)]
      .followedBy(authUsers.expand((auth) => auth.userIds()));

  Map<String, Object?> toJson() {
    return {
      'userId': userId,
      'name': name,
      'profilePicture': profilePicture,
      'email': email,
      'emailIsVerified': emailIsVerified,
      'phone': phone,
      'phoneIsVerified': phoneIsVerified,
      'authUsers': authUsers,
    };
  }
}

class AuthUser<T> {
  ///
  const AuthUser({
    required this.providerId,
    required this.providerUserId,
    this.name,
    this.profilePicture,
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
  final String? profilePicture;
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
        profilePicture: claims.picture?.toString(),
      );

  Map<String, Object?> toJson() => {
        'providerId': providerId,
        'providerUserId': providerUserId,
        'name': name,
        'profilePicture': profilePicture,
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
