import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;

  // Akun demo sementara
  static const String demoUsername = '1234567890';
  static const String demoPassword = 'Sigap123!';

  static const Color primary = Color(0xFF7654D9);
  static const Color primaryLight = Color(0xFF9478EB);
  static const Color background = Color(0xFFF8F6FF);
  static const Color textPrimary = Color(0xFF252238);
  static const Color textSecondary = Color(0xFF817D91);

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final username = _identityController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage('NIM/email dan kata sandi harus diisi.');
      return;
    }

    if (username == demoUsername && password == demoPassword) {
      _showMessage('Login berhasil! Selamat datang di SIgap.');

      // Hubungkan ke halaman dashboard setelah tersedia.
      // Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showMessage('NIM/email atau kata sandi tidak sesuai.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: primary,
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
          // Dekorasi gelombang di bagian bawah
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 115,
            child: CustomPaint(painter: BottomWavePainter()),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 42, 20, 135),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo

                  // Logo aplikasi SIgap
                  Container(
                    width: 60,
                    height: 60,
                    padding: const EdgeInsets.all(0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/images/Logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Judul
                  const Text(
                    'Masuk',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.7,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Gunakan akun kampusmu',
                    style: TextStyle(fontSize: 14, color: textPrimary),
                  ),

                  const SizedBox(height: 27),

                  // Input NIM / Email
                  _buildInputField(
                    controller: _identityController,
                    hint: 'NIM/Email Kampus',
                    icon: Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: 13),

                  // Input Password
                  _buildInputField(
                    controller: _passwordController,
                    hint: 'Kata sandi',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
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

                  const SizedBox(height: 13),

                  // Ingat saya dan lupa password
                  Row(
                    children: [
                      SizedBox(
                        height: 25,
                        width: 25,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 5),

                      const Text(
                        'Ingat saya',
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),

                      const Spacer(),

                      TextButton(
                        onPressed: () {
                          _showMessage('Fitur lupa kata sandi belum tersedia.');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Lupa kata sandi',
                          style: TextStyle(
                            fontSize: 12,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Tombol Masuk
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
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Informasi akun demo
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8E1FA)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AKUN PENGUJIAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'NIM: 1234567890',
                          style: TextStyle(fontSize: 12, color: textPrimary),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Password: Sigap123!',
                          style: TextStyle(fontSize: 12, color: textPrimary),
                        ),
                      ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 53,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFECE9F4), width: 0.8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
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

// Custom gelombang bagian bawah
class BottomWavePainter extends CustomPainter {
  const BottomWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final firstPaint = Paint()..color = const Color(0xFFE7DFFF);

    final firstPath = Path()
      ..moveTo(0, size.height * 0.30)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.05,
        size.width * 0.40,
        size.height * 0.85,
        size.width * 0.62,
        size.height * 0.62,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.42,
        size.width * 0.87,
        size.height * 0.12,
        size.width,
        size.height * 0.18,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(firstPath, firstPaint);

    final secondPaint = Paint()..color = const Color(0xFFD7C9FF);

    final secondPath = Path()
      ..moveTo(0, size.height * 0.30)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.25,
        size.width * 0.32,
        size.height * 0.72,
        size.width * 0.55,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(secondPath, secondPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
