import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../maps/route_map_data.dart';
import '../../theme/app_texts.dart';
import '../../models/ticket_item.dart';
import '../../utils/route_mapping_utils.dart';
import '../../utils/route_data_utils.dart';
import '../../utils/markup_text_utils.dart';
import '../../screens/trip_details/trip_details_screen.dart';
import '../itinerary_leg_tile.dart';
import '../../extensions/string_html_cleaner.dart';

class SelectedItineraryMapPayload {
  final RouteMapData routeData;
  final String title;
  final String subtitle;
  final List<SelectedItineraryLegDetail> legDetails;

  const SelectedItineraryMapPayload({
    required this.routeData,
    required this.title,
    required this.subtitle,
    required this.legDetails,
  });
}

class SelectedItineraryLegDetail {
  final IconData icon;
  final String fromName;
  final String toName;
  final String subtitle;

  const SelectedItineraryLegDetail({
    required this.icon,
    required this.fromName,
    required this.toName,
    required this.subtitle,
  });
}

class RoutePlannerResultsView extends StatelessWidget {
  static const String _spanFontFamily = 'MNR2007';
  static const double _desktopBreakpoint = 600;

  final String responseText;
  final ValueChanged<SelectedItineraryMapPayload> onShowOnMap;
  final TripDetailsBackgroundMapCallback? onShowTripOnMap;
  final bool desktopInlineMapMode;
  final bool hasDesktopMapSelection;
  final bool canLoadMore;
  final bool isLoadingMore;
  final Future<void> Function()? onLoadMore;
  final bool ticketWatch;
  final List<TicketItem> tickets;
  final Function(String, String)? onOpenTripDetailsRequested;

  const RoutePlannerResultsView({
    super.key,
    required this.responseText,
    required this.onShowOnMap,
    this.onShowTripOnMap,
    this.desktopInlineMapMode = false,
    this.hasDesktopMapSelection = false,
    this.canLoadMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.ticketWatch = false,
    this.tickets = const [],
    this.onOpenTripDetailsRequested,
  });

