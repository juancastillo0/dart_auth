import 'dart:convert' show jsonEncode;

import '../oauth.dart';

class Translations {
  ///
  const Translations();

  String get languageCode => 'en';

  static const defaultEnglish = Translations();
  static const defaultSpanish = SpanishTranslations();

  /// EMAIL - PHONE - IDENTIFIER
  ///

  /// Translation for 'A code has been sent'
  String get magicCodeSent => 'A code has been sent';

  /// Translation for 'Code'
  String get magicCodeName => 'Code';

  /// Translation for 'The code sent to your device'
  String get magicCodeDescription => 'The code sent to your device';

  /// Translation for 'Email'
  String get emailName => 'Email';

  /// Translation for 'The email address. This will be your
  /// identifier to sign in.'
  String get emailDescription =>
      'The email address. This will be your identifier to sign in.';

  /// Translation for 'Phone
  String get phoneName => 'Phone';

  /// Translation for 'The phone number. This will be your
  /// identifier to sign in.'
  String get phoneDescription =>
      'The phone number. This will be your identifier to sign in.';

  /// Translation for '$name should be a String.'
  String requiredStringArgument({required String name}) =>
      '$name should be a String.';

  /// Translation for '$name is required.'
  String requiredArgument({required String name}) =>
      '$name is required.'; // TODO: proper "a" vs "an"
  /// Translation for 'A magic code will be sent to the device
  String get magiCodeHelperText => 'A magic code will be sent to the device';

  /// Translation for 'Input the credentials'
  String get passwordHelperText => 'Input the credentials';

  /// Translation for 'Name'
  String get nameName => 'Name';

  /// Translation for '$name does not match:
  /// ${description == null ? '' : '$description '} (${pattern}).'
  String validationError({
    required String name,
    required String? description,
    required String pattern,
  }) =>
      '$name does not match: ${description == null ? '' : '$description '}'
      '(${pattern}).';

  // TOTP
  //

  /// Translation for 'One Time Password Code'
  String get totpName => 'One Time Password Code';

  /// Translation for 'The code presented in your authenticator app.'
  String get totpDescription => 'The code presented in your authenticator app.';

  /// Translation for 'Use the an authenticator application that supports'
  /// ' Time-Base One-Time Passwords (TOTP) such as'
  /// ' Google Authenticator, Twilio Authy or Microsoft Authenticator.'
  /// ' Setup key: "$base32Secret".'
  String totpCreateFlow({required String base32Secret}) =>
      'Use the an authenticator application that supports'
      ' Time-Base One-Time Passwords (TOTP) such as'
      ' Google Authenticator, Twilio Authy or Microsoft Authenticator.'
      ' Setup key: "$base32Secret".';

  /// Translation for 'Input the TOTP code shown in your authenticator
  /// app for the account "$providerUserId".'
  String totpAuthenticateFlow({required String providerUserId}) =>
      'Input the TOTP code shown in your authenticator app'
      ' for the account "$providerUserId".';

  // USERNAME
  //

  /// Translation for 'Username'
  String get usernameName => 'Username';

  /// Translation for 'Alphanumeric username with at least 3 characters.
  /// This will be your identifier to sign in.'
  String get usernameDescription =>
      'Alphanumeric username with at least 3 characters.'
      ' This will be your identifier to sign in.';

  /// Translation for 'Password'
  String get passwordName => 'Password';

  /// Translation for 'Should be at least 8 characters.'
  String get passwordDescription => 'Should be at least 8 characters.';

  /// Translation for 'Input the username and password.'
  String get usernamePasswordFlowMessage => 'Input the username and password.';

  /// ERRORS
  ///

  /// Translation for 'Bad request'
  String get noState => 'Bad request';

  /// Translation for 'Password is required'
  String get noPassword => 'Password is required';

  /// Translation for 'Bad request'
  String get invalidState => 'Bad request';

  /// Translation for 'Invalid credentials'
  String get invalidPassword => 'Invalid credentials';

