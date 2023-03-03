import 'dart:math';

import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth/src/password.dart';

class MagicCodeConfig<U> {
  ///
  MagicCodeConfig({
    required this.onlyMagicCodeNoPassword,
    required this.sendMagicCode,
    required this.persistence,
    this.generateMagicCode = defaultGenerateMagicCode,
  });

  static String defaultGenerateMagicCode({
    int count = 6,
    String alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789',
    Random? random,
  }) {
    final r = random ?? Random.secure();
    // TODO: return Param description, use RegExp.escape
    return String.fromCharCodes(
      Iterable.generate(
        count,
        (_) => alphabet.codeUnitAt(
          r.nextInt(alphabet.length),
        ),
      ),
    );
  }

  final bool onlyMagicCodeNoPassword;
  final Future<Result<Unit, AuthError>> Function({
    required String identifier,
    required String magicCode,
  }) sendMagicCode;
  final Persistence persistence;
  final String Function() generateMagicCode;
}

class IdentifierPasswordProvider<U extends IdentifierPasswordUser>
    extends CredentialsProvider<IdentifierPassword, U> {
  ///
  IdentifierPasswordProvider({
    required this.identifierName,
    required this.identifierDescription,
    required this.providerId,
    required this.makeUser,
    required this.magicCodeConfig,
    ParamDescription? passwordDescription,
    this.redirectUrl,
    this.useIsolateForHashing = true,
  }) : passwordDescription = passwordDescription ??
            UsernamePasswordProvider.defaultPasswordDescription;

  static IdentifierPasswordProvider<EmailPasswordUser> email({
    required MagicCodeConfig<EmailPasswordUser> magicCodeConfig,
    String providerId = ImplementedProviders.email,
    MakeUserFromIdentifier<EmailPasswordUser> makeUser =
        EmailPasswordUser.makeUser,
    ParamDescription? emailDescription,
    ParamDescription? passwordDescription,
    String? redirectUrl,
    bool useIsolateForHashing = true,
  }) {
    return IdentifierPasswordProvider(
      magicCodeConfig: magicCodeConfig,
      providerId: providerId,
      makeUser: makeUser,
      identifierName: 'email',
      identifierDescription: emailDescription ?? defaultEmailDescription,
      passwordDescription: passwordDescription,
      redirectUrl: redirectUrl,
      useIsolateForHashing: useIsolateForHashing,
    );
  }

  static final defaultEmailDescription = ParamDescription(
    name: 'Email',
    description: 'The email address. This will be your identifier to sign in.',
    regExp: RegExp('@'),
  );

  static IdentifierPasswordProvider<PhonePasswordUser> phone({
    required MagicCodeConfig<PhonePasswordUser> magicCodeConfig,
    String providerId = ImplementedProviders.phone,
    MakeUserFromIdentifier<PhonePasswordUser> makeUser =
        PhonePasswordUser.makeUser,
    ParamDescription? phoneDescription,
    ParamDescription? passwordDescription,
    String? redirectUrl,
    bool useIsolateForHashing = true,
  }) {
    return IdentifierPasswordProvider(
      magicCodeConfig: magicCodeConfig,
      providerId: providerId,
      makeUser: makeUser,
      identifierName: 'phone',
      identifierDescription: phoneDescription ?? defaultPhoneDescription,
      passwordDescription: passwordDescription,
      redirectUrl: redirectUrl,
      useIsolateForHashing: useIsolateForHashing,
    );
  }

  static final defaultPhoneDescription = ParamDescription(
    name: 'Phone',
    description: 'The phone number. This will be your identifier to sign in.',
    regExp: RegExp(r'^[0-9]{7,}$'),
  );

  @override
  final String providerId;
  final String identifierName;
  final ParamDescription identifierDescription;
  final ParamDescription passwordDescription;
  final String? redirectUrl;
  final bool useIsolateForHashing;
  final MakeUserFromIdentifier<U> makeUser;
  final MagicCodeConfig<U>? magicCodeConfig;

  bool get onlyMagicCodeNoPassword =>
      magicCodeConfig?.onlyMagicCodeNoPassword ?? false;

  @override
  Map<String, ParamDescription> get paramDescriptions {
    return {
      identifierName: identifierDescription,
      if (!onlyMagicCodeNoPassword) 'password': passwordDescription,
      // TODO: make it required? configurable? localization/internationalization
      'name': ParamDescription(name: 'Name', description: null, regExp: null),
    };
  }

  @override
  Future<Result<Option<CredentialsResponse<U>>, AuthError>> verifyCredentials(
    U user,
    IdentifierPassword credentials,
  ) async {
    if (onlyMagicCodeNoPassword) {
      // TODO: should we always ask for magic link?
      final result = await getUser(credentials);
      return result.map(Some.new);
    }
    final bool isValid;
    if (useIsolateForHashing) {
      isValid = await verifyPasswordFromIsolate(
        credentials.password!,
        user.passwordHash!,
      );
    } else {
      isValid = verifyPasswordFromHash(
        credentials.password!,
        user.passwordHash!,
      );
    }
    return isValid
        // ignore: prefer_const_constructors
        ? Ok(None())
        : Err(
            AuthError(
              error: 'invalid_password',
              message: 'Invalid password.',
            ),
          );
  }

  @override
  Future<Result<CredentialsResponse<U>, AuthError>> getUser(
    IdentifierPassword credentials,
  ) async {
    String? passwordHash;
    if (!onlyMagicCodeNoPassword &&
        credentials.password != null &&
        credentials.magicCode == null) {
      if (useIsolateForHashing) {
        passwordHash = await hashPasswordFromIsolate(credentials.password!);
      } else {
        passwordHash = hashFromPassword(credentials.password!);
      }
    }

    String? name = credentials.name;
    String? state;
    final ml = magicCodeConfig;
    bool authenticated = ml == null;
    String? magicCode;
    if (ml != null) {
      if (credentials.magicCode == null) {
        // No magic code sent by the user, start the flow
        // TODO: should we ask for password after verification? make it configurable?
        if (passwordHash == null && !onlyMagicCodeNoPassword) {
          return Err(
            AuthError(error: 'no_password', message: 'Password is required'),
          );
        }
        state = generateStateToken();
        magicCode = ml.generateMagicCode();
        // initial request
        await ml.persistence.setState(
          state,
          AuthStateModel(
            responseType: null,
            createdAt: DateTime.now(),
            providerId: providerId,
            meta: CredentialsAuthState(
              identifier: credentials.identifier,
              passwordHash: passwordHash,
              magicCode: magicCode,
              name: name,
            ).toJson(),
          ),
        );
        // TODO: should this have a result? what happens if there is an error?
        final result = await ml.sendMagicCode(
          identifier: credentials.identifier,
          magicCode: magicCode,
        );
        if (result.isErr()) return Err(result.unwrapErr());
      } else {
        // A magic code sent by the user, verify the flow
        final s = credentials.state;
        if (s == null) {
          return Err(AuthError(error: 'no_state', message: 'Bad request'));
        }
        state = s;
        final stateModel = await ml.persistence.getState(state);
        if (stateModel == null) {
          return Err(AuthError(error: 'invalid_state', message: 'Bad request'));
        }
        final CredentialsAuthState model;
        try {
          model = CredentialsAuthState.fromJson(stateModel.meta!);
        } catch (_) {
          return Err(AuthError(error: 'invalid_state', message: 'Bad request'));
        }

        if (model.magicCode != credentials.magicCode) {
          return Err(AuthError(error: 'invalid_code', message: 'Unauthorized'));
        }
        if (model.identifier != credentials.identifier) {
          return Err(
            AuthError(error: 'invalid_identifier', message: 'Unauthorized'),
          );
        }
        authenticated = true;
        passwordHash ??= model.passwordHash;
        name ??= model.name;
      }
    }
    if (authenticated && passwordHash == null && !onlyMagicCodeNoPassword) {
      return Err(
        AuthError(error: 'no_password', message: 'Password is required'),
      );
    }
    if (!authenticated) {
      return Ok(
        CredentialsResponse.continueFlow(
          // TODO configurable
          userMessage: 'A code has been sent',
          redirectUrl: redirectUrl,
          state: state!,
          paramDescriptions: {
            // TODO: use it to validate
            'magicCode': ParamDescription(
              name: 'Magic Code',
              description: 'The code sent to your device',
              regExp: RegExp(r'^[a-z0-9]{6}$'),
            ),
          },
        ),
      );
    }
    // final providerUser = UsernamePasswordUser(
    //   username: credentials.identifier,
    //   passwordHash: passwordHash,
    // );
    final authUser = makeUser(
      identifier: credentials.identifier,
      passwordHash: passwordHash,
      providerId: providerId,
      name: name,
    );
    // final emailVerified = ids.any((id) => id.kind ==
    //     UserIdKind.verifiedEmail);
    // final phoneIsVerified =
    //     ids.any((id) => id.kind == UserIdKind.verifiedPhone);
    return Ok(
      CredentialsResponse.authenticated(
        authUser,
        redirectUrl: redirectUrl,
      ),
    );
  }

  @override
  Result<IdentifierPassword, Map<String, FormatException>> parseCredentials(
    Map<String, Object?> json,
  ) {
    final password = json['password'];
    final identifier = json[identifierName];
    final magicCode = json['magicCode'];
    final state = json['state'];
    final name = json['name'];
    if ((password is! String?) ||
        (identifier is! String?) ||
        (magicCode is! String?) ||
        (state is! String?) ||
        (name is! String?)) {
      return Err({
        if (identifier is! String?)
          identifierName: const FormatException(
            'Should have an String identifier.',
          ),
        if (password is! String?)
          'password': const FormatException(
            'Should have a String password.',
          ),
        if (magicCode is! String?)
          'magicCode': const FormatException(
            'Should have a String magicCode.',
          ),
        if (state is! String?)
          'state': const FormatException(
            'Should have a String state.',
          ),
        if (name is! String?)
          'name': const FormatException(
            'Should have a String name.',
          ),
      });
    }

    // onlyMagicCodeNoPassword -> identifier -> magicCode
    // magicCode & password -> identifier & password -> magicCode
    // password -> identifier & password
    if ((magicCodeConfig == null && password == null) ||
        identifier is! String) {
      return Err({
        if (identifier is! String)
          identifierName: const FormatException(
            'Should have an identifier.',
          ),
        if (password is! String)
          'password': const FormatException(
            'Should have a password.',
          ),
      });
    }
    final identifierError = identifierDescription.validate(identifier);
    final passwordError =
        password == null ? null : passwordDescription.validate(password);
    if (identifierError != null || passwordError != null) {
      return Err({
        if (identifierError != null) identifierName: identifierError,
        if (passwordError != null) 'password': passwordError,
      });
    }

    return Ok(
      IdentifierPassword(
        // TODO: normalize identifier
        identifier: identifier,
        password: password,
        magicCode: magicCode,
        state: state,
        name: name?.trim().replaceAll(RegExp(r'\s+'), ' '),
      ),
    );
  }
}

