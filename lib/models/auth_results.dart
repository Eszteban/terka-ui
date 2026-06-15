import 'auth_session.dart';
import 'ticket_item.dart';
import 'ticket_options.dart';

class AuthLoginResult {
  final bool ok;
  final String? error;
  final AuthSession? session;

  const AuthLoginResult({required this.ok, this.error, this.session});
}

class AuthActionResult {
  final bool ok;
  final String? error;
  final String? message;

  const AuthActionResult({required this.ok, this.error, this.message});
}

class TicketFormOptionsResult {
  final bool ok;
  final String? error;
  final List<TicketAgencyOption> agencies;
  final List<TicketTypeOption> ticketTypes;

  const TicketFormOptionsResult({
    required this.ok,
    this.error,
    this.agencies = const [],
    this.ticketTypes = const [],
  });
}

class TicketsResult {
  final bool ok;
  final String? error;
  final List<TicketItem> tickets;

  const TicketsResult({required this.ok, this.error, this.tickets = const []});
}

class AuthProfileUpdateResult {
  final bool ok;
  final String? error;
  final String? message;
  final bool passwordChangeConfirmationRequired;
  final AuthSession? updatedSession;

  const AuthProfileUpdateResult({
    required this.ok,
    this.error,
    this.message,
    this.passwordChangeConfirmationRequired = false,
    this.updatedSession,
  });
}
