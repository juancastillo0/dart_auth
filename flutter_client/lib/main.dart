import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oauth/endpoint_models.dart';

import 'auth_client.dart';
import 'auth_widgets.dart';
import 'base_widgets.dart';
import 'frontend_translations.dart';
import 'secure_storage.dart';
import 'user_info_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await GlobalState.load();

  runApp(
    InheritedGeneric(
      state: state,
      child: ValueListenableBuilder(
        valueListenable: state.translations,
        builder: (context, translations, _) => InheritedGeneric(
          state: translations,
          child: const MainApp(),
        ),
      ),
    ),
  );
}

class GlobalState {
  late final AuthState authState;
  final List<FrontEndTranslations> supportedTranslations;
  final List<Translations> supportedBackendTranslations;
  late final ValueNotifier<FrontEndTranslations> translations;
  final ValueNotifier<bool?> darkTheme = ValueNotifier(null);

  ///
  GlobalState({
    FrontEndTranslations? translations,
    this.supportedTranslations = const [
      FrontEndTranslations.defaultEnglish,
      FrontEndTranslations.defaultSpanish,
    ],
    this.supportedBackendTranslations = const [],
  }) {
    this.translations =
        ValueNotifier(translations ?? supportedTranslations.first);
  }

  static Future<GlobalState> load({FrontEndTranslations? translations}) async {
    final globalState = GlobalState(translations: translations);
    final authState = await AuthState.load(
      globalState: globalState,
      persistence: SecureStorageClientPersistence(),
    );
    globalState.authState = authState;
    return globalState;
  }

  static GlobalState of(BuildContext context) {
    return InheritedGeneric.get(context);
  }

  String translate(Translation value) {
    for (final backendTranslation in supportedBackendTranslations) {
      if (backendTranslation.languageCode == translations.value.languageCode) {
        return value.getMessage(backendTranslation);
      }
    }
    return value.msg ?? value.key;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final globalState = GlobalState.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        globalState.darkTheme,
        globalState.translations,
      ]),
      builder: (context, _) {
        final translations = globalState.translations.value;
        return MaterialApp(
          title: 'Flutter Dart Auth Demo',
          theme: globalTheme(brightness: Brightness.light),
          darkTheme: globalTheme(brightness: Brightness.dark),
          locale: Locale(translations.languageCode, translations.countryCode),
          supportedLocales: [
            ...globalState.supportedTranslations
                .map((e) => Locale(e.languageCode, e.countryCode))
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          themeMode: globalState.darkTheme.value == null
              ? ThemeMode.system
              : globalState.darkTheme.value!
                  ? ThemeMode.dark
                  : ThemeMode.light,
          home: const MainHomePage(title: 'Flutter Dart Auth Demo'),
        );
      },
    );
  }
}

class MainHomePage extends HookWidget {
  const MainHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final globalState = GlobalState.of(context);
    final t = getTranslations(context);
    final state = globalState.authState;
    useEffect(
      () {
        state.getProviders();
        final subs = state.authErrorStream.listen((event) {
          print(event);
        });
        final subs2 = state.errorStream.listen((event) {
          print(event);
        });
        return () {
          subs.cancel();
          subs2.cancel();
        };
      },
      const [],
    );
    final currentFlow = useValueListenable(state.currentFlow);
    final userInfo = useValueListenable(state.userInfo);
    final isAddingMFAProvider = useValueListenable(state.isAddingMFAProvider);

    void showSettingsDialog() {
      showDialog<void>(
        context: context,
        builder: (context) {
          final t = getTranslations(context);
          return AlertDialog(
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 180, child: Text('Theme Brightness')),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: globalState.darkTheme,
                          builder: (context, darkTheme, _) =>
                              DropdownButtonFormField<bool?>(
                            value: darkTheme,
                            items: const [
                              // TODO: translate
                              DropdownMenuItem(
                                value: null,
                                child: Text('System'),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text('Light'),
                              ),
                              DropdownMenuItem(
                                value: true,
                                child: Text('Dark'),
                              ),
                            ],
                            onChanged: (v) => globalState.darkTheme.value = v,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 180, child: Text('Language')),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: globalState.translations,
                          builder: (context, translations, _) =>
                              DropdownButtonFormField<FrontEndTranslations>(
                            value: translations,
                            items: [
                              ...globalState.supportedTranslations.map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.localeName),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                globalState.translations.value = v;
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text(t.close),
              )
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton.icon(
            onPressed: showSettingsDialog,
            style: actionStyle(context),
            icon: const Icon(Icons.settings),
            label: Text(t.settings),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (userInfo != null && !isAddingMFAProvider)
              Expanded(child: UserInfoWidget(userInfo: userInfo))
            else
              OAuthFlowWidget(currentFlow: currentFlow),
          ],
        ),
      ),
    );
  }
}

ThemeData globalTheme({required Brightness brightness}) {
  return ThemeData(
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.teal,
      brightness: brightness,
    ).copyWith(
      onError: const Color(0xffffffff),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      isDense: true,
      filled: true,
      labelStyle: TextStyle(height: 0.5),
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.black12,
        ),
      ),
    ),
    cardTheme: const CardTheme(
      elevation: 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      toolbarHeight: 42,
    ),
  );
}

ButtonStyle actionStyle(BuildContext context) => TextButton.styleFrom(
      primary: Colors.white,
      onSurface: Colors.white,
      disabledMouseCursor: MouseCursor.defer,
      enabledMouseCursor: SystemMouseCursors.click,
      padding: const EdgeInsets.symmetric(horizontal: 17),
    );

  ///
  const InheritedGlobalState({
    super.key,
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
