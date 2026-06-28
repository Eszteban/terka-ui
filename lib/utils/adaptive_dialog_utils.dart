import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

Future<T?> showAdaptiveDetailsDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  final size = MediaQuery.of(context).size;
  final isDesktop = size.shortestSide > 600;
  final orientation = NativeDeviceOrientationReader.orientation(context);
  final isPhoneLandscape = !isDesktop &&
      (orientation == NativeDeviceOrientation.landscapeLeft ||
          orientation == NativeDeviceOrientation.landscapeRight);

  if (isPhoneLandscape) {
    final alignment = orientation == NativeDeviceOrientation.landscapeRight
        ? Alignment.centerLeft
        : Alignment.centerRight;

    final padding = MediaQuery.of(context).padding;
    final insetPadding = orientation == NativeDeviceOrientation.landscapeRight
        ? EdgeInsets.only(
            left: 80.0 + padding.left,
            right: 8.0,
            top: 8.0,
            bottom: 8.0,
          )
        : EdgeInsets.only(
            left: 8.0,
            right: 80.0 + padding.right,
            top: 8.0,
            bottom: 8.0,
          );

    return showDialog<T>(
      context: context,
      builder: (_) => Dialog(
        clipBehavior: Clip.antiAlias,
        alignment: alignment,
        insetPadding: insetPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 380,
            maxHeight: size.height - 16,
          ),
          child: child,
        ),
      ),
    );
  }

  // Fallback to standard desktop/tablet centered dialog
  return showDialog<T>(
    context: context,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 860),
        child: child,
      ),
    ),
  );
}
