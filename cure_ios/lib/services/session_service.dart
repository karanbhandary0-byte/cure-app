import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _tokenKey = "careloop_token";
  static const String _roleKey = "careloop_role";
  static const String _userKey = "careloop_user";

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveSession({
    required String token,
    required String role,
    required Map<String, dynamic> user,
  }) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _roleKey, value: role);
      await _secureStorage.write(key: _userKey, value: jsonEncode(user));
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_roleKey, role);
      await prefs.setString(_userKey, jsonEncode(user));
    }
  }

  Future<String?> getToken() async {
    try {
      final val = await _secureStorage.read(key: _tokenKey);
      if (val != null) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    try {
      final val = await _secureStorage.read(key: _roleKey);
      if (val != null) return val;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    String? raw;
    try {
      raw = await _secureStorage.read(key: _userKey);
    } catch (_) {}
    if (raw == null) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_userKey);
    }
    if (raw != null && raw.isNotEmpty) {
      try {
        return jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
    return null;
  }

  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _roleKey);
      await _secureStorage.delete(key: _userKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userKey);
  }

  static const String _locationKey = "careloop_patient_location";

  Future<void> savePatientLocation(String location) async {
    try {
      await _secureStorage.write(key: _locationKey, value: location);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_locationKey, location);
    } catch (_) {}
  }

  Future<String?> getPatientLocation() async {
    try {
      final val = await _secureStorage.read(key: _locationKey);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_locationKey);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    return null;
  }
}
