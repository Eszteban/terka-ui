import 'dart:convert';
import '../theme/app_texts.dart';

class RouteDataUtils {
  static List<Map<String, dynamic>> extractItineraries(String rawJson) {
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

  static Map<String, String> buildSummary(Map<String, dynamic> itinerary) {
    final duration = itinerary['duration'];
    final transfers = itinerary['numberOfTransfers'];
    final start = itinerary['startTime'];
    final end = itinerary['endTime'];

    return {
      'duration': formatDuration(duration),
      'transfers': transfers?.toString() ?? '-',
      'start': formatEpochMillis(start),
      'end': formatEpochMillis(end),
    };
  }

  static String formatDuration(dynamic secondsValue) {
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

  static String formatEpochMillis(dynamic millisValue) {
    if (millisValue is! num) {
      return '-';
    }
    final dateTime = DateTime.fromMillisecondsSinceEpoch(millisValue.toInt());
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String? nestedString(Map<String, dynamic> map, List<String> path) {
    dynamic current = map;
    for (final key in path) {
      if (current is! Map || !current.containsKey(key)) {
        return null;
      }
      current = current[key];
    }
    return current is String ? current : null;
  }

  static int? durationMinutes(dynamic secondsValue) {
    if (secondsValue is! num) {
      return null;
    }
    return (secondsValue / 60).round();
  }

  static int? waitingMinutesUntilNextTransit(
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
}
