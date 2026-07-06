import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RouteMappingUtils {
  static List<LatLng> decodePolyline(String encoded) {
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

  static Color? parseHexColor(String value) {
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

  static bool isWhiteColor(Color color) {
    final isPureWhite =
        color.red == 255 && color.green == 255 && color.blue == 255;
    final isNearWhite =
        color.red == 254 && color.green == 254 && color.blue == 254;
    return isPureWhite || isNearWhite;
  }

  static Color parseRouteColor(Map<String, dynamic> leg) {
    final route = leg['route'];
    if (route is Map) {
      final colorValue = route['color'];
      if (colorValue is String && colorValue.isNotEmpty) {
        final routeColor = parseHexColor(colorValue);
        if (routeColor != null) {
          return routeColor;
        }
      }
    }
    return Colors.blue;
  }

  static Color parseRouteColorForMap(Map<String, dynamic> leg) {
    final route = leg['route'];
    if (route is Map) {
      final colorValue = route['color'];
      final textColorValue = route['textColor'];

      final routeColor = colorValue is String ? parseHexColor(colorValue) : null;
      final routeTextColor = textColorValue is String ? parseHexColor(textColorValue) : null;

      if (routeColor != null) {
        final routeIsWhite = isWhiteColor(routeColor);
        final textIsNonWhite =
            routeTextColor != null && !isWhiteColor(routeTextColor);
        if (routeIsWhite && textIsNonWhite) {
          return routeTextColor;
        }
        return routeColor;
      }
    }
    return Colors.blue;
  }

  static Color parseRouteTextColor(
    Map<String, dynamic> leg, {
    required Color fallback,
  }) {
    final route = leg['route'];
    if (route is Map) {
      final textColorValue = route['textColor'];
      if (textColorValue is String && textColorValue.isNotEmpty) {
        final parsedColor = parseHexColor(textColorValue);
        if (parsedColor != null) {
          return parsedColor;
        }
      }
    }
    return fallback;
  }

  static Color idealTextColor(Color backgroundColor) {
    final brightness = ThemeData.estimateBrightnessForColor(backgroundColor);
    return brightness == Brightness.dark ? Colors.white : Colors.black;
  }
}
