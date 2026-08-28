import 'dart:ui';
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

    return Material(
      color: AppColors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context).withValues(alpha: 0.84),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
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
        ),
      ),
    );
  }
}
