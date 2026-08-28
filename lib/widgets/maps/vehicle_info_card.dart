import 'dart:async';
import 'package:flutter/material.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/app_tokens.dart';
import 'package:terka/theme/terka_semantic_colors.dart';
import '../../utils/markup_text_utils.dart' as markup;
import '../../utils/vehicle_type_lookup.dart';

class VehicleInfoCard extends StatefulWidget {
  final String lineLabel;
  final bool lineLabelUsesSpanFont;
  final String tripNumberLabel;
  final String tripHeadsignLabel;
  final String serviceLabel;
  final String modelLabel;
  final int vehicleSpeed;
  final int? arrivalDelaySeconds;
  final String? nextStopName;
  final Color markerColor;
  final Color markerTextColor;
  final String nextStopStatus;
  final int? lastUpdated;
  final VoidCallback? onTap;

  static const String _spanFontFamily = 'MNR2007';
  static const double _spanFontScale = 28 / 16;

  const VehicleInfoCard({
    super.key,
    required this.lineLabel,
    required this.lineLabelUsesSpanFont,
    required this.tripNumberLabel,
    required this.tripHeadsignLabel,
    required this.serviceLabel,
    required this.modelLabel,
    required this.vehicleSpeed,
    required this.arrivalDelaySeconds,
    required this.nextStopName,
    required this.markerColor,
    required this.markerTextColor,
    required this.nextStopStatus,
    this.lastUpdated,
    this.onTap,
  });

  static int _stopStatusRank(String status) {
    switch (status.toUpperCase()) {
      case 'INCOMING_AT':
      case 'NEXT':
      case 'EXPECTED':
      case 'PREDICTED':
        return 0;
      case 'STOPPING_AT':
      case 'AT':
      case 'CURRENT':
        return 1;
      case 'IN_TRANSIT_TO':
        return 2;
      default:
        return 10;
    }
  }

