import 'package:flutter_test/flutter_test.dart';
import 'package:terka/models/suggestion_entry.dart';
import 'package:terka/repositories/http_search_repository.dart';
import 'package:terka/services/search_api_service.dart';

class MockSearchApiService extends SearchApiService {
  final Map<String, dynamic>? mockStations;
  final Map<String, dynamic>? mockAddresses;
  final Map<String, dynamic>? mockLines;

  MockSearchApiService({
    this.mockStations,
    this.mockAddresses,
    this.mockLines,
  });

  @override
  Future<Map<String, dynamic>?> fetchStationsRaw(
    String query, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return mockStations;
  }

  @override
  Future<Map<String, dynamic>?> fetchAddressesRaw(
    String query, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return mockAddresses;
  }

  @override
  Future<Map<String, dynamic>?> fetchLinesRaw(
    String query, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    return mockLines;
  }
}

void main() {
  group('HttpSearchRepository Tests', () {
    test('searchStations parses GeoJSON station features correctly', () async {
      final mockApi = MockSearchApiService(
        mockStations: {
          'features': [
            {
              'id': 'STOP_123',
              'properties': {
                'name': 'Deák Ferenc tér',
                'modes': ['SUBWAY', 'TRAM'],
              },
              'geometry': {
                'coordinates': [19.055, 47.498],
              },
            },
          ],
        },
      );

      final repo = HttpSearchRepository(apiService: mockApi);
      final results = await repo.searchStations('Deák');

      expect(results.length, 1);
      final item = results.first;
      expect(item.name, 'Deák Ferenc tér');
      expect(item.id, 'STOP_123');
      expect(item.coordinates, [19.055, 47.498]);
      expect(item.type, SuggestionType.stop);
      expect(item.icons.length, 2);
    });

    test('searchAddresses parses Photon addresses and formats names correctly', () async {
      final mockApi = MockSearchApiService(
        mockAddresses: {
          'features': [
            {
              'properties': {
                'name': 'Hősök tere',
                'street': 'Andrássy út',
                'housenumber': '120',
                'city': 'Budapest',
                'postcode': '1062',
              },
              'geometry': {
                'coordinates': [19.078, 47.514],
              },
            },
          ],
        },
      );

      final repo = HttpSearchRepository(apiService: mockApi);
      final results = await repo.searchAddresses('Hősök');

      expect(results.length, 1);
      final item = results.first;
      expect(item.name, 'Hősök tere, Andrássy út 120, Budapest, 1062');
      expect(item.id, '47.514,19.078');
      expect(item.type, SuggestionType.address);
    });

    test('searchLines parses GraphQL routes and sorts alphanumerically', () async {
      final mockApi = MockSearchApiService(
        mockLines: {
          'routes': [
            {
              'gtfsId': 'BKK_105',
              'shortName': '105',
              'longName': 'Gyöngyösi utca M',
              'mode': 'BUS',
              'color': '009EE3',
              'textColor': 'FFFFFF',
              'agency': {'name': 'BKK'},
            },
            {
              'gtfsId': 'BKK_4',
              'shortName': '4',
              'longName': 'Újbuda-központ M',
              'mode': 'TRAM',
              'color': 'FFD800',
              'textColor': '000000',
              'agency': {'name': 'BKK'},
            },
            {
              'gtfsId': 'BKK_6',
              'shortName': '6',
              'longName': 'Móricz Zsigmond körtér M',
              'mode': 'TRAM',
              'color': 'FFD800',
              'textColor': '000000',
              'agency': {'name': 'BKK'},
            },
          ],
        },
      );

      final repo = HttpSearchRepository(apiService: mockApi);
      final results = await repo.searchLines('tram');

      expect(results.length, 3);
      // Alphanumeric sorting should place '4' before '6' before '105'
      expect(results[0].rawData?['shortName'], '4');
      expect(results[1].rawData?['shortName'], '6');
      expect(results[2].rawData?['shortName'], '105');
      expect(results[0].type, SuggestionType.route);
    });

    test('searchAll combines enabled sources and handles empty query location', () async {
      final mockApi = MockSearchApiService(
        mockStations: {
          'features': [
            {
              'id': 'STOP_1',
              'properties': {'name': 'Stop 1'},
              'geometry': {
                'coordinates': [19.0, 47.0],
              },
            }
          ],
        },
        mockAddresses: {
          'features': [
            {
              'properties': {'name': 'Address 1', 'city': 'Budapest'},
              'geometry': {
                'coordinates': [19.1, 47.1],
              },
            }
          ],
        },
        mockLines: {'routes': []},
      );

      final repo = HttpSearchRepository(apiService: mockApi);

      // Empty query with currentLocation
      final emptyResults = await repo.searchAll(
        query: '',
        isCurrentLocationEnabled: true,
      );
      expect(emptyResults.length, 1);
      expect(emptyResults.first.id, 'CURRENT_LOCATION');

      // Valid query
      final combined = await repo.searchAll(
        query: 'Budapest',
        includeStops: true,
        includeAddresses: true,
        includeLines: true,
      );
      expect(combined.length, 2);
      expect(combined[0].type, SuggestionType.stop);
      expect(combined[1].type, SuggestionType.address);
    });
  });
}
