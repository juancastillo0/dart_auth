import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'auth_client.dart';
import 'auth_widgets.dart';

void main() {
  final state = GlobalState();
  runApp(
    InheritedGlobalState(
      state: state,
      child: const MainApp(),
    ),
  );
}

class GlobalState {
  final authState = AuthState();

  static GlobalState of(BuildContext context) {
    final widget = context
        .getElementForInheritedWidgetOfExactType<InheritedGlobalState>()!
        .widget;
    return (widget as InheritedGlobalState).state;
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dart Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainHomePage(title: 'Flutter Dart Auth Demo'),
    );
  }
}

class MainHomePage extends HookWidget {
  const MainHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final state = GlobalState.of(context).authState;
    final counter = useState(0);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (userInfo != null)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(38),
                    child: Text(jsonEncode(userInfo)),
                  ),
                  ElevatedButton.icon(
                    onPressed: state.signOut,
                    icon: const Icon(Icons.close),
                    label: const Text('Sign Out'),
                  ),
                ],
              )
            else
              OAuthFlowWidget(currentFlow: currentFlow),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${counter.value}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => counter.value++,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class InheritedGlobalState extends InheritedWidget {
  final GlobalState state;

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
