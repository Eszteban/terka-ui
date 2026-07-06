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
  final bool isArrivalView;

  const DepartureCard({
    super.key,
    required this.departure,
    required this.now,
    this.onTap,
    this.isArrivalView = false,
  });

  @override
  Widget build(BuildContext context) {
    final trip = departure['trip'];
    final route = trip is Map ? trip['route'] : null;

    final isWheelchair = trip is Map &&
        (trip['wheelchairAccessible']?.toString().toUpperCase() == 'POSSIBLE' ||
         trip['wheelchairAccessible']?.toString().toUpperCase() == 'ALLOWED');
    final isBike = trip is Map &&
        trip['bikesAllowed']?.toString().toUpperCase() == 'ALLOWED';

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

    final isPast = StopDetailsUtils.isPastDeparture(departure, now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRealtime = departure['realtime'] == true;

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

    // Time calculations
    final seconds = isArrivalView
        ? (StopDetailsUtils.asNum(departure['realtimeArrival']) ?? StopDetailsUtils.asNum(departure['scheduledArrival']))
        : (StopDetailsUtils.asNum(departure['realtimeDeparture']) ?? StopDetailsUtils.asNum(departure['scheduledDeparture']));

    final eventInstant = StopDetailsUtils.resolveDepartureInstant(
      serviceDay: StopDetailsUtils.asNum(departure['serviceDay']),
      secondsOfDay: seconds,
    );

    final minutesLeft = eventInstant != null
        ? eventInstant.difference(now).inMinutes
        : -1;

    final useMinutesFormat = minutesLeft >= 0 && minutesLeft <= 120;
    final timeColor = isArrivalView ? realtimeArrivalColor : realtimeDepartureColor;
    final scheduledTime = isArrivalView ? scheduledArrival : scheduledDeparture;
    final realtimeTime = isArrivalView ? realtimeArrival : realtimeDeparture;

    Widget timeWidget;
    if (useMinutesFormat) {
      timeWidget = Text(
        "$minutesLeft'",
        style: TextStyle(
          color: timeColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      );
    } else {
      if (scheduledTime != null && realtimeTime != null && scheduledTime != realtimeTime) {
        timeWidget = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              StopDetailsUtils.formatTime(scheduledTime),
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: isPast ? Colors.grey : (isDark ? Colors.white54 : Colors.black54),
                fontSize: 12,
              ),
            ),
            Text(
              StopDetailsUtils.formatTime(realtimeTime),
              style: TextStyle(
                color: timeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        );
      } else {
        timeWidget = Text(
          StopDetailsUtils.formatTime(scheduledTime ?? realtimeTime),
          style: TextStyle(
            color: timeColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        );
      }
    }

    final labelText = isArrivalView ? AppTexts.stopArrivals : AppTexts.stopDepartures;

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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: headsign,
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
                            if (isWheelchair) ...[
                              const WidgetSpan(child: SizedBox(width: 6)),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  Icons.accessible,
                                  size: headsignUsesSpanFont ? 20 : 18,
                                  color: isPast ? Colors.grey : Colors.blue,
                                ),
                              ),
                            ],
                            if (isBike) ...[
                              const WidgetSpan(child: SizedBox(width: 6)),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  Icons.directions_bike,
                                  size: headsignUsesSpanFont ? 20 : 18,
                                  color: isPast ? Colors.grey : Colors.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (hasPlatformCode) ...[
                        const SizedBox(height: 4),
                        Text(
                          AppTexts.stopPlatform(platformCode),
                          style: TextStyle(
                            color: isPast ? Colors.grey : (isDark ? Colors.white54 : Colors.black54),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      labelText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.grey : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 2),
                    timeWidget,
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
