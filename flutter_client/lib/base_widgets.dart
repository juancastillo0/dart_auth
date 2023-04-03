import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:oauth/endpoint_models.dart' show AuthError, Translation;
import 'package:oauth/front_end_client.dart';

export 'hooks_mobx.dart' show HookMobxWidget;

FrontEndTranslations getTranslations(BuildContext context) {
  return InheritedGeneric.depend(context);
}

GlobalState globalStateOf(BuildContext context) {
  return InheritedGeneric.get(context);
}

String translate(BuildContext context, Translation value) {
  return globalStateOf(context).translate(value);
}

T useValue<T>(ValueNotifierStream<T> stream) {
  return useStream(stream, initialData: stream.value).data as T;
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBarAuthError(
  BuildContext context,
  AuthError error,
) {
  final state = globalStateOf(context);
  return showSnackBar(
    context,
    error.allErrors.map(state.translate).join('\n'),
    isError: true,
  );
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
  BuildContext context,
  String message, {
  required bool isError,
}) {
  final theme = Theme.of(context);
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? theme.colorScheme.error : null,
      content: Text(message),
    ),
  );
}

class InheritedGeneric<T> extends InheritedWidget {
  final T state;

  ///
  const InheritedGeneric({
    super.key,
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant InheritedGeneric<T> oldWidget) {
    return state != oldWidget.state;
  }

  static T get<T>(BuildContext context) {
    final widget = context
        .getElementForInheritedWidgetOfExactType<InheritedGeneric<T>>()!
        .widget;
    return (widget as InheritedGeneric<T>).state;
  }

  static T depend<T>(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<InheritedGeneric<T>>()!;
    return widget.state;
  }
}
