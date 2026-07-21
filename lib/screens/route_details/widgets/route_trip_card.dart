import 'package:flutter/material.dart';

import '../../../theme/app_texts.dart';

class RouteTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool runsToday;
  final VoidCallback? onTap;

  const RouteTripCard({
    super.key,
    required this.trip,
    required this.runsToday,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final headsign = trip['tripHeadsign']?.toString() ?? '-';
    final shortName = trip['tripShortName']?.toString();
    
    final titleText = shortName != null && shortName.isNotEmpty
        ? '$shortName - $headsign'
        : headsign;

    return Card(
      elevation: runsToday ? 1 : 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: runsToday
            ? BorderSide.none
            : BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      color: runsToday
          ? colorScheme.surfaceContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: runsToday ? FontWeight.w600 : FontWeight.w400,
                        color: runsToday
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!runsToday) ...[
                      const SizedBox(height: 4),
                      Text(
                        AppTexts.routeDetailsNotRunningToday,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (runsToday)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
