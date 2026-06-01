import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

class DesktopDropdownButton extends StatelessWidget {
  final String title;
  final List<String> items;
  final ValueChanged<String>? onSelected;

  const DesktopDropdownButton({
    super.key,
    required this.title,
    required this.items,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(AppSpacing.none, AppSpacing.dropdownOffset),
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.touchTarget,
          minHeight: AppSpacing.touchTarget,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
