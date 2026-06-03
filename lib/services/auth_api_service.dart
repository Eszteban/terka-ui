import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/account_api.dart';
import 'graphql/graphql_client.dart';

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

  const AuthLoginResult({required this.ok, this.error, this.session});
}

class AuthActionResult {
  final bool ok;
  final String? error;
  final String? message;

  const AuthActionResult({required this.ok, this.error, this.message});
}

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
}

class AgencyGroup {
  final String name;
  final List<String> agencyIds;

  const AgencyGroup({required this.name, required this.agencyIds});

  factory AgencyGroup.fromJson(Map<String, dynamic> json) {
    return AgencyGroup(
      name: (json['name'] ?? '').toString(),
      agencyIds: List<String>.from(json['agency_ids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'agency_ids': agencyIds};

  static List<AgencyGroup> getPrebakedGroups() {
    return const [
      AgencyGroup(
        name: 'Országbérlet',
        agencyIds: [
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
        ],
      ),
      AgencyGroup(
        name: 'Országbérlet + Szeged',
        agencyIds: [
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
        ],
      ),
      AgencyGroup(
        name: 'Szeged',
        agencyIds: ['hkir:hkir_V-33367', 'szeged:hkir_V-33367', 'szeged:SZKT'],
      ),
    ];
  }
}

class PassType {
  final String id;
  final String name;
  final List<String> agencyIds;
  final List<String> agencyNames;
  final String durationType; // 'month' or 'days'
  final int? durationDays;

  const PassType({
    required this.id,
    required this.name,
    required this.agencyIds,
    required this.agencyNames,
    required this.durationType,
    this.durationDays,
  });

  factory PassType.fromJson(Map<String, dynamic> json) {
    return PassType(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      agencyIds: List<String>.from(json['agency_ids'] ?? []),
      agencyNames: List<String>.from(json['agency_names'] ?? []),
      durationType: (json['duration_type'] ?? 'month').toString(),
      durationDays: json['duration_days'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'agency_ids': agencyIds,
        'agency_names': agencyNames,
        'duration_type': durationType,
        'duration_days': durationDays,
      };

  static List<PassType> getPrebakedPassTypes() {
    return const [
      PassType(
        id: 'orszagberlet',
        name: 'Országbérlet',
        agencyIds: [
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
        ],
        agencyNames: [
          'BKK',
          'MÁV Személyszállítási Zrt. (HÉV)',
          'MÁV Személyszállítási Zrt. - Érd',
          'MÁV Személyszállítási Zrt. - Csongrád',
          'MÁV Személyszállítási Zrt. - Ercsi',
          'MÁV Személyszállítási Zrt. - Esztergom',
          'MÁV Személyszállítási Zrt. - Helyközi busz',
          'MÁV Személyszállítási Zrt.',
          'DKV Debreceni Közlekedési Zrt.',
          'MVK Zrt.',
          'GYSEV Zrt.',
        ],
        durationType: 'month',
      ),
      PassType(
        id: 'orszagberlet_szeged',
        name: 'Országbérlet + Szeged',
        agencyIds: [
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
        ],
        agencyNames: [
          'BKK',
          'MÁV Személyszállítási Zrt. (HÉV)',
          'MÁV Személyszállítási Zrt. - Érd',
          'MÁV Személyszállítási Zrt. - Csongrád',
          'MÁV Személyszállítási Zrt. - Ercsi',
          'MÁV Személyszállítási Zrt. - Esztergom',
          'MÁV Személyszállítási Zrt. - Helyközi busz',
          'MÁV Személyszállítási Zrt.',
          'DKV Debreceni Közlekedési Zrt.',
          'MVK Zrt.',
          'MÁV Személyszállítási Zrt. - Szeged',
          'Szegedi Közlekedési Kft.',
          'Szegedi Közlekedési Kft.',
          'GYSEV Zrt.',
        ],
        durationType: 'month',
      ),
    ];
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
      response = await http
          .post(
            Uri.parse(AccountApi.loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(_requestTimeout);
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

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        json == null) {
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
      response = await http
          .post(
            Uri.parse(AccountApi.registerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'email': email.trim(),
              'password': password,
              'confirm_password': confirmPassword,
            }),
          )
          .timeout(_requestTimeout);
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

    final bool isHttpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;
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

  Future<AuthActionResult> activateAccount({required String token}) async {
    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(AccountApi.activateUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token.trim()}),
          )
          .timeout(_requestTimeout);
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

    final bool isHttpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;
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
      response = await http
          .post(
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
          )
          .timeout(_requestTimeout);
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

    final bool isHttpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;
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
      response = await http
          .post(
            Uri.parse(AccountApi.confirmPasswordChangeUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token.trim()}),
          )
          .timeout(_requestTimeout);
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

    final bool isHttpSuccess =
        response.statusCode >= 200 && response.statusCode < 300;
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
      message: (json['message'] ?? 'Jelszó módosítva, jelentkezz be újra.')
          .toString(),
    );
  }

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
      return TicketsResult(ok: false, error: 'Hiba a jegyek betöltésekor: $e');
    }
  }

  Future<TicketFormOptionsResult> fetchTicketFormOptions() async {
    const String query = '{agencies {name gtfsId}}';
    final agencies = <TicketAgencyOption>[];
    const ticketTypes = [
      TicketTypeOption(value: 'vonaljegy', label: 'Vonaljegy'),
      TicketTypeOption(value: 'bérlet', label: 'Bérlet'),
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

  Future<List<AgencyGroup>> fetchCustomAgencyGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_agency_groups_v1');
      if (raw == null || raw.trim().isEmpty) {
        return [];
      }
      final dynamic decoded = jsonDecode(raw);
      final groups = <AgencyGroup>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            groups.add(AgencyGroup.fromJson(item.cast<String, dynamic>()));
          }
        }
      }
      return groups;
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCustomAgencyGroup(AgencyGroup group) async {
    try {
      final groups = await fetchCustomAgencyGroups();
      final index = groups.indexWhere(
        (g) => g.name.toLowerCase() == group.name.toLowerCase(),
      );
      if (index != -1) {
        groups[index] = group;
      } else {
        groups.add(group);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'local_agency_groups_v1',
        jsonEncode(groups.map((g) => g.toJson()).toList()),
      );
    } catch (e) {
      // ignore
    }
  }

  Future<List<PassType>> fetchPassTypes() async {
    final prebaked = PassType.getPrebakedPassTypes();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_pass_types_v1');
      if (raw == null || raw.trim().isEmpty) {
        return prebaked;
      }
      final dynamic decoded = jsonDecode(raw);
      final list = <PassType>[];
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            list.add(PassType.fromJson(item.cast<String, dynamic>()));
          }
        }
      }
      return [...prebaked, ...list];
    } catch (e) {
      return prebaked;
    }
  }

  Future<void> savePassType(PassType passType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_pass_types_v1');
      final list = <PassType>[];
      if (raw != null && raw.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              list.add(PassType.fromJson(item.cast<String, dynamic>()));
            }
          }
        }
      }

      final index = list.indexWhere((p) => p.id == passType.id);
      if (index != -1) {
        list[index] = passType;
      } else {
        list.add(passType);
      }

      await prefs.setString(
        'local_pass_types_v1',
        jsonEncode(list.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      // ignore
    }
  }

  Future<void> deletePassType(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('local_pass_types_v1');
      final list = <PassType>[];
      if (raw != null && raw.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              list.add(PassType.fromJson(item.cast<String, dynamic>()));
            }
          }
        }
      }

      list.removeWhere((p) => p.id == id);

      await prefs.setString(
        'local_pass_types_v1',
        jsonEncode(list.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      // ignore
    }
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

      return const AuthActionResult(
        ok: true,
        message: 'Jegy sikeresen hozzáadva!',
      );
    } catch (e) {
      return AuthActionResult(
        ok: false,
        error: 'Hiba a jegy hozzáadásakor: $e',
      );
    }
  }

  Future<AuthActionResult> updateTicket(TicketItem updatedTicket) async {
    try {
      final ticketsResult = await fetchTickets();
      final tickets = List<TicketItem>.from(ticketsResult.tickets);

      final index = tickets.indexWhere((t) => t.id == updatedTicket.id);
      if (index == -1) {
        return const AuthActionResult(
          ok: false,
          error: 'A jegy nem található.',
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

      return const AuthActionResult(
        ok: true,
        message: 'Jegy sikeresen módosítva!',
      );
    } catch (e) {
      return AuthActionResult(
        ok: false,
        error: 'Hiba a jegy módosításakor: $e',
      );
    }
  }

  Future<AuthActionResult> deleteTicket(int ticketId) async {
    try {
      final ticketsResult = await fetchTickets();
      final tickets = List<TicketItem>.from(ticketsResult.tickets);

      final index = tickets.indexWhere((t) => t.id == ticketId);
      if (index == -1) {
        return const AuthActionResult(
          ok: false,
          error: 'A jegy nem található.',
        );
      }

      tickets.removeAt(index);

      final prefs = await SharedPreferences.getInstance();
      final serialized = jsonEncode(tickets.map((t) => t.toJson()).toList());
      await prefs.setString('local_tickets_v1', serialized);

      return const AuthActionResult(
        ok: true,
        message: 'Jegy sikeresen törölve!',
      );
    } catch (e) {
      return AuthActionResult(
        ok: false,
        error: 'Hiba a jegy törlésekor: $e',
      );
    }
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
