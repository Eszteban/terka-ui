part of 'map_view.dart';

class _VehicleMarkerData {
  final String markerId;
  final String tripGtfsId;
  final String serviceDate;
  final LatLng point;
  final double headingDegrees;
  final String serviceLabel;
  final bool serviceLabelUsesSpanFont;
  final String routeShortName;
  final bool routeShortNameUsesSpanFont;
  final String tripNumber;
  final bool tripNumberUsesSpanFont;
  final String tripHeadsign;
  final bool tripHeadsignUsesSpanFont;
  final String vehicleModel;
  final int? arrivalDelaySeconds;
  final String? nextStopName;
  final String mode;
  final Color markerColor;
  final Color markerTextColor;
  final Color markerOutlineAndHeadingColor;

  const _VehicleMarkerData({
    required this.markerId,
    required this.tripGtfsId,
    required this.serviceDate,
    required this.point,
    required this.headingDegrees,
    required this.serviceLabel,
    required this.serviceLabelUsesSpanFont,
    required this.routeShortName,
    required this.routeShortNameUsesSpanFont,
    required this.tripNumber,
    required this.tripNumberUsesSpanFont,
    required this.tripHeadsign,
    required this.tripHeadsignUsesSpanFont,
    required this.vehicleModel,
    required this.arrivalDelaySeconds,
    required this.nextStopName,
    required this.mode,
    required this.markerColor,
    required this.markerTextColor,
    required this.markerOutlineAndHeadingColor,
  });
}

class _MapStopData {
  final String stopId;
  final String name;
  final LatLng point;

  const _MapStopData({
    required this.stopId,
    required this.name,
    required this.point,
  });
}

class _StopQuickInfo {
  final String stopName;
  final int lineCount;
  final List<_StopQuickRoute> lines;

  const _StopQuickInfo({
    required this.stopName,
    required this.lineCount,
    required this.lines,
  });
}

class _StopQuickRoute {
  final String id;
  final String label;
  final bool usesSpanFont;
  final Color backgroundColor;
  final Color textColor;

  const _StopQuickRoute({
    required this.id,
    required this.label,
    required this.usesSpanFont,
    required this.backgroundColor,
    required this.textColor,
  });
}