  factory VehicleInfoCard.fromVehicleMap({
    required Map<String, dynamic> vehicle,
    required Map<String, dynamic>? trip,
    required Map<String, dynamic>? route,
    required Color markerColor,
    required Color markerTextColor,
    VoidCallback? onTap,
  }) {
    final routeMap = route;
    final tripMap = trip;

    final mode = routeMap != null && routeMap['mode'] is String
        ? routeMap['mode'] as String
        : 'UNKNOWN';

    final rawServiceLabel = vehicle['label'] is String
        ? vehicle['label'] as String
        : (vehicle['uicCode']?.toString() ?? AppTexts.unknown);

    final vehicleTrip = vehicle['trip'] ?? tripMap;
    final vehicleTripGtfsId = vehicleTrip is Map
        ? vehicleTrip['gtfsId']?.toString()
        : null;
    final vehicleId = vehicle['vehicleId']?.toString();

    final uicLabel = markup.plainTextFromHtml(
      vehicle['uicCode'] is String
          ? vehicle['uicCode'] as String
          : (vehicle['vehicleId']?.toString() ?? AppTexts.unknown),
    );

    final String serviceLabel;
    if (vehicleId != null &&
        vehicleTripGtfsId != null &&
        vehicleId == vehicleTripGtfsId) {
      serviceLabel = AppTexts.estimatedPosition;
    } else {
      final parsedLabel = markup.plainTextFromHtml(rawServiceLabel);
      serviceLabel = parsedLabel.trim().isNotEmpty
          ? parsedLabel
          : uicLabel.trim();
    }

    final rawVehicleModel = vehicle['vehicleModel']?.toString() ?? '';
    final String modelLabel;
    if (rawVehicleModel.trim().isNotEmpty) {
      modelLabel = markup.plainTextFromHtml(rawVehicleModel);
    } else {
      final lookupName = VehicleTypeLookup(uicLabel).vehicleType;
      if (lookupName == 'Ismeretlen') {
        modelLabel = mode == 'RAIL_REPLACEMENT_BUS'
            ? AppTexts.railReplacementBus
            : AppTexts.unknown;
      } else {
        modelLabel = lookupName;
      }
    }

    final rawRouteShortName =
        tripMap != null && tripMap['routeShortName'] is String
        ? tripMap['routeShortName'] as String
        : (routeMap != null && routeMap['shortName'] is String
              ? routeMap['shortName'] as String
              : '');
    final routeShortName = markup.plainTextFromHtml(rawRouteShortName);
    final routeShortNameUsesSpanFont = markup.containsSpanMarkup(
      rawRouteShortName,
    );

    final lineLabel = routeShortName.trim().isNotEmpty
        ? routeShortName.trim()
        : (serviceLabel.trim().isNotEmpty ? serviceLabel.trim() : '-');

    final rawTripShortName =
        tripMap != null && tripMap['tripShortName'] is String
        ? tripMap['tripShortName'] as String
        : '';
    final tripNumberLabel = rawTripShortName.trim().isNotEmpty
        ? markup.plainTextFromHtml(rawTripShortName).trim()
        : '-';

    final rawTripHeadsign = tripMap != null && tripMap['tripHeadsign'] is String
        ? tripMap['tripHeadsign'] as String
        : '';
    final tripHeadsignLabel = markup.plainTextFromHtml(rawTripHeadsign).trim();

    final nextStop = vehicle['nextStop'];
    final prevOrCurrentStop = vehicle['prevOrCurrentStop'];
    final arrivalDelaySeconds =
        nextStop is Map && nextStop['arrivalDelay'] is num
        ? (nextStop['arrivalDelay'] as num).toInt()
        : (prevOrCurrentStop is Map && prevOrCurrentStop['arrivalDelay'] is num
              ? (prevOrCurrentStop['arrivalDelay'] as num).toInt()
              : (prevOrCurrentStop is Map &&
                        prevOrCurrentStop['departureDelay'] is num
                    ? (prevOrCurrentStop['departureDelay'] as num).toInt()
                    : null));

    String? nextStopName;
    String? stopStatus;
    final stopRelationship = vehicle['stopRelationship'];
    if (stopRelationship is List) {
      int bestRank = 1 << 30;
      for (final rel in stopRelationship) {
        if (rel is! Map) {
          continue;
        }
        final stop = rel['stop'];
        final name = stop is Map ? stop['name'] : null;
        final status = rel['status'];
        if (name is String && name.trim().isNotEmpty) {
          final rank = _stopStatusRank(status is String ? status : '');
          if (rank < bestRank) {
            bestRank = rank;
            nextStopName = markup.plainTextFromHtml(name).trim();
            stopStatus = status is String ? status : null;
          }
        }
      }
    } else if (stopRelationship is Map) {
      final stop = stopRelationship['stop'];
      final name = stop is Map ? stop['name'] : null;
      if (name is String && name.trim().isNotEmpty) {
        nextStopName = markup.plainTextFromHtml(name).trim();
      }
      final status = stopRelationship['status'];
      stopStatus = status is String ? status.toString() : "";
    }

    final vehicleSpeed = vehicle['speed'] is num
        ? ((vehicle['speed'] as num) * 3.6).round()
        : 0;

    final lastUpdated = (vehicle['lastUpdated'] as num?)?.toInt();

    return VehicleInfoCard(
      lineLabel: lineLabel,
      lineLabelUsesSpanFont: routeShortNameUsesSpanFont,
      tripNumberLabel: tripNumberLabel,
      tripHeadsignLabel: tripHeadsignLabel,
      serviceLabel: serviceLabel.isNotEmpty ? serviceLabel : uicLabel,
      modelLabel: modelLabel,
      vehicleSpeed: vehicleSpeed,
      arrivalDelaySeconds: arrivalDelaySeconds,
      nextStopName: nextStopName,
      markerColor: markerColor,
      markerTextColor: markerTextColor,
      nextStopStatus: stopStatus ?? "",
      lastUpdated: lastUpdated,
      onTap: onTap,
    );
  }

