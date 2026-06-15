import 'dart:ui';

class TripStopQuickRoute {
  final String id;
  final String label;
  final bool usesSpanFont;
  final Color backgroundColor;
  final Color textColor;

  const TripStopQuickRoute({
    required this.id,
    required this.label,
    required this.usesSpanFont,
    required this.backgroundColor,
    required this.textColor,
  });
}

class TripStopQuickInfo {
  final String stopId;
  final String stopName;
  final List<TripStopQuickRoute> lines;

  const TripStopQuickInfo({
    required this.stopId,
    required this.stopName,
    required this.lines,
  });
}
