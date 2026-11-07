
import 'package:flutter/material.dart';

import '../../app_styles.dart';
import '../../components/bottom_nav.dart';
import 'user_home_page.dart';
import 'my_reports_page.dart';
import 'profile_page.dart';

/// Menjadi wadah utama tiga menu pengguna.
/// Navbar hanya dibuat satu kali di halaman ini.
class UserMainPage extends StatefulWidget {
  const UserMainPage({super.key});

  @override
  State<UserMainPage> createState() => _UserMainPageState();
}

class _UserMainPageState extends State<UserMainPage> {
  // Indeks halaman yang sedang dibuka.
  // 0 = Beranda, 1 = Laporan, 2 = Profil.
  int _selectedIndex = 0;

  // Daftar halaman yang ditampilkan oleh Bottom Navbar.
  late final List<Widget> _pages = [
    UserHomePage(
      onOpenReports: () => _selectTab(1),
      onOpenProfile: () => _selectTab(2),
    ),
    const MyReportsPage(),
    const ProfilePage(),
  ];

  // Mengganti halaman berdasarkan indeks menu yang dipilih.
  void _selectTab(int index) {
    if (index < 0 || index >= _pages.length) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // Menampilkan halaman sesuai menu yang dipilih.
      // IndexedStack mempertahankan kondisi halaman ketika berpindah menu.
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),

      // Navbar hanya memiliki tiga menu.
      bottomNavigationBar: UserBottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}