  @override
  Widget build(BuildContext context) {
    final itineraries = RouteDataUtils.extractItineraries(responseText);
    final summaryLabel = _buildResultsHeader(itineraries);

    if (desktopInlineMapMode &&
        !hasDesktopMapSelection &&
        itineraries.isNotEmpty) {
      final firstItinerary = itineraries.first;
      final firstSummary = RouteDataUtils.buildSummary(firstItinerary);
      final firstMapData = _buildRouteMapData(firstItinerary);
      if (firstMapData.hasContent) {
        final firstPayload = _buildMapPayload(
          firstItinerary,
          firstSummary,
          firstMapData,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onShowOnMap(firstPayload);
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summaryLabel, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Expanded(
          child: itineraries.isEmpty
              ? Card(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 220),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(responseText),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: itineraries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final itinerary = itineraries[index];
                          final summary = RouteDataUtils.buildSummary(itinerary);
                          final mapData = _buildRouteMapData(itinerary);
                          final lineBadges = _buildLineBadges(itinerary);
                          final mapPayload = _buildMapPayload(
                            itinerary,
                            summary,
                            mapData,
                          );

                          final colorScheme = Theme.of(context).colorScheme;
                          final isDark = Theme.of(context).brightness == Brightness.dark;

                          final missingAgencies = ticketWatch
                               ? TicketItem.getMissingTicketAgencies(itinerary, tickets)
                               : const <String>[];
                           final hasTickets = ticketWatch ? missingAgencies.isEmpty : false;
                           final borderSideColor = ticketWatch
                               ? (hasTickets ? (isDark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32)) : (isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828)))
                               : colorScheme.outlineVariant.withValues(alpha: 0.3);
                           final borderSideWidth = ticketWatch ? 2.0 : 1.0;

                           return Card(
                             margin: const EdgeInsets.symmetric(vertical: 6),
                             clipBehavior: Clip.antiAlias,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(16),
                               side: BorderSide(
                                 color: borderSideColor,
                                 width: borderSideWidth,
                               ),
                             ),
                             child: Padding(
                               padding: const EdgeInsets.all(12),
                               child: ExpansionTile(
                                 shape: const Border(),
                                 collapsedShape: const Border(),
                                 tilePadding: EdgeInsets.zero,
                                 onExpansionChanged: desktopInlineMapMode
                                     ? (expanded) {
                                         if (expanded && mapData.hasContent) {
                                           onShowOnMap(mapPayload);
                                         }
                                       }
                                     : null,
                                 title: _buildBentoHeader(
                                   context,
                                   itinerary,
                                   summary,
                                   lineBadges,
                                   missingAgencies,
                                 ),
                                 childrenPadding: const EdgeInsets.fromLTRB(
                                   0,
                                   12,
                                   0,
                                   0,
                                 ),
                                 children: [
                                   ..._buildLegTiles(context, itinerary),
                                   if (!desktopInlineMapMode) ...[
                                     const SizedBox(height: 12),
                                     SizedBox(
                                       width: double.infinity,
                                       child: FilledButton.icon(
                                           onPressed: mapData.hasContent
                                               ? () => onShowOnMap(mapPayload)
                                               : null,
                                           icon: const Icon(Icons.map),
                                           label: Text(AppTexts.tableShowOnMap),
                                         ),
                                       ),
                                     ],
                                 ],
                               ),
                             ),
                           );
                        },
                      ),
                    ),
                    if (canLoadMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: isLoadingMore
                                ? null
                                : () => onLoadMore?.call(),
                            child: isLoadingMore
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(AppTexts.tableLoadMore),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildBentoHeader(
    BuildContext context,
    Map<String, dynamic> itinerary,
    Map<String, String> summary,
    List<Widget> lineBadges,
    List<String> missingAgencies,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final durationTimeBg = isDark
        ? colorScheme.primaryContainer.withValues(alpha: 0.12)
        : colorScheme.primaryContainer.withValues(alpha: 0.4);
    final linesBg = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final legs = itinerary['legs'];
    String fromName = AppTexts.unknown;
    String toName = AppTexts.unknown;

    if (legs is List && legs.isNotEmpty) {
      final legMaps = legs
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      if (legMaps.isNotEmpty) {
        fromName = (RouteDataUtils.nestedString(legMaps.first, ['from', 'name']) ?? AppTexts.unknown).toPlainTextFromHtml().trim();
        toName = (RouteDataUtils.nestedString(legMaps.last, ['to', 'name']) ?? AppTexts.unknown).toPlainTextFromHtml().trim();
      }
    }

    final durationTimeTile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: durationTimeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppTexts.tableDurationHeader,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summary['duration'] ?? '-',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 13,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                '${summary['start']} - ${summary['end']}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final transferText = summary['transfers'] == '0'
        ? AppTexts.tableDirect
        : AppTexts.tableTransfersCount(summary['transfers']!);

    final linesTile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: linesBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${AppTexts.tableTransitHeader} • ${transferText.toUpperCase()}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          if (lineBadges.isNotEmpty)
            Wrap(spacing: 4, runSpacing: 4, children: lineBadges)
          else
            Text(
              AppTexts.tableWalkMode,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );

    final routeHeader = Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.directions_transit_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$fromName → $toName',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        routeHeader,
        durationTimeTile,
        const SizedBox(height: 6),
        linesTile,
        if (missingAgencies.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C1E1D) : const Color(0xFFFDE8E8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFFEF5350).withOpacity(0.3) : const Color(0xFFE57373).withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppTexts.ticketsMissingFor(missingAgencies.join(", ")),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildLegTiles(
    BuildContext context,
    Map<String, dynamic> itinerary,
  ) {
    final legs = itinerary['legs'];
    if (legs is! List) {
      return [
        ListTile(dense: true, title: Text(AppTexts.tableSegmentNotAvailable)),
      ];
    }

    final legMaps = legs
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    return List<Widget>.generate(legMaps.length, (index) {
      final leg = legMaps[index];
      final nextLeg = index + 1 < legMaps.length ? legMaps[index + 1] : null;
      return ItineraryLegTile(
        leg: leg,
        nextLeg: nextLeg,
        serviceDay: '',
        desktopInlineMapMode: desktopInlineMapMode,
        desktopBreakpoint: _desktopBreakpoint,
        onShowTripOnMap: onShowTripOnMap,
        onOpenTripDetailsRequested: onOpenTripDetailsRequested,
      );
    });
  }

  List<Widget> _buildLineBadges(Map<String, dynamic> itinerary) {
    final legs = itinerary['legs'];
    if (legs is! List) {
      return const [];
    }

    final badges = <Widget>[];

    for (final leg in legs.whereType<Map>()) {
      final map = leg.cast<String, dynamic>();
      final lineNumber = _legLineNumber(map);
      if (lineNumber == '-') {
        continue;
      }

      final plainLineNumber = lineNumber.toPlainTextFromHtml().trim();
      if (plainLineNumber.isEmpty || plainLineNumber == '-') {
        continue;
      }

      final backgroundColor = RouteMappingUtils.parseRouteColor(map);
      final textColor = RouteMappingUtils.parseRouteTextColor(
        map,
        fallback: RouteMappingUtils.idealTextColor(backgroundColor),
      );

      badges.add(
        _containsSpanMarkup(lineNumber)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  plainLineNumber,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    height: 1.0,
                    fontFamily: _spanFontFamily,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  plainLineNumber,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
      );
    }

    return badges;
  }

  RouteMapData _buildRouteMapData(Map<String, dynamic> itinerary) {
    final legs = itinerary['legs'];
    if (legs is! List || legs.isEmpty) {
      return const RouteMapData(segments: [], stops: []);
    }

    final legMaps = legs
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    final segments = <RouteSegment>[];
    final stops = <RouteStopMarker>[];

    for (final leg in legMaps) {
      final legPoints = _extractLegPoints(leg);
      if (legPoints.length >= 2) {
        final mode = leg['mode']?.toString() ?? '';
        segments.add(
          RouteSegment(
            points: legPoints,
            color: RouteMappingUtils.parseRouteColorForMap(leg),
            isWalk: mode.toUpperCase().trim() == 'WALK',
          ),
        );
      }
    }

    final firstFromPoint = _extractPoint(legMaps.first['from']);
    final firstFromName =
        RouteDataUtils.nestedString(legMaps.first, ['from', 'name']) ?? AppTexts.formDeparture;
    if (firstFromPoint != null) {
      stops.add(
        RouteStopMarker(
          point: firstFromPoint,
          label: firstFromName,
          type: RouteStopType.start,
        ),
      );
    }

    for (var i = 0; i < legMaps.length - 1; i++) {
      final transferPoint = _extractPoint(legMaps[i]['to']);
      final transferName =
          RouteDataUtils.nestedString(legMaps[i], ['to', 'name']) ?? AppTexts.formTransfers;
      if (transferPoint != null) {
        stops.add(
          RouteStopMarker(
            point: transferPoint,
            label: transferName,
            type: RouteStopType.transfer,
          ),
        );
      }
    }

    final lastToPoint = _extractPoint(legMaps.last['to']);
    final lastToName = RouteDataUtils.nestedString(legMaps.last, ['to', 'name']) ?? AppTexts.formArrival;
    if (lastToPoint != null) {
      stops.add(
        RouteStopMarker(
          point: lastToPoint,
          label: lastToName,
          type: RouteStopType.end,
        ),
      );
    }

    return RouteMapData(segments: segments, stops: stops);
  }

  SelectedItineraryMapPayload _buildMapPayload(
    Map<String, dynamic> itinerary,
    Map<String, String> summary,
    RouteMapData routeData,
  ) {
    final legs = itinerary['legs'];
    String fromName = AppTexts.unknown;
    String toName = AppTexts.unknown;

    if (legs is List && legs.isNotEmpty) {
      final legMaps = legs
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      if (legMaps.isNotEmpty) {
        fromName = RouteDataUtils.nestedString(legMaps.first, ['from', 'name']) ?? fromName;
        toName = RouteDataUtils.nestedString(legMaps.last, ['to', 'name']) ?? toName;
      }
    }

    return SelectedItineraryMapPayload(
      routeData: routeData,
      title: '$fromName → $toName',
      subtitle: AppTexts.tableSubtitle(
        summary['duration']!,
        summary['transfers']!,
        summary['start']!,
        summary['end']!,
      ),
      legDetails: _buildLegDetails(itinerary),
    );
  }

  String _buildResultsHeader(List<Map<String, dynamic>> itineraries) {
    if (itineraries.isEmpty) {
      return AppTexts.tableResults;
    }

    final firstItinerary = itineraries.first;
    final legs = firstItinerary['legs'];
    if (legs is! List || legs.isEmpty) {
      return AppTexts.tableResults;
    }

    final legMaps = legs
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    if (legMaps.isEmpty) {
      return AppTexts.tableResults;
    }

    final from = (RouteDataUtils.nestedString(legMaps.first, ['from', 'name']) ?? AppTexts.unknown).toPlainTextFromHtml().trim();
    final to = (RouteDataUtils.nestedString(legMaps.last, ['to', 'name']) ?? AppTexts.unknown).toPlainTextFromHtml().trim();

    if (from.isEmpty || to.isEmpty) {
      return AppTexts.tableResults;
    }

    return AppTexts.tableResultsHeader(from, to);
  }

  List<SelectedItineraryLegDetail> _buildLegDetails(
    Map<String, dynamic> itinerary,
  ) {
    final legs = itinerary['legs'];
    if (legs is! List) {
      return const [];
    }

    final legMaps = legs
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    return List<SelectedItineraryLegDetail>.generate(legMaps.length, (index) {
      final leg = legMaps[index];
      final nextLeg = index + 1 < legMaps.length ? legMaps[index + 1] : null;
      final fromName = (RouteDataUtils.nestedString(leg, ['from', 'name']) ?? AppTexts.unknown).toPlainTextFromHtml().trim();
      final toName = (RouteDataUtils.nestedString(leg, ['to', 'name']) ?? AppTexts.unknown).toPlainTextFromHtml().trim();
      final mode = leg['mode']?.toString() ?? '-';
      final duration = RouteDataUtils.formatDuration(leg['duration']);
      final tripNumber = RouteDataUtils.nestedString(leg, ['trip', 'tripShortName']) ?? _legLineNumber(leg);

      final isWalkLeg = mode.toUpperCase().trim() == 'WALK';
      final walkMinutes = RouteDataUtils.durationMinutes(leg['duration']);
      final waitMinutes = isWalkLeg
          ? RouteDataUtils.waitingMinutesUntilNextTransit(leg, nextLeg)
          : null;

      final subtitle = isWalkLeg
          ? '${AppTexts.tableMinutes('${walkMinutes ?? 0}')} ${AppTexts.tableWalkSubtitle}${waitMinutes != null && waitMinutes > 0 ? ', ${AppTexts.tableWaitThen('$waitMinutes')}' : ''}'
          : '${AppTexts.trip}: $tripNumber • $duration';

      return SelectedItineraryLegDetail(
        icon: _iconForMode(mode),
        fromName: fromName,
        toName: toName,
        subtitle: subtitle,
      );
    });
  }

  List<LatLng> _extractLegPoints(Map<String, dynamic> leg) {
    final legGeometry = leg['legGeometry'];
    if (legGeometry is Map) {
      final encoded = legGeometry['points'];
      if (encoded is String && encoded.isNotEmpty) {
        final decoded = RouteMappingUtils.decodePolyline(encoded);
        if (decoded.length >= 2) {
          return decoded;
        }
      }
    }

    final fromPoint = _extractPoint(leg['from']);
    final toPoint = _extractPoint(leg['to']);
    if (fromPoint != null && toPoint != null) {
      return [fromPoint, toPoint];
    }
    return const [];
  }

  LatLng? _extractPoint(dynamic node) {
    if (node is! Map) {
      return null;
    }
    final lat = node['lat'];
    final lon = node['lon'];
    if (lat is num && lon is num) {
      return LatLng(lat.toDouble(), lon.toDouble());
    }
    return null;
  }

  String _legLineNumber(Map<String, dynamic> leg) {
    return RouteDataUtils.nestedString(leg, ['route', 'shortName']) ??
        RouteDataUtils.nestedString(leg, ['route', 'longName']) ??
        '-';
  }

  IconData _iconForMode(String mode) {
    switch (mode.toUpperCase().trim()) {
      case 'RAIL':
      case 'SUBURBAN_RAILWAY':
        return Icons.train;
      case 'RAIL_REPLACEMENT_BUS':
        return Icons.bus_alert;
      case 'BUS':
        return Icons.airport_shuttle;
      case 'COACH':
        return Icons.directions_bus;
      case 'SUBWAY':
        return Icons.directions_subway;
      case 'TRAM':
      case 'TRAMTRAIN':
        return Icons.tram;
      case 'TROLLEYBUS':
        return Icons.directions_bus;
      case 'FERRY':
        return Icons.directions_boat;
      case 'WALK':
        return Icons.hiking;
      default:
        return Icons.alt_route;
    }
  }

  bool _containsSpanMarkup(String value) {
    return containsSpanMarkup(value);
  }
}
