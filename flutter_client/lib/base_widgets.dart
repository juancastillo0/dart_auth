import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:oauth/endpoint_models.dart' show Translation;
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
