import 'package:flutter/material.dart';
import 'package:terka/theme/app_tokens.dart';
import '../../utils/layout_provider.dart';

class DesktopSidebarWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double backgroundAlpha;
  final bool applyPaddingOnMobile;

  const DesktopSidebarWrapper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundAlpha = 0.84,
    this.applyPaddingOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = LayoutProvider.isDesktop(context, breakpoint: 600.0);
    
    if (!isDesktop) {
      return applyPaddingOnMobile ? Padding(padding: padding, child: child) : child;
    }

    final colorScheme = Theme.of(context).colorScheme;
    
    return Align(
      alignment: Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 32,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(context).withValues(alpha: backgroundAlpha),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: AppColors.transparent,
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
