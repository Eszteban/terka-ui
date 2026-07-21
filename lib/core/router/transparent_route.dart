import 'package:flutter/material.dart';

class TransparentRoute<T> extends TransitionRoute<T> with LocalHistoryRoute<T> {
  final Widget child;

  TransparentRoute({
    required this.child,
    super.settings,
  });

  @override
  Iterable<OverlayEntry> createOverlayEntries() sync* {
    yield OverlayEntry(builder: (context) => child);
  }

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  bool get popGestureEnabled => false;
}

class TransparentPage<T> extends Page<T> {
  final Widget child;

  const TransparentPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return TransparentRoute<T>(
      child: child,
      settings: this,
    );
  }
}
