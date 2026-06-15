import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/account_api.dart';
import '../theme/app_texts.dart';
import '../models/auth_session.dart';
import '../models/auth_results.dart';

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
            ? AppTexts.authLoginFailedHttp('${response.statusCode}')
            : serverError,
      );
    }

    final bool ok = json['ok'] == true;
    if (!ok) {
      return AuthLoginResult(
        ok: false,
        error: (json['error'] ?? AppTexts.authLoginFailed).toString(),
      );
    }

    final dynamic userData = json['user'];
    if (userData is! Map) {
      return AuthLoginResult(
        ok: false,
        error: AppTexts.authServerResponseIncomplete,
      );
    }

    final session = AuthSession(
      token: (json['token'] ?? '').toString(),
      userId: (userData['id'] as num?)?.toInt() ?? 0,
      username: (userData['username'] ?? '').toString(),
      email: (userData['email'] ?? '').toString(),
    );

    if (session.token.isEmpty || session.userId == 0 || session.email.isEmpty) {
      return AuthLoginResult(
        ok: false,
        error: AppTexts.authServerResponseInvalid,
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
            ? AppTexts.authRegistrationFailedHttp('${response.statusCode}')
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
      message: (json['message'] ?? AppTexts.authRegistrationSuccess).toString(),
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
            ? AppTexts.authActivationFailedHttp('${response.statusCode}')
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
      message: (json['message'] ?? AppTexts.authActivationSuccess).toString(),
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
      return AuthProfileUpdateResult(
        ok: false,
        error: AppTexts.authSessionExpired,
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
            ? AppTexts.authProfileUpdateFailedHttp('${response.statusCode}')
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
        message: (json['message'] ?? AppTexts.authProfileUpdateSuccess).toString(),
      );
    }

    return AuthProfileUpdateResult(
      ok: true,
      passwordChangeConfirmationRequired: passwordChangeConfirmationRequired,
      message: (json['message'] ?? AppTexts.authProfileUpdateSuccess).toString(),
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
            ? AppTexts.authPasswordConfirmFailedHttp('${response.statusCode}')
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
      message: (json['message'] ?? AppTexts.authPasswordConfirmSuccess)
          .toString(),
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
      return AppTexts.authNetworkTimeout;
    }
    if (error is SocketException || error is http.ClientException) {
      return AppTexts.authNetworkBackendUnavailable;
    }
    return AppTexts.authNetworkGeneralError;
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
