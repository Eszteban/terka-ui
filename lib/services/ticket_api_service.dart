import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket_item.dart';
import '../models/auth_results.dart';
import '../models/ticket_options.dart';
import 'package:terka/theme/app_texts.dart';
import 'graphql/graphql_client.dart';

class TicketApiService {
  const TicketApiService();

  Future<TicketsResult> fetchTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_tickets_v1');
      if (raw == null || raw.trim().isEmpty) {
        return const TicketsResult(ok: true, tickets: []);
      }

      final dynamic decoded = jsonDecode(raw);
      final tickets = <TicketItem>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            tickets.add(TicketItem.fromJson(item.cast<String, dynamic>()));
          }
        }
      }
      return TicketsResult(ok: true, tickets: tickets);
    } catch (e) {
      return TicketsResult(ok: false, error: AppTexts.authLoadTicketsFailed('$e'));
    }
  }

  Future<TicketFormOptionsResult> fetchTicketFormOptions() async {
    const String query = '{agencies {name gtfsId}}';
    final agencies = <TicketAgencyOption>[];
    final ticketTypes = [
      TicketTypeOption(value: 'vonaljegy', label: AppTexts.addTicketTypeSingle),
      TicketTypeOption(value: 'bérlet', label: AppTexts.addTicketTypePass),
    ];

    try {
      final client = const GraphqlClient();
      final response = await client
          .execute(query: query)
          .timeout(const Duration(seconds: 8));

      if (response.isSuccess && response.json != null) {
        final data = response.json!['data'];
        if (data is Map) {
          final rawAgencies = data['agencies'];
          if (rawAgencies is List) {
            for (final item in rawAgencies) {
              if (item is Map) {
                final gtfsId = (item['gtfsId'] ?? '').toString();
                final name = (item['name'] ?? '').toString();
                if (gtfsId.isNotEmpty && name.isNotEmpty) {
                  agencies.add(TicketAgencyOption(id: gtfsId, name: name));
                }
              }
            }
          }
        }
      }
    } catch (e) {
      // Fallback
    }

    if (agencies.isEmpty) {
      agencies.add(
        const TicketAgencyOption(
          id: '1:198',
          name: 'MÁV Személyszállítási Zrt.',
        ),
      );
      agencies.add(const TicketAgencyOption(id: 'BKK:BKK', name: 'BKK'));
      agencies.add(const TicketAgencyOption(id: '1:134', name: 'GYSEV Zrt.'));
    }

    const Map<String, String> accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ö': 'o',
      'ő': 'o',
      'ú': 'u',
      'ü': 'u',
      'ű': 'u',
      'Á': 'a',
      'É': 'e',
      'Í': 'i',
      'Ó': 'o',
      'Ö': 'o',
      'Ő': 'o',
      'Ú': 'u',
      'Ü': 'u',
      'Ű': 'u',
    };

    String normalize(String s) {
      final sb = StringBuffer();
      for (int i = 0; i < s.length; i++) {
        final char = s[i];
        sb.write(accents[char] ?? char.toLowerCase());
      }
      return sb.toString();
    }

    agencies.sort((a, b) {
      final normA = normalize(a.name);
      final normB = normalize(b.name);
      final cmp = normA.compareTo(normB);
      if (cmp != 0) return cmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return TicketFormOptionsResult(
      ok: true,
      agencies: agencies,
      ticketTypes: ticketTypes,
    );
  }

  Future<AuthActionResult> addTicket({
    required String agency,
    required String ticketType,
    String? ticketStart,
    String? ticketEnd,
    int? quantity,
    List<String>? agencyIds,
  }) async {
    try {
      final ticketsResult = await fetchTickets();
      final tickets = List<TicketItem>.from(ticketsResult.tickets);

      final optionsResult = await fetchTicketFormOptions();
      final List<String> finalAgencyIds = agencyIds ?? [agency];
      final List<String> finalAgencyNames = [];

      for (final id in finalAgencyIds) {
        final agencyObj = optionsResult.agencies.firstWhere(
          (a) => a.id == id,
          orElse: () => TicketAgencyOption(id: id, name: id),
        );
        finalAgencyNames.add(agencyObj.name);
      }

      int nextId = 1;
      if (tickets.isNotEmpty) {
        nextId = tickets.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
      }

      final newTicket = TicketItem(
        id: nextId,
        agencyId: finalAgencyIds.isNotEmpty ? finalAgencyIds.first : agency,
        agencyName: finalAgencyNames.isNotEmpty
            ? finalAgencyNames.first
            : agency,
        agencyIds: finalAgencyIds,
        agencyNames: finalAgencyNames,
        ticketType: ticketType,
        ticketStart: ticketStart,
        ticketEnd: ticketEnd,
        quantity: quantity,
      );

      tickets.add(newTicket);

      final prefs = await SharedPreferences.getInstance();
      final serialized = jsonEncode(tickets.map((t) => t.toJson()).toList());
      await prefs.setString('local_tickets_v1', serialized);

      return AuthActionResult(
        ok: true,
        message: AppTexts.authAddTicketSuccess,
      );
    } catch (e) {
      return AuthActionResult(
        ok: false,
        error: AppTexts.authAddTicketError('$e'),
      );
    }
  }

  Future<AuthActionResult> updateTicket(TicketItem updatedTicket) async {
    try {
      final ticketsResult = await fetchTickets();
      final tickets = List<TicketItem>.from(ticketsResult.tickets);

      final index = tickets.indexWhere((t) => t.id == updatedTicket.id);
      if (index == -1) {
        return AuthActionResult(
          ok: false,
          error: AppTexts.authTicketNotFound,
        );
      }

      final optionsResult = await fetchTicketFormOptions();
      final List<String> finalAgencyIds = updatedTicket.agencyIds ?? [updatedTicket.agencyId];
      final List<String> finalAgencyNames = [];

      for (final id in finalAgencyIds) {
        final agencyObj = optionsResult.agencies.firstWhere(
          (a) => a.id == id,
          orElse: () => TicketAgencyOption(id: id, name: id),
        );
        finalAgencyNames.add(agencyObj.name);
      }

      tickets[index] = TicketItem(
        id: updatedTicket.id,
        agencyId: finalAgencyIds.isNotEmpty ? finalAgencyIds.first : updatedTicket.agencyId,
        agencyName: finalAgencyNames.isNotEmpty ? finalAgencyNames.first : updatedTicket.agencyName,
        agencyIds: finalAgencyIds,
        agencyNames: finalAgencyNames,
        ticketType: updatedTicket.ticketType,
        ticketStart: updatedTicket.ticketStart,
        ticketEnd: updatedTicket.ticketEnd,
        quantity: updatedTicket.quantity,
      );

      final prefs = await SharedPreferences.getInstance();
      final serialized = jsonEncode(tickets.map((t) => t.toJson()).toList());
      await prefs.setString('local_tickets_v1', serialized);

      return AuthActionResult(
        ok: true,
        message: AppTexts.authUpdateTicketSuccess,
      );
    } catch (e) {
      return AuthActionResult(
        ok: false,
        error: AppTexts.authUpdateTicketError('$e'),
      );
    }
  }

  Future<AuthActionResult> deleteTicket(int ticketId) async {
    try {
      final ticketsResult = await fetchTickets();
      final tickets = List<TicketItem>.from(ticketsResult.tickets);

      final index = tickets.indexWhere((t) => t.id == ticketId);
      if (index == -1) {
        return AuthActionResult(
          ok: false,
          error: AppTexts.authTicketNotFound,
        );
      }

      tickets.removeAt(index);

      final prefs = await SharedPreferences.getInstance();
      final serialized = jsonEncode(tickets.map((t) => t.toJson()).toList());
      await prefs.setString('local_tickets_v1', serialized);

      return AuthActionResult(
        ok: true,
        message: AppTexts.authDeleteTicketSuccess,
      );
    } catch (e) {
      return AuthActionResult(
        ok: false,
        error: AppTexts.authDeleteTicketError('$e'),
      );
    }
  }
}
