import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum RouteStopType { start, transfer, end }

class RouteSegment {
  final List<LatLng> points;
  final Color color;
  final bool isWalk;

  const RouteSegment({
    required this.points,
    required this.color,
    this.isWalk = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteSegment &&
          runtimeType == other.runtimeType &&
          listEquals(points, other.points) &&
          color == other.color &&
          isWalk == other.isWalk;

  @override
  int get hashCode => Object.hash(Object.hashAll(points), color, isWalk);
}

class RouteStopMarker {
  final LatLng point;
  final String label;
  final RouteStopType type;
  final String? stopId;
  final double? bearing;

  const RouteStopMarker({
    required this.point,
    required this.label,
    required this.type,
    this.stopId,
    this.bearing,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteStopMarker &&
          runtimeType == other.runtimeType &&
          point == other.point &&
          label == other.label &&
          type == other.type &&
          stopId == other.stopId &&
          bearing == other.bearing;

  @override
  int get hashCode => Object.hash(point, label, type, stopId, bearing);
}

class RouteVehicleMarker {
  final LatLng point;
  final double headingDegrees;
  final Color markerColor;
  final Color markerTextColor;
  final String lineLabel;
  final bool lineLabelUsesSpanFont;
  final String tripShortName;
  final bool tripShortNameUsesSpanFont;
  final String tripHeadsign;
  final bool tripHeadsignUsesSpanFont;
  final String vehicleInfoText;
  final String? tripId;
  final String? serviceDay;

  const RouteVehicleMarker({
    required this.point,
    required this.headingDegrees,
    required this.markerColor,
    required this.markerTextColor,
    this.lineLabel = '-',
    this.lineLabelUsesSpanFont = false,
    this.tripShortName = '-',
    this.tripShortNameUsesSpanFont = false,
    this.tripHeadsign = '-',
    this.tripHeadsignUsesSpanFont = false,
    this.vehicleInfoText = '',
    this.tripId,
    this.serviceDay,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteVehicleMarker &&
          runtimeType == other.runtimeType &&
          point == other.point &&
          headingDegrees == other.headingDegrees &&
          markerColor == other.markerColor &&
          markerTextColor == other.markerTextColor &&
          lineLabel == other.lineLabel &&
          lineLabelUsesSpanFont == other.lineLabelUsesSpanFont &&
          tripShortName == other.tripShortName &&
          tripShortNameUsesSpanFont == other.tripShortNameUsesSpanFont &&
          tripHeadsign == other.tripHeadsign &&
          tripHeadsignUsesSpanFont == other.tripHeadsignUsesSpanFont &&
          vehicleInfoText == other.vehicleInfoText &&
          tripId == other.tripId &&
          serviceDay == other.serviceDay;

  @override
  int get hashCode => Object.hash(
        point,
        headingDegrees,
        markerColor,
        markerTextColor,
        lineLabel,
        lineLabelUsesSpanFont,
        tripShortName,
        tripShortNameUsesSpanFont,
        tripHeadsign,
        tripHeadsignUsesSpanFont,
        vehicleInfoText,
        tripId,
        serviceDay,
      );
}

class RouteMapData {
  final List<RouteSegment> segments;
  final List<RouteStopMarker> stops;

  const RouteMapData({required this.segments, required this.stops});

  bool get hasContent => segments.isNotEmpty || stops.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteMapData &&
          runtimeType == other.runtimeType &&
          listEquals(segments, other.segments) &&
          listEquals(stops, other.stops);

  @override
  int get hashCode => Object.hash(Object.hashAll(segments), Object.hashAll(stops));
}
