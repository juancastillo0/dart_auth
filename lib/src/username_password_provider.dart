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
  // TODO: add name description
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
    return isValid ? const Ok(None()) : const Err(AuthError.invalidPassword);
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
  final String error;
  final String? message;

  const AuthError({
    required this.error,
    required this.message,
  });

  Map<String, Object?> toJson() {
    return {
      'error': error,
      'message': message,
    };
  }

  static const noState = AuthError(
    error: 'no_state',
    message: 'Bad request',
  );
  static const noPassword = AuthError(
    error: 'no_password',
    message: 'Password is required',
  );
  static const invalidState = AuthError(
    error: 'invalid_state',
    message: 'Bad request',
  );
  static const invalidPassword = AuthError(
    error: 'invalid_password',
    message: 'Invalid credentials',
  );
  static const invalidCode = AuthError(
    error: 'invalid_code',
    message: 'Unauthorized, wrong code',
  );
  static const invalidIdentifier = AuthError(
    error: 'invalid_identifier',
    message: 'Unauthorized, wrong identifier',
  );
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
  /// The unique global provider identifier
  String get providerId;

  /// The description of the params required for authentication
  Map<String, ParamDescription>? get paramDescriptions;

  /// Parses a [json] Map into the credentials [C] or returns a Map of
  /// [FormatException]s for the fields that contain an error.
  Result<C, Map<String, FormatException>> parseCredentials(
    Map<String, Object?> json,
  );

  /// Verifies that the [credentials] are associated with the [user].
  /// May return a [CredentialsResponse] without an user if the flow
  /// requires additional verification.
  Future<Result<Option<CredentialsResponse<U>>, AuthError>> verifyCredentials(
    U user,
    C credentials,
  );

  /// May return a [CredentialsResponse] without an user if the flow
  /// requires additional verification.
  Future<Result<CredentialsResponse<U>, AuthError>> getUser(C credentials);
}

abstract class CredentialsData {
  // TODO: allow for email/phone ids
  String? get providerUserId;
}

class CredentialsResponse<U> implements SerializableToJson {
  final AuthUser<U>? user;
  final String? redirectUrl;
  final String? qrUrl;
  final String? userMessage;
  final String? state;
  final Map<String, ParamDescription>? paramDescriptions;

  CredentialsResponse.continueFlow({
    required String this.state,
    required String this.userMessage,
    this.redirectUrl,
    this.qrUrl,
    this.paramDescriptions,
  }) : user = null;

  CredentialsResponse.authenticated(
    AuthUser<U> this.user, {
    this.redirectUrl,
    this.userMessage,
  })  : state = null,
        paramDescriptions = null,
        qrUrl = null;

  factory CredentialsResponse.fromJson(Map<String, Object?> json) {
    return CredentialsResponse.continueFlow(
      state: json['state']! as String,
      userMessage: json['userMessage']! as String,
      redirectUrl: json['redirectUrl'] as String?,
      qrUrl: json['qrUrl'] as String?,
      paramDescriptions: json['paramDescriptions'] == null
          ? null
          : (json['paramDescriptions']! as Map).map(
              (key, value) => MapEntry(
                key as String,
                ParamDescription.fromJson(
                  (value as Map).cast(),
                ),
              ),
            ),
    );
  }

  @override
  Map<String, Object?> toJson() => {
        'user': user,
        'state': state,
        'userMessage': userMessage,
        'redirectUrl': redirectUrl,
        'qrUrl': qrUrl,
        'paramDescriptions': paramDescriptions,
      }..removeWhere((key, value) => value == null);
}

class ParamDescription implements SerializableToJson {
  final String name;
  final String? description;
  final RegExp? regExp;
  final Map<String, ParamDescription>? paramsDescriptions;

  ///
  ParamDescription({
    required this.name,
    required this.description,
    required this.regExp,
    this.paramsDescriptions,
  });

  factory ParamDescription.fromJson(Map<String, Object?> json) {
    return ParamDescription(
      name: json['name']! as String,
      description: json['description'] as String?,
      regExp: json['regExp'] == null ? null : RegExp(json['regExp']! as String),
      paramsDescriptions: json['paramsDescriptions'] == null
          ? null
          : (json['paramsDescriptions']! as Map).map(
              (key, value) => MapEntry(
                key! as String,
                ParamDescription.fromJson((value as Map).cast()),
              ),
            ),
    );
  }

  FormatException? validate(String value) {
    if (regExp != null && !regExp!.hasMatch(value)) {
      return FormatException(
        '$name does not match ${description ?? 'validation'}'
        ' (${regExp!.pattern}).',
      );
    }
    return null;
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'name': name,
      'description': description,
      'regExp': regExp?.pattern,
      'paramsDescriptions': paramsDescriptions,
    }..removeWhere((key, value) => value == null);
  }
}
