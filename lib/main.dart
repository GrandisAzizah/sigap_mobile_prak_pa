import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/fcm_service.dart';
import 'firebase_options.dart';
import 'screens/auth/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FcmService.init();
  runApp(const SigapApp());
}

class SigapApp extends StatelessWidget {
  const SigapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SIGAP',
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
    );
  }
}
