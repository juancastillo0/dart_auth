import 'package:oauth/providers.dart';

abstract class Persistence {
  Future<String?> getState(String key);
  Future<void> setState(String key, String value);
}

class AuthUser {
  ///
  const AuthUser({
    required this.provider,
    this.name,
    this.email,
    required this.emailIsVerified,
    this.phone,
  });

  final SupportedProviders provider;
  final String? name;
  final String? email;
  final bool emailIsVerified;
  final String? phone;
}
