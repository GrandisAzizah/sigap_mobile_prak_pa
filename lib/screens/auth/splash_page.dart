import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_styles.dart';
import '../auth/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _buildingOpacity;
  late Animation<double> _buildingScale;
  late Animation<double> _buildingPosition;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Gedung muncul secara perlahan
    _buildingOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.42, curve: Curves.easeIn),
      ),
    );

    // Efek zoom gedung
    _buildingScale = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.48, curve: Curves.easeOutBack),
      ),
    );

    // Gedung bergerak ke bagian bawah
    _buildingPosition = Tween<double>(begin: 0.34, end: 0.64).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.66, curve: Curves.easeInOutCubic),
      ),
    );

    // Logo muncul dengan efek pop / bounce
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.82, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.73, curve: Curves.easeIn),
      ),
    );

    // Nama aplikasi muncul setelah logo
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 0.88, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Pindah ke halaman login setelah 5 detik
    Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      Get.offAll(() => const LoginPage());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // BACKGROUND
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFEDE6FF),
                      Color(0xFFF8F9FB),
                      Color(0xFFFFF9F1),
                    ],
                  ),
                ),
              ),

              // DEKORASI AWAN
              Positioned(
                top: screenHeight * 0.12,
                left: -20,
                child: _buildCloud(100),
              ),

              Positioned(
                top: screenHeight * 0.20,
                right: -15,
                child: _buildCloud(120),
              ),

              Positioned(
                top: screenHeight * 0.48,
                left: -30,
                child: _buildCloud(90),
              ),

              // DEKORASI BAWAH
              Positioned(bottom: -45, left: -40, child: _buildDecoration()),

              Positioned(
                bottom: -45,
                right: -40,
                child: Transform.flip(flipX: true, child: _buildDecoration()),
              ),

              // --- BLOK TENGAH: LOGO & TEKS & GEDUNG ---
              Positioned(
                top: screenHeight * 0.10, // Titik mulai blok di layar
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. LOGO SIGAP
                    Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Image.asset(
                          'assets/images/Logo.png',
                          width: screenWidth * 0.32,
                          height: screenWidth * 0.32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16), // Jarak logo ke teks
                    // 2. NAMA & TAGLINE
                    Opacity(
                      opacity: _textOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            'SIGAP',
                            style: AppTextStyle.heading.copyWith(
                              fontSize: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Lapor, Pantau, Perbaiki',
                            style: AppTextStyle.body.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'Fasilitas Kampus',
                            style: AppTextStyle.body.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16), // Jarak teks ke gedung
                    // 3. GEDUNG REKTORAT
                    Opacity(
                      opacity: _buildingOpacity.value,
                      child: Transform.scale(
                        scale: _buildingScale.value,
                        child: Image.asset(
                          'assets/images/rektorat.png',
                          width: screenWidth * 0.85, // Ukuran gedung
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // WIDGET AWAN
  Widget _buildCloud(double size) {
    return Icon(
      Icons.cloud,
      size: size,
      color: AppColors.secondary.withValues(alpha: 0.13),
    );
  }

  // WIDGET DEKORASI DAUN
  Widget _buildDecoration() {
    return SizedBox(
      width: 170,
      height: 150,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 35,
            child: Icon(
              Icons.eco,
              size: 100,
              color: AppColors.secondary.withValues(alpha: 0.35),
            ),
          ),
          Positioned(
            bottom: 15,
            left: 0,
            child: Icon(
              Icons.eco,
              size: 65,
              color: AppColors.accent.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
