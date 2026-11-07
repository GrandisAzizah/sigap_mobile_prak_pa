import 'package:flutter/material.dart';
import '../../app_styles.dart';
import '../../components/bottom_nav.dart';
import 'user_home_page.dart';
import 'my_reports_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

/// Menjadi wadah utama empat menu. Navbar hanya dibuat di halaman ini.
class UserMainPage extends StatefulWidget {
  const UserMainPage({super.key});

  @override
  State<UserMainPage> createState() => _UserMainPageState();
}

class _UserMainPageState extends State<UserMainPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    UserHomePage(
      onOpenReports: () => _selectTab(1),
      onOpenProfile: () => _selectTab(3),
    ),
    const MyReportsPage(),
    const NotificationsPage(),
    const ProfilePage(),
  ];

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: UserBottomNavbar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}