  /// Translation for 'Unauthorized, wrong code'
  String get invalidCode => 'Unauthorized, wrong code';

  /// Translation for 'Unauthorized, wrong identifier'
  String get invalidIdentifier => 'Unauthorized, wrong identifier';

  // 'Could not verify the idToken'
  // 'Could not validate the idToken claims'

  /// Translation for 'Provider id not found.'
  String get providerNotFound => 'Provider id not found.';
  // '"${config.allProviders.keys.followedBy(config.allCredentialsProviders.keys).join('", "')}"'
  /// Translation for 'Session revoked'
  String get sessionRevoked => 'Session revoked';

  /// Translation for 'Multiple users with same credentials'
  String get multipleUsersWithSameCredentials =>
      'Multiple users with same credentials';

  /// Translation for 'Provider does not support implicit flow.'
  String get providerDoesNotSupportImplicitFlow =>
      'Provider does not support implicit flow.';

  /// Translation for 'Provider does not support device code flow.'
  String get providerDoesNotSupportDeviceFlow =>
      'Provider does not support device code flow.';

  /// Translation for 'Error retrieving user information'
  String get errorRetrievingUserInfo => 'Error retrieving user information';

  /// Translation for 'Error polling device code authentication status.'
  String get errorPollingDeviceCode =>
      'Error polling device code authentication status.';

  /// Translation for 'Wrong access token'
  String get wrongAccessToken => 'Wrong access token';

  /// Translation for 'Unauthorized'
  String get unauthorized => 'Unauthorized';

  /// Translation for 'Timeout'
  String get timeout => 'Timeout';

  /// Translation for 'notFoundMethods'
  String get notFoundMethods => 'notFoundMethods';

  /// Translation for 'Can not have a single MFA provider.'
  String get canNotHaveSingleMFAProvider =>
      'Can not have a single MFA provider.';

  /// Translation for 'No authentication provider found.'
  String get authProviderNotFoundToDelete =>
      'No authentication provider found.';

  /// Translation for 'Can not delete the only authentication provider.'
  String get canNotDeleteOnlyProvider =>
      'Can not delete the only authentication provider.';

  /// Translation for 'Can not delete an authentication provider used in MFA.'
  String get canNotDeleteMFAProvider =>
      'Can not delete an authentication provider used in MFA.';

  /// Translation for 'providerUserId is required.'
  String get providerUserIdIsRequired => 'providerUserId is required.';

  /// Translation for 'Duplicate User.'
  String get duplicateUser => 'Duplicate user.';

  /// Translation for 'User not found.'
  String get userNotFound => 'User not found.';

  /// Translation for 'Field input errors.'
  String get fieldErrors => 'Field input errors.';

  /// Translation for 'Session expired.'
  String get sessionExpired => 'Session expired.';

  /// Translation for 'Can not sign up in a MFA flow'
  String get canNotSignUpInMFAFlow => 'Can not sign up in a MFA flow';

  /// Translation for 'Wrong parameters for MFA'
  String get wrongParametersForMFA => 'Wrong parameters for MFA';

  /// Translation for 'Error merging users.'
  String get errorMergingUsers => 'Error merging users.';

  /// Translation for 'Credentials not found.'
  String get credentialsNotFound => 'Credentials not found.';

  // KEYS
  //