  @override
  State<VehicleInfoCard> createState() => _VehicleInfoCardState();
}

class _VehicleInfoCardState extends State<VehicleInfoCard> {
  int? _elapsedSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCounter();
  }

  void _initCounter() {
    _timer?.cancel();
    if (widget.lastUpdated != null) {
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _elapsedSeconds = (nowSeconds - widget.lastUpdated!).clamp(0, 999999);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsedSeconds = (_elapsedSeconds ?? 0) + 1;
          });
        }
      });
    } else {
      _elapsedSeconds = null;
      _timer = null;
    }
  }

  @override
  void didUpdateWidget(covariant VehicleInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastUpdated != oldWidget.lastUpdated) {
      _initCounter();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDelayValue(int? delaySeconds) {
    if (delaySeconds == null) return AppTexts.delayNa;
    if (delaySeconds.abs() < 60) return AppTexts.delayZero;
    final minutes = (delaySeconds / 60).round();
    final unit = AppTexts.delayMinutesUnit;
    if (minutes > 0) return '+$minutes$unit';
    return '$minutes$unit';
  }

  Color _delayColor(int? delaySeconds, TerkaSemanticColors semantic) {
    if (delaySeconds == null) return semantic.scheduledOnly;
    final minutes = (delaySeconds / 60).round();
    if (minutes > 0) return semantic.delayed;
    return semantic.onTime;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    final nextStop = (widget.nextStopName ?? widget.tripHeadsignLabel).trim();
    String stopStatusText = widget.nextStopStatus;
    if (stopStatusText.isNotEmpty) {
      if (stopStatusText == "IN_TRANSIT_TO") {
        stopStatusText = AppTexts.tripNextStopPrefix;
      } else if (stopStatusText == "INCOMING_AT") {
        stopStatusText = AppTexts.tripNextStopIncomingAt;
      } else if (widget.nextStopStatus == "STOPPED_AT") {
        stopStatusText = AppTexts.tripNextStopStoppedAt;
      } else {
        stopStatusText = "";
      }
    }

    final nextStopPart = nextStop.isNotEmpty ? '$stopStatusText$nextStop' : '';

    final delayString = _formatDelayValue(widget.arrivalDelaySeconds);
    final delayColor = _delayColor(widget.arrivalDelaySeconds, semantic);

    final cardContent = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: widget.lineLabelUsesSpanFont
                    ? const EdgeInsets.symmetric(horizontal: AppSpacing.none, vertical: AppSpacing.none)
                    : const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: widget.markerColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.lineLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: widget.markerTextColor,
                    fontSize: widget.lineLabelUsesSpanFont ? 14 * VehicleInfoCard._spanFontScale : 14,
                    fontFamily: widget.lineLabelUsesSpanFont ? VehicleInfoCard._spanFontFamily : null,
                    leadingDistribution: widget.lineLabelUsesSpanFont
                        ? TextLeadingDistribution.even
                        : null,
                    height: widget.lineLabelUsesSpanFont ? 1.0 : null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.tripNumberLabel,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (widget.tripHeadsignLabel.isNotEmpty) ...[
            Text(
              widget.tripHeadsignLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          Text(
            '${widget.serviceLabel}\n${widget.modelLabel}\n${widget.vehicleSpeed} km/h',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.white.withValues(alpha: 0.6)
                  : AppColors.black.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Text(
                AppTexts.delayPrefix,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              Text(
                delayString,
                style: TextStyle(
                  color: delayColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (nextStopPart.isNotEmpty)
            Text(nextStopPart, style: TextStyle(color: colorScheme.onSurface)),

          if (_elapsedSeconds != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    AppTexts.vehicleLastUpdatedSeconds(_elapsedSeconds!),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Material(
      color: AppColors.transparent,
      child: widget.onTap != null
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: cardContent,
            )
          : cardContent,
    );
  }
}
