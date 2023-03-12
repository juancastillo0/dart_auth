import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
// ignore: implementation_imports
import 'package:mobx/src/core.dart' show ReactionImpl;

/// A [StatelessWidget] that rebuilds when an [Observable] used inside [build]
/// updates.
///
/// See also:
///
/// - [Observer], which subclass this interface and delegate its [build]
///   to a callback.
/// - [StatefulObserverWidget], similar to this class, but that has a [State].
abstract class HookMobxWidget extends StatelessWidget with ObserverWidgetMixin {
  /// Initializes [key], [context] and [name] for subclasses.
  const HookMobxWidget({
    super.key,
    ReactiveContext? context,
    String? name,
    this.warnWhenNoObservables = false,
  })  : _name = name,
        _context = context;

  final String? _name;
  final ReactiveContext? _context;
  @override
  final bool? warnWhenNoObservables;

  @override
  String getName() => _name ?? '$this';

  @override
  ReactiveContext getContext() => _context ?? super.getContext();

  @override
  HookMobxElement createElement() => HookMobxElement(this);
}

/// An [Element] that uses a [HookMobxWidget] as its configuration.
class HookMobxElement extends StatelessElement
    with
        // ignore: invalid_use_of_visible_for_testing_member
        HookElement,
        ObserverElementMixinModified {
  /// Creates an element that uses the given widget as its configuration.
  HookMobxElement(HookMobxWidget super.widget);

  @override
  HookMobxWidget get widget => super.widget as HookMobxWidget;

  @override
  void mount(Element? parent, Object? newSlot) {
    mountMobx(parent, newSlot);
    super.mount(parent, newSlot);
  }

  @override
  Widget build() {
    Widget? built;

    this.reaction.track(() {
      built = super.build();
    });

    if (enableWarnWhenNoObservables &&
        (_widget.warnWhenNoObservables ?? true) &&
        !this.reaction.hasObservables) {
      _widget.log(
        'No observables detected in the build method of ${this.reaction.name}',
      );
    }

    // This "throw" is better than a "LateInitializationError"
    // which confused the user. Please see #780 for details.
    if (built == null) {
      throw Exception('Error happened when building ${_widget.runtimeType},'
          ' but it was captured since disableErrorBoundaries==true');
    }

    return built!;
  }

  @override
  void unmount() {
    unmountMobx();
    super.unmount();
  }
}

/// A mixin that overrides [build] to listen to the observables used by
/// [ObserverWidgetMixin].
///
/// Modified from [ObserverElementMixin] to expose [mount] and [unmount]
/// as [mountMobx] and [unmountMobx].
mixin ObserverElementMixinModified on ComponentElement {
  ReactionImpl get reaction => _reaction!;

  // null means it is unmounted
  ReactionImpl? _reaction;

  // Not using the original `widget` getter as it would otherwise make the mixin
  // impossible to use
  ObserverWidgetMixin get _widget => widget as ObserverWidgetMixin;

  void mountMobx(Element? parent, dynamic newSlot) {
    _reaction = _widget.createReaction(invalidate, onError: (e, _) {
      FlutterError.reportError(FlutterErrorDetails(
        library: 'flutter_mobx',
        exception: e,
        stack: e is Error ? e.stackTrace : null,
        context: ErrorDescription(
            'From reaction of ${_widget.getName()} of type $runtimeType.'),
      ));
    }) as ReactionImpl;
  }

  void invalidate() => _markNeedsBuildImmediatelyOrDelayed();

  void _markNeedsBuildImmediatelyOrDelayed() async {
    // reference
    // 1. https://github.com/mobxjs/mobx.dart/issues/768
    // 2. https://stackoverflow.com/a/64702218/4619958
    // 3. https://stackoverflow.com/questions/71367080

    // if there's a current frame,
    final schedulerPhase =
        _ambiguate(SchedulerBinding.instance)!.schedulerPhase;
    final shouldWait =
        // surely, `idle` is ok
        schedulerPhase != SchedulerPhase.idle &&
            // By experience, it is safe to do something like
            // `SchedulerBinding.addPostFrameCallback((_) => someObservable.value = newValue)`
            // So it is safe if we are in this phase
            schedulerPhase != SchedulerPhase.postFrameCallbacks;
    if (shouldWait) {
      // uncomment to log
      // print('hi wait phase=$schedulerPhase');

      // wait for the end of that frame.
      await _ambiguate(SchedulerBinding.instance)!.endOfFrame;

      // If it is disposed after this frame, we should no longer call `markNeedsBuild`
      if (_reaction == null) return;
    }

    markNeedsBuild();
  }

  void unmountMobx() {
    _reaction!.dispose();
    _reaction = null;
  }
}

/// This allows a value of type T or T?
/// to be treated as a value of type T?.
///
/// We use this so that APIs that have become
/// non-nullable can still be used with `!` and `?`
/// to support older versions of the API as well.
T? _ambiguate<T>(T? value) => value;