  static const magicCodeSentKey = 'magicCodeSent';
  static const magicCodeNameKey = 'magicCodeName';
  static const magicCodeDescriptionKey = 'magicCodeDescription';
  static const emailNameKey = 'emailName';
  static const emailDescriptionKey = 'emailDescription';
  static const phoneNameKey = 'phoneName';
  static const phoneDescriptionKey = 'phoneDescription';
  static const requiredStringArgumentKey = 'requiredStringArgument';
  static const requiredArgumentKey = 'requiredArgument';
  static const magiCodeHelperTextKey = 'magiCodeHelperText';
  static const passwordHelperTextKey = 'passwordHelperText';
  static const nameNameKey = 'nameName';
  static const validationErrorKey = 'validationError';
  static const totpNameKey = 'totpName';
  static const totpDescriptionKey = 'totpDescription';
  static const totpCreateFlowKey = 'totpCreateFlow';
  static const totpAuthenticateFlowKey = 'totpAuthenticateFlow';
  static const usernameNameKey = 'usernameName';
  static const usernameDescriptionKey = 'usernameDescription';
  static const passwordNameKey = 'passwordName';
  static const passwordDescriptionKey = 'passwordDescription';
  static const usernamePasswordFlowMessageKey = 'usernamePasswordFlowMessage';
  static const noStateKey = 'noState';
  static const noPasswordKey = 'noPassword';
  static const invalidStateKey = 'invalidState';
  static const invalidPasswordKey = 'invalidPassword';
  static const invalidCodeKey = 'invalidCode';
  static const invalidIdentifierKey = 'invalidIdentifier';
  static const providerNotFoundKey = 'providerNotFound';
  static const sessionRevokedKey = 'sessionRevoked';
  static const multipleUsersWithSameCredentialsKey =
      'multipleUsersWithSameCredentials';
  static const providerDoesNotSupportImplicitFlowKey =
      'providerDoesNotSupportImplicitFlow';
  static const providerDoesNotSupportDeviceFlowKey =
      'providerDoesNotSupportDeviceFlow';
  static const errorRetrievingUserInfoKey = 'errorRetrievingUserInfo';
  static const errorPollingDeviceCodeKey = 'errorPollingDeviceCode';
  static const wrongAccessTokenKey = 'wrongAccessToken';
  static const unauthorizedKey = 'unauthorized';
  static const timeoutKey = 'timeout';
  static const notFoundMethodsKey = 'notFoundMethods';
  static const canNotHaveSingleMFAProviderKey = 'canNotHaveSingleMFAProvider';
  static const authProviderNotFoundToDeleteKey = 'authProviderNotFoundToDelete';
  static const canNotDeleteOnlyProviderKey = 'canNotDeleteOnlyProvider';
  static const canNotDeleteMFAProviderKey = 'canNotDeleteMFAProvider';
  static const providerUserIdIsRequiredKey = 'providerUserIdIsRequired';
  static const duplicateUserKey = 'duplicateUser';
  static const userNotFoundKey = 'userNotFound';
  static const fieldErrorsKey = 'fieldErrors';
  static const sessionExpiredKey = 'sessionExpired';
  static const canNotSignUpInMFAFlowKey = 'canNotSignUpInMFAFlow';
  static const wrongParametersForMFAKey = 'wrongParametersForMFA';
  static const errorMergingUsersKey = 'errorMergingUsers';
  static const credentialsNotFoundKey = 'credentialsNotFound';

  static const allKeys = {
    magicCodeSentKey,
    magicCodeNameKey,
    magicCodeDescriptionKey,
    emailNameKey,
    emailDescriptionKey,
    phoneNameKey,
    phoneDescriptionKey,
    requiredStringArgumentKey,
    requiredArgumentKey,
    magiCodeHelperTextKey,
    passwordHelperTextKey,
    nameNameKey,
    validationErrorKey,
    totpNameKey,
    totpDescriptionKey,
    totpCreateFlowKey,
    totpAuthenticateFlowKey,
    usernameNameKey,
    usernameDescriptionKey,
    passwordNameKey,
    passwordDescriptionKey,
    usernamePasswordFlowMessageKey,
    noStateKey,
    noPasswordKey,
    invalidStateKey,
    invalidPasswordKey,
    invalidCodeKey,
    invalidIdentifierKey,
    providerNotFoundKey,
    sessionRevokedKey,
    multipleUsersWithSameCredentialsKey,
    providerDoesNotSupportImplicitFlowKey,
    providerDoesNotSupportDeviceFlowKey,
    errorRetrievingUserInfoKey,
    errorPollingDeviceCodeKey,
    wrongAccessTokenKey,
    unauthorizedKey,
    timeoutKey,
    notFoundMethodsKey,
    canNotHaveSingleMFAProviderKey,
    authProviderNotFoundToDeleteKey,
    canNotDeleteOnlyProviderKey,
    canNotDeleteMFAProviderKey,
    providerUserIdIsRequiredKey,
    duplicateUserKey,
    userNotFoundKey,
    fieldErrorsKey,
    sessionExpiredKey,
    canNotSignUpInMFAFlowKey,
    wrongParametersForMFAKey,
    errorMergingUsersKey,
    credentialsNotFoundKey,
  };

