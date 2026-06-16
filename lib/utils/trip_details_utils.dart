import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_texts.dart';
import '../widgets/maps/route_map_data.dart';
import '../widgets/maps/vehicle_info_card.dart';
import '../utils/markup_text_utils.dart' as markup;
import '../utils/vehicle_type_lookup.dart';

class TripDetailsUtils {
  static num? asNum(dynamic value) => value is num ? value : null;

  static bool containsSpanMarkup(String value) {
    return markup.containsSpanMarkup(value);
  }

  static DateTime? parseServiceDay(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 8) {
      return null;
    }
    final year = int.tryParse(digitsOnly.substring(0, 4));
    final month = int.tryParse(digitsOnly.substring(4, 6));
    final day = int.tryParse(digitsOnly.substring(6, 8));
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  static DateTime? resolveDateTime(num rawValue, String serviceDay) {
    final intValue = rawValue.toInt();

    if (intValue > 9999999999) {
      return DateTime.fromMillisecondsSinceEpoch(intValue);
    }

    if (intValue > 2000000000) {
      return DateTime.fromMillisecondsSinceEpoch(intValue * 1000);
    }

    final serviceDate = parseServiceDay(serviceDay);
    if (serviceDate == null) {
      return null;
    }
    final hours = intValue ~/ 3600;
    final minutes = (intValue % 3600) ~/ 60;
    final seconds = intValue % 60;
    return DateTime(
      serviceDate.year,
      serviceDate.month,
      serviceDate.day,
      hours,
      minutes,
      seconds,
    );
  }

  static String formatEpoch(num? value, String serviceDay) {
    final dt = value == null ? null : resolveDateTime(value, serviceDay);
    if (dt == null) {
      return '-';
    }
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String delayText(num? delaySeconds) {
    if (delaySeconds == null) {
      return AppTexts.tripDelayNa;
    }
    final minutes = (delaySeconds / 60).round();
    if (minutes > 0) {
      return AppTexts.tripDelayMinutes('+$minutes');
    }
    if (minutes < 0) {
      return AppTexts.tripDelayMinutes('$minutes');
    }
    return AppTexts.tripDelayZero;
  }

  static String plainText(String input) {
    return markup.plainTextFromHtml(input);
  }

  static Color hexColor(String rawHex) {
    final hex = rawHex.replaceAll('#', '').trim();
    final parsed = int.tryParse(hex.length == 6 ? hex : '0A84FF', radix: 16);
    return parsed == null
        ? const Color(0xFF0A84FF)
        : Color(0xFF000000 | parsed);
  }

  static bool isPassedStop(Map<String, dynamic> stopTime, String serviceDay) {
    final reference =
        asNum(stopTime['realtimeDeparture']) ??
        asNum(stopTime['scheduledDeparture']) ??
        asNum(stopTime['realtimeArrival']) ??
        asNum(stopTime['scheduledArrival']);
    if (reference == null) {
      return false;
    }
    final dt = resolveDateTime(reference, serviceDay);
    if (dt == null) {
      return false;
    }
    return dt.isBefore(DateTime.now());
  }

  static bool isWhiteLike(Color color) {
    // Avoid precision loss deprecated warnings by calling r/g/b values safely
    return (color.r * 255.0 >= 254 &&
        color.g * 255.0 >= 254 &&
        color.b * 255.0 >= 254);
  }

  static Color resolvedPolylineColor({
    required Color routeColor,
    required Color routeTextColor,
  }) {
    return isWhiteLike(routeColor) ? routeTextColor : routeColor;
  }

  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lon = 0;

    while (index < encoded.length) {
      var value = 0;
      var shift = 0;
      var chunk = 0;
      do {
        chunk = encoded.codeUnitAt(index++) - 63;
        value |= (chunk & 0x1f) << shift;
        shift += 5;
      } while (chunk >= 0x20);
      final latMagnitude = value >> 1;
      final deltaLat = (value & 1) != 0 ? -(latMagnitude + 1) : latMagnitude;
      lat += deltaLat;

      value = 0;
      shift = 0;
      do {
        chunk = encoded.codeUnitAt(index++) - 63;
        value |= (chunk & 0x1f) << shift;
        shift += 5;
      } while (chunk >= 0x20);
      final lonMagnitude = value >> 1;
      final deltaLon = (value & 1) != 0 ? -(lonMagnitude + 1) : lonMagnitude;
      lon += deltaLon;

      points.add(LatLng(lat / 1e5, lon / 1e5));
    }

    return points;
  }

  static List<LatLng> tripGeometryPoints(Map<String, dynamic> trip) {
    final tripGeometry = trip['tripGeometry'];
    if (tripGeometry is! Map) {
      return const [];
    }

    final encoded = tripGeometry['points'];
    if (encoded is! String || encoded.isEmpty) {
      return const [];
    }

    return decodePolyline(encoded);
  }

