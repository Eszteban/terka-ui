import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terka/models/stop_point.dart';
import 'package:terka/models/trip_stop_time.dart';
import 'package:terka/widgets/tables/trip_stop_times_list.dart';

void main() {
  final now = DateTime.now();
  final serviceDay = '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

  // Create stop times: Stop 1 and Stop 2 passed, Stop 3 in the future
  final pastTime1 = (now.hour - 2) * 3600;
  final pastTime2 = (now.hour - 1) * 3600;
  final futureTime3 = (now.hour + 1) * 3600;

  final stopTimes = [
    TripStopTime(
      stop: const StopPoint(id: 's1', name: 'Budapest-Keleti', platformCode: ''),
      scheduledDeparture: pastTime1,
      realtimeDeparture: pastTime1,
      isRealtime: true,
    ),
    TripStopTime(
      stop: const StopPoint(id: 's2', name: 'Kelenföld', platformCode: ''),
      scheduledDeparture: pastTime2,
      realtimeDeparture: pastTime2,
      isRealtime: true,
    ),
    TripStopTime(
      stop: const StopPoint(id: 's3', name: 'Győr', platformCode: ''),
      scheduledDeparture: futureTime3,
      realtimeDeparture: futureTime3,
      isRealtime: true,
    ),
  ];

  testWidgets('TripStopTimesList hides earlier passed stops and leaves the last passed stop visible', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TripStopTimesList(
              stopTimes: stopTimes,
              serviceDay: serviceDay,
              onStopTap: ({required initialStopPoint, required stopId, required stopName}) {},
            ),
          ),
        ),
      ),
    );

    // Stop 1 (Budapest-Keleti) should be hidden by default
    expect(find.text('Budapest-Keleti'), findsNothing);

    // Stop 2 (Kelenföld - last passed stop) should be visible
    expect(find.text('Kelenföld'), findsOneWidget);

    // Stop 3 (Győr) should be visible
    expect(find.text('Győr'), findsOneWidget);

    // Expand button should be visible with "1 korábbi megálló megjelenítése"
    expect(find.text('1 korábbi megálló megjelenítése'), findsOneWidget);

    // Tap to expand
    await tester.tap(find.text('1 korábbi megálló megjelenítése'));
    await tester.pumpAndSettle();

    // Now all stops should be visible
    expect(find.text('Budapest-Keleti'), findsOneWidget);
    expect(find.text('Kelenföld'), findsOneWidget);
    expect(find.text('Győr'), findsOneWidget);
    expect(find.text('Korábbi megállók elrejtése'), findsOneWidget);

    // Tap to collapse
    await tester.tap(find.text('Korábbi megállók elrejtése'));
    await tester.pumpAndSettle();

    expect(find.text('Budapest-Keleti'), findsNothing);
    expect(find.text('Kelenföld'), findsOneWidget);
  });
}
