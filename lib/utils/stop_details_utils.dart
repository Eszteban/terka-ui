import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../utils/markup_text_utils.dart' as markup;

class StopDetailsUtils {
  static num? asNum(dynamic value) => value is num ? value : null;

  static bool containsSpanMarkup(String value) {
    return markup.containsSpanMarkup(value);
  }

  static String plainText(String input) {
    return markup.plainTextFromHtml(input);
  }

  static Color hexColor(String rawHex) {
    final hex = rawHex.replaceAll('#', '').trim();
    final parsed = int.tryParse(hex.length == 6 ? hex : '0A84FF', radix: 16);
    return parsed == null ? const Color(0xFF0A84FF) : Color(0xFF000000 | parsed);
  }

  static bool isArrivalEntry(Map<String, dynamic> stopTime) {
    return isScheduledStopAction(stopTime['dropoffType']);
  }

  static bool isDepartureEntry(Map<String, dynamic> stopTime) {
    return isScheduledStopAction(stopTime['pickupType']);
  }

  static bool isScheduledStopAction(dynamic value) {
    return value?.toString().toUpperCase() == 'SCHEDULED';
  }

  static bool isPastDeparture(Map<String, dynamic> departure, DateTime now) {
    final departureInstant = resolveDepartureInstant(
      serviceDay: asNum(departure['serviceDay']),
      secondsOfDay: eventSecondsOfDay(departure),
    );
    if (departureInstant == null) {
      return false;
    }
    return departureInstant.isBefore(now);
  }

  static num? eventSecondsOfDay(Map<String, dynamic> departure) {
    return asNum(departure['realtimeDeparture']) ??
        asNum(departure['scheduledDeparture']) ??
        asNum(departure['realtimeArrival']) ??
        asNum(departure['scheduledArrival']);
  }

  static int getBudapestOffsetHours(DateTime utcTime) {
    final year = utcTime.year;
    // Find last Sunday of March (DST starts)
    DateTime dstStart = DateTime.utc(year, 3, 31, 1);
    while (dstStart.weekday != DateTime.sunday) {
      dstStart = dstStart.subtract(const Duration(days: 1));
    }
    // Find last Sunday of October (DST ends)
    DateTime dstEnd = DateTime.utc(year, 10, 31, 1);
    while (dstEnd.weekday != DateTime.sunday) {
      dstEnd = dstEnd.subtract(const Duration(days: 1));
    }
    if (!utcTime.isBefore(dstStart) && utcTime.isBefore(dstEnd)) {
      return 2; // CEST (UTC+2)
    } else {
      return 1; // CET (UTC+1)
    }
  }

  static DateTime toBudapestTime(DateTime utcTime) {
    final offset = getBudapestOffsetHours(utcTime);
    return utcTime.add(Duration(hours: offset));
  }

  static DateTime budapestMidnightUtc(int year, int month, int day) {
    final approxUtc = DateTime.utc(year, month, day);
    final offset = getBudapestOffsetHours(approxUtc);
    return approxUtc.subtract(Duration(hours: offset));
  }

  static DateTime budapestToday() {
    final nowUtc = DateTime.now().toUtc();
    final nowBudapest = toBudapestTime(nowUtc);
    return DateTime.utc(nowBudapest.year, nowBudapest.month, nowBudapest.day);
  }

  static bool isSameBudapestDay(DateTime a, DateTime b) {
    final aBudapest = a.isUtc ? toBudapestTime(a) : toBudapestTime(a.toUtc());
    final bBudapest = b.isUtc ? toBudapestTime(b) : toBudapestTime(b.toUtc());
    return aBudapest.year == bBudapest.year &&
        aBudapest.month == bBudapest.month &&
        aBudapest.day == bBudapest.day;
  }

  static DateTime? resolveDepartureInstant({
    required num? serviceDay,
    required num? secondsOfDay,
  }) {
    if (serviceDay == null || secondsOfDay == null) {
      return null;
    }

    final dayMillis = serviceDay.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(
      dayMillis + secondsOfDay.toInt() * 1000,
      isUtc: true,
    );
  }

  static DateTime? resolveDepartureTime({
    required num? serviceDay,
    required num? secondsOfDay,
  }) {
    if (serviceDay == null || secondsOfDay == null) {
      return null;
    }
    final serviceDayMidnight = serviceDayLocalMidnight(serviceDay);
    if (serviceDayMidnight == null) {
      return null;
    }
    final totalSeconds = secondsOfDay.toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return DateTime.utc(
      serviceDayMidnight.year,
      serviceDayMidnight.month,
      serviceDayMidnight.day,
      hours,
      minutes,
      seconds,
    );
  }

