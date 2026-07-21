import 'package:flutter/material.dart';
import 'package:terka/theme/app_texts.dart';
import '../utils/route_data_utils.dart';
import '../utils/layout_provider.dart';
import '../utils/route_mapping_utils.dart';
import '../utils/markup_text_utils.dart';
import '../utils/adaptive_dialog_utils.dart';
import '../screens/trip_details/trip_details_screen.dart';
import '../extensions/string_html_cleaner.dart';
import 'package:terka/theme/app_tokens.dart';

class ItineraryLegTile extends StatelessWidget {
  static const String _spanFontFamily = 'MNR2007';

  final Map<String, dynamic> leg;
  final Map<String, dynamic>? nextLeg;
  final String serviceDay;
  final bool desktopInlineMapMode;
  final double desktopBreakpoint;
  final Function(String, String)? onOpenTripDetailsRequested;

  const ItineraryLegTile({
    super.key,
    required this.leg,
    this.nextLeg,
    required this.serviceDay,
    this.desktopInlineMapMode = false,
    this.desktopBreakpoint = 600,
    this.onOpenTripDetailsRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fromName = RouteDataUtils.nestedString(leg, ['from', 'name']) ?? AppTexts.unknown;
    final toName = RouteDataUtils.nestedString(leg, ['to', 'name']) ?? AppTexts.unknown;
    final mode = leg['mode']?.toString() ?? '-';
    final duration = RouteDataUtils.formatDuration(leg['duration']);
    final startTime = RouteDataUtils.formatEpochMillis(leg['startTime']);
    final endTime = RouteDataUtils.formatEpochMillis(leg['endTime']);
    final lineNumber = _legLineNumber(leg);
    final tripNumber = _legTripDisplayNumber(leg);
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium;
    final routeColor = RouteMappingUtils.parseRouteColor(leg);
    final routeTextColor = RouteMappingUtils.parseRouteTextColor(
      leg,
      fallback: RouteMappingUtils.idealTextColor(routeColor),
    );

    final isWalkLeg = mode.toUpperCase().trim() == 'WALK';
    final waitMinutes = isWalkLeg
        ? RouteDataUtils.waitingMinutesUntilNextTransit(leg, nextLeg)
        : null;

    final rawTripId = RouteDataUtils.nestedString(leg, ['trip', 'gtfsId']) ?? '';
    final tripId = rawTripId.trim();
    final serviceDayRaw = RouteDataUtils.nestedString(leg, ['serviceDate']) ?? '';
    final resolvedServiceDay = serviceDayRaw.trim().isNotEmpty
        ? serviceDayRaw.trim()
        : _todayServiceDate();
    final canOpenTrip = !isWalkLeg && tripId.isNotEmpty;

    final leftTile = Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.xs),
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
                      horizontal: AppSpacing.none,
                      vertical: AppSpacing.none,
                    ),
                    decoration: BoxDecoration(
                      color: routeColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      lineNumber.toPlainTextFromHtml(),
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
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: routeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lineNumber.toPlainTextFromHtml(),
                      style: TextStyle(
                        color: routeTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
          const SizedBox(height: AppSpacing.sm),
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
      padding: const EdgeInsets.all(AppSpacing.md),
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
          const SizedBox(height: AppSpacing.xs),
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
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
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
          const SizedBox(height: AppSpacing.xs),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: canOpenTrip
              ? () => _openTripDetails(
                  context,
                  tripId: tripId,
                  serviceDay: resolvedServiceDay,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                leftTile,
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: rightTile),
              ],
            ),
          ),
        ),
      ),
    );
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
        LayoutProvider.isDesktop(context, breakpoint: desktopBreakpoint);

    if (isDesktop) {
      await showAdaptiveDetailsDialog<void>(
        context: context,
        child: TripDetailsScreen(
          tripId: tripId,
          serviceDay: serviceDay,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailsScreen(
          tripId: tripId,
          serviceDay: serviceDay,
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

  String _legLineNumber(Map<String, dynamic> leg) {
    return RouteDataUtils.nestedString(leg, ['route', 'shortName']) ??
        RouteDataUtils.nestedString(leg, ['route', 'longName']) ??
        '-';
  }

  String _legTripDisplayNumber(Map<String, dynamic> leg) {
    return RouteDataUtils.nestedString(leg, ['trip', 'tripShortName']) ?? _legLineNumber(leg);
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
      final beforeText = before.toPlainTextFromHtml();
      if (beforeText.isNotEmpty) {
        result.add(TextSpan(text: beforeText));
      }

      final spanContent = match.group(1) ?? '';
      final spanText = spanContent.toPlainTextFromHtml();
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
    final tailText = tail.toPlainTextFromHtml();
    if (tailText.isNotEmpty) {
      result.add(TextSpan(text: tailText));
    }

    if (result.isEmpty) {
      result.add(TextSpan(text: raw.toPlainTextFromHtml()));
    }

    return result;
  }
}
