
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Menyiapkan layanan notifikasi.
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings: settings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    _initialized = true;
  }

  // Menjadwalkan notifikasi percobaan 10 detik kemudian.
  static Future<void> scheduleTestNotification({
    required bool soundEnabled,
    required bool vibrationEnabled,
  }) async {
    await initialize();

    const channelId = 'sigap_test_notification';
    const channelName = 'Tes Notifikasi SIGAP';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifikasi percobaan aplikasi SIGAP',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );

    final details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.zonedSchedule(
      id: 999,
      title: 'Tes Notifikasi SIGAP',
      body: 'Berhasil! Notifikasi SIGAP tetap berjalan di latar belakang.',
      scheduledDate: tz.TZDateTime.now(tz.local).add(
        const Duration(seconds: 10),
      ),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // Membatalkan notifikasi percobaan yang masih terjadwal.
  static Future<void> cancelTestNotification() async {
    await _plugin.cancel(id: 999);
  }
}
