import '../models/ticket_item.dart';
import '../models/auth_results.dart';
import '../services/ticket_api_service.dart';
import 'ticket_repository.dart';

class HttpTicketRepository implements TicketRepository {
  final TicketApiService _apiService;

  const HttpTicketRepository({
    required TicketApiService apiService,
  }) : _apiService = apiService;

  @override
  Future<TicketsResult> fetchTickets() {
    return _apiService.fetchTickets();
  }

  @override
  Future<TicketFormOptionsResult> fetchTicketFormOptions() {
    return _apiService.fetchTicketFormOptions();
  }

  @override
  Future<AuthActionResult> addTicket({
    required String agency,
    required String ticketType,
    String? ticketStart,
    String? ticketEnd,
    int? quantity,
    List<String>? agencyIds,
  }) {
    return _apiService.addTicket(
      agency: agency,
      ticketType: ticketType,
      ticketStart: ticketStart,
      ticketEnd: ticketEnd,
      quantity: quantity,
      agencyIds: agencyIds,
    );
  }

  @override
  Future<AuthActionResult> updateTicket(TicketItem updatedTicket) {
    return _apiService.updateTicket(updatedTicket);
  }

  @override
  Future<AuthActionResult> deleteTicket(int ticketId) {
    return _apiService.deleteTicket(ticketId);
  }
}