  static Object? getValue(Translations t, String key) {
    switch (key) {
      case magicCodeSentKey:
        return t.magicCodeSent;
      case magicCodeNameKey:
        return t.magicCodeName;
      case magicCodeDescriptionKey:
        return t.magicCodeDescription;
      case emailNameKey:
        return t.emailName;
      case emailDescriptionKey:
        return t.emailDescription;
      case phoneNameKey:
        return t.phoneName;
      case phoneDescriptionKey:
        return t.phoneDescription;
      case requiredStringArgumentKey:
        return t.requiredStringArgument;
      case requiredArgumentKey:
        return t.requiredArgument;
      case magiCodeHelperTextKey:
        return t.magiCodeHelperText;
      case passwordHelperTextKey:
        return t.passwordHelperText;
      case nameNameKey:
        return t.nameName;
      case validationErrorKey:
        return t.validationError;
      case totpNameKey:
        return t.totpName;
      case totpDescriptionKey:
        return t.totpDescription;
      case totpCreateFlowKey:
        return t.totpCreateFlow;
      case totpAuthenticateFlowKey:
        return t.totpAuthenticateFlow;
      case usernameNameKey:
        return t.usernameName;
      case usernameDescriptionKey:
        return t.usernameDescription;
      case passwordNameKey:
        return t.passwordName;
      case passwordDescriptionKey:
        return t.passwordDescription;
      case usernamePasswordFlowMessageKey:
        return t.usernamePasswordFlowMessage;
      case noStateKey:
        return t.noState;
      case noPasswordKey:
        return t.noPassword;
      case invalidStateKey:
        return t.invalidState;
      case invalidPasswordKey:
        return t.invalidPassword;
      case invalidCodeKey:
        return t.invalidCode;
      case invalidIdentifierKey:
        return t.invalidIdentifier;
      case providerNotFoundKey:
        return t.providerNotFound;
      case sessionRevokedKey:
        return t.sessionRevoked;
      case multipleUsersWithSameCredentialsKey:
        return t.multipleUsersWithSameCredentials;
      case providerDoesNotSupportImplicitFlowKey:
        return t.providerDoesNotSupportImplicitFlow;
      case providerDoesNotSupportDeviceFlowKey:
        return t.providerDoesNotSupportDeviceFlow;
      case errorRetrievingUserInfoKey:
        return t.errorRetrievingUserInfo;
      case errorPollingDeviceCodeKey:
        return t.errorPollingDeviceCode;
      case wrongAccessTokenKey:
        return t.wrongAccessToken;
      case unauthorizedKey:
        return t.unauthorized;
      case timeoutKey:
        return t.timeout;
      case notFoundMethodsKey:
        return t.notFoundMethods;
      case canNotHaveSingleMFAProviderKey:
        return t.canNotHaveSingleMFAProvider;
      case authProviderNotFoundToDeleteKey:
        return t.authProviderNotFoundToDelete;
      case canNotDeleteOnlyProviderKey:
        return t.canNotDeleteOnlyProvider;
      case canNotDeleteMFAProviderKey:
        return t.canNotDeleteMFAProvider;
      case providerUserIdIsRequiredKey:
        return t.providerUserIdIsRequired;
      case duplicateUserKey:
        return t.duplicateUser;
      case userNotFoundKey:
        return t.userNotFound;
      case fieldErrorsKey:
        return t.fieldErrors;
      case sessionExpiredKey:
        return t.sessionExpired;
      case canNotSignUpInMFAFlowKey:
        return t.canNotSignUpInMFAFlow;
      case wrongParametersForMFAKey:
        return t.wrongParametersForMFA;
      case errorMergingUsersKey:
        return t.errorMergingUsers;
      case credentialsNotFoundKey:
        return t.credentialsNotFound;
    }
    return null;
  }
}

