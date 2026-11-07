import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _notifications = 'notifications_enabled';
  static const _sound = 'notification_sound';
  static const _vibration = 'notification_vibration';

  Future<bool> get notificationsEnabled async =>
      (await SharedPreferences.getInstance()).getBool(_notifications) ?? true;

  Future<bool> get soundEnabled async =>
      (await SharedPreferences.getInstance()).getBool(_sound) ?? true;

  Future<bool> get vibrationEnabled async =>
      (await SharedPreferences.getInstance()).getBool(_vibration) ?? true;

  Future<void> setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifications, value);
  }

  Future<void> setSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sound, value);
  }

  Future<void> setVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibration, value);
  }
}
