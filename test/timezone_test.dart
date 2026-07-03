import 'package:flutter_test/flutter_test.dart';
import 'package:terka/utils/stop_details_utils.dart';

void main() {
  group('Europe/Budapest Timezone Calculations', () {
    test('Standard time offset (CET, UTC+1)', () {
      final winter = DateTime.utc(2026, 1, 15, 12, 0);
      expect(StopDetailsUtils.getBudapestOffsetHours(winter), 1);
      
      final localWinter = StopDetailsUtils.toBudapestTime(winter);
      expect(localWinter.hour, 13);
      expect(localWinter.day, 15);
    });

    test('Daylight saving time offset (CEST, UTC+2)', () {
      final summer = DateTime.utc(2026, 7, 15, 12, 0);
      expect(StopDetailsUtils.getBudapestOffsetHours(summer), 2);

      final localSummer = StopDetailsUtils.toBudapestTime(summer);
      expect(localSummer.hour, 14);
      expect(localSummer.day, 15);
    });

    test('DST March transition bounds (March 29, 2026)', () {
      // Last Sunday of March 2026 is March 29th. Transition is at 01:00 UTC.
      final beforeDst = DateTime.utc(2026, 3, 29, 0, 59, 59);
      final afterDst = DateTime.utc(2026, 3, 29, 1, 0, 0);

      expect(StopDetailsUtils.getBudapestOffsetHours(beforeDst), 1);
      expect(StopDetailsUtils.getBudapestOffsetHours(afterDst), 2);

      final localBefore = StopDetailsUtils.toBudapestTime(beforeDst);
      final localAfter = StopDetailsUtils.toBudapestTime(afterDst);

      expect(localBefore.hour, 1); // 00:59:59 + 1 hour = 01:59:59
      expect(localAfter.hour, 3);  // 01:00:00 + 2 hours = 03:00:00
    });

    test('DST October transition bounds (October 25, 2026)', () {
      // Last Sunday of October 2026 is October 25th. Transition is at 01:00 UTC.
      final beforeTransition = DateTime.utc(2026, 10, 25, 0, 59, 59);
      final afterTransition = DateTime.utc(2026, 10, 25, 1, 0, 0);

      expect(StopDetailsUtils.getBudapestOffsetHours(beforeTransition), 2);
      expect(StopDetailsUtils.getBudapestOffsetHours(afterTransition), 1);

      final localBefore = StopDetailsUtils.toBudapestTime(beforeTransition);
      final localAfter = StopDetailsUtils.toBudapestTime(afterTransition);

      expect(localBefore.hour, 2); // 00:59:59 + 2 hours = 02:59:59
      expect(localAfter.hour, 2);  // 01:00:00 + 1 hour = 02:00:00
    });

    test('budapestMidnightUtc calculation', () {
      // June 17, 2026 (DST active -> UTC+2)
      final midSummer = StopDetailsUtils.budapestMidnightUtc(2026, 6, 17);
      expect(midSummer, DateTime.utc(2026, 6, 16, 22, 0));

      // December 17, 2026 (Standard time -> UTC+1)
      final midWinter = StopDetailsUtils.budapestMidnightUtc(2026, 12, 17);
      expect(midWinter, DateTime.utc(2026, 12, 16, 23, 0));
    });

    test('isSameBudapestDay matching', () {
      final dateBudapest = DateTime.utc(2026, 6, 17);
      
      // 00:30 Budapest time on June 17 (which is 22:30 UTC on June 16)
      final earlyMorning = DateTime.utc(2026, 6, 16, 22, 30);
      expect(StopDetailsUtils.isSameBudapestDay(dateBudapest, earlyMorning), true);

      // 23:30 Budapest time on June 17 (which is 21:30 UTC on June 17)
      final lateNight = DateTime.utc(2026, 6, 17, 21, 30);
      expect(StopDetailsUtils.isSameBudapestDay(dateBudapest, lateNight), true);

      // 00:30 Budapest time on June 18 (which is 22:30 UTC on June 17)
      final nextDayEarly = DateTime.utc(2026, 6, 17, 22, 30);
      expect(StopDetailsUtils.isSameBudapestDay(dateBudapest, nextDayEarly), false);
    });

    test('resolveDepartureInstant resolves absolute physical time', () {
      // serviceDay: 2026-06-16 22:00:00Z (midnight Budapest on June 17)
      // secondsOfDay: 75000 (20:50)
      final serviceDay = 1781647200;
      final secondsOfDay = 75000;

      final instant = StopDetailsUtils.resolveDepartureInstant(
        serviceDay: serviceDay,
        secondsOfDay: secondsOfDay,
      );

      expect(instant, DateTime.utc(2026, 6, 17, 18, 50));
    });

    test('resolveDepartureTime resolves to correct Budapest fields', () {
      final serviceDay = 1781647200; // June 17, 2026 Budapest midnight
      final secondsOfDay = 75000;    // 20:50:00

      final departureTime = StopDetailsUtils.resolveDepartureTime(
        serviceDay: serviceDay,
        secondsOfDay: secondsOfDay,
      );

      expect(departureTime?.isUtc, true);
      expect(departureTime?.year, 2026);
      expect(departureTime?.month, 6);
      expect(departureTime?.day, 17);
      expect(departureTime?.hour, 20);
      expect(departureTime?.minute, 50);
    });
  });
}
