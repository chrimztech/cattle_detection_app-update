import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'models/app_models.dart';

class SessionController extends ChangeNotifier {
  static const _sessionKey = 'unza.mobile.session';
  static const _apiBaseUrlKey = 'unza.mobile.apiBaseUrl';
  // Build-time override: flutter build apk --dart-define=API_BASE_URL=https://cattle.unza.ac.zm
  // Default 10.0.2.2:8080 maps to host loopback on Android emulator.
  // On a physical device / production build set API_BASE_URL to the server LAN IP or domain.
  static const defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  bool _bootstrapping = true;
  bool get bootstrapping => _bootstrapping;

  UserSession? _session;
  UserSession? get session => _session;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  String _apiBaseUrl = defaultApiBaseUrl;
  String get apiBaseUrl => _apiBaseUrl;

  ApiService get api => ApiService(baseUrl: _apiBaseUrl, token: _session?.token);

  bool get isAuthenticated => _session != null;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _apiBaseUrl = prefs.getString(_apiBaseUrlKey) ?? defaultApiBaseUrl;
    final rawSession = prefs.getString(_sessionKey);
    if (rawSession != null && rawSession.isNotEmpty) {
      try {
        _session = UserSession.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(rawSession) as Map<String, dynamic>,
          ),
        );
        await refreshProfile(silentOnFailure: true);
      } catch (_) {
        await _clearSession(prefs: prefs, notify: false);
      }
    }
    _bootstrapping = false;
    notifyListeners();
  }

  Future<void> updateApiBaseUrl(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'/$'), '');
    if (normalized.isEmpty) {
      throw const ApiException('API base URL is required');
    }
    _apiBaseUrl = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, _apiBaseUrl);
    _profile = null;
    notifyListeners();

    if (_session == null) return;

    try {
      await refreshProfile();
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        throw const ApiException(
          'Backend URL updated. Please sign in again for the new server.',
          statusCode: 401,
        );
      }
      rethrow;
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final nextSession = await api.login(username, password);
    await _saveSession(nextSession);
    await refreshProfile(silentOnFailure: true);
  }

  Future<void> register({
    required String username,
    required String password,
  }) async {
    final nextSession = await api.register(username, password);
    await _saveSession(nextSession);
    await refreshProfile(silentOnFailure: true);
  }

  Future<void> refreshProfile({bool silentOnFailure = false}) async {
    if (_session == null) return;
    try {
      _profile = await api.getProfile();
      notifyListeners();
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _clearSession(notify: !silentOnFailure);
        if (!silentOnFailure) {
          throw const ApiException(
            'Your session is no longer valid. Please sign in again.',
            statusCode: 401,
          );
        }
        return;
      }
      if (!silentOnFailure) rethrow;
    }
  }

  Future<void> logout() async {
    await _clearSession();
  }

  Future<void> _clearSession({
    SharedPreferences? prefs,
    bool notify = true,
  }) async {
    _session = null;
    _profile = null;
    final targetPrefs = prefs ?? await SharedPreferences.getInstance();
    await targetPrefs.remove(_sessionKey);
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _saveSession(UserSession value) async {
    _session = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(value.toJson()));
    notifyListeners();
  }
}
