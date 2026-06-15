import 'package:flutter_test/flutter_test.dart';
import 'package:terka/models/pass_type.dart';
import 'package:terka/models/ticket_item.dart';
import 'package:terka/theme/app_texts.dart';

void main() {
  group('TicketItem.getDisplayName tests', () {
    final prebakedPassTypes = PassType.getPrebakedPassTypes();

    test('Returns Országbérlet when agencyIds matches perfectly', () {
      final orszagberletAgencies = [
        'BKK:BKK',
        '1:1164',
        'hkir:hkir_V-30988',
        'hkir:hkir_V-05111',
        'hkir:hkir_V-23603',
        'hkir:hkir_V-25131',
        'hkir:hkir_V',
        '1:198',
        'debrecen:DKV',
        'mvkzrt:MVK',
        '1:134',
      ];

      final ticket = TicketItem(
        id: 1,
        agencyId: 'BKK:BKK',
        agencyName: 'BKK',
        agencyIds: orszagberletAgencies,
        agencyNames: ['BKK', 'MÁV', 'GYSEV'],
        ticketType: 'bérlet',
      );

      expect(ticket.getDisplayName(prebakedPassTypes), equals('Országbérlet'));
    });

    test('Returns Országbérlet + Szeged when agencyIds matches that pass type', () {
      final szegedAgencies = [
        'BKK:BKK',
        '1:1164',
        'hkir:hkir_V-30988',
        'hkir:hkir_V-05111',
        'hkir:hkir_V-23603',
        'hkir:hkir_V-25131',
        'hkir:hkir_V',
        '1:198',
        'debrecen:DKV',
        'mvkzrt:MVK',
        'hkir:hkir_V-33367',
        'szeged:hkir_V-33367',
        'szeged:SZKT',
        '1:134',
      ];

      final ticket = TicketItem(
        id: 2,
        agencyId: 'BKK:BKK',
        agencyName: 'BKK',
        agencyIds: szegedAgencies,
        agencyNames: ['BKK', 'MÁV', 'SZKT'],
        ticketType: 'bérlet',
      );

      expect(ticket.getDisplayName(prebakedPassTypes), equals('Országbérlet + Szeged'));
    });

    test('Falls back to agencyNames join when ticketType is not bérlet', () {
      final orszagberletAgencies = [
        'BKK:BKK',
        '1:1164',
        'hkir:hkir_V-30988',
        'hkir:hkir_V-05111',
        'hkir:hkir_V-23603',
        'hkir:hkir_V-25131',
        'hkir:hkir_V',
        '1:198',
        'debrecen:DKV',
        'mvkzrt:MVK',
        '1:134',
      ];

      final ticket = TicketItem(
        id: 3,
        agencyId: 'BKK:BKK',
        agencyName: 'BKK',
        agencyIds: orszagberletAgencies,
        agencyNames: ['BKK', 'MÁV', 'GYSEV'],
        ticketType: 'vonaljegy',
      );

      // Should join agencyNames since it's a vonaljegy, not a bérlet
      expect(ticket.getDisplayName(prebakedPassTypes), equals('BKK, MÁV, GYSEV'));
    });

    test('Falls back to agencyNames join when pass type is not in list', () {
      final ticket = TicketItem(
        id: 4,
        agencyId: 'BKK:BKK',
        agencyName: 'BKK',
        agencyIds: ['BKK:BKK', 'unknown:agency'],
        agencyNames: ['BKK', 'Egyéb Társaság'],
        ticketType: 'bérlet',
      );

      expect(ticket.getDisplayName(prebakedPassTypes), equals('BKK, Egyéb Társaság'));
    });

    test('Falls back to agencyName if agencyNames is empty or null', () {
      final ticket = TicketItem(
        id: 5,
        agencyId: 'BKK:BKK',
        agencyName: 'BKK Solo',
        agencyIds: [],
        agencyNames: null,
        ticketType: 'bérlet',
      );

      expect(ticket.getDisplayName(prebakedPassTypes), equals('BKK Solo'));
    });
  });

  group('AppTexts.managePassTypesAgencies tests', () {
    test('Formats correctly for empty list', () {
      AppTexts.setLanguage(AppLanguage.hu);
      expect(AppTexts.managePassTypesAgencies([]), equals('Érvényes szolgáltatók: -'));
      AppTexts.setLanguage(AppLanguage.en);
      expect(AppTexts.managePassTypesAgencies([]), equals('Valid agencies: -'));
    });

    test('Formats correctly for <= 3 agencies', () {
      AppTexts.setLanguage(AppLanguage.hu);
      expect(AppTexts.managePassTypesAgencies(['BKK']), equals('Érvényes szolgáltatók: BKK'));
      expect(AppTexts.managePassTypesAgencies(['BKK', 'MÁV', 'GYSEV']), equals('Érvényes szolgáltatók: BKK, MÁV, GYSEV'));

      AppTexts.setLanguage(AppLanguage.en);
      expect(AppTexts.managePassTypesAgencies(['BKK']), equals('Valid agencies: BKK'));
      expect(AppTexts.managePassTypesAgencies(['BKK', 'MÁV', 'GYSEV']), equals('Valid agencies: BKK, MÁV, GYSEV'));
    });

    test('Formats correctly for > 3 agencies with truncation and extra count', () {
      final agencies = ['BKK', 'MÁV', 'GYSEV', 'DKV', 'MVK'];

      AppTexts.setLanguage(AppLanguage.hu);
      expect(AppTexts.managePassTypesAgencies(agencies), equals('Érvényes szolgáltatók: BKK, MÁV, GYSEV és 2 további'));

      AppTexts.setLanguage(AppLanguage.en);
      expect(AppTexts.managePassTypesAgencies(agencies), equals('Valid agencies: BKK, MÁV, GYSEV and 2 more'));
    });
  });

  group('TicketItem.hasValidTicketsForItinerary tests', () {
    test('Walking-only plan needs no tickets (returns true)', () {
      final itinerary = {
        'legs': [
          {'mode': 'WALK'}
        ]
      };
      expect(TicketItem.hasValidTicketsForItinerary(itinerary, []), isTrue);
    });

    test('Transit plan covered by a valid pass returns true', () {
      final itinerary = {
        'legs': [
          {
            'mode': 'BUS',
            'agency': {'id': 'BKK:BKK'}
          }
        ]
      };

      // Valid pass for BKK
      final tickets = [
        TicketItem(
          id: 1,
          agencyId: 'BKK:BKK',
          agencyName: 'BKK',
          agencyIds: ['BKK:BKK'],
          ticketType: 'bérlet',
          ticketStart: '2026-01-01T00:00',
          ticketEnd: '2027-12-31T23:59',
        )
      ];

      expect(TicketItem.hasValidTicketsForItinerary(itinerary, tickets), isTrue);
    });

    test('Transit plan covered by a multi-agency pass (Országbérlet) returns true', () {
      final itinerary = {
        'legs': [
          {
            'mode': 'BUS',
            'agency': {'id': 'BKK:BKK'}
          },
          {
            'mode': 'RAIL',
            'agency': {'id': '1:198'}
          }
        ]
      };

      // Valid Országbérlet covering both BKK and MÁV
      final tickets = [
        TicketItem(
          id: 2,
          agencyId: '1:198',
          agencyName: 'MÁV',
          agencyIds: ['BKK:BKK', '1:198'],
          ticketType: 'bérlet',
          ticketStart: '2026-01-01T00:00',
          ticketEnd: '2027-12-31T23:59',
        )
      ];

      expect(TicketItem.hasValidTicketsForItinerary(itinerary, tickets), isTrue);
    });

    test('Expired pass returns false', () {
      final itinerary = {
        'legs': [
          {
            'mode': 'BUS',
            'agency': {'id': 'BKK:BKK'}
          }
        ]
      };

      // Expired pass
      final tickets = [
        TicketItem(
          id: 3,
          agencyId: 'BKK:BKK',
          agencyName: 'BKK',
          agencyIds: ['BKK:BKK'],
          ticketType: 'bérlet',
          ticketStart: '2025-01-01T00:00',
          ticketEnd: '2025-12-31T23:59',
        )
      ];

      expect(TicketItem.hasValidTicketsForItinerary(itinerary, tickets), isFalse);
    });

    test('Single tickets coverage matches quantities correctly', () {
      final itinerary = {
        'legs': [
          {
            'mode': 'BUS',
            'agency': {'id': 'BKK:BKK'}
          },
          {
            'mode': 'TRAM',
            'agency': {'id': 'BKK:BKK'}
          }
        ]
      };

      // Scenario A: Only 1 single ticket for BKK -> should return false (need 2)
      final tickets1 = [
        TicketItem(
          id: 4,
          agencyId: 'BKK:BKK',
          agencyName: 'BKK',
          ticketType: 'vonaljegy',
          quantity: 1,
        )
      ];
      expect(TicketItem.hasValidTicketsForItinerary(itinerary, tickets1), isFalse);

      // Scenario B: 2 single tickets for BKK -> should return true
      final tickets2 = [
        TicketItem(
          id: 5,
          agencyId: 'BKK:BKK',
          agencyName: 'BKK',
          ticketType: 'vonaljegy',
          quantity: 2,
        )
      ];
      expect(TicketItem.hasValidTicketsForItinerary(itinerary, tickets2), isTrue);

      // Scenario C: 2 different tickets summing up to 2 -> should return true
      final tickets3 = [
        TicketItem(
          id: 6,
          agencyId: 'BKK:BKK',
          agencyName: 'BKK',
          ticketType: 'vonaljegy',
          quantity: 1,
        ),
        TicketItem(
          id: 7,
          agencyId: 'BKK:BKK',
          agencyName: 'BKK',
          ticketType: 'vonaljegy',
          quantity: 1,
        )
      ];
      expect(TicketItem.hasValidTicketsForItinerary(itinerary, tickets3), isTrue);
    });
  });

  group('TicketItem.getMissingTicketAgencies tests', () {
    test('Walking-only plan returns empty list', () {
      final itinerary = {
        'legs': [
          {'mode': 'WALK'}
        ]
      };
      expect(TicketItem.getMissingTicketAgencies(itinerary, []), isEmpty);
    });

    test('All transits covered by pass returns empty list', () {
      final itinerary = {
        'legs': [
          {
            'mode': 'BUS',
            'agency': {'id': 'BKK:BKK', 'name': 'BKK'}
          }
        ]
      };
      final tickets = [
        TicketItem(
          id: 1,
          agencyId: 'BKK:BKK',
          agencyName: 'BKK',
          ticketType: 'bérlet',
          ticketStart: '2026-01-01T00:00',
          ticketEnd: '2027-12-31T23:59',
        )
      ];
      expect(TicketItem.getMissingTicketAgencies(itinerary, tickets), isEmpty);
    });

    test('Missing ticket for single agency returns that agency name', () {
      final itinerary = {
        'legs': [
          {
            'mode': 'BUS',
            'agency': {'id': 'BKK:BKK', 'name': 'BKK'}
          }
        ]
      };
      expect(TicketItem.getMissingTicketAgencies(itinerary, []), equals(['BKK']));
    });

    test('Missing tickets for multiple agencies returns both agency names without duplicates', () {
      final itinerary = {
        'legs': [
          {
            'mode': 'BUS',
            'agency': {'id': 'BKK:BKK', 'name': 'BKK'}
          },
          {
            'mode': 'BUS',
            'agency': {'id': 'BKK:BKK', 'name': 'BKK'}
          },
          {
            'mode': 'RAIL',
            'agency': {'id': '1:198', 'name': 'MÁV'}
          }
        ]
      };

      // Only 1 BKK single ticket (needs 2) and 0 MÁV tickets
      final tickets = [
        TicketItem(
          id: 1,
          agencyId: 'BKK:BKK',
          agencyName: 'BKK',
          ticketType: 'vonaljegy',
          quantity: 1,
        )
      ];

      final missing = TicketItem.getMissingTicketAgencies(itinerary, tickets);
      expect(missing, contains('BKK'));
      expect(missing, contains('MÁV'));
      expect(missing.length, equals(2));
    });

    test('Robust agency matching: prefix removal, case-insensitivity, name sub-matches', () {
      final itinerary = {
        'legs': [
          {
            'mode': 'BUS',
            'agency': {'id': 'BKK:BKK', 'name': 'BKK'}
          },
          {
            'mode': 'RAIL',
            'agency': {'id': '1:198', 'name': 'MÁV-START'}
          }
        ]
      };

      final tickets = [
        TicketItem(
          id: 1,
          agencyId: 'BKK',
          agencyName: 'BKK',
          ticketType: 'bérlet',
          ticketStart: '2026-01-01T00:00',
          ticketEnd: '2027-12-31T23:59',
        ),
        TicketItem(
          id: 2,
          agencyId: '198',
          agencyName: 'MÁV Személyszállítási Zrt.',
          ticketType: 'bérlet',
          ticketStart: '2026-01-01T00:00',
          ticketEnd: '2027-12-31T23:59',
        )
      ];

      // Since both match robustly, missing agencies list should be empty
      expect(TicketItem.getMissingTicketAgencies(itinerary, tickets), isEmpty);
    });
  });
}

