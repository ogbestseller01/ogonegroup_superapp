import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Basic profile shown on the "Continue as [User]" button.
class RememberedAccount {
  final int id;
  final String name;
  final String email;
  final String? photo;

  const RememberedAccount({
    required this.id,
    required this.name,
    required this.email,
    this.photo,
  });

  factory RememberedAccount.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return RememberedAccount(
      id: rawId is int ? rawId : int.tryParse('${rawId ?? ''}') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      photo: json['photo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'photo': photo,
  };

  RememberedAccount copyWith({String? name, String? email, String? photo}) =>
      RememberedAccount(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        photo: photo ?? this.photo,
      );
}

class StorageService {
  // Isolate from FundiApp + super app
  static const String _p = 'nf_';

  static const String _tokenKey = '${_p}auth_token';
  static const String _userKey = '${_p}user';
  static const String _localeKey = '${_p}locale';
  static const String _notificationsKey = '${_p}notifications_enabled';

  // Secure (Keystore / Keychain) keys: "remember me"
  static const String _rememberTokenKey = '${_p}remember_token';
  static const String _rememberAccountKey = '${_p}remember_account';

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ─── Session ────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUserJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json);
  }

  static Future<String?> getUserJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  static Future<void> saveLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  static Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  static Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  static Future<bool?> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey);
  }

  /// Only this mini-app's session keys — never prefs.clear().
  /// The remembered account (secure storage) is intentionally KEPT on logout.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    // keep locale / notifications if you want them to survive logout
  }

  // ─── Remember me (secure) ───────────────────────────────────
  static Future<void> saveRememberToken(String token) async {
    try {
      await _secure.write(key: _rememberTokenKey, value: token);
    } catch (e) {
      debugPrint('saveRememberToken failed: $e');
    }
  }

  static Future<String?> getRememberToken() async {
    try {
      return await _secure.read(key: _rememberTokenKey);
    } catch (e) {
      debugPrint('getRememberToken failed: $e');
      return null;
    }
  }

  static Future<void> saveRememberedAccount(RememberedAccount account) async {
    try {
      await _secure.write(
        key: _rememberAccountKey,
        value: jsonEncode(account.toJson()),
      );
    } catch (e) {
      debugPrint('saveRememberedAccount failed: $e');
    }
  }

  static Future<RememberedAccount?> getRememberedAccount() async {
    try {
      final raw = await _secure.read(key: _rememberAccountKey);
      if (raw == null || raw.isEmpty) return null;
      final acc = RememberedAccount.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      return acc.id == 0 ? null : acc;
    } catch (e) {
      debugPrint('getRememberedAccount failed: $e');
      return null;
    }
  }

  /// "Switch account", expired remember token, or account deleted.
  static Future<void> clearRemembered() async {
    try {
      await _secure.delete(key: _rememberTokenKey);
      await _secure.delete(key: _rememberAccountKey);
    } catch (e) {
      debugPrint('clearRemembered failed: $e');
    }
  }
}