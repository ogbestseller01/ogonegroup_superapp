// lib/services/fundi_remember_store.dart
//
// Remember-me storage for FundiApp. Keys are namespaced ("fundiapp.*") so the
// customer app (same super app / same keychain) can never read or overwrite it.

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RememberedAccount {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? photo;

  const RememberedAccount({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.photo,
  });

  /// What the card shows under the name (fundis may have no email).
  String get identifier => email.isNotEmpty ? email : phone;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'photo': photo,
  };

  factory RememberedAccount.fromJson(Map<String, dynamic> j) =>
      RememberedAccount(
        id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
        name: j['name']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        phone: j['phone']?.toString() ?? '',
        photo: (j['photo'] as String?)?.isNotEmpty == true
            ? j['photo'] as String
            : null,
      );
}

class FundiRememberStore {
  FundiRememberStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _kToken = 'fundiapp.remember_token';
  static const String _kAccount = 'fundiapp.remembered_account';

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _kToken);
    } catch (e) {
      debugPrint('remember store read token failed: $e');
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _kToken, value: token);
    } catch (e) {
      debugPrint('remember store write token failed: $e');
    }
  }

  static Future<RememberedAccount?> getAccount() async {
    try {
      final raw = await _storage.read(key: _kAccount);
      if (raw == null || raw.isEmpty) return null;
      final acc = RememberedAccount.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      return acc.id == 0 ? null : acc;
    } catch (e) {
      debugPrint('remember store read account failed: $e');
      return null;
    }
  }

  static Future<void> saveAccount(RememberedAccount account) async {
    try {
      await _storage.write(key: _kAccount, value: jsonEncode(account.toJson()));
    } catch (e) {
      debugPrint('remember store write account failed: $e');
    }
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kAccount);
    } catch (e) {
      debugPrint('remember store clear failed: $e');
    }
  }
}