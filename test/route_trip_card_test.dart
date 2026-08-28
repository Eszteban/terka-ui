import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terka/screens/route_details/widgets/route_trip_card.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/theme/terka_semantic_colors.dart';

void main() {
  testWidgets('RouteTripCard renders with green border when active vehicle is registered', (tester) async {
    final trip = {
      'gtfsId': 'test_trip_1',
      'tripShortName': 'S50',
      'tripHeadsign': 'Monor',
      'vehiclePositions': [
        {'vehicleId': 'test_vehicle_1', 'lat': 47.4, 'lon': 19.1}
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [TerkaSemanticColors.light],
        ),
        home: Scaffold(
          body: RouteTripCard(
            trip: trip,
            runsToday: true,
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    expect(shape.side.color, TerkaSemanticColors.light.onTime);
    expect(shape.side.width, 2.0);
  });

  testWidgets('RouteTripCard renders without green border when runs today without active vehicle', (tester) async {
    final trip = {
      'gtfsId': 'test_trip_1_no_veh',
      'tripShortName': 'S50',
      'tripHeadsign': 'Monor',
      'vehiclePositions': <dynamic>[],
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [TerkaSemanticColors.light],
        ),
        home: Scaffold(
          body: RouteTripCard(
            trip: trip,
            runsToday: true,
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    expect(shape.side, BorderSide.none);
    expect(find.text('Bejelentkezve'), findsNothing);
  });

  testWidgets('RouteTripCard renders with outline border and warning when runsToday is false', (tester) async {
    final trip = {
      'gtfsId': 'test_trip_2',
      'tripShortName': 'Z50',
      'tripHeadsign': 'Szolnok',
      'vehiclePositions': <dynamic>[],
    };

    final themeData = ThemeData(
      extensions: const [TerkaSemanticColors.light],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: themeData,
        home: Scaffold(
          body: RouteTripCard(
            trip: trip,
            runsToday: false,
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    expect(shape.side.color, themeData.colorScheme.outlineVariant);
    expect(find.text(AppTexts.routeDetailsNotRunningToday), findsOneWidget);
  });
}
