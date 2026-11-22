import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/splash_page.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Hive (Local Database) sebelum Supabase
  await Hive.initFlutter();
  await Hive.openBox('sigap_local_box');

  // 2. Load .env dan inisialisasi Supabase
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 3. Inisialisasi layanan notifikasi lokal
  await NotificationService.initialize();

  runApp(const SigapApp());
}

class SigapApp extends StatelessWidget {
  const SigapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      title: 'SIGAP',
      debugShowCheckedModeBanner: false,
      home: SplashPage(),
    );
  }
}