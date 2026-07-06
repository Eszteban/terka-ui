class TicketItem {
  final int id;
  final String agencyId;
  final String agencyName;
  final List<String>? agencyIds;
  final List<String>? agencyNames;
  final String ticketType;
  final String? ticketStart;
  final String? ticketEnd;
  final int? quantity;

  const TicketItem({
    required this.id,
    required this.agencyId,
    required this.agencyName,
    this.agencyIds,
    this.agencyNames,
    required this.ticketType,
    this.ticketStart,
    this.ticketEnd,
    this.quantity,
  });

  factory TicketItem.fromJson(Map<String, dynamic> json) {
    final List<String> ids = json['agency_ids'] != null
        ? List<String>.from(json['agency_ids'])
        : [];
    final List<String> names = json['agency_names'] != null
        ? List<String>.from(json['agency_names'])
        : [];

    final String fallbackId = (json['agency_id'] ?? '').toString();
    final String fallbackName = (json['agency_name'] ?? '').toString();

    return TicketItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      agencyId: fallbackId,
      agencyName: fallbackName,
      agencyIds: ids.isNotEmpty
          ? ids
          : (fallbackId.isNotEmpty ? [fallbackId] : []),
      agencyNames: names.isNotEmpty
          ? names
          : (fallbackName.isNotEmpty ? [fallbackName] : []),
      ticketType: (json['ticket_type'] ?? '').toString(),
      ticketStart: json['ticket_start']?.toString(),
      ticketEnd: json['ticket_end']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'agency_id': (agencyIds != null && agencyIds!.isNotEmpty)
        ? agencyIds!.first
        : agencyId,
    'agency_name': (agencyNames != null && agencyNames!.isNotEmpty)
        ? agencyNames!.first
        : agencyName,
    'agency_ids': agencyIds,
    'agency_names': agencyNames,
    'ticket_type': ticketType,
    'ticket_start': ticketStart,
    'ticket_end': ticketEnd,
    'quantity': quantity,
  };

  static bool hasValidTicketsForItinerary(Map<String, dynamic> itinerary, List<TicketItem> tickets) {
    return getMissingTicketAgencies(itinerary, tickets).isEmpty;
  }

  static List<String> getMissingTicketAgencies(Map<String, dynamic> itinerary, List<TicketItem> tickets) {
    final legs = itinerary['legs'];
    if (legs is! List) return const [];

    final transitLegs = legs.whereType<Map>().where((leg) {
      final mode = leg['mode']?.toString() ?? '';
      final isWalk = mode.toUpperCase().trim() == 'WALK';
      final hasAgency = leg['agency'] != null && leg['agency']['id'] != null;
      return !isWalk && hasAgency;
    }).toList();

    if (transitLegs.isEmpty) return const [];

    final now = DateTime.now();
    final validPasses = tickets.where((t) {
      if (t.ticketType != 'bérlet') return false;
      final start = t.ticketStart != null ? DateTime.tryParse(t.ticketStart!) : null;
      final end = t.ticketEnd != null ? DateTime.tryParse(t.ticketEnd!) : null;
      if (start != null && now.isBefore(start)) return false;
      if (end != null && now.isAfter(end)) return false;
      return true;
    }).toList();

    final legsRequiringSingleTickets = <String, int>{};
    final agencyNamesById = <String, String>{};

    for (final leg in transitLegs) {
      final agencyId = leg['agency']['id'].toString();
      final agencyName = leg['agency']['name']?.toString() ?? agencyId;
      agencyNamesById[agencyId] = agencyName;
      
      bool coveredByPass = false;
      for (final pass in validPasses) {
        if (_agencyMatches(legAgencyId: agencyId, legAgencyName: agencyName, ticket: pass)) {
          coveredByPass = true;
          break;
        }
      }

      if (!coveredByPass) {
        legsRequiringSingleTickets[agencyId] = (legsRequiringSingleTickets[agencyId] ?? 0) + 1;
      }
    }

    final missingAgencies = <String>[];

    for (final entry in legsRequiringSingleTickets.entries) {
      final agencyId = entry.key;
      final requiredCount = entry.value;
      final agencyName = agencyNamesById[agencyId] ?? agencyId;

      int availableCount = 0;
      for (final ticket in tickets) {
        if (ticket.ticketType == 'vonaljegy') {
          if (_agencyMatches(legAgencyId: agencyId, legAgencyName: agencyName, ticket: ticket)) {
            availableCount += ticket.quantity ?? 0;
          }
        }
      }

      if (availableCount < requiredCount) {
        final displayName = agencyNamesById[agencyId] ?? agencyId;
        if (!missingAgencies.contains(displayName)) {
          missingAgencies.add(displayName);
        }
      }
    }

    return missingAgencies;
  }

  static bool _agencyMatches({
    required String legAgencyId,
    required String legAgencyName,
    required TicketItem ticket,
  }) {
    final ticketAgencyId = ticket.agencyId;
    final ticketAgencyName = ticket.agencyName;
    final ticketAgencyIds = ticket.agencyIds ?? const <String>[];
    final ticketAgencyNames = ticket.agencyNames ?? const <String>[];

    // 1. Exact ID match (case-insensitive)
    final cleanLegId = legAgencyId.trim().toLowerCase();
    final cleanTicketId = ticketAgencyId.trim().toLowerCase();
    if (cleanLegId == cleanTicketId) return true;

    // 2. Check in ticketAgencyIds list (case-insensitive)
    for (final id in ticketAgencyIds) {
      if (id.trim().toLowerCase() == cleanLegId) return true;
    }

    // 3. Extract the last segment (after the colon) and compare
    // This handles cases like "1:198" matching "198" or "BKK:BKK" matching "BKK"
    final legIdLast = cleanLegId.split(':').last;
    final ticketIdLast = cleanTicketId.split(':').last;
    if (legIdLast == ticketIdLast && legIdLast.isNotEmpty) return true;

    for (final id in ticketAgencyIds) {
      final cleanId = id.trim().toLowerCase();
      final idLast = cleanId.split(':').last;
      if (legIdLast == idLast && legIdLast.isNotEmpty) return true;
    }

    // 4. Name-based match (case-insensitive, ignoring common suffixes/punc)
    final cleanLegName = _normalizeAgencyName(legAgencyName);
    final cleanTicketName = _normalizeAgencyName(ticketAgencyName);
    if (cleanLegName == cleanTicketName && cleanLegName.isNotEmpty) return true;

    for (final name in ticketAgencyNames) {
      final cleanName = _normalizeAgencyName(name);
      if (cleanLegName == cleanName && cleanLegName.isNotEmpty) return true;
    }

    // 5. Check if one name contains the other (for substrings like "MÁV" matching "MÁV Személyszállítási Zrt.")
    if (cleanLegName.isNotEmpty && cleanTicketName.isNotEmpty) {
      if (cleanLegName.contains(cleanTicketName) || cleanTicketName.contains(cleanLegName)) {
        return true;
      }
    }
    for (final name in ticketAgencyNames) {
      final cleanName = _normalizeAgencyName(name);
      if (cleanLegName.isNotEmpty && cleanName.isNotEmpty) {
        if (cleanLegName.contains(cleanName) || cleanName.contains(cleanLegName)) {
          return true;
        }
      }
    }

    return false;
  }

  static String _normalizeAgencyName(String name) {
    const accents = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ö': 'o', 'ő': 'o', 'ú': 'u', 'ü': 'u', 'ű': 'u',
      'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ö': 'o', 'Ő': 'o', 'Ú': 'u', 'Ü': 'u', 'Ű': 'u'
    };
    
    // Replace accents
    final sb = StringBuffer();
    for (int i = 0; i < name.length; i++) {
      final char = name[i];
      sb.write(accents[char] ?? char.toLowerCase());
    }
    
    return sb.toString()
        .replaceAll(RegExp(r'szemelyszallitasi\s+zrt\.?'), '')
        .replaceAll(RegExp(r'zrt\.?'), '')
        .replaceAll(RegExp(r'kft\.?'), '')
        .replaceAll(RegExp(r'kozlekedesi\s+zrt\.?'), '')
        .replaceAll(RegExp(r'szemelyszallitasi'), '')
        .replaceAll(RegExp(r'start'), '')
        .replaceAll(RegExp(r'-'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
  }
}
