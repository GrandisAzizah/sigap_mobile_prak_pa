import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../components/bottom_wave_painter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nim = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _auth = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  // Warna lokal disamakan dengan login
  static const Color primary = Color(0xFF7654D9);
  static const Color primaryLight = Color(0xFF9478EB);
  static const Color background = Color(0xFFF8F6FF);
  static const Color textPrimary = Color(0xFF252238);
  static const Color textSecondary = Color(0xFF817D91);

  @override
  void dispose() {
    _nim.dispose();
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.register(
        nim: _nim.text.trim(),
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
      );
      _showMessage('Akun berhasil dibuat. Silakan login.', isError: false);
      Get.back();
    } on AuthException catch (e) {
      _showMessage(e.message);
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
                    'Daftar Akun',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lengkapi data untuk mulai melapor',
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),
                  const SizedBox(height: 27),

                  // Form Fields
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _nim,
                          hint: 'NIM',
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'NIM wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 13),

                        _buildInputField(
                          controller: _name,
                          hint: 'Nama Lengkap',
                          icon: Icons.person_outline_rounded,
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Nama wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 13),

                        _buildInputField(
                          controller: _email,
                          hint: 'Email Kampus',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Email tidak valid'
                              : null,
                        ),
                        const SizedBox(height: 13),

                        _buildInputField(
                          controller: _pass,
                          hint: 'Kata sandi (min 6 karakter)',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Minimal 6 karakter'
                              : null,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textSecondary,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Tombol Daftar
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
                        onPressed: _loading ? null : _register,
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
                                'Daftar',
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

  // Widget input field custom disamakan dengan login
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 53,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFECE9F4), width: 0.8),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 13, color: textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12, color: textSecondary),
          prefixIcon: Icon(icon, size: 19, color: textSecondary),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
