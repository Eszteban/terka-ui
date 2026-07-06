import '../models/ticket_item.dart';
import '../models/pass_type.dart';

extension TicketUi on TicketItem {
  String getDisplayName(List<PassType> passTypes) {
    if (ticketType == 'bérlet') {
      final ticketIds = Set<String>.from(agencyIds ?? []);
      if (ticketIds.isNotEmpty) {
        for (final pt in passTypes) {
          final ptIds = Set<String>.from(pt.agencyIds);
          if (ticketIds.length == ptIds.length && ticketIds.containsAll(ptIds)) {
            return pt.name;
          }
        }
      }
    }
    return (agencyNames != null && agencyNames!.isNotEmpty)
        ? agencyNames!.join(', ')
        : agencyName;
  }
}
