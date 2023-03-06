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
    this.userMessage = 'A code has been sent',
    this.generateMagicCode = defaultGenerateMagicCode,
  });

  static GeneratedMagicCode defaultGenerateMagicCode({
    int count = 6,
    String alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789',
    Random? random,
  }) {
    final r = random ?? Random.secure();
    final code = String.fromCharCodes(
      Iterable.generate(
        count,
        (_) => alphabet.codeUnitAt(
          r.nextInt(alphabet.length),
        ),
      ),
    );

    return GeneratedMagicCode(
      code,
      ParamDescription(
        name: 'Code',
        description: 'The code sent to your device',
        regExp: RegExp('^[${RegExp.escape(alphabet)}]{${count}}\$'),
      ),
    );
  }

  final String userMessage;
  final bool onlyMagicCodeNoPassword;
  final Future<Result<Unit, AuthError>> Function({
    required String identifier,
    required String magicCode,
  }) sendMagicCode;
  final Persistence persistence;
  final GeneratedMagicCode Function() generateMagicCode;
}

class GeneratedMagicCode {
  /// The magic code used to authenticate the user
  final String code;

  /// The description for the input field for this code.
  /// Presented in the user interface.
  final ParamDescription paramDescription;

  ///
  GeneratedMagicCode(this.code, this.paramDescription);
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
    this.normalizeIdentifier,
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
    String Function(String)? normalizeEmail,
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
      normalizeIdentifier: normalizeEmail ?? defaultNormalizeEmail,
    );
  }

  /// The default identifier parameter description
  /// used in [IdentifierPasswordProvider.email]
  static final defaultEmailDescription = ParamDescription(
    name: 'Email',
    description: 'The email address. This will be your identifier to sign in.',
    regExp: RegExp('@'),
  );

  /// Normalizes an [email] address.
  /// Default used in [IdentifierPasswordProvider.email]
  static String defaultNormalizeEmail(String email) {
    final split = email.toLowerCase().replaceAll(RegExp(r'\s'), '').split('@');
    final domain = split.last.split(',').first;
    return '${split.first}@${domain}';
  }

  static IdentifierPasswordProvider<PhonePasswordUser> phone({
    required MagicCodeConfig<PhonePasswordUser> magicCodeConfig,
    String providerId = ImplementedProviders.phone,
    MakeUserFromIdentifier<PhonePasswordUser> makeUser =
        PhonePasswordUser.makeUser,
    ParamDescription? phoneDescription,
    ParamDescription? passwordDescription,
    String? redirectUrl,
    bool useIsolateForHashing = true,
    String Function(String)? normalizePhone,
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
      normalizeIdentifier: normalizePhone,
    );
  }

  /// The default identifier parameter description
  /// used in [IdentifierPasswordProvider.phone]
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
  final String Function(String)? normalizeIdentifier;

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
    return isValid ? const Ok(None()) : const Err(AuthError.invalidPassword);
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
    GeneratedMagicCode? magicCode;
    if (ml != null) {
      if (credentials.magicCode == null) {
        // No magic code sent by the user, start the flow
        // TODO: should we ask for password after verification? make it configurable?
        if (passwordHash == null && !onlyMagicCodeNoPassword) {
          return const Err(AuthError.noPassword);
        }
        state = generateStateToken();
        magicCode = ml.generateMagicCode();
        // initial request
        await ml.persistence.setState(
          state,
          AuthStateModel(
            state: state,
            responseType: null,
            createdAt: DateTime.now(),
            providerId: providerId,
            meta: CredentialsAuthState(
              identifier: credentials.identifier,
              passwordHash: passwordHash,
              magicCode: magicCode.code,
              name: name,
            ).toJson(),
          ),
        );
        final result = await ml.sendMagicCode(
          identifier: credentials.identifier,
          magicCode: magicCode.code,
        );
        if (result.isErr()) return Err(result.unwrapErr());
      } else {
        // A magic code sent by the user, verify the flow
        final s = credentials.state;
        if (s == null) {
          return const Err(AuthError.noState);
        }
        state = s;
        final stateModel = await ml.persistence.getState(state);
        if (stateModel == null) {
          return const Err(AuthError.invalidState);
        }
        final CredentialsAuthState model;
        try {
          model = CredentialsAuthState.fromJson(stateModel.meta!);
        } catch (_) {
          return const Err(AuthError.invalidState);
        }

        if (model.magicCode != credentials.magicCode) {
          return const Err(AuthError.invalidCode);
        }
        if (model.identifier != credentials.identifier) {
          return const Err(AuthError.invalidIdentifier);
        }
        authenticated = true;
        passwordHash ??= model.passwordHash;
        name ??= model.name;
      }
    }
    if (authenticated && passwordHash == null && !onlyMagicCodeNoPassword) {
      return const Err(AuthError.noPassword);
    }
    if (!authenticated) {
      return Ok(
        CredentialsResponse.continueFlow(
          userMessage: ml!.userMessage,
          redirectUrl: redirectUrl,
          state: state!,
          paramDescriptions: {
            'magicCode': magicCode!.paramDescription,
          },
        ),
      );
    }
    // final providerUser = UsernamePasswordUser(
    //   username: credentials.identifier,
    //   passwordHash: passwordHash,
    // );
    final authUser = makeUser(
      UserIdentifierData(
        identifier: credentials.identifier,
        passwordHash: passwordHash,
        providerId: providerId,
        name: name,
      ),
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
    final normalizedIdentifier =
        normalizeIdentifier?.call(identifier) ?? identifier;
    return Ok(
      IdentifierPassword(
        identifier: normalizedIdentifier,
        password: password,
        magicCode: magicCode,
        state: state,
        name: name?.trim().replaceAll(RegExp(r'\s+'), ' '),
      ),
    );
  }


  @override
  Future<CredentialsResponse<U>?> mfaCredentialsFlow(MFAItem mfaItem) async {
    return CredentialsResponse.continueFlow(
      state: null,
      userMessage: magicCodeConfig != null
          ? 'A magic code will be sent to the device'
          : 'Input the credentials',
      paramDescriptions: {
        identifierName: identifierDescription,
        if (!onlyMagicCodeNoPassword) 'password': passwordDescription,
      },
    );
  }
}

