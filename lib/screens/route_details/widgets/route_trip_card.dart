import 'package:flutter/material.dart';

import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';
import 'package:terka/theme/terka_semantic_colors.dart';

class RouteTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool runsToday;
  final bool? hasActiveVehicle;
  final VoidCallback? onTap;

  const RouteTripCard({
    super.key,
    required this.trip,
    required this.runsToday,
    this.hasActiveVehicle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.semanticColors;
    
    final headsign = trip['tripHeadsign']?.toString() ?? '-';
    final shortName = trip['tripShortName']?.toString();
    
    final titleText = shortName != null && shortName.isNotEmpty
        ? '$shortName - $headsign'
        : headsign;

    final vehicles = trip['vehiclePositions'];
    final isVehicleActive = hasActiveVehicle ?? (vehicles is List && vehicles.isNotEmpty);

    return Card(
      elevation: isVehicleActive ? 2 : (runsToday ? 1 : 0),
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isVehicleActive
            ? BorderSide(color: semantics.onTime, width: 2)
            : (runsToday
                ? BorderSide.none
                : BorderSide(color: colorScheme.outlineVariant, width: 1)),
      ),
      color: runsToday
          ? (isVehicleActive
              ? semantics.successContainer.withValues(alpha: 0.12)
              : colorScheme.surfaceContainer)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titleText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: (runsToday || isVehicleActive) ? FontWeight.w600 : FontWeight.w400,
                              color: runsToday
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      ],
                    ),
                    if (!runsToday) ...[
                      const SizedBox(height: AppSpacing.xs),
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
