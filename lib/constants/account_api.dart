class AccountApi {
  // Android emulator alatt a localhost a host gépre a 10.0.2.2 címen érhető el.
  static const String baseUrl = 'http://192.168.1.69:8000/terkapi/account';

  static String get registerUrl => '$baseUrl/register/';
  static String get activateUrl => '$baseUrl/activate/';
  static String get loginUrl => '$baseUrl/login/';
  static String get logoutUrl => '$baseUrl/logout/';
  static String get updateProfileUrl => '$baseUrl/profile/update/';
  static String get confirmPasswordChangeUrl => '$baseUrl/profile/password/confirm/';
  static String get ticketsUrl => '$baseUrl/profile/tickets/';
  static String get ticketOptionsUrl => '$baseUrl/profile/tickets/options/';
  static String get addTicketUrl => '$baseUrl/profile/tickets/add/';
  static String get meUrl => '$baseUrl/me/';
  static String get validateTokenUrl => '$baseUrl/validate-token/';
}
