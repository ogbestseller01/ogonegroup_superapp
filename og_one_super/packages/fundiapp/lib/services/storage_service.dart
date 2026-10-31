// lib/services/storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Local persistence for auth state, user preferences, and pending Fundi
/// registration.
///
/// Clearing is deliberately layered so a **session expiry** never destroys
/// in-flight registration progress:
///
///   • [clearAuth]           — auth token + cached user + biometric only.
///   • [clearTechnicianData] — pending registration (draft_id, email,
///                             registration_token).
///   • [clearAll]            — full factory reset.
class StorageService {
  static const String _p = 'fa_';

  // ── Auth ────────────────────────────────────────────────
  static const String _tokenKey = '${_p}auth_token';
  static const String _userKey = '${_p}user';

  // ── Preferences ─────────────────────────────────────────
  static const String _localeKey = '${_p}locale';
  static const String _notificationsKey = '${_p}notifications_enabled';

  // ── Pending fundi registration ──────────────────────────
  //
  // `_technicianIdKey` now stores the **draft_id** returned from step 1.
  // It is deliberately kept under the old key so code that reads
  // `getTechnicianId()` continues to work; see doc on each getter.
  static const String _technicianIdKey      = '${_p}technician_id';
  static const String _technicianEmailKey   = '${_p}technician_email';
  static const String _registrationTokenKey = '${_p}registration_token';

  // ── Biometric / device ──────────────────────────────────
  static const String _biometricTokenKey   = '${_p}biometric_token';
  static const String _biometricEnabledKey = '${_p}biometric_enabled';
  static const String _deviceIdKey         = '${_p}device_id';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<SharedPreferences> _prefs() =>
      SharedPreferences.getInstance();

  // ========================================================
  // AUTH
  // ========================================================

  static Future<void> saveToken(String token) async {
    final prefs = await _prefs();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await _prefs();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserJson(String json) async {
    final prefs = await _prefs();
    await prefs.setString(_userKey, json);
  }

  static Future<String?> getUserJson() async {
    final prefs = await _prefs();
    return prefs.getString(_userKey);
  }

  // ========================================================
  // SETTINGS
  // ========================================================

  static Future<void> saveLocale(String locale) async {
    final prefs = await _prefs();
    await prefs.setString(_localeKey, locale);
  }

  static Future<String?> getLocale() async {
    final prefs = await _prefs();
    return prefs.getString(_localeKey);
  }

  static Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await _prefs();
    await prefs.setBool(_notificationsKey, enabled);
  }

  static Future<bool?> getNotificationsEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_notificationsKey);
  }

  // ========================================================
  // PENDING FUNDI REGISTRATION
  //
  // The stored ID is now the **registration draft ID** (returned by
  // `/v19/technicians/register/step1`). It is used for:
  //   • `GET /v19/technicians/registration-status/{id}`
  //   • resume-flow navigation
  //
  // `getRegistrationToken()` returns the short-lived bearer issued by
  // `/v19/technicians/register/verify-otp` and required for steps 2-6.
  // ========================================================

  /// Saves the **draft_id** returned by step 1 (also called "technicianId"
  /// in the resume flow — same value).
  static Future<void> saveTechnicianId(int id) async {
    final prefs = await _prefs();
    await prefs.setInt(_technicianIdKey, id);
  }

  /// Returns the draft_id, or null if there is no in-progress registration.
  static Future<int?> getTechnicianId() async {
    final prefs = await _prefs();
    return prefs.getInt(_technicianIdKey);
  }

  static Future<void> saveTechnicianEmail(String email) async {
    final prefs = await _prefs();
    await prefs.setString(_technicianEmailKey, email);
  }

  static Future<String?> getTechnicianEmail() async {
    final prefs = await _prefs();
    return prefs.getString(_technicianEmailKey);
  }

  /// Saves the draft-scoped bearer token issued by `/verify-otp`. Steps 2-6
  /// attach this as `Authorization: Bearer <token>`.
  static Future<void> saveRegistrationToken(String token) async {
    final prefs = await _prefs();
    await prefs.setString(_registrationTokenKey, token);
  }

  static Future<String?> getRegistrationToken() async {
    final prefs = await _prefs();
    return prefs.getString(_registrationTokenKey);
  }

  static Future<void> clearRegistrationToken() async {
    final prefs = await _prefs();
    await prefs.remove(_registrationTokenKey);
  }

  /// Wipes the entire pending-registration context:
  ///   • draft_id
  ///   • draft email
  ///   • registration bearer token
  ///
  /// Use when the user explicitly **discards** the registration, when
  /// step 6 succeeds, or when the server reports the draft expired.
  /// Never call from [clearAuth] — that path must not touch drafts.
  static Future<void> clearTechnicianData() async {
    final prefs = await _prefs();
    await Future.wait([
      prefs.remove(_technicianIdKey),
      prefs.remove(_technicianEmailKey),
      prefs.remove(_registrationTokenKey),
    ]);
  }

  // ========================================================
  // BIOMETRIC
  // ========================================================

  static Future<void> saveBiometricToken(String token) async {
    await _secureStorage.write(key: _biometricTokenKey, value: token);
  }

  static Future<String?> getBiometricToken() async {
    return _secureStorage.read(key: _biometricTokenKey);
  }

  static Future<void> clearBiometricToken() async {
    await _secureStorage.delete(key: _biometricTokenKey);
  }

  static Future<void> setBiometricEnabled(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_biometricEnabledKey, value);
  }

  static Future<bool> isBiometricEnabled() async {
    final prefs = await _prefs();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await _prefs();
    String? id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    return id;
  }

  static Future<String?> getDeviceId() async {
    final prefs = await _prefs();
    return prefs.getString(_deviceIdKey);
  }

  // ========================================================
  // CLEAR METHODS
  // ========================================================

  /// Clears **only** authentication artifacts:
  ///   • auth token
  ///   • cached user JSON
  ///   • biometric auth token
  ///
  /// Preserves everything else — most importantly the pending registration
  /// (draft_id, draft email, registration token), plus locale, notifications,
  /// biometric opt-in, and device id.
  ///
  /// Called by `AuthProvider._clearSession()` on:
  ///   • startup 401 from a stale token
  ///   • mid-session 401
  ///   • explicit logout
  static Future<void> clearAuth() async {
    final prefs = await _prefs();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_userKey),
      _secureStorage.delete(key: _biometricTokenKey),
    ]);
  }

  /// Full factory-reset wipe.
  static Future<void> clearAll() async {
    final prefs = await _prefs();
    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_userKey),
      prefs.remove(_localeKey),
      prefs.remove(_notificationsKey),
      prefs.remove(_technicianIdKey),
      prefs.remove(_technicianEmailKey),
      prefs.remove(_registrationTokenKey),
      prefs.remove(_biometricEnabledKey),
      prefs.remove(_deviceIdKey),
      _secureStorage.delete(key: _biometricTokenKey),
    ]);
  }
}