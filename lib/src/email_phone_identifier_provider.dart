import 'dart:math';

import 'package:oauth/flow.dart';
import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth/src/backend_translation.dart';
import 'package:oauth/src/password.dart';

class MagicCodeConfig<U> {
  ///
  MagicCodeConfig({
    required this.onlyMagicCodeNoPassword,
    required this.sendMagicCode,
    required this.persistence,
    this.userMessage = const Translation(key: Translations.magicCodeSentKey),
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
        name: const Translation(key: Translations.magicCodeNameKey),
        description:
            const Translation(key: Translations.magicCodeDescriptionKey),
        regExp: RegExp('^[${RegExp.escape(alphabet)}]{${count}}\$'),
        keyboardType: RegExp(r'^[0-9]+$').hasMatch(alphabet)
            ? ParamKeyboardType.number
            : ParamKeyboardType.text,
      ),
    );
  }

  final Translation userMessage;
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

class IdentifierPasswordProvider<U extends IdentifierPasswordUser<U>>
    extends CredentialsProvider<IdentifierPassword, U> {
  ///
  IdentifierPasswordProvider({
    required this.identifierName,
    required this.identifierDescription,
    required this.providerId,
    required this.providerName,
    required this.makeUser,
    required this.userFromJson,
    required this.magicCodeConfig,
    ParamDescription? passwordDescription,
    this.redirectUrl,
    this.useIsolateForHashing = true,
    this.normalizeIdentifier,
    this.withName = true,
  }) : passwordDescription = passwordDescription ??
            UsernamePasswordProvider.defaultPasswordDescription;

  /// Email authentication provider with password or [magicCodeConfig].
  static IdentifierPasswordProvider<EmailPasswordUser> email({
    required MagicCodeConfig<EmailPasswordUser> magicCodeConfig,
    String providerId = ImplementedProviders.email,
    MakeUserFromIdentifier<EmailPasswordUser> makeUser =
        EmailPasswordUser.makeUser,
    ParamDescription? emailDescription,
    ParamDescription? passwordDescription,
    String? redirectUrl,
    bool useIsolateForHashing = true,
    String Function(String)? normalizeEmail = defaultNormalizeEmail,
    bool withName = true,
    Translation providerName = const Translation(
      key: Translations.emailProviderNameKey,
    ),
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
      normalizeIdentifier: normalizeEmail,
      userFromJson: EmailPasswordUser.fromJson,
      withName: withName,
      providerName: providerName,
    );
  }

  /// The default identifier parameter description
  /// used in [IdentifierPasswordProvider.email]
  static final defaultEmailDescription = ParamDescription(
    name: const Translation(key: Translations.emailNameKey),
    description: const Translation(key: Translations.emailDescriptionKey),
    regExp: RegExp('@'),
    keyboardType: ParamKeyboardType.emailAddress,
  );

  /// Normalizes an [email] address.
  /// Default used in [IdentifierPasswordProvider.email]
  static String defaultNormalizeEmail(String email) {
    final split = email.toLowerCase().replaceAll(RegExp(r'\s'), '').split('@');
    final domain = split.last.split(',').first;
    return '${split.first}@${domain}';
  }

  /// Phone authentication provider with password or [magicCodeConfig].
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
    bool withName = true,
    Translation providerName = const Translation(
      key: Translations.phoneProviderNameKey,
    ),
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
      userFromJson: PhonePasswordUser.fromJson,
      withName: withName,
      providerName: providerName,
    );
  }

  /// The default identifier parameter description
  /// used in [IdentifierPasswordProvider.phone]
  static final defaultPhoneDescription = ParamDescription(
    name: const Translation(key: Translations.phoneNameKey),
    description: const Translation(key: Translations.phoneDescriptionKey),
    regExp: RegExp(r'^[0-9]{7,}$'),
    keyboardType: ParamKeyboardType.phone,
  );

  @override
  final String providerId;
  @override
  final Translation providerName;

  /// The identifier field key
  final String identifierName;

  /// The description for the identifier field
  final ParamDescription identifierDescription;

  /// The description for the password field
  final ParamDescription passwordDescription;
  final String? redirectUrl;

  /// Whether to use isolate for password hashing
  final bool useIsolateForHashing;

  /// Creates an user model from [UserIdentifierData]
  final MakeUserFromIdentifier<U> makeUser;

  /// Parser [U] from a json [Map]
  final U Function(Map<String, Object?> json) userFromJson;

  /// If you are using a magic code sent to a device or server
  /// (phone or email, for example), this will be the configuration.
  final MagicCodeConfig<U>? magicCodeConfig;

  /// Maps an identifier string to a normalized string.
  /// For example: lowercasing emails.
  final String Function(String)? normalizeIdentifier;

  /// Whether to use name as a parameter to signing up
  final bool withName;

  bool get onlyMagicCodeNoPassword =>
      magicCodeConfig?.onlyMagicCodeNoPassword ?? false;

  @override
  Map<String, ParamDescription> get paramDescriptions {
    return {
      identifierName: identifierDescription,
      if (!onlyMagicCodeNoPassword) 'password': passwordDescription,
      // TODO: make it required?
      if (withName)
        'name': ParamDescription(
          name: const Translation(key: Translations.nameNameKey),
          description: null,
          regExp: null,
          keyboardType: ParamKeyboardType.name,
          textCapitalization: ParamTextCapitalization.words,
        ),
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
          ResponseContinueFlow(
            userMessage: ml!.userMessage,
            redirectUrl: redirectUrl,
            state: state!,
            paramDescriptions: {
              'magicCode': magicCode!.paramDescription,
            },
          ),
        ),
      );
    }
    final authUser = makeUser(
      UserIdentifierData(
        identifier: credentials.identifier,
        passwordHash: passwordHash,
        providerId: providerId,
        name: name,
      ),
    );
    return Ok(
      CredentialsResponse.authenticated(
        authUser.toAuthUser(providerId: providerId),
        redirectUrl: redirectUrl,
      ),
    );
  }

  @override
  Result<IdentifierPassword, Map<String, Translation>> parseCredentials(
    Map<String, Object?> json,
  ) {
    final password = json['password'];
    final identifier = json[identifierName] ?? json['providerUserId'];
    final magicCode = json['magicCode'];
    final state = json['state'];
    final name = json['name'];
    if ((password is! String?) ||
        (identifier is! String?) ||
        (magicCode is! String?) ||
        (state is! String?) ||
        (name is! String?)) {
      return Err(
        Map.fromEntries(
          [
            if (identifier is! String?) 'identifier',
            if (password is! String?) 'password',
            if (magicCode is! String?) 'magicCode',
            if (state is! String?) 'state',
            if (name is! String?) 'name',
          ].map(
            (e) => MapEntry(
              e,
              Translation(
                key: Translations.requiredStringArgumentKey,
                args: {'name': e},
              ),
            ),
          ),
        ),
      );
    }

    // onlyMagicCodeNoPassword -> identifier -> magicCode
    // magicCode & password -> identifier & password -> magicCode
    // password -> identifier & password
    if ((magicCodeConfig == null && password == null) ||
        identifier is! String) {
      return Err({
        if (identifier is! String)
          identifierName: Translation(
            key: Translations.requiredArgumentKey,
            args: {'name': identifierName},
          ),
        if (password is! String)
          'password': const Translation(
            key: Translations.requiredArgumentKey,
            args: {'name': 'password'},
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
  Future<ResponseContinueFlow?> mfaCredentialsFlow(
      ProviderUserId mfaItem) async {
    return ResponseContinueFlow(
      state: null,
      userMessage: magicCodeConfig != null
          ? const Translation(key: Translations.magiCodeHelperTextKey)
          : const Translation(key: Translations.passwordHelperTextKey),
      paramDescriptions: {
        identifierName: identifierDescription,
        if (!onlyMagicCodeNoPassword) 'password': passwordDescription,
      },
    );
  }

  @override
  Future<Result<CredentialsResponse<U>, AuthError>> updateCredentials(
    U user,
    IdentifierPassword credentials,
  ) {
    // TODO should we do more?
    return getUser(credentials);
  }

  @override
  ResponseContinueFlow? updateCredentialsParams(U user) {
    return ResponseContinueFlow(
      state: null,
      userMessage: Translation.empty,
      paramDescriptions: {
        identifierName: identifierDescription.copyWith(
          initialValue: user.identifier,
        ),
        // TODO: test empty password
        if (!onlyMagicCodeNoPassword) 'password': passwordDescription,
        // TODO: Name param
      },
    );
  }

  @override
  AuthUser<U> parseUser(Map<String, Object?> userData) {
    final providerUser = userFromJson(userData);
    return providerUser.toAuthUser(providerId: providerId);
  }
}

///
typedef MakeUserFromIdentifier<U> = U Function(UserIdentifierData data);

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

class EmailPasswordUser
    implements IdentifierPasswordUser<EmailPasswordUser>, SerializableToJson {
  final String email;
  @override
  final String? passwordHash;
  final String? name;
  @override
  String get identifier => email;

  ///
  EmailPasswordUser({
    required this.email,
    required this.passwordHash,
    required this.name,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'email': email,
      'passwordHash': passwordHash,
      'name': name,
    }..removeWhere((key, value) => value == null);
  }

  factory EmailPasswordUser.fromJson(Map<String, Object?> json) {
    return EmailPasswordUser(
      name: json['name'] as String?,
      email: json['email']! as String,
      passwordHash: json['passwordHash'] as String?,
    );
  }

  AuthUser<EmailPasswordUser> toAuthUser({
    required String providerId,
  }) {
    return AuthUser(
      providerId: providerId,
      providerUserId: email,
      emailIsVerified: true,
      phoneIsVerified: false,
      rawUserData: toJson(),
      providerUser: this,
      email: email,
      name: name,
    );
  }

  static EmailPasswordUser makeUser(UserIdentifierData data) {
    return EmailPasswordUser(
      email: data.identifier,
      passwordHash: data.passwordHash,
      name: data.name,
    );
  }
}

class PhonePasswordUser implements IdentifierPasswordUser<PhonePasswordUser> {
  final String phone;
  @override
  final String? passwordHash;
  final String? name;

  @override
  String get identifier => phone;

  ///
  PhonePasswordUser({
    required this.phone,
    required this.passwordHash,
    required this.name,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'phone': phone,
      'passwordHash': passwordHash,
      'name': name,
    }..removeWhere((key, value) => value == null);
  }

  factory PhonePasswordUser.fromJson(Map<String, Object?> json) {
    return PhonePasswordUser(
      phone: json['phone']! as String,
      passwordHash: json['passwordHash'] as String?,
      name: json['name'] as String?,
    );
  }

  static PhonePasswordUser makeUser(UserIdentifierData data) {
    return PhonePasswordUser(
      phone: data.identifier,
      passwordHash: data.passwordHash,
      name: data.name,
    );
  }

  @override
  AuthUser<PhonePasswordUser> toAuthUser({required String providerId}) {
    return AuthUser(
      providerId: providerId,
      providerUserId: phone,
      emailIsVerified: false,
      phoneIsVerified: true,
      rawUserData: toJson(),
      providerUser: this,
      phone: phone,
      name: name,
    );
  }
}

abstract class IdentifierPasswordUser<U> implements SerializableToJson {
  /// The password hash to be saved so we can validate the password
  /// on future sign in attempts.
  /// May be null if the provider does not use passwords.
  String? get passwordHash;

  /// The identifier for this user
  String get identifier;

  /// Returns the user account
  AuthUser<U> toAuthUser({
    required String providerId,
  });
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
