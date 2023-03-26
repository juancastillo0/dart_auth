import 'package:flutter/material.dart';
import 'package:flutter_client/auth_widgets.dart';
import 'package:flutter_client/base_widgets.dart';
import 'package:flutter_client/secure_storage.dart';
import 'package:flutter_client/user_info_widget.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oauth/front_end_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await GlobalState.load(
    persistence: SecureStorageClientPersistence(),
  );

  runApp(
    InheritedGeneric(
      state: state,
      child: StreamBuilder(
        stream: state.translations,
        builder: (context, _) => InheritedGeneric(
          state: state.translations.value,
          child: const MainApp(),
        ),
      ),
    ),
  );
}

class MainApp extends HookMobxWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final globalState = globalStateOf(context);
    final darkTheme = useValue(globalState.darkTheme);
    final translations = useValue(globalState.translations);

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
      themeMode: darkTheme == null
          ? ThemeMode.system
          : darkTheme
              ? ThemeMode.dark
              : ThemeMode.light,
      home: const MainHomePage(title: 'Flutter Dart Auth Demo'),
    );
  }
}

class MainHomePage extends HookWidget {
  const MainHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final globalState = globalStateOf(context);
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
    final currentFlow = useValue(state.currentFlow);
    final userInfo = useValue(state.userInfo);
    final isAddingMFAProvider = useValue(state.isAddingMFAProvider);

    void showSettingsDialog() {
      showDialog<void>(
        context: context,
        builder: (context) {
          final t = getTranslations(context);
          return AlertDialog(
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: Text(t.themeBrightnessSetting),
                      ),
                      Expanded(
                        child: StreamBuilder(
                          stream: globalState.darkTheme,
                          builder: (context, _) =>
                              DropdownButtonFormField<bool?>(
                            value: globalState.darkTheme.value,
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text(t.themeBrightnessSystem),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text(t.themeBrightnessLight),
                              ),
                              DropdownMenuItem(
                                value: true,
                                child: Text(t.themeBrightnessDark),
                              ),
                            ],
                            onChanged: (v) => globalState.darkTheme.value = v,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      SizedBox(width: 200, child: Text(t.languageSetting)),
                      Expanded(
                        child: StreamBuilder(
                          stream: globalState.translations,
                          builder: (context, _) =>
                              DropdownButtonFormField<FrontEndTranslations>(
                            value: globalState.translations.value,
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
      helperMaxLines: 100,
      errorMaxLines: 100,
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
