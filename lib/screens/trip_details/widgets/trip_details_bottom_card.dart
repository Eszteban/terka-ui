import 'package:flutter/material.dart';
import '../../../utils/trip_details_utils.dart';
import '../../../widgets/line_badge.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';

class TripDetailsBottomCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final Color routeColor;
  final Color routeTextColor;
  final String serviceDay;
  final VoidCallback onBack;

  const TripDetailsBottomCard({
    super.key,
    required this.trip,
    required this.routeColor,
    required this.routeTextColor,
    required this.serviceDay,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final info = TripDetailsUtils.buildTripVehicleInfo(trip);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: AppColors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: isDark
              ? Border.all(color: AppColors.white.withValues(alpha: 0.08))
              : null,
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                LineBadge(
                  lineLabel: info.line,
                  routeColor: routeColor,
                  routeTextColor: routeTextColor,
                  useSpanFont: info.lineUsesSpanFont,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${info.tripShortName} - ${info.tripHeadsign}',
                    softWrap: true,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(info.vehicleInfoText, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${AppTexts.isHungarian ? "Dátum:" : "Date:"} $serviceDay',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onBack,
                child: Text(AppTexts.back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
