import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/account_api.dart';

class AuthSession {
  final String token;
  final int userId;
  final String username;
  final String email;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.username,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'username': username,
    'email': email,
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: (json['token'] ?? '').toString(),
      userId: json['userId'] as int,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class AuthLoginResult {
  final bool ok;
  final String? error;
  final AuthSession? session;

  const AuthLoginResult({
    required this.ok,
    this.error,
    this.session,
  });
}

class AuthActionResult {
  final bool ok;
  final String? error;
  final String? message;

  const AuthActionResult({
    required this.ok,
    this.error,
    this.message,
  });
}

class TicketItem {
  final int id;
  final String agencyId;
  final String agencyName;
  final String ticketType;
  final String? ticketStart;
  final String? ticketEnd;
  final int? quantity;

  const TicketItem({
    required this.id,
    required this.agencyId,
    required this.agencyName,
    required this.ticketType,
    this.ticketStart,
    this.ticketEnd,
    this.quantity,
  });

  factory TicketItem.fromJson(Map<String, dynamic> json) {
    return TicketItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      agencyId: (json['agency_id'] ?? '').toString(),
      agencyName: (json['agency_name'] ?? '').toString(),
      ticketType: (json['ticket_type'] ?? '').toString(),
      ticketStart: json['ticket_start']?.toString(),
      ticketEnd: json['ticket_end']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt(),
    );
  }
}

class TicketAgencyOption {
  final String id;
  final String name;

  const TicketAgencyOption({required this.id, required this.name});

