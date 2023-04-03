class FrontEndTranslations {
  ///
  const FrontEndTranslations();

  /// The default english translations
  static const defaultEnglish = FrontEndTranslations();

  /// The default spanish translations
  static const defaultSpanish = SpanishFrontEndTranslations();

  /// The language code in lowercase
  String get languageCode => 'en';

  /// The country code in uppercase
  String? get countryCode => null;

  // Settings

  /// The name used for selecting this translation in the user interface
  String get localeName => 'English';

  /// Translation for 'Close'
  String get close => 'Close';

  /// Translation for 'Settings'
  String get settings => 'Settings';

  /// Translation for 'Admin Dashboard'
  String get adminDashboard => 'Admin Dashboard';

  /// Translation for 'Language'
  String get languageSetting => 'Language';

  /// Translation for 'Brightness'
  String get themeBrightnessSetting => 'Theme Brightness';

  /// Translation for 'Predetermined'
  String get themeBrightnessSystem => 'Predetermined';

  /// Translation for 'Light'
  String get themeBrightnessLight => 'Light';

  /// Translation for 'Dark'
  String get themeBrightnessDark => 'Dark';

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

  /// Translation for 'Sign Up'
  String get signUp => 'Sign Up';

  /// Translation for 'Sign In'
  String get signIn => 'Sign In';

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

  /// Translation for 'Are you sure you want to sign out?'
  String get signOutConfirmationConfirmation =>
      'Are you sure you want to sign out?';

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

  // Admin

  /// Translation for 'Search Query'
  String get adminSearchLabel => 'Search Query';

  /// Translation for 'Search by identifier, email or phone.'
  String get adminSearchHelperText => 'Search by identifier, email or phone.';

  /// Translation for 'email@example.com +138920303 id provider:userId'
  String get adminSearchHint =>
      'email@example.com +138920303 id provider:userId';

  /// Translation for 'Search by identifier, email or phone.'
  String get adminSearchMainPrompt => 'Search by identifier, email or phone.';

  /// Translation for 'No users found.'
  String get adminNoUsersFound => 'No users found.';

  /// Translation for 'View Sessions'
  String get adminViewSessions => 'View Sessions';

  /// Translation for 'SessionId'
  String get adminSessionId => 'SessionId';

  /// Translation for 'UserId'
  String get adminUserId => 'UserId';

  /// Translation for 'Dates'
  String get adminDates => 'Dates';

  /// Translation for 'CreatedAt'
  String get adminCreatedAt => 'CreatedAt';

  /// Translation for 'LastTokenRefresh'
  String get adminLastTokenRefresh => 'LastTokenRefresh';

  /// Translation for 'EndedAt'
  String get adminEndedAt => 'EndedAt';

  /// Translation for 'Client Network Data'
  String get adminClientNetworkData => 'Client Network Data';

  /// Translation for 'IpAddress'
  String get adminIpAddress => 'IpAddress';

  /// Translation for 'Host'
  String get adminHost => 'Host';

  /// Translation for 'Country'
  String get adminCountry => 'Country';

  /// Translation for 'Languages'
  String get adminLanguages => 'Languages';

  /// Translation for 'Timezone'
  String get adminTimezone => 'Timezone';

  /// Translation for 'Client Device'
  String get adminClientDevice => 'Client Device';

  /// Translation for 'DeviceId'
  String get adminDeviceId => 'DeviceId';

  /// Translation for 'Platform'
  String get adminPlatform => 'Platform';

  /// Translation for 'UserAgent'
  String get adminUserAgent => 'UserAgent';

  /// Translation for 'ApiVersion'
  String get adminApiVersion => 'ApiVersion';

  /// Translation for 'Authentication Providers'
  String get adminAuthenticationProviders => 'Authentication Providers';

  /// Translation for 'ProviderId'
  String get adminProviderId => 'ProviderId';

  /// Translation for 'ProviderUserId'
  String get adminProviderUserId => 'ProviderUserId';

  /// Translation for 'Sessions'
  String get adminSessions => 'Sessions';
}

class SpanishFrontEndTranslations implements FrontEndTranslations {
  ///
  const SpanishFrontEndTranslations();

  @override
  String get languageCode => 'es';
  @override
  String? get countryCode => null;
  @override
  String get localeName => 'Español';

  @override
  String get close => 'Cerrar';
  @override
  String get settings => 'Configuración';
  @override
  String get adminDashboard => 'Administrar Usuarios';
  @override
  String get languageSetting => 'Lenguaje';
  @override
  String get themeBrightnessSetting => 'Claridad de Interfaz';
  @override
  String get themeBrightnessSystem => 'Predeterminada';
  @override
  String get themeBrightnessLight => 'Clara';
  @override
  String get themeBrightnessDark => 'Oscura';

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
  @override
  String get signUp => 'Registrarme';
  @override
  String get signIn => 'Inicio de Sesión';

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
  String get signOutConfirmationConfirmation =>
      '¿Estás seguro que deseas cerrar sesión?';
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

  // Admin

  @override
  String get adminSearchLabel => 'Texto de búsqueda';
  @override
  String get adminSearchHelperText =>
      'Busca por identificador, correo o teléfono.';
  @override
  String get adminSearchHint =>
      'email@example.com +138920303 id provider:userId';
  @override
  String get adminSearchMainPrompt =>
      'Busca por identificador, correo o teléfono.';
  @override
  String get adminNoUsersFound => 'No se encontraron usuarios.';
  @override
  String get adminViewSessions => 'Ver Sesiones';
  @override
  String get adminSessionId => 'Identificador de Sesión';
  @override
  String get adminUserId => 'Identificador de Usuario';
  @override
  String get adminDates => 'Fechas';
  @override
  String get adminCreatedAt => 'Creada En';
  @override
  String get adminLastTokenRefresh => 'Ultima actualización de Token';
  @override
  String get adminEndedAt => 'Finalizada En';
  @override
  String get adminClientNetworkData => 'Client Network Data';
  @override
  String get adminIpAddress => 'Dirección IP';
  @override
  String get adminHost => 'Servidor';
  @override
  String get adminCountry => 'País';
  @override
  String get adminLanguages => 'Lenguajes';
  @override
  String get adminTimezone => 'Zona Horaria';
  @override
  String get adminClientDevice => 'Dispositivo del Cliente';
  @override
  String get adminDeviceId => 'Identificador de dispositivo';
  @override
  String get adminPlatform => 'Plataforma';
  @override
  String get adminUserAgent => 'UserAgent';
  @override
  String get adminApiVersion => 'Versión de API';
  @override
  String get adminAuthenticationProviders => 'Proveedores de Autenticación';
  @override
  String get adminProviderId => 'Identificador de Proveedor';
  @override
  String get adminProviderUserId => 'Identificador de Usuario del Proveedor';
  @override
  String get adminSessions => 'Sesiones';
}
