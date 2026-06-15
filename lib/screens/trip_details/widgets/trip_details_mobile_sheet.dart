import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../utils/trip_details_utils.dart';
import '../../../theme/app_texts.dart';
import '../../../widgets/maps/plan_map_view.dart';
import '../../../widgets/maps/route_map_data.dart';
import '../../../widgets/line_badge.dart';
import '../../../widgets/alerts_section.dart';
import '../../../widgets/tables/stop_times_data_table.dart';

class TripDetailsMobileSheet extends StatelessWidget {
  static const double _mobileSheetMinSize = 0.16;
  static const double _mobileSheetInitialSize = 0.24;
  static const double _mobileSheetMaxSize = 0.9;

  final Map<String, dynamic> trip;
  final String tripId;
  final String serviceDay;
  final void Function({
    required String stopId,
    required String stopName,
    required LatLng? initialStopPoint,
  }) onStopTap;
  final Widget Function(BuildContext, RouteStopMarker) stopInfoCardBuilder;

  const TripDetailsMobileSheet({
    super.key,
    required this.trip,
    required this.tripId,
    required this.serviceDay,
    required this.onStopTap,
    required this.stopInfoCardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final routeData = TripDetailsUtils.buildTripRouteMapData(trip);
    final route = TripDetailsUtils.route(trip);
    final routeColor = TripDetailsUtils.hexColor(route['color']?.toString() ?? '0A84FF');
    final routeTextColor = TripDetailsUtils.hexColor(
      route['textColor']?.toString() ?? 'FFFFFF',
    );
    final vehicleMarker = TripDetailsUtils.buildTripVehicleMarker(trip, tripId);
    final stopTimes = TripDetailsUtils.stopTimes(trip);
    final rawTripHeadsign = trip['tripHeadsign']?.toString() ?? '-';
    final tripHeadsign = TripDetailsUtils.plainText(rawTripHeadsign);
    final rawLineLabel = route['shortName']?.toString() ?? '-';
    final lineLabel = TripDetailsUtils.plainText(rawLineLabel);
    final lineLabelUsesSpanFont = TripDetailsUtils.containsSpanMarkup(rawLineLabel);
    final tripShortName = TripDetailsUtils.plainText(trip['tripShortName']?.toString() ?? '-');
    final combinedAlerts = <dynamic>[];
    final seenIds = <String>{};
    if (trip['alerts'] is List) {
      for (final alert in trip['alerts']) {
        if (alert is Map) {
          final id = alert['id']?.toString() ?? '';
          if (id.isEmpty || seenIds.add(id)) {
            combinedAlerts.add(alert);
          }
        }
      }
    }
    if (route is Map && route['alerts'] is List) {
      for (final alert in route['alerts']) {
        if (alert is Map) {
          final id = alert['id']?.toString() ?? '';
          if (id.isEmpty || seenIds.add(id)) {
            combinedAlerts.add(alert);
          }
        }
      }
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final controlsBottomInset = screenHeight * _mobileSheetInitialSize + 24;

    return Stack(
      children: [
        Positioned.fill(
          child: PlanMapView(
            routeData: routeData,
            controlsBottomInset: controlsBottomInset,
            fitPadding: EdgeInsets.fromLTRB(
              48,
              48,
              48,
              controlsBottomInset + 120,
            ),
            showStopLabels: false,
            useBaseMapStopIcon: true,
            vehicleMarker: vehicleMarker,
            enableVehicleInfoLabelTap: vehicleMarker != null,
            vehicleInfoCardBuilder: vehicleMarker == null
                ? null
                : (context) => TripDetailsUtils.buildVehicleTapInfoCard(
                      trip: trip,
                      routeColor: routeColor,
                      routeTextColor: routeTextColor,
                    ),
            enableStopInfoLabelTap: true,
            stopInfoCardBuilder: stopInfoCardBuilder,
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
              child: Column(
                children: [
                  SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              LineBadge(
                                lineLabel: lineLabel,
                                routeColor: routeColor,
                                routeTextColor: routeTextColor,
                                useSpanFont: lineLabelUsesSpanFont,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tripShortName,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tripHeadsign,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AlertsSection(alerts: combinedAlerts),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      child: StopTimesDataTable(
                        stopTimes: stopTimes,
                        serviceDay: serviceDay,
                        onStopTap: onStopTap,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
