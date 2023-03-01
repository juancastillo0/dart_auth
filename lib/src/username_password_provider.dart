import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth/src/password.dart';

class UsernamePasswordProvider
    extends CredentialsProvider<UsernamePassword, UsernamePasswordUser> {
  ///
  UsernamePasswordProvider({
    this.providerId = ImplementedProviders.username,
    ParamDescription? usernameDescription,
    ParamDescription? passwordDescription,
    this.redirectUrl,
    this.useIsolateForHashing = true,
  })  : usernameDescription = usernameDescription ?? defaultUsernameDescription,
        passwordDescription = passwordDescription ?? defaultPasswordDescription;

  static final defaultUsernameDescription = ParamDescription(
    name: 'Username',
    description: 'Alphanumeric username with at least 3 characters.'
        ' This will be your identifier to sign in.',
    regExp: RegExp(r'^[a-zA-Z0-9_-]{3,}$'),
  );
  static final defaultPasswordDescription = ParamDescription(
    name: 'Password',
    description: 'Should be at least 8 characters.',
    regExp: RegExp(r'[\s\S]{8,}'),
  );

  @override
  final String providerId;
  final ParamDescription usernameDescription;
  final ParamDescription passwordDescription;
  final String? redirectUrl;
  final bool useIsolateForHashing;

  @override
  Future<Result<Option<CredentialsResponse<UsernamePasswordUser>>, AuthError>>
      verifyCredentials(
    UsernamePasswordUser user,
    UsernamePassword credentials,
  ) async {
    final bool isValid;
    if (useIsolateForHashing) {
      isValid = await verifyPasswordFromIsolate(
        credentials.password,
        user.passwordHash,
      );
    } else {
      isValid = verifyPasswordFromHash(
        credentials.password,
        user.passwordHash,
      );
    }
    return isValid
        ? const Ok(None())
        : Err(
            AuthError(
              code: 'invalid_password',
              message: 'Invalid password.',
            ),
          );
  }

  @override
  Future<Result<CredentialsResponse<UsernamePasswordUser>, AuthError>> getUser(
    UsernamePassword credentials,
  ) async {
    final String passwordHash;
    if (useIsolateForHashing) {
      passwordHash = await hashPasswordFromIsolate(credentials.password);
    } else {
      passwordHash = hashFromPassword(credentials.password);
    }
    final providerUser = UsernamePasswordUser(
      username: credentials.username,
      passwordHash: passwordHash,
    );
    return Ok(
      CredentialsResponse.authenticated(
        AuthUser(
          providerId: providerId,
          providerUserId: providerUser.username,
          emailIsVerified: false,
          phoneIsVerified: false,
          rawUserData: providerUser.toJson(),
          providerUser: providerUser,
        ),
        redirectUrl: redirectUrl,
      ),
    );
  }

  @override
  Map<String, ParamDescription> get paramDescriptions =>
      {'username': usernameDescription, 'password': passwordDescription};

  @override
  Result<UsernamePassword, Map<String, FormatException>> parseCredentials(
    Map<String, Object?> json,
  ) {
    final password = json['password'];
    final username = json['username'];
    if (password is! String || username is! String) {
      return Err({
        if (username is! String)
          'username': const FormatException(
            'Should have an username.',
          ),
        if (password is! String)
          'password': const FormatException(
            'Should have a password.',
          ),
      });
    }
    final usernameError = usernameDescription.validate(username);
    final passwordError = passwordDescription.validate(password);
    if (usernameError != null || passwordError != null) {
      return Err({
        if (usernameError != null) 'username': usernameError,
        if (passwordError != null) 'password': passwordError,
      });
    }

    return Ok(UsernamePassword(username: username, password: password));
  }
}

class AuthError {
  final String code;
  final String? message;

  AuthError({required this.code, required this.message});

  Map<String, Object?> toJson() {
    return {
      'code': code,
      'message': message,
    };
  }
}

class UsernamePasswordUser {
  final String username;
  final String passwordHash;

  ///
  UsernamePasswordUser({
    required this.username,
    required this.passwordHash,
  });

  Map<String, Object?> toJson() {
    return {
      'username': username,
      'passwordHash': passwordHash,
    };
  }
}

class UsernamePassword extends CredentialsData {
  final String username;
  final String password;

  ///
  UsernamePassword({
    required this.username,
    required this.password,
  });

  @override
  String get providerUserId => username;
}

abstract class CredentialsProvider<C extends CredentialsData, U> {
  String get providerId;
  Map<String, ParamDescription>? get paramDescriptions;
  Result<C, Map<String, FormatException>> parseCredentials(
    Map<String, Object?> json,
  );

  Future<Result<Option<CredentialsResponse<U>>, AuthError>> verifyCredentials(
    U user,
    C credentials,
  );
  Future<Result<CredentialsResponse<U>, AuthError>> getUser(C credentials);
}

abstract class CredentialsData {
  // TODO: allow for email/phone ids
  String get providerUserId;
}

class CredentialsResponse<U> implements SerializableToJson {
  final AuthUser<U>? user;
  final String? redirectUrl;
  final String? userMessage;
  final String? state;

  CredentialsResponse.continueFlow({
    this.redirectUrl,
    this.userMessage,
    this.state,
  }) : user = null;

  CredentialsResponse.authenticated(
    AuthUser<U> this.user, {
    this.redirectUrl,
    this.userMessage,
  }) : state = null;

  @override
  Map<String, Object?> toJson() => {
        'user': user,
        'redirectUrl': redirectUrl,
        'userMessage': userMessage,
        'state': state,
      }..removeWhere((key, value) => value == null);
}

class ParamDescription {
  final String name;
  final String? description;
  final RegExp? regExp;
  final Map<String, ParamDescription>? paramsDescription;

  ParamDescription({
    required this.name,
    required this.description,
    required this.regExp,
    this.paramsDescription,
  });

  FormatException? validate(String value) {
    if (regExp != null && !regExp!.hasMatch(value)) {
      return FormatException(
        '$name does not match ${description ?? 'validation'}'
        ' (${regExp!.pattern}).',
      );
    }
    return null;
  }
}
