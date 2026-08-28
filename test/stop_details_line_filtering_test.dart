import 'package:flutter_test/flutter_test.dart';
import 'package:terka/controllers/stop_details_cubit.dart';
import 'package:terka/repositories/transit_repository.dart';

class MockTransitRepository implements TransitRepository {
  int fetchCallCount = 0;

  @override
  Future<List<Map<String, dynamic>>?> fetchStopDetails({
    required List<String> stopIds,
    required DateTime selectedDate,
  }) async {
    fetchCallCount++;
    return [
      {
        'gtfsId': 'stop_1',
        'name': 'Test Stop',
        'lat': 47.49,
        'lon': 19.04,
        'routes': [
          {'shortName': '4', 'color': 'FFF000', 'textColor': '000000'},
          {'shortName': '6', 'color': 'FFF000', 'textColor': '000000'},
        ],
        'stoptimesWithoutPatterns': [
          {
            'scheduledDeparture': 36000,
            'realtimeDeparture': 36000,
            'serviceDay': 1700000000,
            'trip': {
              'gtfsId': 'trip_4',
              'route': {'shortName': '4'},
            },
          },
          {
            'scheduledDeparture': 36100,
            'realtimeDeparture': 36100,
            'serviceDay': 1700000000,
            'trip': {
              'gtfsId': 'trip_6',
              'route': {'shortName': '6'},
            },
          },
        ],
      }
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('StopDetailsCubit line filter selection and reset does not trigger re-fetch', () async {
    final mockRepo = MockTransitRepository();
    final cubit = StopDetailsCubit(
      transitRepository: mockRepo,
      stopId: 'stop_1',
    );

    // Wait for initial load
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(mockRepo.fetchCallCount, 1);
    expect(cubit.state, isA<StopDetailsLoaded>());
    
    final initialState = cubit.state as StopDetailsLoaded;
    expect(initialState.selectedLines, isEmpty);
    expect(initialState.uniqueLines.length, 2);

    // Select line "4"
    cubit.toggleLine('4', true);
    expect(mockRepo.fetchCallCount, 1); // No new network call!
    expect(cubit.state, isA<StopDetailsLoaded>());
    expect((cubit.state as StopDetailsLoaded).selectedLines, {'4'});

    // Select line "6"
    cubit.toggleLine('6', true);
    expect(mockRepo.fetchCallCount, 1);
    expect((cubit.state as StopDetailsLoaded).selectedLines, {'4', '6'});

    // Clear line selection (Alaphelyzet)
    cubit.clearSelectedLines();
    expect(mockRepo.fetchCallCount, 1);
    expect((cubit.state as StopDetailsLoaded).selectedLines, isEmpty);

    cubit.close();
  });
}
