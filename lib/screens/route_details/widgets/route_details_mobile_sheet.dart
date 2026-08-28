import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:terka/theme/app_texts.dart';
import '../../../widgets/maps/map_view.dart';
import '../../../widgets/line_badge.dart';
import '../../../utils/stop_details_utils.dart';
import '../../../utils/trip_details_utils.dart';
import 'route_trip_card.dart';
import 'package:terka/theme/app_tokens.dart';

class RouteDetailsMobileSheet extends StatelessWidget {
  static const double _mobileSheetMinSize = 0.16;
  static const double _mobileSheetInitialSize = 0.24;
  static const double _mobileSheetMaxSize = 0.9;

  final Map<String, dynamic> routeData;
  final String todayDateString;
  final void Function(String tripId, String serviceDay) onOpenTripDetailsRequested;

  const RouteDetailsMobileSheet({
    super.key,
    required this.routeData,
    required this.todayDateString,
    required this.onOpenTripDetailsRequested,
  });

  @override
  Widget build(BuildContext context) {
    final shortName = routeData['shortName']?.toString();
    final longName = routeData['longName']?.toString();
    final colorHex = routeData['color']?.toString() ?? '0A84FF';
    final textColorHex = routeData['textColor']?.toString() ?? 'FFFFFF';
    
    Widget headerTitleWidget = Text(AppTexts.routeDetailsTitle);
    
    if (shortName != null && shortName.isNotEmpty) {
      final plainShortName = TripDetailsUtils.plainText(shortName).trim();
      final useSpanFont = TripDetailsUtils.containsSpanMarkup(shortName);
      
      final badge = LineBadge(
        lineLabel: plainShortName,
        routeColor: StopDetailsUtils.hexColor(colorHex),
        routeTextColor: StopDetailsUtils.hexColor(textColorHex),
        useSpanFont: useSpanFont,
      );
      
      if (longName != null && longName.isNotEmpty) {
        final plainLongName = TripDetailsUtils.plainText(longName).trim();
        headerTitleWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge,
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                plainLongName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                softWrap: true,
              ),
            ),
          ],
        );
      } else {
        headerTitleWidget = badge;
      }
    } else if (longName != null && longName.isNotEmpty) {
      headerTitleWidget = Text(
        TripDetailsUtils.plainText(longName).trim(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final controlsBottomInset = screenHeight * _mobileSheetInitialSize + 24;

    return Stack(
      children: [
        Positioned.fill(
          child: MapView(
            controlsBottomInset: controlsBottomInset,
            routeOverlayData: TripDetailsUtils.buildRouteMapData(routeData),
            selectedRouteName: shortName ?? longName ?? '',
            hideGeneralStopsAndVehicles: false,
            routeFitPadding: EdgeInsets.fromLTRB(
              48,
              48,
              48,
              controlsBottomInset + 120,
            ),
            showRouteStopLabels: false,
            useBaseMapStopIcon: true,
            onOpenTripDetailsRequested: onOpenTripDetailsRequested,
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: _mobileSheetInitialSize,
          minChildSize: _mobileSheetMinSize,
          maxChildSize: _mobileSheetMaxSize,
          snap: true,
          snapSizes: const [_mobileSheetInitialSize, 0.5, _mobileSheetMaxSize],
          builder: (context, scrollController) {
            final colorScheme = Theme.of(context).colorScheme;
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context).withValues(alpha: 0.84),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Material(
                    color: AppColors.transparent,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: colorScheme.outlineVariant,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Center(
                              child: Text(
                                AppTexts.tripSwipeInstruction,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            headerTitleWidget,
                            const SizedBox(height: AppSpacing.lg),
                            _buildTripsList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTripsList() {
    final patterns = routeData['patterns'];
    if (patterns is! List || patterns.isEmpty) {
      return Center(
        child: Text(AppTexts.noData),
      );
    }

    final allTrips = <Map<String, dynamic>>[];
    for (final pattern in patterns) {
      if (pattern is Map) {
        final trips = pattern['trips'];
        if (trips is List) {
          allTrips.addAll(trips.whereType<Map<String, dynamic>>());
        }
      }
    }

    if (allTrips.isEmpty) {
      return Center(
        child: Text(AppTexts.noData),
      );
    }

    // Sort trips: first trips with registered/live vehicles, then running today, then the rest.
    allTrips.sort((a, b) {
      final aVehicles = a['vehiclePositions'] as List?;
      final bVehicles = b['vehiclePositions'] as List?;
      final aHasVehicle = aVehicles != null && aVehicles.isNotEmpty;
      final bHasVehicle = bVehicles != null && bVehicles.isNotEmpty;
      if (aHasVehicle && !bHasVehicle) return -1;
      if (!aHasVehicle && bHasVehicle) return 1;

      final aActive = (a['activeDates'] as List?)?.contains(todayDateString) ?? false;
      final bActive = (b['activeDates'] as List?)?.contains(todayDateString) ?? false;
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;

      final aName = a['tripShortName']?.toString() ?? a['tripHeadsign']?.toString() ?? '';
      final bName = b['tripShortName']?.toString() ?? b['tripHeadsign']?.toString() ?? '';
      return aName.compareTo(bName);
    });

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
      itemCount: allTrips.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final trip = allTrips[index];
        final activeDates = trip['activeDates'] as List?;
        final runsToday = activeDates?.contains(todayDateString) ?? false;

        return RouteTripCard(
          trip: trip,
          runsToday: runsToday,
          onTap: () {
            final tripId = trip['gtfsId']?.toString();
            if (tripId == null) return;

            final serviceDay = runsToday ? todayDateString : (activeDates?.isNotEmpty == true ? activeDates!.first.toString() : '');
            
            onOpenTripDetailsRequested(tripId, serviceDay);
          },
        );
      },
    );
  }
}
