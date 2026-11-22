import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  print("Pesan background diterima: ${message.messageId}");
}

class FcmService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    await _localNotif.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    // 1. Daftarkan listener (CUKUP SATU KALI)
    _fcm.onRegistered.listen((String installationId) {
      _saveTokenToSupabase(installationId);
    });

    // 2. Panggil register
    await _fcm.register();

    // 3. Listener untuk saat aplikasi sedang dibuka (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotif.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'sigap_push_channel',
              'SIGAP Push Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': token})
          .eq('id', user.id);
      print("Token FCM berhasil disimpan ke Supabase!");
    } catch (e) {
      print("Gagal menyimpan token FCM: $e");
    }
  }

  // Fungsi untuk LOGOUT
  static Future<void> removeTokenFromSupabase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Hapus FCM Token dari database
      await Supabase.instance.client
          .from('users')
          .update({'fcm_token': null})
          .eq('id', user.id);

      // 2. Hentikan registrasi FCM di perangkat ini
      await _fcm.unregister();

      print("Token FCM berhasil dihapus dan di-unregister.");
    } catch (e) {
      print("Gagal menghapus token FCM: $e");
    }
  }
}
