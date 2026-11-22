import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef LocalMap = Map<String, dynamic>;

class LocalDb {
  // Instansiasi private
  LocalDb._();

  static const String _boxName = 'sigap_local_box';
  static const String _reportsKey = 'cached_reports';
  static const String _adminReportsKey = 'cached_admin_reports';
  static const String _userSessionKey = 'offline_user_session';
  static const String _savedAccountsKey = 'saved_offline_accounts';

  static Box get _box => Hive.box(_boxName);

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

  // Simpan sesi user yang sedang login ke Hive
  static Future<void> saveUserSession(LocalMap userData) async {
    await _box.put(_userSessionKey, userData);
  }

  // Ambil sesi user dari Hive untuk mode offline
  static LocalMap? getUserSession() {
    final raw = _box.get(_userSessionKey);
    if (raw == null || raw is! Map) return null;
    return LocalMap.from(raw);
  }

  // Cek apakah ada sesi offline yang tersimpan
  static bool hasOfflineSession() {
    return getUserSession() != null;
  }

  // Hapus sesi user aktif saat logout
  static Future<void> clearUserSession() async {
    await _box.delete(_userSessionKey);
  }

  // Simpan riwayat akun yang pernah login agar tetap bisa masuk saat offline
  static Future<void> saveOfflineAccount({
    required String id,
    required String nim,
    required String password,
    required String role,
  }) async {
    final raw = _box.get(_savedAccountsKey);
    final Map accounts = raw is Map ? Map.from(raw) : {};

    accounts[nim] = {'id': id, 'nim': nim, 'password': password, 'role': role};

    await _box.put(_savedAccountsKey, accounts);
  }

  // Ambil data akun berdasarkan NIM untuk verifikasi login offline
  static LocalMap? getOfflineAccount(String nim) {
    final raw = _box.get(_savedAccountsKey);
    if (raw == null || raw is! Map) return null;

    final account = raw[nim];
    if (account == null || account is! Map) return null;

    return LocalMap.from(account);
  }

  // Simpan daftar laporan user ke Hive
  static Future<void> saveReports(List reports) async {
    await _box.put(_reportsKey, reports);
  }

  // Ambil daftar laporan user dari Hive
  static List getReports() {
    final raw = _box.get(_reportsKey);
    if (raw == null || raw is! List) return [];

    return raw.map((item) => LocalMap.from(item as Map)).toList();
  }

  // Hapus cache laporan user
  static Future<void> clearReports() async {
    await _box.delete(_reportsKey);
  }

  // Simpan daftar semua laporan untuk halaman admin ke Hive
  static Future<void> saveAdminReports(List reports) async {
    await _box.put(_adminReportsKey, reports);
  }

  // Ambil daftar laporan admin dari Hive saat offline
  static List getAdminReports() {
    final raw = _box.get(_adminReportsKey);
    if (raw == null || raw is! List) return [];

    return raw.map((item) => LocalMap.from(item as Map)).toList();
  }

  // Hapus cache laporan admin
  static Future<void> clearAdminReports() async {
    await _box.delete(_adminReportsKey);
  }

  // Hapus seluruh data lokal di SharedPreferences dan Hive
  static Future<void> clearAllLocalData() async {
    await clearAll();
    await _box.clear();
  }
}