  static String serviceDayToYmd(num? serviceDay) {
    final dt = serviceDayLocalMidnight(serviceDay);
    if (dt == null) {
      return '';
    }
    final yyyy = dt.year.toString().padLeft(4, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$yyyy$mm$dd';
  }

  static DateTime? serviceDayLocalMidnight(num? serviceDay) {
    if (serviceDay == null) {
      return null;
    }
    final serviceDayUtc = DateTime.fromMillisecondsSinceEpoch(serviceDay.toInt() * 1000, isUtc: true);
    return toBudapestTime(serviceDayUtc);
  }


  static String formatTime(DateTime? dt) {
    if (dt == null) {
      return '-';
    }
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static List<String> expandStopIdVariants(List<String> ids) {
    final ordered = <String>[];
    final seen = <String>{};

    void add(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) {
        return;
      }
      seen.add(trimmed);
      ordered.add(trimmed);
    }

    for (final raw in ids) {
      final id = raw.trim();
      add(id);

      // Support generic SOM:AGENCY|CODE matching and conversion to AGENCY:CODE / CODE
      if (id.startsWith('SOM:') && id.contains('|')) {
        final colonIdx = id.indexOf(':');
        final pipeIdx = id.indexOf('|');
        if (pipeIdx > colonIdx) {
          final agency = id.substring(colonIdx + 1, pipeIdx);
          final code = id.substring(pipeIdx + 1);
          add('$agency:$code');
          add(code);
        }
      }
      // Support generic AGENCY:CODE matching and conversion to SOM:AGENCY|CODE / CODE
      else if (id.contains(':') && !id.startsWith('SOM:')) {
        final colonIdx = id.indexOf(':');
        final agency = id.substring(0, colonIdx);
        final code = id.substring(colonIdx + 1);
        add('SOM:$agency|$code');
        add(code);
      }

      // Legacy hkir matching rules
      if (id.startsWith('SOM:hkir|')) {
        final suffix = id.substring('SOM:hkir|'.length);
        add('hkir:$suffix');
        add(suffix);
      }
      if (id.startsWith('hkir:')) {
        final suffix = id.substring('hkir:'.length);
        add('SOM:hkir|$suffix');
        add(suffix);
      }
      if (id.startsWith('hkir_')) {
        add('hkir:$id');
        add('SOM:hkir|$id');
      }
      if (id.contains('|')) {
        final suffix = id.split('|').last;
        add(suffix);
        if (suffix.startsWith('hkir_')) {
          add('hkir:$suffix');
          add('SOM:hkir|$suffix');
        }
      }
    }

    return ordered;
  }

  static List<Map<String, dynamic>> departures(Map<String, dynamic> stop) {
    final list = stop['stoptimesWithoutPatterns'];
    if (list is! List) {
      return const [];
    }
    final mapped = list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    mapped.sort((a, b) {
      final aTime = resolveDepartureInstant(
            serviceDay: asNum(a['serviceDay']),
            secondsOfDay: eventSecondsOfDay(a),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = resolveDepartureInstant(
            serviceDay: asNum(b['serviceDay']),
            secondsOfDay: eventSecondsOfDay(b),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });
    return mapped;
  }

  static LatLng? stopPoint(Map<String, dynamic> stop) {
    final lat = asNum(stop['lat']);
    final lon = asNum(stop['lon']);
    if (lat == null || lon == null) {
      return null;
    }
    final latValue = lat.toDouble();
    final lonValue = lon.toDouble();
    if (latValue < -90 || latValue > 90 || lonValue < -180 || lonValue > 180) {
      return null;
    }
    return LatLng(latValue, lonValue);
  }

  static double distanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degToRad(double degrees) => degrees * (3.141592653589793 / 180);

  static Map<String, dynamic>? selectClosestStop(
    List<Map<String, dynamic>> stops,
    LatLng? target,
  ) {
    if (target == null) {
      return null;
    }

    Map<String, dynamic>? closest;
    var bestDistance = double.infinity;
    for (final stop in stops) {
      final stopPointVal = stopPoint(stop);
      if (stopPointVal == null) {
        continue;
      }
      final distance = distanceBetween(
        target.latitude,
        target.longitude,
        stopPointVal.latitude,
        stopPointVal.longitude,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        closest = stop;
      }
    }
    return closest;
  }
}
