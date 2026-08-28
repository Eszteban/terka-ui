import 'package:flutter/material.dart';

enum SuggestionType { stop, address, route }

class SuggestionEntry {
  final String name;
  final String? id;
  final List<double>? coordinates;
  final List<IconData> icons;
  final SuggestionType type;
  final Map<String, dynamic>? rawData;

  const SuggestionEntry({
    required this.name,
    required this.id,
    required this.coordinates,
    required this.icons,
    required this.type,
    this.rawData,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionEntry &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => name.hashCode ^ id.hashCode ^ type.hashCode;
}