abstract class TranslationSerializableToJson implements SerializableToJson {
  @override
  Map<String, Object?> toJson({
    Translations translations = Translations.defaultEnglish,
  });
}

// ignore: avoid_dynamic_calls
dynamic _defaultToEncodable(dynamic object) => object.toJson();

String jsonEncodeWithTranslate(
  SerializableToJson value,
  Translations translations,
) {
  return jsonEncode(
    value,
    toEncodable: (nonEncodable) {
      if (nonEncodable is TranslationSerializableToJson) {
        return nonEncodable.toJson(translations: translations);
      }
      return _defaultToEncodable(nonEncodable);
    },
  );
}

class Translation implements TranslationSerializableToJson {
  final String key;
  final String? msg;
  final Map<String, Object?>? args;

  ///
  const Translation({
    required this.key,
    this.msg,
    this.args,
  });

  static const empty = Translation(key: '');

  factory Translation.fromJson(Object? json) {
    if (json is String) {
      return Translation(key: json);
    } else if (json is! Map) {
      throw FormatException(
        'TranslationValue.fromJson should be a Map or a String key.',
        json,
      );
    }
    return Translation(
      key: json['key']! as String,
      args: json['args'] as Map<String, Object?>?,
      msg: json['msg'] as String?,
    );
  }

  String getMessage(Translations translations) {
    final value = Translations.getValue(translations, key);
    if (value == null) {
      return msg ?? key;
    } else if (value is Function) {
      return Function.apply(
        value,
        null,
        args?.map((key, value) => MapEntry(Symbol(key), value)),
      ) as String;
    } else {
      return value as String;
    }
  }

  @override
  Map<String, Object?> toJson({
    Translations translations = Translations.defaultEnglish,
  }) {
    final message = getMessage(translations);
    return {
      'key': key,
      if (message != key) 'msg': getMessage(translations),
      if (msg != null && message != msg) 'defaultMsg': msg,
      if (args != null) 'args': args,
    };
  }

  @override
  String toString() {
    return 'TranslationValue${toJson()}';
  }
}

class SpanishTranslations implements Translations {
  const SpanishTranslations();

