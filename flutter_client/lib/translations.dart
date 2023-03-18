class Translations {
  ///
  const Translations();

  /// The default english translations
  static const defaultEnglish = Translations();

  /// The default spanish translations
  static const defaultSpanish = SpanishTranslations();

  String get languageCode => 'en';
  String? get countryCode => null;
  String get localeName => 'English';

  String get close => 'Close';
  String get settings => 'Settings';

  // Credentials

  /// Translation for 'Update'
  String get update => 'Update';

  /// Translation for 'Cancel'
  String get cancel => 'Cancel';

  /// Translation for 'Submit'
  String get submit => 'Submit';

  // Auth Widgets

  /// Translation for 'Sign Up with Device'
  String get signUpWithDevice => 'Sign Up with Device'; // TODO: providerId
  /// Translation for 'Sign Up'
  String get sigUpWithOAuth => 'Sign Up'; // TODO: providerId
  /// Translation for 'Enter the code in the url to authorize this device.'
  String get enterDeviceCode =>
      'Enter the code in the url to authorize this device.';

  /// Translation for 'Add'
  String get add => 'Add';

  /// Translation for 'Multi-Factor Authentication (MFA)'
  String get multiFactorAuthentication => 'Multi-Factor Authentication (MFA)';

  /// Translation for 'Add Multi-Factor Authentication'
  String get addMultiFactorAuthentication => 'Add Multi-Factor Authentication';

  // User Info Widget

  /// Translation for 'Sign Out'
  String get signOut => 'Sign Out';

  /// Translation for 'Authentication Providers'
  String get authenticationProviders => 'Authentication Providers';

  /// Translation for 'Required Providers'
  String get requiredProviders => 'Required Providers';

  /// Translation for 'No required providers'
  String get noRequiredProviders => 'No required providers';

  /// Translation for 'Optional Providers'
  String get optionalProviders => 'Optional Providers';

  /// Translation for 'No optional providers'
  String get noOptionalProviders => 'No optional providers';

  /// Translation for 'Optional Amount'
  String get optionalAmount => 'Optional Amount';

  /// Translation for 'Edit MFA'
  String get editMFA => 'Edit MFA';

  /// Translation for 'Revert MFA'
  String get revertMFA => 'Revert MFA';

  /// Translation for 'Submit MFA Update'
  String get submitMFAUpdate => 'Submit MFA Update';

  /// Translation for 'Edit'
  String get edit => 'Edit';

  /// Translation for 'Are you sure you want to delete
  /// the authentication provider?'
  String get deleteAuthenticationProviderConfirmation =>
      'Are you sure you want to delete the authentication provider?';

  /// Translation for 'Delete'
  String get delete => 'Delete';

  // Profile

  /// Translation for 'Identifier'
  String get identifier => 'Identifier';

  /// Translation for 'Name'
  String get name => 'Name';

  /// Translation for 'Email'
  String get email => 'Email';

  /// Translation for 'verified'
  String get verified => 'verified';

  /// Translation for 'not verified'
  String get notVerified => 'not verified';

  /// Translation for 'Phone'
  String get phone => 'Phone';
}

class SpanishTranslations implements Translations {
  ///
  const SpanishTranslations();

  String get languageCode => 'es';
  String? get countryCode => null;
  String get localeName => 'Español';

  String get close => 'Cerrar';
  String get settings => 'Configuración';

  /// Credentials
  @override
  String get update => 'Actualizar';
  @override
  String get cancel => 'Cancelar';
  @override
  String get submit => 'Continuar';

  /// Auth Widgets
  @override
  String get signUpWithDevice =>
      'Registrarme con Dispositivo'; // TODO: providerId
  @override
  String get sigUpWithOAuth => 'Registrarme'; // TODO: providerId
  @override
  String get enterDeviceCode =>
      'Ingresa el código en la página pra autorizar este dispositivo.';
  @override
  String get add => 'Añadir';
  @override
  String get multiFactorAuthentication =>
      'Autenticación de Múltiples Pasos (MFA)';
  @override
  String get addMultiFactorAuthentication =>
      'Añadir Autenticación de Múltiples Pasos';

  /// User Info Widget

  @override
  String get signOut => 'Cerrar Sesión';
  @override
  String get authenticationProviders => 'Proveedores de Autenticación';
  @override
  String get requiredProviders => 'Proveedores Requeridos';
  @override
  String get noRequiredProviders => 'No tienes proveedores requeridos';
  @override
  String get optionalProviders => 'Proveedores Opcionales';
  @override
  String get noOptionalProviders => 'No tienes proveedores opcionales';
  @override
  String get optionalAmount => 'Cantidad Opcional';
  @override
  String get editMFA => 'Editar MFA';
  @override
  String get revertMFA => 'Revertir MFA';
  @override
  String get submitMFAUpdate => 'Enviar cambios MFA';
  @override
  String get edit => 'Editar';
  @override
  String get deleteAuthenticationProviderConfirmation =>
      '¿Estás seguro que deseas eliminar el proveedor de autenticación?';
  @override
  String get delete => 'Eliminar';

  ///

  @override
  String get identifier => 'Identificador';
  @override
  String get name => 'Nombre';
  @override
  String get email => 'Email';
  @override
  String get verified => 'verificado';
  @override
  String get notVerified => 'no verificado';
  @override
  String get phone => 'Teléfono';
}
