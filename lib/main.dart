
import 'package:flutter/material.dart';

import 'app_styles.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SIgapApp());
}

class SIgapApp extends StatelessWidget {
  const SIgapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIgap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Halaman pertama saat aplikasi dibuka
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
