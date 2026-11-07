import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import 'login_page.dart';
import '../admin/admin_home_page.dart';
import '../user/user_home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    if (_auth.currentSession == null) {
      Get.offAll(() => const LoginPage());
      return;
    }

    final role = await _auth.getRole();
    if (!mounted) return;

    Get.offAll(
      () => role == 'admin' ? const AdminHomePage() : const UserHomePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