///
typedef MakeUserFromIdentifier<U> = AuthUser<U> Function({
  required String providerId,
  required String identifier,
  required String? passwordHash,
  String? name,
});

class EmailPasswordUser implements IdentifierPasswordUser {
  final String email;
  @override
  final String? passwordHash;

  ///
  EmailPasswordUser({
    required this.email,
    required this.passwordHash,
  });

  Map<String, Object?> toJson() {
    return {
      'email': email,
      'passwordHash': passwordHash,
    };
  }

  static AuthUser<EmailPasswordUser> makeUser({
    required String providerId,
    required String identifier,
    required String? passwordHash,
    String? name,
  }) {
    final providerUser = EmailPasswordUser(
      email: identifier,
      passwordHash: passwordHash,
    );
    return AuthUser(
      providerId: providerId,
      providerUserId: identifier,
      emailIsVerified: true,
      phoneIsVerified: false,
      rawUserData: providerUser.toJson(),
      providerUser: providerUser,
      email: identifier,
      name: name,
    );
  }
}

class PhonePasswordUser implements IdentifierPasswordUser {
  final String phone;
  @override
  final String? passwordHash;

  ///
  PhonePasswordUser({
    required this.phone,
    required this.passwordHash,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'phone': phone,
      'passwordHash': passwordHash,
    };
  }