  static List<({LatLng point, String label, String? stopId, double? bearing})>
  stopPoints(Map<String, dynamic> trip) {
    final result =
        <({LatLng point, String label, String? stopId, double? bearing})>[];
    for (final stopTime in stopTimes(trip)) {
      final stop = stopTime['stop'];
      if (stop is! Map) {
        continue;
      }
      final lat = stop['lat'];
      final lon = stop['lon'];
      final name = stop['name']?.toString() ?? '';
      final bearing = stop['bearing'] is num
          ? (stop['bearing'] as num).toDouble()
          : null;
      if (lat is num && lon is num) {
        result.add((
          point: LatLng(lat.toDouble(), lon.toDouble()),
          label: plainText(name),
          stopId: stop['id']?.toString().trim(),
          bearing: bearing,
        ));
      }
    }
    return result;
  }

  static Map<String, dynamic> firstVehicle(Map<String, dynamic> trip) {
    final pattern = trip['pattern'];
    final vehicles = pattern is Map
        ? pattern['vehiclePositions']
        : trip['vehiclePositions'];
    if (vehicles is List && vehicles.isNotEmpty && vehicles.first is Map) {
      return (vehicles.first as Map).cast<String, dynamic>();
    }
    return const {};
  }

  static Map<String, dynamic> route(Map<String, dynamic> trip) {
    final route = trip['route'];
    return route is Map ? route.cast<String, dynamic>() : const {};
  }

  static List<Map<String, dynamic>> stopTimes(Map<String, dynamic> trip) {
    final stopTimes = trip['stoptimes'];
    if (stopTimes is! List) {
      return const [];
    }
    return stopTimes
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }

  static RouteMapData buildTripRouteMapData(Map<String, dynamic> trip) {
    final routeData = route(trip);
    final routeColor = hexColor(routeData['color']?.toString() ?? '0A84FF');
    final routeTextColor = hexColor(
      routeData['textColor']?.toString() ?? 'FFFFFF',
    );
    final displayedRouteColor = resolvedPolylineColor(
      routeColor: routeColor,
      routeTextColor: routeTextColor,
    );

    final stopPts = stopPoints(trip);
    final geometryPoints = tripGeometryPoints(trip);

    var finalGeometryPoints = geometryPoints;
    if (finalGeometryPoints.length < 2 && stopPts.length >= 2) {
      finalGeometryPoints = stopPts.map((e) => e.point).toList();
    }

    final segments = <RouteSegment>[];
    if (finalGeometryPoints.length >= 2) {
      segments.add(
        RouteSegment(points: finalGeometryPoints, color: displayedRouteColor),
      );
    }

    final stops = <RouteStopMarker>[];
    for (var i = 0; i < stopPts.length; i++) {
      final item = stopPts[i];
      final type = i == 0
          ? RouteStopType.start
          : (i == stopPts.length - 1
                ? RouteStopType.end
                : RouteStopType.transfer);
      stops.add(
        RouteStopMarker(
          point: item.point,
          label: item.label,
          type: type,
          stopId: item.stopId,
          bearing: item.bearing,
        ),
      );
    }

    return RouteMapData(segments: segments, stops: stops);
  }

  static RouteVehicleMarker? buildTripVehicleMarker(
    Map<String, dynamic> trip,
    String tripId,
  ) {
    final vehicle = firstVehicle(trip);
    if (vehicle.isEmpty) {
      return null;
    }

    final lat = vehicle['lat'];
    final lon = vehicle['lon'];
    if (lat is! num || lon is! num) {
      return null;
    }

    final latValue = lat.toDouble();
    final lonValue = lon.toDouble();

    final heading = vehicle['heading'] is num
        ? (vehicle['heading'] as num).toDouble()
        : 0.0;
    final info = buildTripVehicleInfo(trip);

    final routeData = route(trip);
    final routeColor = hexColor(routeData['color']?.toString() ?? '0A84FF');
    final routeTextColor = hexColor(
      routeData['textColor']?.toString() ?? 'FFFFFF',
    );

    return RouteVehicleMarker(
      point: LatLng(latValue, lonValue),
      headingDegrees: heading,
      markerColor: routeColor,
      markerTextColor: routeTextColor,
      lineLabel: info.line,
      lineLabelUsesSpanFont: info.lineUsesSpanFont,
      tripShortName: info.tripShortName,
      tripShortNameUsesSpanFont: info.tripShortNameUsesSpanFont,
      tripHeadsign: info.tripHeadsign,
      tripHeadsignUsesSpanFont: info.tripHeadsignUsesSpanFont,
      vehicleInfoText: info.vehicleInfoText,
      tripId: tripId,
    );
  }

