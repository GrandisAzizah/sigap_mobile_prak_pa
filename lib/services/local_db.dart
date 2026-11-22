import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDb {
  // Instansiasi private
  LocalDb._();

  static const String _boxName = 'sigap_local_box';
  static const String _reportsKey = 'cached_reports';
  static const String _userSessionKey = 'offline_user_session';

  static Box get _box => Hive.box(_boxName);
  // 1. SHARED PREFERENCES (Method Asli Dipertahankan)
  // Fungsi untuk menyimpan data (String, int, bool, dll)
  static Future<bool> setPref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      return await prefs.setString(key, value);
    } else if (value is int) {
      return await prefs.setInt(key, value);
    } else if (value is bool) {
      return await prefs.setBool(key, value);
    } else if (value is double) {
      return await prefs.setDouble(key, value);
    } else {
      return false;
    }
  }

  // Fungsi untuk mengambil data dengan nilai default
  static Future<dynamic> getPref(String key, {dynamic defaultValue}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.get(key) ?? defaultValue;
  }

  // Fungsi khusus untuk menghapus satu data
  static Future<bool> removePref(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(key);
  }

  // Fungsi khusus untuk menghapus semua data di SharedPreferences
  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }
  // 2. HIVE LOCAL DATABASE — SESI LOGIN OFFLINE
  /// Menyimpan sesi user setelah berhasil login online (id, email, nama, role, dll).
  static Future<void> saveUserSession(Map<String, dynamic> userData) async {
    await _box.put(_userSessionKey, userData);
  }

  /// Mengambil sesi user yang tersimpan di Hive untuk login/akses offline.
  static Map<String, dynamic>? getUserSession() {
    final raw = _box.get(_userSessionKey);
    if (raw == null || raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  /// Mengecek apakah terdapat sesi user tersimpan untuk mode offline.
  static bool hasOfflineSession() {
    return getUserSession() != null;
  }

  /// Menghapus sesi user lokal (dipanggil saat logout).
  static Future<void> clearUserSession() async {
    await _box.delete(_userSessionKey);
  }
  // 3. HIVE LOCAL DATABASE — DATA LAPORAN OFFLINE
  /// Menyimpan daftar laporan (dalam bentuk List) ke Hive.
  static Future<void> saveReports(List reports) async {
    await _box.put(_reportsKey, reports);
  }

  /// Mengambil daftar laporan yang tersimpan di Hive saat offline.
  static List getReports() {
    final raw = _box.get(_reportsKey);
    if (raw == null || raw is! List) return [];

    return raw
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Menghapus cache laporan lokal dari Hive.
  static Future<void> clearReports() async {
    await _box.delete(_reportsKey);
  }

  /// Menghapus seluruh data lokal (baik SharedPreferences maupun Hive).
  static Future<void> clearAllLocalData() async {
    await clearAll();
    await _box.clear();
  }
}