  static AuthUser<PhonePasswordUser> makeUser({
    required String providerId,
    required String identifier,
    required String? passwordHash,
    String? name,
  }) {
    final providerUser = PhonePasswordUser(
      phone: identifier,
      passwordHash: passwordHash,
    );
    return AuthUser(
      providerId: providerId,
      providerUserId: identifier,
      emailIsVerified: false,
      phoneIsVerified: true,
      rawUserData: providerUser.toJson(),
      providerUser: providerUser,
      phone: identifier,
      name: name,
    );
  }
}

abstract class IdentifierPasswordUser implements SerializableToJson {
  String? get passwordHash;
}

class IdentifierPassword extends CredentialsData {
  final String identifier;
  final String? password;
  final String? magicCode;
  final String? state;
  final String? name;

  ///
  IdentifierPassword({
    required this.identifier,
    required this.password,
    required this.magicCode,
    required this.state,
    required this.name,
  });

  // TODO: may be an email or phone
  @override
  String get providerUserId => identifier;
}

class CredentialsAuthState extends SerializableToJson {
  final String identifier;
  final String magicCode;
  final String? passwordHash;
  final String? name;

  ///
  CredentialsAuthState({
    required this.identifier,
    required this.magicCode,
    required this.passwordHash,
    required this.name,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'identifier': identifier,
      'magicCode': magicCode,
      'passwordHash': passwordHash,
      'name': name,
    };
  }

  factory CredentialsAuthState.fromJson(Map<String, Object?> json) {
    return CredentialsAuthState(
      identifier: json['identifier']! as String,
      magicCode: json['magicCode']! as String,
      passwordHash: json['passwordHash'] as String?,
      name: json['name'] as String?,
    );
  }
}
