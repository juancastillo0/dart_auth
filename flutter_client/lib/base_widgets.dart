import 'package:flutter/material.dart';

import 'translations.dart';

export 'hooks_mobx.dart' show HookMobxWidget;

Translations getTranslations(BuildContext context) {
  return InheritedGeneric.depend(context);
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
