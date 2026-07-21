import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../utils/trip_details_utils.dart';
import '../../../widgets/line_badge.dart';
import '../../../widgets/alerts_section.dart';
import '../../../widgets/tables/trip_stop_times_list.dart';
import '../../../models/trip_stop_time.dart';
import 'trip_details_additional_info.dart';

class TripDetailsTableView extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String serviceDay;
  final void Function({
    required String stopId,
    required String stopName,
    required LatLng? initialStopPoint,
  }) onStopTap;

  const TripDetailsTableView({
    super.key,
    required this.trip,
    required this.serviceDay,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    final stopTimes = TripDetailsUtils.stopTimes(trip)
        .map((json) => TripStopTime.fromJson(json))
        .toList();
    final route = TripDetailsUtils.route(trip);
    final rawTripHeadsign = trip['tripHeadsign']?.toString() ?? '-';
    final tripHeadsign = TripDetailsUtils.plainText(rawTripHeadsign);
    final title = TripDetailsUtils.plainText(trip['tripShortName']?.toString() ?? '-');
    final rawLineLabel = route['shortName']?.toString() ?? '-';
    final lineLabel = TripDetailsUtils.plainText(rawLineLabel);
    final lineLabelUsesSpanFont = TripDetailsUtils.containsSpanMarkup(rawLineLabel);
    final routeColor = TripDetailsUtils.hexColor(route['color']?.toString() ?? '0A84FF');
    final routeTextColor = TripDetailsUtils.hexColor(
      route['textColor']?.toString() ?? 'FFFFFF',
    );

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
    if (route['alerts'] is List) {
      for (final alert in route['alerts']) {
        if (alert is Map) {
          final id = alert['id']?.toString() ?? '';
          if (id.isEmpty || seenIds.add(id)) {
            combinedAlerts.add(alert);
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      title,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleMedium,
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
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AlertsSection(alerts: combinedAlerts),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TripStopTimesList(
                  stopTimes: stopTimes,
                  serviceDay: serviceDay,
                  onStopTap: onStopTap,
                ),
                TripDetailsAdditionalInfo(
                  trip: trip,
                  serviceDay: serviceDay,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
