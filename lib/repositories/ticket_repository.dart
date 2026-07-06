import '../models/ticket_item.dart';
import '../models/auth_results.dart';

abstract class TicketRepository {
  Future<TicketsResult> fetchTickets();
  Future<TicketFormOptionsResult> fetchTicketFormOptions();
  Future<AuthActionResult> addTicket({
    required String agency,
    required String ticketType,
    String? ticketStart,
    String? ticketEnd,
    int? quantity,
    List<String>? agencyIds,
  });
  Future<AuthActionResult> updateTicket(TicketItem updatedTicket);
  Future<AuthActionResult> deleteTicket(int ticketId);
}
