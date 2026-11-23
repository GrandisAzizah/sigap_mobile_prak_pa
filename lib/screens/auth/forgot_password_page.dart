import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/bottom_wave_painter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _newPassword = TextEditingController();
  bool _loading = false;
  bool _emailDitemukan = false; // Penanda apakah email terdaftar

  static const Color primary = Color(0xFF7654D9);
  static const Color primaryLight = Color(0xFF9478EB);
  static const Color background = Color(0xFFF8F6FF);
  static const Color textPrimary = Color(0xFF252238);
  static const Color textSecondary = Color(0xFF817D91);

  @override
  void dispose() {
    _email.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  // Fungsi 1: Cek Email
  Future<void> _cekEmail() async {
    if (_email.text.trim().isEmpty) {
      _showMessage('Email harus diisi.');
      return;
    }

    setState(() => _loading = true);
    try {
      // Panggil fungsi RPC di Supabase.
      // Kita isi password dengan string kosong dulu untuk ngecek.
      final hasil = await Supabase.instance.client.rpc(
        'cek_dan_ganti_password',
        params: {'p_email': _email.text.trim(), 'p_password_baru': ''},
      );

      // Fungsi mengembalikan true jika email terdaftar
      if (hasil == true) {
        setState(() => _emailDitemukan = true);
      } else {
        _showMessage('Email tidak terdaftar di SIGAP.');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Fungsi 2: Simpan Password Baru
  Future<void> _simpanPassword() async {
    if (_newPassword.text.trim().length < 6) {
      _showMessage('Password minimal 6 karakter.');
      return;
    }

    setState(() => _loading = true);
    try {
      // Panggil fungsi RPC lagi, kali ini dengan password baru
      await Supabase.instance.client.rpc(
        'cek_dan_ganti_password',
        params: {
          'p_email': _email.text.trim(),
          'p_password_baru': _newPassword.text.trim(),
        },
      );

      _showMessage('Password berhasil diubah! Silakan login.', isError: false);
      Get.back(); // Kembali ke halaman login
    } catch (e) {
      _showMessage('Gagal mengubah password: $e');
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
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: textPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lupa Kata Sandi',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _emailDitemukan
                        ? 'Masukkan kata sandi baru kamu'
                        : 'Masukkan email untuk mencari akun',
                    style: const TextStyle(fontSize: 14, color: textPrimary),
                  ),
                  const SizedBox(height: 27),

                  // INPUT EMAIL
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
                      enabled: !_emailDitemukan, // Kunci input kalau email udah ketemu
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Email Kampus',
                        prefixIcon: Icon(Icons.mail_outline_rounded, size: 19),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  // INPUT PASSWORD BARU (Hanya muncul jika email ditemukan)
                  if (_emailDitemukan) ...[
                    const SizedBox(height: 16),
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
                        controller: _newPassword,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Kata Sandi Baru',
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            size: 19,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // TOMBOL UTAMA
                  SizedBox(
                    width: double.infinity,
                    height: 49,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : (_emailDitemukan ? _simpanPassword : _cekEmail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _emailDitemukan
                                  ? 'Simpan Sandi Baru'
                                  : 'Cek Email',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
