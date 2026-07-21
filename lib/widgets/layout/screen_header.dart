import 'package:flutter/material.dart';
import 'package:terka/theme/app_tokens.dart';

class ScreenHeader extends StatelessWidget {
  final Widget title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final EdgeInsetsGeometry padding;

  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
          else
            const SizedBox(width: AppSpacing.sm), // Padding if no back button
          Expanded(
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ) ??
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              child: title,
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
