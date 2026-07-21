import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'layout_provider.dart';
import 'package:terka/theme/app_tokens.dart';

Future<T?> showAdaptiveDetailsDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  final size = MediaQuery.of(context).size;
  final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600);
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
            left: 80 + padding.left,
            right: AppSpacing.sm,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          )
        : EdgeInsets.only(
            left: AppSpacing.sm,
            right: 80 + padding.right,
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
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
  final padding = MediaQuery.of(context).viewPadding;
  final safeMaxHeight = (size.height - padding.top - padding.bottom - 48).clamp(0.0, 860.0);

  return showDialog<T>(
    context: context,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl + padding.top,
        bottom: AppSpacing.xl + padding.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: safeMaxHeight,
        ),
        child: child,
      ),
    ),
  );
}
