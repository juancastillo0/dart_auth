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
    obscureText: true,
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

  @override
  Future<ResponseContinueFlow?> mfaCredentialsFlow(
    ProviderUserId mfaItem,
  ) async {
    return ResponseContinueFlow(
      state: null,
      userMessage: 'Input the username and password.',
      // TODO: should we ask for the username? if we should then do not sent it to the client
      paramDescriptions: paramDescriptions,
    );
  }

  @override
  ResponseContinueFlow? updateCredentialsParams(UsernamePasswordUser user) {
    return ResponseContinueFlow(
      state: null,
      // TODO: null user message
      userMessage: '',
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

  /// Parses the [userData] JSON and returns the generic [AuthUser] model.
  AuthUser<U> parseUser(Map<String, Object?> userData);
}

abstract class CredentialsProvider<C extends CredentialsData, U>
    implements AuthenticationProvider<U> {
  /// The unique global provider identifier
  @override
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
  final String? redirectUrl;
  final String? qrUrl;
  final String? userMessage;
  final String? buttonText;
  final String? state;
  final Map<String, ParamDescription>? paramDescriptions;

  ///
  ResponseContinueFlow({
    required this.state,
    required String this.userMessage,
    this.redirectUrl,
    this.qrUrl,
    this.paramDescriptions,
    this.buttonText,
  });

  factory ResponseContinueFlow.fromJson(Map<String, Object?> json) {
    return ResponseContinueFlow(
      state: json['state'] as String?,
      userMessage: json['userMessage']! as String,
      redirectUrl: json['redirectUrl'] as String?,
      qrUrl: json['qrUrl'] as String?,
      buttonText: json['buttonText'] as String?,
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
  final String name;
  final String? description;
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

  FormatException? validate(String value) {
    if (regExp != null && !regExp!.hasMatch(value)) {
      return FormatException(
        '$name does not match ${description ?? 'validation'}'
        ' (${regExp!.pattern}).',
      );
    }
    return null;
  }

  ParamDescription copyWith({
    String? name,
    String? description,
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
