import 'package:flutter/material.dart';
import '../../../theme/app_texts.dart';
import '../../../widgets/maps/map_view.dart';
import '../../../widgets/line_badge.dart';
import '../../../utils/stop_details_utils.dart';
import '../../../utils/trip_details_utils.dart';
import 'route_trip_card.dart';

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
            const SizedBox(width: 8),
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
            return Material(
              elevation: 8,
              color: colorScheme.surface.withValues(alpha: 0.97),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
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
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          AppTexts.tripSwipeInstruction,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      headerTitleWidget,
                      const SizedBox(height: 16),
                      _buildTripsList(),
                    ],
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

    allTrips.sort((a, b) {
      final aActive = (a['activeDates'] as List?)?.contains(todayDateString) ?? false;
      final bActive = (b['activeDates'] as List?)?.contains(todayDateString) ?? false;
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;

      final aName = a['tripShortName']?.toString() ?? a['tripHeadsign']?.toString() ?? '';
      final bName = b['tripShortName']?.toString() ?? b['tripHeadsign']?.toString() ?? '';
      return aName.compareTo(bName);
    });

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
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