  static ({
    String line,
    bool lineUsesSpanFont,
    String tripShortName,
    bool tripShortNameUsesSpanFont,
    String tripHeadsign,
    bool tripHeadsignUsesSpanFont,
    String vehicleInfoText,
  })
  buildTripVehicleInfo(Map<String, dynamic> trip) {
    final routeData = route(trip);
    final vehicle = firstVehicle(trip);
    final hasVehicle = vehicle.isNotEmpty;
    final rawLine = routeData['shortName']?.toString() ?? '-';
    final line = plainText(rawLine);
    final lineUsesSpanFont = containsSpanMarkup(rawLine);
    final rawTripHeadsign = trip['tripHeadsign']?.toString() ?? '-';
    final tripHeadsign = plainText(rawTripHeadsign);
    final tripHeadsignUsesSpanFont = containsSpanMarkup(rawTripHeadsign);
    final vehicleTrip = vehicle['trip'];
    final vehicleTripGtfsId = vehicleTrip is Map
        ? vehicleTrip['gtfsId']?.toString()
        : null;
    final vehicleId = vehicle['vehicleId']?.toString();
    final rawVehicleLabel = vehicle['label']?.toString() ?? '';
    final label = !hasVehicle
        ? ''
        : (vehicleId != null &&
              vehicleTripGtfsId != null &&
              vehicleId == vehicleTripGtfsId)
        ? AppTexts.estimatedPosition
        : rawVehicleLabel.trim().isNotEmpty
        ? plainText(rawVehicleLabel)
        : AppTexts.unknownVehicle;
    final rawVehicleModel = vehicle['vehicleModel']?.toString() ?? '';
    final model = rawVehicleModel.trim().isNotEmpty
        ? plainText(rawVehicleModel)
        : VehicleTypeLookup(label).vehicleType;

    final rawTripShortName = trip['tripShortName']?.toString() ?? '-';
    final tripShortName = plainText(rawTripShortName);
    final tripShortNameUsesSpanFont = containsSpanMarkup(rawTripShortName);

    final delayTextVal = delayText(
      vehicle["nextStop"] != null
          ? vehicle["nextStop"]["arrivalDelay"] as num?
          : null,
    );

    final nextStop = vehicle['nextStop'];
    final stop = nextStop != null ? nextStop['stop'] : null;
    String nextStopName = stop != null ? stop["name"]?.toString() ?? '' : '';

    final vehicleInfoText = hasVehicle
        ? '$label\n$model\n$delayTextVal\n${AppTexts.tripNextStopPrefix}$nextStopName'
        : AppTexts.tripNoVehicle;

    return (
      line: line,
      lineUsesSpanFont: lineUsesSpanFont,
      tripShortName: tripShortName,
      tripShortNameUsesSpanFont: tripShortNameUsesSpanFont,
      tripHeadsign: tripHeadsign,
      tripHeadsignUsesSpanFont: tripHeadsignUsesSpanFont,
      vehicleInfoText: vehicleInfoText,
    );
  }

  static VehicleInfoCard buildVehicleTapInfoCard({
    required Map<String, dynamic> trip,
    required Color routeColor,
    required Color routeTextColor,
  }) {
    final routeData = route(trip);
    final vehicle = firstVehicle(trip);
    final hasVehicle = vehicle.isNotEmpty;
    final rawLine = routeData['shortName']?.toString() ?? '-';
    final lineLabel = plainText(rawLine);
    final lineLabelUsesSpanFont = containsSpanMarkup(rawLine);

    final rawTripShortName = trip['tripShortName']?.toString() ?? '-';
    final tripNumberLabel = plainText(rawTripShortName);

    final rawTripHeadsign = trip['tripHeadsign']?.toString() ?? '-';
    final tripHeadsignLabel = plainText(rawTripHeadsign);

    final vehicleTrip = vehicle['trip'];
    final vehicleTripGtfsId = vehicleTrip is Map
        ? vehicleTrip['gtfsId']?.toString()
        : null;
    final vehicleId = vehicle['vehicleId']?.toString();
    final rawVehicleLabel =
        vehicle['label']?.toString() != "" && vehicle['label'] != null
        ? vehicle['label'].toString()
        : vehicle['uicCode'] != null
        ? vehicle['uicCode'].toString()
        : '';
    final serviceLabel = !hasVehicle
        ? ''
        : (vehicleId != null &&
              vehicleTripGtfsId != null &&
              vehicleId == vehicleTripGtfsId)
        ? AppTexts.estimatedPosition
        : rawVehicleLabel.trim().isNotEmpty
        ? plainText(rawVehicleLabel)
        : AppTexts.unknownVehicle;

    final rawVehicleModel = vehicle['vehicleModel']?.toString() ?? '';
    final modelLabel = rawVehicleModel.trim().isNotEmpty
        ? plainText(rawVehicleModel)
        : VehicleTypeLookup(serviceLabel).vehicleType;

    final nextStop = vehicle['nextStop'];
    final int? arrivalDelaySeconds =
        nextStop != null && nextStop['arrivalDelay'] is num
        ? (nextStop['arrivalDelay'] as num).toInt()
        : null;

    final nextStopName = nextStop != null && nextStop['stop'] != null
        ? nextStop['stop']['name']?.toString()
        : null;

    return VehicleInfoCard(
      lineLabel: lineLabel,
      lineLabelUsesSpanFont: lineLabelUsesSpanFont,
      tripNumberLabel: tripNumberLabel,
      tripHeadsignLabel: tripHeadsignLabel,
      serviceLabel: serviceLabel,
      modelLabel: modelLabel,
      arrivalDelaySeconds: arrivalDelaySeconds,
      nextStopName: nextStopName,
      markerColor: routeColor,
      markerTextColor: routeTextColor,
      onTap: null,
    );
  }
}
