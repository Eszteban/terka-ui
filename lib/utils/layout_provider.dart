import 'package:flutter/material.dart';
import '../app.dart';

class LayoutProvider extends InheritedWidget {
  final AppLayoutMode mode;

  const LayoutProvider({
    super.key,
    required this.mode,
    required super.child,
  });

  static AppLayoutMode _getMode(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<LayoutProvider>();
    return provider?.mode ?? AppLayoutMode.automatic;
  }

  static bool isDesktop(BuildContext context, {double breakpoint = 600}) {
    final mode = _getMode(context);
    if (mode == AppLayoutMode.mobile) return false;
    if (mode == AppLayoutMode.tablet) return true;
    return MediaQuery.of(context).size.width > breakpoint;
  }

  @override
  bool updateShouldNotify(LayoutProvider oldWidget) {
    return mode != oldWidget.mode;
  }
}
