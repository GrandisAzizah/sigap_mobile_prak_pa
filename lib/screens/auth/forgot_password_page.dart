import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../components/bottom_wave_painter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  // Warna lokal disamakan dengan login
  static const Color primary = Color(0xFF7654D9);
  static const Color primaryLight = Color(0xFF9478EB);
  static const Color background = Color(0xFFF8F6FF);
  static const Color textPrimary = Color(0xFF252238);
  static const Color textSecondary = Color(0xFF817D91);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_email.text.trim().isEmpty) {
      _showMessage('Email harus diisi.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.forgotPassword(_email.text.trim());
      _showMessage('Link reset telah dikirim ke email kamu.', isError: false);
      Get.back();
    } catch (e) {
      _showMessage('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.redAccent : primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Dekorasi gelombang bawah
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 115,
            child: CustomPaint(painter: BottomWavePainter()),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 135),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tombol Back
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Judul
                  const Text(
                    'Lupa Kata Sandi',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masukkan email kampusmu untuk reset sandi',
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                  const SizedBox(height: 27),

                  // Input Email
                  Container(
                    height: 53,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: const Color(0xFFECE9F4),
                        width: 0.8,
                      ),
                    ),
                    child: TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 13, color: textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Email Kampus',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.mail_outline_rounded,
                          size: 19,
                          color: textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tombol Kirim
                  SizedBox(
                    width: double.infinity,
                    height: 49,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryLight, primary],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Kirim Link Reset',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
