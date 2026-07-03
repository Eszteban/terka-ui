import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';

import '../maps/route_map_data.dart';
import '../../screens/trip_details/trip_details_screen.dart';
import '../../theme/app_texts.dart';
import '../../utils/markup_text_utils.dart';
import '../../models/ticket_item.dart';
import '../../utils/adaptive_dialog_utils.dart';

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

class DummyTable extends StatelessWidget {
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

  const DummyTable({
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
    final itineraries = _extractItineraries(responseText);
    final summaryLabel = _buildResultsHeader(itineraries);

    if (desktopInlineMapMode &&
        !hasDesktopMapSelection &&
        itineraries.isNotEmpty) {
      final firstItinerary = itineraries.first;
      final firstSummary = _buildSummary(firstItinerary);
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
                          final summary = _buildSummary(itinerary);
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
        fromName = _plainTextFromHtml(
          _nestedString(legMaps.first, ['from', 'name']) ?? AppTexts.unknown,
        ).trim();
        toName = _plainTextFromHtml(
          _nestedString(legMaps.last, ['to', 'name']) ?? AppTexts.unknown,
        ).trim();
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

  List<Map<String, dynamic>> _extractItineraries(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        return const [];
      }

      final data = decoded['data'];
      if (data is! Map) {
        return const [];
      }

      final plan = data['plan'];
      if (plan is! Map) {
        return const [];
      }

      final itineraries = plan['itineraries'];
      if (itineraries is! List) {
        return const [];
      }

      return itineraries
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, String> _buildSummary(Map<String, dynamic> itinerary) {
    final duration = itinerary['duration'];
    final transfers = itinerary['numberOfTransfers'];
    final start = itinerary['startTime'];
    final end = itinerary['endTime'];

    return {
      'duration': _formatDuration(duration),
      'transfers': transfers?.toString() ?? '-',
      'start': _formatEpochMillis(start),
      'end': _formatEpochMillis(end),
    };
  }

  List<Widget> _buildLegTiles(
    BuildContext context,
    Map<String, dynamic> itinerary,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
      final fromName = _nestedString(leg, ['from', 'name']) ?? AppTexts.unknown;
      final toName = _nestedString(leg, ['to', 'name']) ?? AppTexts.unknown;
      final mode = leg['mode']?.toString() ?? '-';
      final duration = _formatDuration(leg['duration']);
      final startTime = _formatEpochMillis(leg['startTime']);
      final endTime = _formatEpochMillis(leg['endTime']);
      final lineNumber = _legLineNumber(leg);
      final tripNumber = _legTripDisplayNumber(leg);
      final titleStyle = Theme.of(context).textTheme.titleMedium;
      final subtitleStyle = Theme.of(context).textTheme.bodyMedium;
      final routeColor = _parseRouteColor(leg);
      final routeTextColor = _parseRouteTextColor(
        leg,
        fallback: _idealTextColor(routeColor),
      );

      final isWalkLeg = mode.toUpperCase().trim() == 'WALK';
      final waitMinutes = isWalkLeg
          ? _waitingMinutesUntilNextTransit(leg, nextLeg)
          : null;

      final rawTripId = _nestedString(leg, ['trip', 'gtfsId']) ?? '';
      final tripId = rawTripId.trim();
      final serviceDayRaw = _nestedString(leg, ['serviceDate']) ?? '';
      final serviceDay = serviceDayRaw.trim().isNotEmpty
          ? serviceDayRaw.trim()
          : _todayServiceDate();
      final canOpenTrip = !isWalkLeg && tripId.isNotEmpty;

      final leftTile = Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isWalkLeg
              ? (isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ))
              : routeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isWalkLeg
                ? colorScheme.outlineVariant.withValues(alpha: 0.15)
                : routeColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isWalkLeg ? AppTexts.tableWalk : AppTexts.tableTransit,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isWalkLeg
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                    : routeColor,
              ),
            ),
            const SizedBox(height: 6),
            if (isWalkLeg)
              Icon(
                _iconForMode(mode),
                size: 24,
                color: colorScheme.onSurfaceVariant,
              )
            else
              _containsSpanMarkup(lineNumber)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      decoration: BoxDecoration(
                        color: routeColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _plainTextFromHtml(lineNumber),
                        style: TextStyle(
                          color: routeTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          height: 1.0,
                          fontFamily: _spanFontFamily,
                          leadingDistribution: TextLeadingDistribution.even,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: routeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _plainTextFromHtml(lineNumber),
                        style: TextStyle(
                          color: routeTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
            const SizedBox(height: 8),
            Text(
              duration,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isWalkLeg
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );

      final rightTile = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerLowest.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isWalkLeg ? AppTexts.tableWalkDetails : AppTexts.tableTransitDetails,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: titleStyle?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                      children: [
                        ..._buildSpanAwareInlineSpans(fromName, titleStyle),
                        const TextSpan(text: ' → '),
                        ..._buildSpanAwareInlineSpans(toName, titleStyle),
                      ],
                    ),
                  ),
                ),
                if (canOpenTrip)
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '$startTime - $endTime',
                  style: subtitleStyle?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (isWalkLeg)
              Text(
                waitMinutes != null && waitMinutes > 0
                    ? AppTexts.tableWaitThen('$waitMinutes')
                    : AppTexts.tableWalkSubtitle,
                style: subtitleStyle?.copyWith(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              )
            else
              Text(
                AppTexts.tableTripId(tripNumber),
                style: subtitleStyle?.copyWith(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canOpenTrip
                ? () => _openTripDetails(
                    context,
                    tripId: tripId,
                    serviceDay: serviceDay,
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftTile,
                  const SizedBox(width: 8),
                  Expanded(child: rightTile),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Future<void> _openTripDetails(
    BuildContext context, {
    required String tripId,
    required String serviceDay,
  }) async {
    if (onOpenTripDetailsRequested != null) {
      onOpenTripDetailsRequested!(tripId, serviceDay);
      return;
    }

    final isDesktop =
        desktopInlineMapMode &&
        MediaQuery.of(context).size.width > _desktopBreakpoint;

    if (isDesktop) {
      await showAdaptiveDetailsDialog<void>(
        context: context,
        child: TripDetailsScreen(
          tripId: tripId,
          serviceDay: serviceDay,
          onShowOnBackgroundMap: onShowTripOnMap,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailsScreen(
          tripId: tripId,
          serviceDay: serviceDay,
          onShowOnBackgroundMap: onShowTripOnMap,
        ),
      ),
    );
  }

  String _todayServiceDate() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  int? _durationMinutes(dynamic secondsValue) {
    if (secondsValue is! num) {
      return null;
    }
    return (secondsValue / 60).round();
  }

  int? _waitingMinutesUntilNextTransit(
    Map<String, dynamic> currentLeg,
    Map<String, dynamic>? nextLeg,
  ) {
    if (nextLeg == null) {
      return null;
    }

    final nextMode = nextLeg['mode']?.toString() ?? '';
    if (nextMode.toUpperCase().trim() == 'WALK') {
      return null;
    }

    final currentEnd = currentLeg['endTime'];
    final nextStart = nextLeg['startTime'];
    if (currentEnd is! num || nextStart is! num) {
      return null;
    }

    final diffMillis = nextStart.toInt() - currentEnd.toInt();
    if (diffMillis <= 0) {
      return null;
    }

    return (diffMillis / 60000).round();
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

      final plainLineNumber = _plainTextFromHtml(lineNumber).trim();
      if (plainLineNumber.isEmpty || plainLineNumber == '-') {
        continue;
      }

      final backgroundColor = _parseRouteColor(map);
      final textColor = _parseRouteTextColor(
        map,
        fallback: _idealTextColor(backgroundColor),
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
            color: _parseRouteColorForMap(leg),
            isWalk: mode.toUpperCase().trim() == 'WALK',
          ),
        );
      }
    }

    final firstFromPoint = _extractPoint(legMaps.first['from']);
    final firstFromName =
        _nestedString(legMaps.first, ['from', 'name']) ?? AppTexts.formDeparture;
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
          _nestedString(legMaps[i], ['to', 'name']) ?? AppTexts.formTransfers;
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
    final lastToName = _nestedString(legMaps.last, ['to', 'name']) ?? AppTexts.formArrival;
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
        fromName = _nestedString(legMaps.first, ['from', 'name']) ?? fromName;
        toName = _nestedString(legMaps.last, ['to', 'name']) ?? toName;
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

    final from = _plainTextFromHtml(
      _nestedString(legMaps.first, ['from', 'name']) ?? AppTexts.unknown,
    ).trim();
    final to = _plainTextFromHtml(
      _nestedString(legMaps.last, ['to', 'name']) ?? AppTexts.unknown,
    ).trim();

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
      final fromName = _plainTextFromHtml(
        _nestedString(leg, ['from', 'name']) ?? AppTexts.unknown,
      ).trim();
      final toName = _plainTextFromHtml(
        _nestedString(leg, ['to', 'name']) ?? AppTexts.unknown,
      ).trim();
      final mode = leg['mode']?.toString() ?? '-';
      final duration = _formatDuration(leg['duration']);
      final tripNumber = _plainTextFromHtml(_legTripDisplayNumber(leg)).trim();

      final isWalkLeg = mode.toUpperCase().trim() == 'WALK';
      final walkMinutes = _durationMinutes(leg['duration']);
      final waitMinutes = isWalkLeg
          ? _waitingMinutesUntilNextTransit(leg, nextLeg)
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
        final decoded = _decodePolyline(encoded);
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

  Color _parseRouteColor(Map<String, dynamic> leg) {
    final route = leg['route'];
    if (route is Map) {
      final colorValue = route['color'];
      if (colorValue is String && colorValue.isNotEmpty) {
        final routeColor = _parseHexColor(colorValue);
        if (routeColor != null) {
          return routeColor;
        }
      }
    }
    return Colors.blue;
  }

  Color _parseRouteColorForMap(Map<String, dynamic> leg) {
    final route = leg['route'];
    if (route is Map) {
      final colorValue = route['color'];
      final textColorValue = route['textColor'];

      final routeColor = colorValue is String
          ? _parseHexColor(colorValue)
          : null;
      final routeTextColor = textColorValue is String
          ? _parseHexColor(textColorValue)
          : null;

      if (routeColor != null) {
        final routeIsWhite = _isWhiteColor(routeColor);
        final textIsNonWhite =
            routeTextColor != null && !_isWhiteColor(routeTextColor);
        if (routeIsWhite && textIsNonWhite) {
          return routeTextColor;
        }
        return routeColor;
      }
    }
    return Colors.blue;
  }

  Color? _parseHexColor(String value) {
    final hex = value.replaceAll('#', '').trim();
    if (hex.length != 6) {
      return null;
    }

    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) {
      return null;
    }

    return Color(0xFF000000 | parsed);
  }

  bool _isWhiteColor(Color color) {
    final isPureWhite =
        color.red == 255 && color.green == 255 && color.blue == 255;
    final isNearWhite =
        color.red == 254 && color.green == 254 && color.blue == 254;
    return isPureWhite || isNearWhite;
  }

  Color _parseRouteTextColor(
    Map<String, dynamic> leg, {
    required Color fallback,
  }) {
    final route = leg['route'];
    if (route is Map) {
      final textColorValue = route['textColor'];
      if (textColorValue is String && textColorValue.isNotEmpty) {
        final parsedColor = _parseHexColor(textColorValue);
        if (parsedColor != null) {
          return parsedColor;
        }
      }
    }
    return fallback;
  }

  Color _idealTextColor(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }

  String _legLineNumber(Map<String, dynamic> leg) {
    return _nestedString(leg, ['route', 'shortName']) ??
        _nestedString(leg, ['route', 'longName']) ??
        '-';
  }

  String _legTripDisplayNumber(Map<String, dynamic> leg) {
    return _nestedString(leg, ['trip', 'tripShortName']) ?? _legLineNumber(leg);
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

  List<LatLng> _decodePolyline(String encoded) {
    final result = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var b = 0;
      var shift = 0;
      var value = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        value |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final deltaLat = (value & 1) != 0 ? ~(value >> 1) : (value >> 1);
      lat += deltaLat;

      shift = 0;
      value = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        value |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < encoded.length);
      final deltaLng = (value & 1) != 0 ? ~(value >> 1) : (value >> 1);
      lng += deltaLng;

      result.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return result;
  }

  String _formatDuration(dynamic secondsValue) {
    if (secondsValue is! num) {
      return '-';
    }
    final totalMinutes = (secondsValue / 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours == 0) {
      return AppTexts.tableMinutes('$minutes');
    }
    return AppTexts.tableHoursMinutes('$hours', '$minutes');
  }

  String _formatEpochMillis(dynamic millisValue) {
    if (millisValue is! num) {
      return '-';
    }
    final dateTime = DateTime.fromMillisecondsSinceEpoch(millisValue.toInt());
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String? _nestedString(Map<String, dynamic> map, List<String> path) {
    dynamic current = map;
    for (final key in path) {
      if (current is! Map || !current.containsKey(key)) {
        return null;
      }
      current = current[key];
    }
    return current is String ? current : null;
  }

  bool _containsSpanMarkup(String value) {
    return containsSpanMarkup(value);
  }

  List<InlineSpan> _buildSpanAwareInlineSpans(
    String raw,
    TextStyle? baseStyle,
  ) {
    final spanPattern = RegExp(
      r'<span[^>]*>(.*?)</span>',
      caseSensitive: false,
      dotAll: true,
    );

    final result = <InlineSpan>[];
    var lastEnd = 0;
    for (final match in spanPattern.allMatches(raw)) {
      final before = raw.substring(lastEnd, match.start);
      final beforeText = _plainTextFromHtml(before);
      if (beforeText.isNotEmpty) {
        result.add(TextSpan(text: beforeText));
      }

      final spanContent = match.group(1) ?? '';
      final spanText = _plainTextFromHtml(spanContent);
      if (spanText.isNotEmpty) {
        result.add(
          TextSpan(
            text: spanText,
            style: (baseStyle ?? const TextStyle()).copyWith(
              fontFamily: _spanFontFamily,
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    final tail = raw.substring(lastEnd);
    final tailText = _plainTextFromHtml(tail);
    if (tailText.isNotEmpty) {
      result.add(TextSpan(text: tailText));
    }

    if (result.isEmpty) {
      result.add(TextSpan(text: _plainTextFromHtml(raw)));
    }

    return result;
  }

  String _plainTextFromHtml(String input) {
    return plainTextFromHtml(input);
  }
}
