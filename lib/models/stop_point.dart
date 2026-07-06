class StopPoint {
  final String id;
  final String name;
  final String platformCode;
  final double? lat;
  final double? lon;
  final List<dynamic>? alerts;

  const StopPoint({
    required this.id,
    required this.name,
    required this.platformCode,
    this.lat,
    this.lon,
    this.alerts,
  });

  factory StopPoint.fromJson(Map<String, dynamic> json) {
    return StopPoint(
      id: (json['id'] ?? '').toString().trim(),
      name: json['name']?.toString() ?? '-',
      platformCode: (json['platformCode'] ?? '').toString().trim(),
      lat: json['lat'] is num ? (json['lat'] as num).toDouble() : null,
      lon: json['lon'] is num ? (json['lon'] as num).toDouble() : null,
      alerts: json['alerts'] as List?,
    );
  }
}
