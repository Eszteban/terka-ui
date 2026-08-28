import '../models/suggestion_entry.dart';

abstract class SearchRepository {
  /// Searches transit stations / stops matching [query].
  Future<List<SuggestionEntry>> searchStations(String query);

  /// Searches geographic addresses matching [query] via Photon Geocoder.
  Future<List<SuggestionEntry>> searchAddresses(String query);

  /// Searches transit lines / routes matching [query].
  Future<List<SuggestionEntry>> searchLines(String query);

  /// Aggregates enabled search sources concurrently and returns combined suggestions.
  Future<List<SuggestionEntry>> searchAll({
    required String query,
    bool includeStops = true,
    bool includeAddresses = true,
    bool includeLines = false,
    bool isCurrentLocationEnabled = false,
  });
}