///
typedef MakeUserFromIdentifier<U> = AuthUser<U> Function(
  UserIdentifierData data,
);

/// Parameters for [MakeUserFromIdentifier]
class UserIdentifierData {
  /// The provider id
  final String providerId;

  /// The identifier.
  /// For example, the email if using [IdentifierPasswordProvider.email] or
  /// phone if using [IdentifierPasswordProvider.phone].
  final String identifier;

  /// The password hash to be saved so we can validate the password
  /// on future sign in attempts.
  /// May be null if the provider does not use passwords.
  final String? passwordHash;

  /// The user's name
  final String? name;

  /// Parameters for [MakeUserFromIdentifier]
  UserIdentifierData({
    required this.providerId,
    required this.identifier,
    required this.passwordHash,
    required this.name,
  });
}

class EmailPasswordUser implements IdentifierPasswordUser, SerializableToJson {
  final String email;
  @override
  final String? passwordHash;

  ///
  EmailPasswordUser({
    required this.email,
    required this.passwordHash,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'email': email,
      'passwordHash': passwordHash,
    }..removeWhere((key, value) => value == null);
  }

  static AuthUser<EmailPasswordUser> makeUser(UserIdentifierData data) {
    final providerUser = EmailPasswordUser(
      email: data.identifier,
      passwordHash: data.passwordHash,
    );
    return AuthUser(
      providerId: data.providerId,
      providerUserId: data.identifier,
      emailIsVerified: true,
      phoneIsVerified: false,
      rawUserData: providerUser.toJson(),
      providerUser: providerUser,
      email: data.identifier,
      name: data.name,
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

  static AuthUser<PhonePasswordUser> makeUser(UserIdentifierData data) {
    final providerUser = PhonePasswordUser(
      phone: data.identifier,
      passwordHash: data.passwordHash,
    );
    return AuthUser(
      providerId: data.providerId,
      providerUserId: data.identifier,
      emailIsVerified: false,
      phoneIsVerified: true,
      rawUserData: providerUser.toJson(),
      providerUser: providerUser,
      phone: data.identifier,
      name: data.name,
    );
  }
}

abstract class IdentifierPasswordUser implements SerializableToJson {
  /// The password hash to be saved so we can validate the password
  /// on future sign in attempts.
  /// May be null if the provider does not use passwords.
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