  @override
  String get languageCode => 'es';
  @override
  String get authProviderNotFoundToDelete =>
      'No se encontró el proveedor de autenticación.';
  @override
  String get canNotDeleteMFAProvider =>
      'No se puede eliminar un proveedor de autenticación'
      ' usado en autenticación de múltiples pasos.';
  @override
  String get canNotDeleteOnlyProvider =>
      'No se puede eliminar el único proveedor de autenticación.';
  @override
  String get canNotHaveSingleMFAProvider =>
      'No se puede tener un solo proveedor de autenticación'
      ' en autenticación de múltiples pasos.';
  @override
  String get canNotSignUpInMFAFlow =>
      'No se puede registrar en autenticación de múltiples pasos.';
  @override
  String get credentialsNotFound => 'Las credenciales no se encontraron.';
  @override
  String get duplicateUser => 'Usuario duplicado.';
  @override
  String get emailDescription =>
      'El correo electrónico. Será tu identificador para iniciar sesión.';
  @override
  String get emailName => 'Correo Electrónico';
  @override
  String get errorMergingUsers => 'Error uniendo cuentas de usuario.';
  @override
  String get errorPollingDeviceCode =>
      'Error accediendo al estado de autenticación del dispositivo.';
  @override
  String get errorRetrievingUserInfo =>
      'Error al traer la información de usuario.';
  @override
  String get fieldErrors => 'Errores en los parámetros enviados.';
  @override
  String get invalidCode => 'El código no es válido.';
  @override
  String get invalidIdentifier => 'El identificador no es válido.';
  @override
  String get invalidPassword => 'La credenciales no son válidas.';
  @override
  String get invalidState => 'Flujo incorrecto.';
  @override
  String get magiCodeHelperText =>
      'El código de autenticación se enviará a tu dispositivo.';
  @override
  String get magicCodeDescription => 'El código que se envío a tu dispositivo.';
  @override
  String get magicCodeName => 'Código';
  @override
  String get magicCodeSent => 'El código se ha enviado';
  @override
  String get multipleUsersWithSameCredentials =>
      'Varios usuarios tienen las mismas credenciales.';
  @override
  String get nameName => 'Nombre';
  @override
  String get noPassword => 'La contraseña es requerida';
  @override
  String get noState => 'Flujo incorrecto';
  @override
  String get notFoundMethods =>
      'No se encontraron algunos proveedores de autenticación.';
  @override
  String get passwordDescription => 'Debería tener al menos 8 caracteres.';
  @override
  String get passwordHelperText => 'Ingresa las credenciales';
  @override
  String get passwordName => 'Contraseña';
  @override
  String get phoneDescription =>
      'El número móvil. Este será tu identificador para iniciar sesión.';
  @override
  String get phoneName => 'Teléfono Celular';
  @override
  String get providerDoesNotSupportDeviceFlow =>
      'El proveedor no soporte el flujo de dispositivo.';
  @override
  String get providerDoesNotSupportImplicitFlow =>
      'El proveedor no soporta el flujo implícito.';
  @override
  String get providerNotFound => 'El proveedor no se encontró.';
  @override
  String get providerUserIdIsRequired => 'providerUserId es requerido.';
  @override
  String requiredArgument({required String name}) => '$name es requerido';

  @override
  String requiredStringArgument({required String name}) =>
      '$name debería ser una String.';

  @override
  String get sessionExpired => 'La sesión ha expirado.';
  @override
  String get sessionRevoked => 'La sesión ha sido revocada.';
  @override
  String get timeout => 'El tiempo de espera ha terminado.';
  @override
  String totpAuthenticateFlow({required String providerUserId}) =>
      'Ingresa el código TOTP presentado en tu aplicación de'
      ' autenticación para la cuenta "$providerUserId".';

  @override
  String totpCreateFlow({required String base32Secret}) =>
      'Usa la aplicación de autenticación que soporte contraseñas de un solo'
      ' uso basadas en tiempo (TOTP) Como Google Authenticator, Twilio Authy'
      ' o Microsoft Authenticator. Llave: "$base32Secret".';

  @override
  String get totpDescription =>
      'El código presentado en la aplicación de autenticación.';
  @override
  String get totpName => 'Código de Autenticación (TOTP)';
  @override
  String get unauthorized => 'No autorizado';
  @override
  String get userNotFound => 'Usuario no encontrado';
  @override
  String get usernameDescription =>
      'Identificador alpha-numérico de al menos 3 caracteres.'
      ' Este será tu identificador para iniciar sesión.';
  @override
  String get usernameName => 'Identificador de Usuario';
  @override
  String get usernamePasswordFlowMessage =>
      'Ingresa el usuario y la contraseña.';
  @override
  String validationError({
    required String name,
    required String? description,
    required String pattern,
  }) =>
      '$name no es válido: ${description == null ? '' : '$description '}'
      ' (${pattern}).';

  @override
  String get wrongAccessToken => 'Código de acceso inválido';
  @override
  String get wrongParametersForMFA =>
      'Parámetros no válidos para autenticación de múltiples etapas';
}
