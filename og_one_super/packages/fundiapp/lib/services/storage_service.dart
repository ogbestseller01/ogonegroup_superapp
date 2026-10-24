import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _p = 'fa_';

  static const String _tokenKey = '${_p}auth_token';
  static const String _userKey = '${_p}user';
  static const String _localeKey = '${_p}locale';
  static const String _notificationsKey = '${_p}notifications_enabled';
  static const String _technicianIdKey = '${_p}technician_id';
  static const String _technicianEmailKey = '${_p}technician_email';

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

  static Future<void> saveTechnicianId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_technicianIdKey, id);
  }

  static Future<int?> getTechnicianId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_technicianIdKey);
  }

  static Future<void> saveTechnicianEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_technicianEmailKey, email);
  }

  static Future<String?> getTechnicianEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_technicianEmailKey);
  }

  static Future<void> clearTechnicianData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_technicianIdKey);
    await prefs.remove(_technicianEmailKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_technicianIdKey);
    await prefs.remove(_technicianEmailKey);
  }
}