  factory TicketAgencyOption.fromJson(Map<String, dynamic> json) {
    return TicketAgencyOption(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class TicketTypeOption {
  final String value;
  final String label;

  const TicketTypeOption({required this.value, required this.label});

  factory TicketTypeOption.fromJson(Map<String, dynamic> json) {
    return TicketTypeOption(
      value: (json['value'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
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

  const TicketsResult({
    required this.ok,
    this.error,
    this.tickets = const [],
  });
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

class AuthApiService {
  static const String _sessionStorageKey = 'auth_session_v1';
  static const Duration _requestTimeout = Duration(seconds: 10);

  const AuthApiService();

  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse(AccountApi.loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ).timeout(_requestTimeout);
    } catch (e) {
      return AuthLoginResult(ok: false, error: _networkErrorMessage(e));
    }

    Map<String, dynamic>? json;
    try {
      final dynamic parsed = jsonDecode(response.body);
      if (parsed is Map) {
        json = parsed.cast<String, dynamic>();
      }
    } catch (_) {
      json = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300 || json == null) {
      final serverError = _extractServerError(json, response.body);
      return AuthLoginResult(
        ok: false,
        error: serverError.isEmpty
            ? 'Sikertelen bejelentkezés (HTTP ${response.statusCode}).'
            : serverError,
      );
    }

    final bool ok = json['ok'] == true;
    if (!ok) {
      return AuthLoginResult(
        ok: false,
        error: (json['error'] ?? 'Sikertelen bejelentkezés.').toString(),
      );
    }

    final dynamic userData = json['user'];
    if (userData is! Map) {
      return const AuthLoginResult(
        ok: false,
        error: 'A szerver válasza hiányos.',
      );
    }

    final session = AuthSession(
      token: (json['token'] ?? '').toString(),
      userId: (userData['id'] as num?)?.toInt() ?? 0,
      username: (userData['username'] ?? '').toString(),
      email: (userData['email'] ?? '').toString(),
    );

    if (session.token.isEmpty || session.userId == 0 || session.email.isEmpty) {
      return const AuthLoginResult(
        ok: false,
        error: 'A szerver válasza érvénytelen.',
      );
    }

    await saveSession(session);
    return AuthLoginResult(ok: true, session: session);
  }

  Future<AuthActionResult> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse(AccountApi.registerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          'confirm_password': confirmPassword,
        }),
      ).timeout(_requestTimeout);
    } catch (e) {
      return AuthActionResult(ok: false, error: _networkErrorMessage(e));
    }

    Map<String, dynamic>? json;
    try {
      final dynamic parsed = jsonDecode(response.body);
      if (parsed is Map) {
        json = parsed.cast<String, dynamic>();
      }
    } catch (_) {
      json = null;
    }

    final bool isHttpSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isHttpSuccess || json == null) {
      final serverError = _extractServerError(json, response.body);
      return AuthActionResult(
        ok: false,
        error: serverError.isEmpty
            ? 'Sikertelen regisztráció (HTTP ${response.statusCode}).'
            : serverError,
      );
    }

    final bool ok = json['ok'] == true;
    if (!ok) {
      return AuthActionResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    return AuthActionResult(
      ok: true,
      message: (json['message'] ?? 'Sikeres regisztráció.').toString(),
    );
  }

  Future<AuthActionResult> activateAccount({
    required String token,
  }) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse(AccountApi.activateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token.trim()}),
      ).timeout(_requestTimeout);
    } catch (e) {
      return AuthActionResult(ok: false, error: _networkErrorMessage(e));
    }

    Map<String, dynamic>? json;
    try {
      final dynamic parsed = jsonDecode(response.body);
      if (parsed is Map) {
        json = parsed.cast<String, dynamic>();
      }
    } catch (_) {
      json = null;
    }

    final bool isHttpSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isHttpSuccess || json == null) {
      final serverError = _extractServerError(json, response.body);
      return AuthActionResult(
        ok: false,
        error: serverError.isEmpty
            ? 'Sikertelen aktiválás (HTTP ${response.statusCode}).'
            : serverError,
      );
    }

    final bool ok = json['ok'] == true;
    if (!ok) {
      return AuthActionResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    return AuthActionResult(
      ok: true,
      message: (json['message'] ?? 'A fiók sikeresen aktiválva.').toString(),
    );
  }

  Future<AuthProfileUpdateResult> updateProfile({
    required String username,
    String currentPassword = '',
    String newPassword = '',
    String confirmNewPassword = '',
  }) async {
    final currentSession = await loadSession();
    if (currentSession == null) {
      return const AuthProfileUpdateResult(
        ok: false,
        error: 'Nincs aktív munkamenet. Jelentkezz be újra.',
      );
    }

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse(AccountApi.updateProfileUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${currentSession.token}',
        },
        body: jsonEncode({
          'username': username.trim(),
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_new_password': confirmNewPassword,
        }),
      ).timeout(_requestTimeout);
    } catch (e) {
      return AuthProfileUpdateResult(ok: false, error: _networkErrorMessage(e));
    }

    Map<String, dynamic>? json;
    try {
      final dynamic parsed = jsonDecode(response.body);
      if (parsed is Map) {
        json = parsed.cast<String, dynamic>();
      }
    } catch (_) {
      json = null;
    }

    final bool isHttpSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isHttpSuccess || json == null) {
      final serverError = _extractServerError(json, response.body);
      return AuthProfileUpdateResult(
        ok: false,
        error: serverError.isEmpty
            ? 'Sikertelen profilmódosítás (HTTP ${response.statusCode}).'
            : serverError,
      );
    }

    final bool ok = json['ok'] == true;
    if (!ok) {
      return AuthProfileUpdateResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    final bool passwordChangeConfirmationRequired =
        json['password_change_confirmation_required'] == true;

    final dynamic userData = json['user'];
    if (userData is Map) {
      final updated = AuthSession(
        token: currentSession.token,
        userId: (userData['id'] as num?)?.toInt() ?? currentSession.userId,
        username: (userData['username'] ?? currentSession.username).toString(),
        email: (userData['email'] ?? currentSession.email).toString(),
      );
      await saveSession(updated);
      return AuthProfileUpdateResult(
        ok: true,
        passwordChangeConfirmationRequired: passwordChangeConfirmationRequired,
        updatedSession: updated,
        message: (json['message'] ?? 'Profil sikeresen frissítve.').toString(),
      );
    }

    return AuthProfileUpdateResult(
      ok: true,
      passwordChangeConfirmationRequired: passwordChangeConfirmationRequired,
      message: (json['message'] ?? 'Profil sikeresen frissítve.').toString(),
    );
  }

  Future<AuthActionResult> confirmPasswordChange({
    required String token,
  }) async {
    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse(AccountApi.confirmPasswordChangeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token.trim()}),
      ).timeout(_requestTimeout);
    } catch (e) {
      return AuthActionResult(ok: false, error: _networkErrorMessage(e));
    }

    Map<String, dynamic>? json;
    try {
      final dynamic parsed = jsonDecode(response.body);
      if (parsed is Map) {
        json = parsed.cast<String, dynamic>();
      }
    } catch (_) {
      json = null;
    }

    final bool isHttpSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isHttpSuccess || json == null) {
      final serverError = _extractServerError(json, response.body);
      return AuthActionResult(
        ok: false,
        error: serverError.isEmpty
            ? 'Sikertelen jelszó-megerősítés (HTTP ${response.statusCode}).'
            : serverError,
      );
    }

    final bool ok = json['ok'] == true;
    if (!ok) {
      return AuthActionResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    await clearSession();
    return AuthActionResult(
      ok: true,
      message: (json['message'] ?? 'Jelszó módosítva, jelentkezz be újra.').toString(),
    );
  }

  Future<TicketsResult> fetchTickets() async {
    final currentSession = await loadSession();
    if (currentSession == null) {
      return const TicketsResult(ok: false, error: 'Nincs aktív munkamenet.');
    }

    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse(AccountApi.ticketsUrl),
        headers: {'Authorization': 'Bearer ${currentSession.token}'},
      ).timeout(_requestTimeout);
    } catch (e) {
      return TicketsResult(ok: false, error: _networkErrorMessage(e));
    }

    Map<String, dynamic>? json;
    try {
      final dynamic parsed = jsonDecode(response.body);
      if (parsed is Map) {
        json = parsed.cast<String, dynamic>();
      }
    } catch (_) {
      json = null;
    }

    final bool isHttpSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isHttpSuccess || json == null) {
      return TicketsResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    final bool ok = json['ok'] == true;
    if (!ok) {
      return TicketsResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    final dynamic rawTickets = json['tickets'];
    final tickets = <TicketItem>[];
    if (rawTickets is List) {
      for (final item in rawTickets) {
        if (item is Map) {
          tickets.add(TicketItem.fromJson(item.cast<String, dynamic>()));
        }
      }
    }

    return TicketsResult(ok: true, tickets: tickets);
  }

  Future<TicketFormOptionsResult> fetchTicketFormOptions() async {
    final currentSession = await loadSession();
    if (currentSession == null) {
      return const TicketFormOptionsResult(ok: false, error: 'Nincs aktív munkamenet.');
    }

    late final http.Response response;
    try {
      response = await http.get(
        Uri.parse(AccountApi.ticketOptionsUrl),
        headers: {'Authorization': 'Bearer ${currentSession.token}'},
      ).timeout(_requestTimeout);
    } catch (e) {
      return TicketFormOptionsResult(ok: false, error: _networkErrorMessage(e));
    }

    Map<String, dynamic>? json;
    try {
      final dynamic parsed = jsonDecode(response.body);
      if (parsed is Map) {
        json = parsed.cast<String, dynamic>();
      }
    } catch (_) {
      json = null;
    }

    final bool isHttpSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isHttpSuccess || json == null) {
      return TicketFormOptionsResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    final bool ok = json['ok'] == true;
    if (!ok) {
      return TicketFormOptionsResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    final dynamic options = json['options'];
    final agencies = <TicketAgencyOption>[];
    final ticketTypes = <TicketTypeOption>[];
    if (options is Map) {
      final rawAgencies = options['agencies'];
      if (rawAgencies is List) {
        for (final item in rawAgencies) {
          if (item is Map) {
            agencies.add(TicketAgencyOption.fromJson(item.cast<String, dynamic>()));
          }
        }
      }

      final rawTypes = options['ticket_types'];
      if (rawTypes is List) {
        for (final item in rawTypes) {
          if (item is Map) {
            ticketTypes.add(TicketTypeOption.fromJson(item.cast<String, dynamic>()));
          }
        }
      }
    }

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
  }) async {
    final currentSession = await loadSession();
    if (currentSession == null) {
      return const AuthActionResult(ok: false, error: 'Nincs aktív munkamenet.');
    }

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse(AccountApi.addTicketUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${currentSession.token}',
        },
        body: jsonEncode({
          'agency': agency,
          'ticket_type': ticketType,
          'ticket_start': ticketStart,
          'ticket_end': ticketEnd,
          'quantity': quantity,
        }),
      ).timeout(_requestTimeout);
    } catch (e) {
      return AuthActionResult(ok: false, error: _networkErrorMessage(e));
    }

    Map<String, dynamic>? json;
    try {
      final dynamic parsed = jsonDecode(response.body);
      if (parsed is Map) {
        json = parsed.cast<String, dynamic>();
      }
    } catch (_) {
      json = null;
    }

    final bool isHttpSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (!isHttpSuccess || json == null) {
      return AuthActionResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    final bool ok = json['ok'] == true;
    if (!ok) {
      return AuthActionResult(
        ok: false,
        error: _extractServerError(json, response.body),
      );
    }

    return AuthActionResult(
      ok: true,
      message: (json['message'] ?? 'Jegy hozzáadva!').toString(),
    );
  }

  Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionStorageKey, jsonEncode(session.toJson()));
  }

  Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final dynamic parsed = jsonDecode(raw);
      if (parsed is! Map) {
        return null;
      }
      return AuthSession.fromJson(parsed.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionStorageKey);
  }

  String _networkErrorMessage(Object error) {
    if (error is TimeoutException) {
      return 'A szerver nem válaszol időben. Ellenőrizd az internetet vagy próbáld újra később.';
    }
    if (error is SocketException || error is http.ClientException) {
      return 'Nem érhető el a backend. Ellenőrizd az internetkapcsolatot és hogy fut-e a szerver.';
    }
    return 'Hálózati hiba történt. Kérlek, próbáld újra.';
  }

  String _extractServerError(Map<String, dynamic>? json, String rawBody) {
    if (json != null) {
      final dynamic error = json['error'];
      if (error != null && error.toString().trim().isNotEmpty) {
        return error.toString();
      }

      final dynamic detail = json['detail'];
      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }

      final dynamic message = json['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    final text = rawBody.trim();
    return text;
  }
}
