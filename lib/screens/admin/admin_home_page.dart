import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../../services/notification_service.dart';
import 'admin_profile_page.dart';
import 'admin_reports_page.dart';

/// Shell admin: bottom navigation (Laporan, Profil).
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Mulai mendengarkan laporan baru dari Supabase Realtime saat admin masuk halaman ini.
    NotificationService.startAdminReportListener();
  }

  @override
  void dispose() {
    // Hentikan listener saat halaman admin ditutup / logout.
    NotificationService.stopAdminReportListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [AdminReportsPage(), AdminProfilePage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.light,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment, color: AppColors.primary),
            label: 'Laporan',
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