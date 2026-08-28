import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terka/theme/app_texts.dart';
import 'package:terka/widgets/maps/vehicle_info_card.dart';

void main() {
  setUp(() {
    AppTexts.setLanguage(AppLanguage.hu);
  });

  testWidgets('VehicleInfoCard shows elapsed seconds and ticks every second', (tester) async {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final lastUpdated = nowSeconds - 5;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleInfoCard(
            lineLabel: '1',
            lineLabelUsesSpanFont: false,
            tripNumberLabel: '1234',
            tripHeadsignLabel: 'Keleti pályaudvar',
            serviceLabel: 'BKK-1234',
            modelLabel: 'Solaris Trollino',
            vehicleSpeed: 35,
            arrivalDelaySeconds: 120,
            nextStopName: 'Blaha Lujza tér',
            markerColor: Colors.blue,
            markerTextColor: Colors.white,
            nextStopStatus: 'IN_TRANSIT_TO',
            lastUpdated: lastUpdated,
          ),
        ),
      ),
    );

    final initialFinder = find.byWidgetPredicate(
      (widget) => widget is Text && widget.data?.contains('másodperce frissült') == true,
    );
    expect(initialFinder, findsOneWidget);
    final initialText = (tester.widget(initialFinder) as Text).data!;
    final match = RegExp(r'(\d+)').firstMatch(initialText);
    expect(match, isNotNull);
    final initialCount = int.parse(match!.group(1)!);

    // Advance 3 seconds
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('${initialCount + 3} másodperce frissült'), findsOneWidget);

    // Advance another 2 seconds
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('${initialCount + 5} másodperce frissült'), findsOneWidget);
  });

  testWidgets('VehicleInfoCard without lastUpdated does not show or tick counter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleInfoCard(
            lineLabel: '1',
            lineLabelUsesSpanFont: false,
            tripNumberLabel: '1234',
            tripHeadsignLabel: 'Keleti pályaudvar',
            serviceLabel: 'BKK-1234',
            modelLabel: 'Solaris Trollino',
            vehicleSpeed: 35,
            arrivalDelaySeconds: 120,
            nextStopName: 'Blaha Lujza tér',
            markerColor: Colors.blue,
            markerTextColor: Colors.white,
            nextStopStatus: 'IN_TRANSIT_TO',
            lastUpdated: null,
          ),
        ),
      ),
    );

    expect(find.textContaining('másodperce frissült'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(find.textContaining('másodperce frissült'), findsNothing);
  });
}
