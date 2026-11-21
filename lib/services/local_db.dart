import 'package:shared_preferences/shared_preferences.dart';

class LocalDb {
  // Instansiasi private
  LocalDb._();

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

  // Fungsi khusus untuk menghapus semua data di local storage
  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }
}
