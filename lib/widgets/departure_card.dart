import 'package:flutter/material.dart';
import '../utils/stop_details_utils.dart';
import '../theme/app_texts.dart';
import 'line_badge.dart';

class DepartureCard extends StatelessWidget {
  static const String spanFontFamily = 'MNR2007';
  static const double spanFontScale = 28 / 16;

  final Map<String, dynamic> departure;
  final DateTime now;
  final VoidCallback? onTap;

  const DepartureCard({
    super.key,
    required this.departure,
    required this.now,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trip = departure['trip'];
    final route = trip is Map ? trip['route'] : null;

    final rawRouteShortName =
        route is Map ? (route['shortName']?.toString() ?? '-') : '-';
    final routeShortName = StopDetailsUtils.plainText(
      rawRouteShortName,
    );
    final routeShortNameUsesSpanFont = StopDetailsUtils.containsSpanMarkup(rawRouteShortName);
    final rawHeadsign = trip is Map
        ? (trip['tripHeadsign']?.toString() ??
            departure['headsign']?.toString() ??
            '-')
        : (departure['headsign']?.toString() ?? '-');
    final headsign = StopDetailsUtils.plainText(
      rawHeadsign,
    );
    final headsignUsesSpanFont = StopDetailsUtils.containsSpanMarkup(rawHeadsign);

    final scheduledArrival = StopDetailsUtils.resolveDepartureTime(
      serviceDay: StopDetailsUtils.asNum(departure['serviceDay']),
      secondsOfDay: StopDetailsUtils.asNum(departure['scheduledArrival']),
    );
    final realtimeArrival = StopDetailsUtils.resolveDepartureTime(
      serviceDay: StopDetailsUtils.asNum(departure['serviceDay']),
      secondsOfDay: StopDetailsUtils.asNum(departure['realtimeArrival']),
    );
    final scheduledDeparture = StopDetailsUtils.resolveDepartureTime(
      serviceDay: StopDetailsUtils.asNum(departure['serviceDay']),
      secondsOfDay: StopDetailsUtils.asNum(departure['scheduledDeparture']),
    );
    final realtimeDeparture = StopDetailsUtils.resolveDepartureTime(
      serviceDay: StopDetailsUtils.asNum(departure['serviceDay']),
      secondsOfDay: StopDetailsUtils.asNum(departure['realtimeDeparture']),
    );

    final isArrivalByType = StopDetailsUtils.isArrivalEntry(departure);
    final isDepartureByType = StopDetailsUtils.isDepartureEntry(departure);
    final eventLabel = isArrivalByType && isDepartureByType
        ? AppTexts.stopArrivalDeparture
        : isArrivalByType
            ? AppTexts.stopArrivals
            : isDepartureByType
                ? AppTexts.stopDepartures
                : AppTexts.stopTimeLabel;

    final hasDeparture =
        StopDetailsUtils.asNum(departure['scheduledDeparture']) != null ||
        StopDetailsUtils.asNum(departure['realtimeDeparture']) != null;

    final scheduled = hasDeparture ? scheduledDeparture : scheduledArrival;
    final realtime = hasDeparture ? realtimeDeparture : realtimeArrival;

    final isPast = StopDetailsUtils.isPastDeparture(departure, now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delay = hasDeparture
        ? StopDetailsUtils.asNum(departure['departureDelay'])
        : StopDetailsUtils.asNum(departure['arrivalDelay']);
    final isRealtime = departure['realtime'] == true;
    final isOnTime = (delay ?? 0) == 0;
    final realtimeColor = isPast
        ? Colors.grey
        : !isRealtime
            ? (isDark ? Colors.white : Colors.black)
            : isOnTime
                ? Colors.green
                : (delay ?? 0) < 0
                    ? Colors.blue
                    : Colors.red;

    final scheduledArrivalSecs = StopDetailsUtils.asNum(departure['scheduledArrival']);
    final scheduledDepartureSecs = StopDetailsUtils.asNum(departure['scheduledDeparture']);
    final hasBothScheduledTimes = scheduledArrivalSecs != null && scheduledDepartureSecs != null;
    final scheduledTimesDiffer = hasBothScheduledTimes && scheduledArrivalSecs != scheduledDepartureSecs;

    final arrDelay = StopDetailsUtils.asNum(departure['arrivalDelay']);
    final isArrivalOnTime = (arrDelay ?? 0) == 0;
    final realtimeArrivalColor = isPast
        ? Colors.grey
        : !isRealtime
            ? (isDark ? Colors.white : Colors.black)
            : isArrivalOnTime
                ? Colors.green
                : (arrDelay ?? 0) < 0
                    ? Colors.blue
                    : Colors.red;

    final depDelay = StopDetailsUtils.asNum(departure['departureDelay']);
    final isDepartureOnTime = (depDelay ?? 0) == 0;
    final realtimeDepartureColor = isPast
        ? Colors.grey
        : !isRealtime
            ? (isDark ? Colors.white : Colors.black)
            : isDepartureOnTime
                ? Colors.green
                : (depDelay ?? 0) < 0
                    ? Colors.blue
                    : Colors.red;

    final platformCode = departure['stop'] is Map
        ? (departure['stop']['platformCode']?.toString().trim() ?? '')
        : '';
    final hasPlatformCode = platformCode.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LineBadge(
                  lineLabel: routeShortName,
                  routeColor: StopDetailsUtils.hexColor(
                    route is Map ? route['color']?.toString() ?? '0A84FF' : '0A84FF',
                  ),
                  routeTextColor: StopDetailsUtils.hexColor(
                    route is Map
                        ? route['textColor']?.toString() ?? 'FFFFFF'
                        : 'FFFFFF',
                  ),
                  useSpanFont: routeShortNameUsesSpanFont,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headsign,
                        softWrap: true,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: headsignUsesSpanFont
                              ? 14 * spanFontScale
                              : null,
                          fontFamily:
                              headsignUsesSpanFont ? spanFontFamily : null,
                          leadingDistribution: headsignUsesSpanFont
                              ? TextLeadingDistribution.even
                              : null,
                          height: headsignUsesSpanFont ? 1.0 : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eventLabel,
                        style: TextStyle(
                          color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasPlatformCode)
                        Text(
                          AppTexts.stopPlatform(platformCode),
                          style: TextStyle(
                            color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (scheduledTimesDiffer) ...[
                        Row(
                          children: [
                            Text(
                              '${AppTexts.tripArrivalColumn} ',
                              style: TextStyle(
                                color: isPast ? Colors.grey : (isDark ? Colors.white70 : Colors.black54),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              StopDetailsUtils.formatTime(scheduledArrival),
                              style: TextStyle(
                                color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black),
                                decoration: (scheduledArrival != null && realtimeArrival != null &&
                                        scheduledArrival != realtimeArrival)
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              StopDetailsUtils.formatTime(realtimeArrival),
                              style: TextStyle(
                                color: realtimeArrivalColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${AppTexts.tripDepartureColumn} ',
                              style: TextStyle(
                                color: isPast ? Colors.grey : (isDark ? Colors.white70 : Colors.black54),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              StopDetailsUtils.formatTime(scheduledDeparture),
                              style: TextStyle(
                                color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black),
                                decoration: (scheduledDeparture != null && realtimeDeparture != null &&
                                        scheduledDeparture != realtimeDeparture)
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              StopDetailsUtils.formatTime(realtimeDeparture),
                              style: TextStyle(
                                color: realtimeDepartureColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Text(
                              StopDetailsUtils.formatTime(scheduled),
                              style: TextStyle(
                                color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black),
                                decoration: (scheduled != null && realtime != null &&
                                        scheduled != realtime)
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              StopDetailsUtils.formatTime(realtime),
                              style: TextStyle(
                                color: realtimeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
