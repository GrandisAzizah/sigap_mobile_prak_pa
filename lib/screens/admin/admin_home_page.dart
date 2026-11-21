import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_styles.dart';
import '../../services/notification_service.dart';
import 'admin_map_page.dart';
import 'admin_notif.dart';
import 'admin_profile_page.dart';
import 'admin_reports_page.dart';
import 'admin_staff_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _db = Supabase.instance.client;
  final _built = <int>{0}; // tab dibuat saat pertama dibuka
  final _notifTick = ValueNotifier<int>(0);
  RealtimeChannel? _channel;
  int _index = 0;
  int _unread = 0;

  @override
  void initState() {
    super.initState();

    // 1) Muat jumlah notifikasi belum dibaca, subscribe realtime
    _loadUnread();
    final uid = _db.auth.currentUser?.id;
    if (uid != null) {
      _channel = _db
          .channel('admin-notif-$uid')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: uid,
            ),
            callback: (payload) {
              _loadUnread();
              _notifTick.value++;
              if (mounted) {
                Get.snackbar(
                  (payload.newRecord['title'] ?? 'Notifikasi baru').toString(),
                  (payload.newRecord['body_notifications'] ?? '').toString(),
                  snackPosition: SnackPosition.TOP,
                );
              }
            },
          )
          .subscribe();
    }

    // 2) Listener laporan baru (notifikasi lokal)
    unawaited(NotificationService.startAdminReportListener());
  }

  @override
  void dispose() {
    if (_channel != null) _db.removeChannel(_channel!);
    _notifTick.dispose();
    unawaited(NotificationService.stopAdminReportListener());
    super.dispose();
  }

  Future<void> _loadUnread() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final res = await _db
          .from('notifications')
          .select('id')
          .eq('user_id', uid)
          .eq('is_read', false);
      if (mounted) setState(() => _unread = (res as List).length);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Get.to(
      () => AdminNotificationsPage(onChanged: _loadUnread, refresh: _notifTick),
    );
    _loadUnread();
  }

  Widget _page(int i) {
    if (!_built.contains(i)) return const SizedBox.shrink();
    switch (i) {
      case 0:
        return AdminReportsPage(
          unread: _unread,
          onOpenNotifications: _openNotifications,
        );
      case 1:
        return const AdminMapPage();
      case 2:
        return const AdminStaffPage();
      default:
        return const AdminProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: List.generate(4, _page)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          _built.add(i);
        }),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.light,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.primary),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups, color: AppColors.primary),
            label: 'Petugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
