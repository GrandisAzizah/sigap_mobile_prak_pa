import 'package:flutter/material.dart';
import '../../app_styles.dart';

/// Daftar notifikasi akan diisi dari tabel notifications atau FCM.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Notifikasi'), centerTitle: true),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.notifications_none_rounded, size: 55, color: AppColors.primary),
            SizedBox(height: 14),
            Text('Belum ada notifikasi'),
            SizedBox(height: 6),
            Text('Pembaruan status laporan akan muncul di halaman ini.',
              textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
