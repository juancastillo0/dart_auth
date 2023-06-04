import 'package:oauth/oauth.dart';
import 'package:oauth_example/auth_handler.dart';
import 'package:oauth_example/rate_limit.dart';

class RateLimits {
  final List<RateLimit> baseQueriesLimits;
  final List<RateLimit> baseMutateLimits;
  final Map<AuthHandlerEndpoint, List<RateLimit>> authHandlerLimits;
  final Map<AuthHandlerEndpoint, Duration> authHandlerMaxSessionCreation;
  final Map<AuthHandlerEndpoint, Duration> authHandlerMaxSessionRefresh;

  ///
  const RateLimits({
    this.authHandlerLimits = defaultAuthHandlerLimits,
    this.authHandlerMaxSessionCreation = defaultMaxSessionCreation,
    this.authHandlerMaxSessionRefresh = defaultMaxSessionRefresh,
    this.baseQueriesLimits = defaultBaseQueriesLimits,
    this.baseMutateLimits = defaultBaseMutateLimits,
  });

  static const defaultBaseQueriesLimits = [
    RateLimit(200, Duration(minutes: 1)),
    RateLimit(2000, Duration(hours: 1)),
  ];

  static const defaultBaseMutateLimits = [
    RateLimit(40, Duration(minutes: 1)),
    RateLimit(100, Duration(hours: 1)),
  ];

  factory RateLimits.fromJson(Map<String, Object?> json) {
    final mergeDefaults = json['mergeDefaults'] as bool? ?? true;
    final authHandlerLimits = <AuthHandlerEndpoint, List<RateLimit>>{
      if (mergeDefaults) ...defaultAuthHandlerLimits,
    };
    final authHandlerMaxSessionCreation = <AuthHandlerEndpoint, Duration>{
      if (mergeDefaults) ...defaultMaxSessionCreation,
      ...?(json['authHandlerMaxSessionCreation'] as Map<String, Object?>?)?.map(
        (key, value) => MapEntry(
          AuthHandlerEndpoint.values.firstWhere((e) => e.name == key),
          Duration(microseconds: value! as int),
        ),
      ),
    };
    final authHandlerMaxSessionRefresh = <AuthHandlerEndpoint, Duration>{
      if (mergeDefaults) ...defaultMaxSessionRefresh,
      // TODO:
    };
    for (final entry
        in (json['authHandlerLimits'] as Map<String, Object?>? ?? {}).entries) {
      final endpoint = AuthHandlerEndpoint.values.firstWhereOrNull(
        (e) => e.name == entry.key,
      );
      if (endpoint != null) {
        final limits = (entry.value! as List)
            .map((e) => RateLimit.fromJson(e as Map<String, Object?>))
            .toList();
        authHandlerLimits[endpoint] = limits;
      }
    }
    return RateLimits(
      authHandlerLimits: authHandlerLimits,
      authHandlerMaxSessionCreation: authHandlerMaxSessionCreation,
      authHandlerMaxSessionRefresh: authHandlerMaxSessionRefresh,
      baseMutateLimits: json['baseMutateLimits'] == null
          ? defaultBaseMutateLimits
          : (json['baseMutateLimits']! as List)
              .map((e) => RateLimit.fromJson(e as Map<String, Object?>))
              .toList(),
      baseQueriesLimits: json['baseQueriesLimits'] == null
          ? defaultBaseQueriesLimits
          : (json['baseQueriesLimits']! as List)
              .map((e) => RateLimit.fromJson(e as Map<String, Object?>))
              .toList(),
    );
  }

  static const defaultMaxSessionCreation = {
    AuthHandlerEndpoint.userMfa: Duration(minutes: 10),
    AuthHandlerEndpoint.userSignout: Duration(minutes: 2),
    AuthHandlerEndpoint.userDelete: Duration(minutes: 1),
    AuthHandlerEndpoint.providersDelete: Duration(minutes: 5),
    AuthHandlerEndpoint.credentialsUpdate: Duration(minutes: 5),
    AuthHandlerEndpoint.adminUsersDisable: Duration(minutes: 5),
  };

  static const defaultMaxSessionRefresh = {
    AuthHandlerEndpoint.jwtRefresh: Duration(days: 8),
  };

  static const defaultAuthHandlerLimits = {
    AuthHandlerEndpoint.oauthUrl: [
      RateLimit(5, Duration(minutes: 1)),
      RateLimit(20, Duration(hours: 1)),
      RateLimit(40, Duration(days: 1)),
    ],
    AuthHandlerEndpoint.oauthDevice: [
      RateLimit(5, Duration(minutes: 1)),
      RateLimit(20, Duration(hours: 1)),
      RateLimit(40, Duration(days: 1)),
    ],
    AuthHandlerEndpoint.credentialsSignin: [
      RateLimit(5, Duration(minutes: 1)),
      RateLimit(20, Duration(hours: 1)),
      RateLimit(40, Duration(days: 1)),
    ],
    AuthHandlerEndpoint.credentialsSignup: [
      RateLimit(15, Duration(minutes: 1)),
      RateLimit(50, Duration(hours: 1)),
      RateLimit(100, Duration(days: 1)),
    ],
    AuthHandlerEndpoint.credentialsUpdate: [
      RateLimit(5, Duration(minutes: 1)),
      RateLimit(15, Duration(hours: 1)),
      RateLimit(30, Duration(days: 1)),
    ],
    AuthHandlerEndpoint.providersDelete: [
      RateLimit(3, Duration(minutes: 1)),
      RateLimit(5, Duration(hours: 1)),
      RateLimit(10, Duration(days: 1)),
    ],
    AuthHandlerEndpoint.adminUsersDisable: [
      RateLimit(15, Duration(minutes: 1)),
      RateLimit(50, Duration(hours: 1)),
      RateLimit(100, Duration(days: 1)),
    ],
    AuthHandlerEndpoint.userDelete: [
      RateLimit(1, Duration(minutes: 1)),
      RateLimit(3, Duration(hours: 1)),
      RateLimit(5, Duration(days: 1)),
    ],
  };
}
