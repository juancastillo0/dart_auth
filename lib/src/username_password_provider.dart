import 'package:oauth/oauth.dart';
import 'package:oauth/providers.dart';
import 'package:oauth/src/backend_translation.dart';
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
    this.providerName = const Translation(
      key: Translations.usernameProviderNameKey,
    ),
  })  : usernameDescription = usernameDescription ?? defaultUsernameDescription,
        passwordDescription = passwordDescription ?? defaultPasswordDescription;

  static final defaultUsernameDescription = ParamDescription(
    name: const Translation(key: Translations.usernameNameKey),
    description: const Translation(key: Translations.usernameDescriptionKey),
    regExp: RegExp(r'^[a-zA-Z0-9_-]{3,}$'),
  );
  static final defaultPasswordDescription = ParamDescription(
    name: const Translation(key: Translations.passwordNameKey),
    description: const Translation(key: Translations.passwordDescriptionKey),
    regExp: RegExp(r'[\s\S]{8,}'),
    obscureText: true,
  );

  @override
  final String providerId;
  @override
  final Translation providerName;
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
  Future<Result<CredentialsResponse<UsernamePasswordUser>, AuthError>>
      updateCredentials(
    UsernamePasswordUser user,
    UsernamePassword credentials,
  ) async {
    return getUser(credentials);
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
  Result<UsernamePassword, Map<String, Translation>> parseCredentials(
    Map<String, Object?> json,
  ) {
    final password = json['password'];
    final username = json['username'];
    if (password is! String || username is! String) {
      return Err({
        if (username is! String)
          'username': const Translation(
            key: Translations.requiredArgumentKey,
            args: {'name': 'username'},
          ),
        if (password is! String)
          'password': const Translation(
            key: Translations.requiredArgumentKey,
            args: {'name': 'password'},
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

  @override
  Future<ResponseContinueFlow?> mfaCredentialsFlow(
    ProviderUserId mfaItem,
  ) async {
    return ResponseContinueFlow(
      state: null,
      userMessage: const Translation(
        key: Translations.usernamePasswordFlowMessageKey,
      ),
      // TODO: should we ask for the username? if we should then do not sent it to the client
      paramDescriptions: paramDescriptions,
    );
  }

  @override
  ResponseContinueFlow? updateCredentialsParams(UsernamePasswordUser user) {
    return ResponseContinueFlow(
      state: null,
      userMessage: Translation.empty,
      paramDescriptions: {
        'username': usernameDescription.copyWith(initialValue: user.username),
        // TODO: test empty password
        'password': passwordDescription,
      },
    );
  }

  @override
  AuthUser<UsernamePasswordUser> parseUser(Map<String, Object?> userData) {
    final providerUser = UsernamePasswordUser.fromJson(userData);
    return AuthUser(
      providerId: providerId,
      providerUserId: providerUser.username,
      emailIsVerified: false,
      phoneIsVerified: false,
      rawUserData: userData,
      providerUser: providerUser,
    );
  }
}

class UsernamePasswordUser implements SerializableToJson {
  final String username;
  final String passwordHash;

  ///
  UsernamePasswordUser({
    required this.username,
    required this.passwordHash,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'username': username,
      'passwordHash': passwordHash,
    };
  }

  factory UsernamePasswordUser.fromJson(Map<String, Object?> userData) {
    return UsernamePasswordUser(
      username: userData['username']! as String,
      passwordHash: userData['passwordHash']! as String,
    );
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

abstract class AuthenticationProvider<U> {
  /// The unique global provider identifier
  String get providerId;

  /// The name of the provider to be presented to the user
  Translation get providerName;

  /// Parses the [userData] JSON and returns the generic [AuthUser] model.
  AuthUser<U> parseUser(Map<String, Object?> userData);

  /// The regular expression the [providerId] must match
  static final providerIdRegExp = RegExp(r'^[a-zA-Z0-9-_]+$');
}

abstract class CredentialsProvider<C extends CredentialsData, U>
    implements AuthenticationProvider<U> {
  /// The unique global provider identifier
  @override
  String get providerId;

  /// The description of the params required for authentication
  Map<String, ParamDescription>? get paramDescriptions;

  /// Parses a [json] Map into the credentials [C] or returns a Map of
  /// [Translation]s for the fields that contain an error.
  Result<C, Map<String, Translation>> parseCredentials(
    Map<String, Object?> json,
  );

  /// Verifies that the [credentials] are associated with the [user].
  /// May return a [CredentialsResponse] without an user if the flow
  /// requires additional verification.
  Future<Result<Option<CredentialsResponse<U>>, AuthError>> verifyCredentials(
    U user,
    C credentials,
  );

  /// The form configuration for the [updateCredentials] flow.
  /// If it is null, then the credentials cant be updated.
  ResponseContinueFlow? updateCredentialsParams(U user);

  /// Updates the credentials for the the [user] with the new values
  /// in [credentials].
  /// May return a [CredentialsResponse] without an user if the flow
  /// requires additional verification.
  Future<Result<CredentialsResponse<U>, AuthError>> updateCredentials(
    U user,
    C credentials,
  );

  /// May return a [CredentialsResponse] without an user if the flow
  /// requires additional verification.
  Future<Result<CredentialsResponse<U>, AuthError>> getUser(C credentials);

  /// Returns the information required to continue a mfa credentials flow.
  /// null if not supported
  Future<ResponseContinueFlow?> mfaCredentialsFlow(ProviderUserId mfaItem);
}

abstract class CredentialsData {
  // TODO: allow for email/phone ids
  String? get providerUserId;
}

class CredentialsResponse<U> {
  final AuthUser<U>? user;
  final String? redirectUrl;
  final ResponseContinueFlow? flow;

  CredentialsResponse.continueFlow(
    ResponseContinueFlow this.flow,
  )   : user = null,
        redirectUrl = flow.redirectUrl;

  CredentialsResponse.authenticated(
    AuthUser<U> this.user, {
    this.redirectUrl,
  }) : flow = null;
}

class ResponseContinueFlow implements SerializableToJson {
  final Translation userMessage;
  final String? redirectUrl;
  final String? qrUrl;
  final Translation? buttonText;
  final String? state;
  final Map<String, ParamDescription>? paramDescriptions;

  ///
  ResponseContinueFlow({
    required this.state,
    required this.userMessage,
    this.redirectUrl,
    this.qrUrl,
    this.paramDescriptions,
    this.buttonText,
  });

  factory ResponseContinueFlow.fromJson(Map<String, Object?> json) {
    return ResponseContinueFlow(
      state: json['state'] as String?,
      userMessage: Translation.fromJson(json['userMessage']),
      redirectUrl: json['redirectUrl'] as String?,
      qrUrl: json['qrUrl'] as String?,
      buttonText: json['buttonText'] == null
          ? null
          : Translation.fromJson(json['buttonText']),
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
        'state': state,
        'userMessage': userMessage,
        'redirectUrl': redirectUrl,
        'qrUrl': qrUrl,
        'buttonText': buttonText,
        'paramDescriptions': paramDescriptions,
      }..removeWhere((key, value) => value == null);
}

enum ParamKeyboardType {
  text,
  multiline,
  number,
  phone,
  datetime,
  emailAddress,
  url,
  visiblePassword,
  name,
  streetAddress,
  none,
}

/// Configures how the platform keyboard will select an uppercase or
/// lowercase keyboard.
///
/// Only supports text keyboards, other keyboard types will ignore this
/// configuration. Capitalization is locale-aware.
enum ParamTextCapitalization {
  /// Defaults to an uppercase keyboard for the first letter of each word.
  ///
  /// Corresponds to `InputType.TYPE_TEXT_FLAG_CAP_WORDS` on Android, and
  /// `UITextAutocapitalizationTypeWords` on iOS.
  words,

  /// Defaults to an uppercase keyboard for the first letter of each sentence.
  ///
  /// Corresponds to `InputType.TYPE_TEXT_FLAG_CAP_SENTENCES` on Android, and
  /// `UITextAutocapitalizationTypeSentences` on iOS.
  sentences,

  /// Defaults to an uppercase keyboard for each character.
  ///
  /// Corresponds to `InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS` on Android, and
  /// `UITextAutocapitalizationTypeAllCharacters` on iOS.
  characters,

  /// Defaults to a lowercase keyboard.
  none,
}

class NumberParamKeyboardType implements SerializableToJson {
  final bool? signed;
  final bool? decimal;

  ///
  const NumberParamKeyboardType({
    this.signed = false,
    this.decimal = false,
  });

  @override
  Map<String, Object?> toJson() {
    return {
      'signed': signed,
      'decimal': decimal,
    };
  }

  factory NumberParamKeyboardType.fromJson(Map<String, Object?> json) {
    return NumberParamKeyboardType(
      signed: json['signed'] as bool?,
      decimal: json['decimal'] as bool?,
    );
  }
}

class ParamDescription implements SerializableToJson {
  final Translation name;
  final Translation? description;
  final RegExp? regExp;
  final bool required;
  final String? initialValue;
  final bool readOnly;
  final Map<String, ParamDescription>? paramsDescriptions;
  final bool obscureText;
  final String? hint;
  final ParamKeyboardType keyboardType;
  final NumberParamKeyboardType? numberKeyboardType;
  final ParamTextCapitalization textCapitalization;
  // TODO: maxLines? maxLenght required/optional

  ///
  ParamDescription({
    required this.name,
    required this.description,
    required this.regExp,
    this.required = false,
    this.initialValue,
    this.readOnly = false,
    this.obscureText = false,
    this.hint,
    this.keyboardType = ParamKeyboardType.text,
    this.numberKeyboardType,
    this.textCapitalization = ParamTextCapitalization.none,
    this.paramsDescriptions,
  });

  factory ParamDescription.fromJson(Map<String, Object?> json) {
    return ParamDescription(
      name: Translation.fromJson(json['name']),
      description: json['description'] == null
          ? null
          : Translation.fromJson(json['description']),
      regExp: json['regExp'] == null ? null : RegExp(json['regExp']! as String),
      paramsDescriptions: json['paramsDescriptions'] == null
          ? null
          : (json['paramsDescriptions']! as Map).map(
              (key, value) => MapEntry(
                key! as String,
                ParamDescription.fromJson((value as Map).cast()),
              ),
            ),
      required: json['required'] as bool? ?? false,
      initialValue: json['initialValue'] as String?,
      readOnly: json['readOnly'] as bool? ?? false,
      obscureText: json['obscureText'] as bool? ?? false,
      hint: json['hint'] as String?,
      keyboardType: json['keyboardType'] == null
          ? ParamKeyboardType.text
          : ParamKeyboardType.values.byName(json['keyboardType']! as String),
      numberKeyboardType: json['numberKeyboardType'] == null
          ? null
          : NumberParamKeyboardType.fromJson(
              json['numberKeyboardType']! as Map<String, Object?>,
            ),
      textCapitalization: json['textCapitalization'] == null
          ? ParamTextCapitalization.none
          : ParamTextCapitalization.values
              .byName(json['textCapitalization']! as String),
    );
  }

  Translation? validate(String value) {
    if (regExp != null && !regExp!.hasMatch(value)) {
      return Translation(
        key: Translations.validationErrorKey,
        args: {
          'name': name,
          'description': description,
          'pattern': regExp!.pattern,
        },
      );
    }
    return null;
  }

  ParamDescription copyWith({
    Translation? name,
    Translation? description,
    bool descriptionToNull = false,
    RegExp? regExp,
    bool regExpToNull = false,
    bool? required,
    String? initialValue,
    bool initialValueToNull = false,
    bool? readOnly,
    Map<String, ParamDescription>? paramsDescriptions,
    bool paramsDescriptionsToNull = false,
    bool? obscureText,
    String? hint,
    bool hintToNull = false,
    ParamKeyboardType? keyboardType,
    NumberParamKeyboardType? numberKeyboardType,
    bool numberKeyboardTypeToNull = false,
    ParamTextCapitalization? textCapitalization,
  }) {
    return ParamDescription(
      name: name ?? this.name,
      description: description ?? (descriptionToNull ? null : this.description),
      regExp: regExp ?? (regExpToNull ? null : this.regExp),
      required: required ?? this.required,
      initialValue:
          initialValue ?? (initialValueToNull ? null : this.initialValue),
      readOnly: readOnly ?? this.readOnly,
      paramsDescriptions: paramsDescriptions ??
          (paramsDescriptionsToNull ? null : this.paramsDescriptions),
      obscureText: obscureText ?? this.obscureText,
      hint: hint ?? (hintToNull ? null : this.hint),
      keyboardType: keyboardType ?? this.keyboardType,
      numberKeyboardType: numberKeyboardType ??
          (numberKeyboardTypeToNull ? null : this.numberKeyboardType),
      textCapitalization: textCapitalization ?? this.textCapitalization,
    );
  }

  @override
  Map<String, Object?> toJson() {
    return {
      'name': name,
      'description': description,
      'regExp': regExp?.pattern,
      'paramsDescriptions': paramsDescriptions,
      'required': required,
      'initialValue': initialValue,
      'readOnly': readOnly,
      'obscureText': obscureText,
      'hint': hint,
      'keyboardType': keyboardType.name,
      'numberKeyboardType': numberKeyboardType,
      'textCapitalization': textCapitalization.name,
    }..removeWhere((key, value) => value == null);
  }
}
