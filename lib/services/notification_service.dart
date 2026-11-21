import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static RealtimeChannel? _userChannel;
  static RealtimeChannel? _adminChannel;

  // Menyiapkan layanan notifikasi.
  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(android: androidSettings);

    // v22: positional parameter
    await _plugin.initialize(settings: settings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.requestNotificationsPermission();

    _initialized = true;
  }

  // Menampilkan notifikasi langsung.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      'sigap_realtime_notification',
      'Notifikasi Laporan SIGAP',
      channelDescription: 'Notifikasi status laporan dan laporan masuk SIGAP',
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );

    // v22: positional parameter
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
    );
  }

  // 1. Listener laporan user (perubahan status).
  static Future<void> startUserReportListener() async {
    await initialize();
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;
    if (user == null) return;

    await stopUserReportListener();

    _userChannel = db
        .channel('user-reports-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'reports',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final oldStatus = payload.oldRecord['status']?.toString();
            final newStatus = payload.newRecord['status']?.toString();
            final title =
                payload.newRecord['title']?.toString() ?? 'Laporan Anda';

            if (newStatus != null && oldStatus != newStatus) {
              // ignore: discarded_futures
              showNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: 'Status Laporan Diperbarui',
                body: '$title kini berstatus: $newStatus',
              );
            }
          },
        )
        .subscribe();
  }

  // 2. Listener laporan baru admin.
  static Future<void> startAdminReportListener() async {
    await initialize();
    final db = Supabase.instance.client;

    await stopAdminReportListener();

    _adminChannel = db
        .channel('admin-new-reports')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'reports',
          callback: (payload) {
            final title =
                payload.newRecord['title']?.toString() ??
                'Laporan Kerusakan Baru';
            final detail = payload.newRecord['report_detail']?.toString() ?? '';
            showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: title,
              body: detail.isNotEmpty
                  ? detail
                  : 'Ada laporan kerusakan baru yang perlu ditinjau.',
            );
          },
        )
        .subscribe();
  }

  static Future<void> stopUserReportListener() async {
    if (_userChannel != null) {
      await Supabase.instance.client.removeChannel(_userChannel!);
      _userChannel = null;
    }
  }

  static Future<void> stopAdminReportListener() async {
    if (_adminChannel != null) {
      await Supabase.instance.client.removeChannel(_adminChannel!);
      _adminChannel = null;
    }
  }

  static Future<void> stopAllListeners() async {
    await stopUserReportListener();
    await stopAdminReportListener();
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

    final details = NotificationDetails(android: androidDetails);

    // v22: positional parameter + named androidScheduleMode
    await _plugin.zonedSchedule(
      id: 999,
      title: 'Tes Notifikasi SIGAP',
      body: 'Berhasil! ...',
      scheduledDate: tz.TZDateTime.now(tz.local)
          .add(const Duration(seconds: 10)),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  // Membatalkan notifikasi percobaan.
  static Future<void> cancelTestNotification() async {
    await _plugin.cancel(id: 999);
  }
}
