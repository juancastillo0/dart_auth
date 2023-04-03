import 'dart:async';
import 'dart:io';

import 'package:oauth/src/backend_translation.dart';
import 'package:oauth/src/frontend/admin_client_state.dart';
import 'package:oauth/src/frontend/auth_client.dart';
import 'package:oauth/src/frontend/frontend_translations.dart';

abstract class ClientPersistence {
  FutureOr<String?> read(String key);
  FutureOr<void> write(String key, String value);
  FutureOr<void> delete(String key);
}

class GlobalState {
  late final AuthState authState;
  late final AdminClient adminState;
  final List<FrontEndTranslations> supportedTranslations;
  final List<Translations> supportedBackendTranslations;
  Translations? backendTranslations;
  late final ValueNotifierStream<FrontEndTranslations> translations;
  final ValueNotifierStream<bool?> darkTheme = ValueNotifierStream(null);

  ///
  GlobalState._({
    FrontEndTranslations? translations,
    this.supportedTranslations = const [
      FrontEndTranslations.defaultEnglish,
      FrontEndTranslations.defaultSpanish,
    ],
    this.supportedBackendTranslations = const [],
  }) {
    this.translations =
        ValueNotifierStream(translations ?? supportedTranslations.first);
    _computeBackendTranslations(this.translations.value);
    this.translations.listen(_computeBackendTranslations);
    adminState = AdminClient(this);
  }

  void _computeBackendTranslations(FrontEndTranslations front) {
    if (supportedBackendTranslations.isEmpty) return;
    backendTranslations = supportedBackendTranslations.firstWhere(
      (t) => t.languageCode == front.languageCode,
      orElse: () => supportedBackendTranslations.first,
    );
  }

  static Future<GlobalState> load({
    FrontEndTranslations? translations,
    required ClientPersistence persistence,
    String baseUrl = 'http://localhost:3000',
  }) async {
    final globalState = GlobalState._(translations: translations);
    final authState = await AuthState.load(
      globalState: globalState,
      persistence: persistence,
      baseUrl: baseUrl,
    );
    globalState.authState = authState;
    return globalState;
  }

  String translate(Translation value) {
    if (backendTranslations != null) value.getMessage(backendTranslations!);
    return value.msg ?? value.key;
  }
}

enum AppPlatform {
  web,
  android,
  ios,
  linux,
  macos,
  windows,
  fuchsia,
  other;

  /// The current platform executing the code.
  static final AppPlatform current = _getCurrent();

  static AppPlatform _getCurrent() {
    if (identical(0, 0.0)) return AppPlatform.web;
    if (Platform.isAndroid) return AppPlatform.android;
    if (Platform.isIOS) return AppPlatform.ios;
    if (Platform.isLinux) return AppPlatform.linux;
    if (Platform.isMacOS) return AppPlatform.macos;
    if (Platform.isWindows) return AppPlatform.windows;
    if (Platform.isFuchsia) return AppPlatform.fuchsia;
    return AppPlatform.other;
  }
}

class ValueNotifierStream<T> extends Stream<T> {
  ///
  ValueNotifierStream(this._value) {
    _controller.add(_value);
  }

  final _controller = StreamController<T>.broadcast(sync: true);
  T _value;

  T get value => _value;
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    _controller.add(_value);
  }

  void setValue(T newValue) {
    value = newValue;
  }

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  }

  StreamSubscription<T> addListener(void Function() callback) {
    return listen((_) => callback());
  }

  Future<Object?> dispose() {
    return _controller.close();
  }
}
