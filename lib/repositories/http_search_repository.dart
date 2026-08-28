import 'package:flutter/material.dart';
import 'package:terka/theme/app_texts.dart';
import '../models/suggestion_entry.dart';
import '../services/search_api_service.dart';
import 'search_repository.dart';

class HttpSearchRepository implements SearchRepository {
  final SearchApiService _apiService;

  const HttpSearchRepository({
    required SearchApiService apiService,
  }) : _apiService = apiService;

  @override
  Future<List<SuggestionEntry>> searchStations(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final raw = await _apiService.fetchStationsRaw(trimmedQuery);
    if (raw == null || raw['features'] is! List) return const [];

    final entries = <SuggestionEntry>[];
    for (final item in raw['features']) {
      if (item is! Map) continue;
      final properties = item['properties'];
      final geometry = item['geometry'];
      final id = item['id']?.toString();
      String? name;
      List<double>? coord;
      List<String> modes = const [];

      if (properties is Map) {
        final n = properties['name'];
        if (n is String) name = n;
        final m = properties['modes'];
        if (m is List) {
          modes = m.whereType<String>().toList();
        }
      }
      if (geometry is Map && geometry['coordinates'] is List) {
        final c = geometry['coordinates'];
        if (c.length == 2 && c[0] is num && c[1] is num) {
          coord = [c[0].toDouble(), c[1].toDouble()];
        }
      }
      if (name != null) {
        entries.add(
          SuggestionEntry(
            name: name,
            id: id,
            coordinates: coord,
            icons: iconsForModes(modes),
            type: SuggestionType.stop,
          ),
        );
      }
    }
    return entries;
  }

  @override
  Future<List<SuggestionEntry>> searchAddresses(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final raw = await _apiService.fetchAddressesRaw(trimmedQuery);
    if (raw == null || raw['features'] is! List) return const [];

    final entries = <SuggestionEntry>[];
    for (final item in raw['features']) {
      if (item is! Map) continue;
      final properties = item['properties'];
      final geometry = item['geometry'];
      List<double>? coord;
      if (geometry is Map && geometry['coordinates'] is List) {
        final c = geometry['coordinates'];
        if (c.length == 2 && c[0] is num && c[1] is num) {
          coord = [c[0].toDouble(), c[1].toDouble()];
        }
      }
      if (properties is Map && coord != null) {
        final formattedName = formatPhotonName(properties.cast<String, dynamic>());
        final lat = coord[1];
        final lon = coord[0];
        entries.add(
          SuggestionEntry(
            name: formattedName,
            id: '$lat,$lon',
            coordinates: coord,
            icons: const [Icons.place],
            type: SuggestionType.address,
          ),
        );
      }
    }
    return entries;
  }

  @override
  Future<List<SuggestionEntry>> searchLines(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final raw = await _apiService.fetchLinesRaw(trimmedQuery);
    if (raw == null) return const [];

    final routes = raw['routes'];
    if (routes is! List) return const [];

    final sortedRoutes = List.from(routes);
    sortedRoutes.sort((a, b) {
      final sA = (a is Map ? a['shortName']?.toString() : '') ?? '';
      final sB = (b is Map ? b['shortName']?.toString() : '') ?? '';
      return compareAlphanumeric(sA, sB);
    });

    final entries = <SuggestionEntry>[];
    for (final r in sortedRoutes) {
      if (r is! Map) continue;
      final gtfsId = r['gtfsId']?.toString();
      final shortName = r['shortName']?.toString() ?? '-';
      final longName = r['longName']?.toString();
      final mode = r['mode']?.toString();
      final color = r['color']?.toString() ?? '0A84FF';
      final textColor = r['textColor']?.toString() ?? 'FFFFFF';
      final agency = r['agency'] is Map ? r['agency']['name']?.toString() : null;

      entries.add(
        SuggestionEntry(
          name: longName != null && longName.isNotEmpty ? '$shortName - $longName' : shortName,
          id: gtfsId,
          coordinates: null,
          icons: const [Icons.directions_bus],
          type: SuggestionType.route,
          rawData: {
            'gtfsId': gtfsId,
            'shortName': shortName,
            'longName': longName,
            'mode': mode,
            'color': color,
            'textColor': textColor,
            'agency': agency,
          },
        ),
      );
    }
    return entries;
  }

