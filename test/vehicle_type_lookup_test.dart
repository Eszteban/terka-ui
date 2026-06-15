import 'package:flutter_test/flutter_test.dart';
import 'package:terka/utils/vehicle_type_lookup.dart';

void main() {
  group('VehicleTypeLookup tests', () {
    test('Exact 4-digit UIC series lookup', () {
      expect(VehicleTypeLookup.lookup('0431'), equals('V43 Szili'));
      expect(VehicleTypeLookup.lookup('0418'), equals('M41 Csörgő'));
      expect(VehicleTypeLookup.lookup('0815'), equals('Stadler KISS'));
      expect(VehicleTypeLookup.lookup('2920'), equals('C-50'));
    });

    test('Full 12-digit UIC number lookup', () {
      // 91 55 0431 012-3 -> extracted series is "0431"
      expect(VehicleTypeLookup.lookup('91 55 0431 012-3'), equals('V43 Szili'));
      expect(VehicleTypeLookup.lookup('915504310123'), equals('V43 Szili'));
      // 91 55 0418 309-3 -> extracted series is "0418"
      expect(VehicleTypeLookup.lookup('91 55 0418 309-3'), equals('M41 Csörgő'));
    });

    test('Object constructor and getter lookup', () {
      const lookupSzili = VehicleTypeLookup('0431');
      expect(lookupSzili.vehicleType, equals('V43 Szili'));
      expect(lookupSzili.name, equals('V43 Szili'));

      const lookupUnknown = VehicleTypeLookup('9999');
      expect(lookupUnknown.vehicleType, equals('Ismeretlen'));
    });

    test('Bracket operator lookup', () {
      const lookup = VehicleTypeLookup('');
      expect(lookup['0431'], equals('V43 Szili'));
      expect(lookup['0418'], equals('M41 Csörgő'));
      expect(lookup['9999'], equals('Ismeretlen'));
    });

    test('Callable lookup', () {
      const lookup = VehicleTypeLookup('');
      expect(lookup('0431'), equals('V43 Szili'));
      expect(lookup('0418'), equals('M41 Csörgő'));
      expect(lookup('9999'), equals('Ismeretlen'));
    });

    test('Unknown or empty inputs', () {
      expect(VehicleTypeLookup.lookup(''), equals('Ismeretlen'));
      expect(VehicleTypeLookup.lookup('   '), equals('Ismeretlen'));
      expect(VehicleTypeLookup.lookup('ABCD'), equals('Ismeretlen'));
    });
  });
}