  @override
  Future<List<SuggestionEntry>> searchAll({
    required String query,
    bool includeStops = true,
    bool includeAddresses = true,
    bool includeLines = false,
    bool isCurrentLocationEnabled = false,
  }) async {
    final trimmedQuery = query.trim();
    final newEntries = <SuggestionEntry>[];

    // Current location entry when query is empty
    if (trimmedQuery.isEmpty && isCurrentLocationEnabled) {
      final name = AppTexts.isHungarian ? 'Jelenlegi helyzet' : 'Current location';
      newEntries.add(
        SuggestionEntry(
          name: name,
          id: 'CURRENT_LOCATION',
          coordinates: null,
          icons: const [Icons.my_location],
          type: SuggestionType.address,
        ),
      );
      return newEntries;
    }

    if (trimmedQuery.isEmpty) {
      return const [];
    }

    final futures = <Future<List<SuggestionEntry>>>[];
    if (includeStops) {
      futures.add(searchStations(trimmedQuery));
    }
    if (includeAddresses) {
      futures.add(searchAddresses(trimmedQuery));
    }
    if (includeLines) {
      futures.add(searchLines(trimmedQuery));
    }

    if (futures.isEmpty) {
      return const [];
    }

    final results = await Future.wait(futures);
    for (final list in results) {
      newEntries.addAll(list);
    }
    return newEntries;
  }

  static List<IconData> iconsForModes(List<String> modes) {
    if (modes.isEmpty) {
      return const [Icons.directions_bus];
    }
    final mapped = <IconData>[];
    for (final mode in modes) {
      switch (mode) {
        case 'RAIL':
        case 'SUBURBAN_RAILWAY':
          mapped.add(Icons.train);
          break;
        case 'RAIL_REPLACEMENT_BUS':
          mapped.add(Icons.bus_alert);
          break;
        case 'BUS':
          mapped.add(Icons.airport_shuttle);
          break;
        case 'COACH':
          mapped.add(Icons.directions_bus);
          break;
        case 'SUBWAY':
          mapped.add(Icons.directions_subway);
          break;
        case 'TRAM':
        case 'TRAMTRAIN':
          mapped.add(Icons.tram);
          break;
        case 'TROLLEYBUS':
          mapped.add(Icons.directions_bus);
          break;
        case 'FERRY':
          mapped.add(Icons.directions_boat);
          break;
      }
    }
    final unique = <IconData>[];
    for (final icon in mapped) {
      if (!unique.contains(icon)) {
        unique.add(icon);
      }
    }
    return unique.isEmpty ? const [Icons.directions_bus] : unique;
  }

  static String formatPhotonName(Map<String, dynamic> properties) {
    final name = properties['name']?.toString() ?? '';
    final street = properties['street']?.toString() ?? '';
    final houseNumber = properties['housenumber']?.toString() ?? '';
    final city = properties['city']?.toString() ?? '';
    final postcode = properties['postcode']?.toString() ?? '';

    final cleanName = (name.isNotEmpty && RegExp(r'^\d+$').hasMatch(name)) ? '' : name;
    final parts = <String>[];

    if (cleanName.isNotEmpty) {
      parts.add(cleanName);
      if (street.isNotEmpty) {
        if (houseNumber.isNotEmpty) {
          parts.add('$street $houseNumber');
        } else {
          parts.add(street);
        }
      }
    } else if (street.isNotEmpty) {
      if (houseNumber.isNotEmpty) {
        parts.add('$street $houseNumber');
      } else {
        parts.add(street);
      }
    }

    if (city.isNotEmpty) {
      parts.add(city);
    }
    if (postcode.isNotEmpty && !parts.contains(postcode)) {
      parts.add(postcode);
    }

    if (parts.isEmpty) {
      return name.isNotEmpty ? name : 'Ismeretlen hely';
    }

    return parts.join(', ');
  }

  static int compareAlphanumeric(String a, String b) {
    final regExp = RegExp(r'(\d+|\D+)');
    final matchesA = regExp.allMatches(a).map((m) => m.group(0)!).toList();
    final matchesB = regExp.allMatches(b).map((m) => m.group(0)!).toList();

    for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
      final partA = matchesA[i];
      final partB = matchesB[i];

      final numA = int.tryParse(partA);
      final numB = int.tryParse(partB);

      if (numA != null && numB != null) {
        if (numA != numB) return numA.compareTo(numB);
      } else {
        final cmp = partA.compareTo(partB);
        if (cmp != 0) return cmp;
      }
    }
    return matchesA.length.compareTo(matchesB.length);
  }
}
