import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../app_styles.dart';
import '../auth/login_page.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = _db.auth.currentUser;
    try {
      if (user != null) {
        final row = await _db
            .from('users')
            .select('name, nim, email, role')
            .eq('id', user.id)
            .maybeSingle();

        debugPrint('USER ID : ${user.id}');
        debugPrint('ROW     : $row');
        if (row == null) {
          _error =
              'Baris profil untuk akun ini tidak ditemukan di tabel users '
              '(id ${user.id}). Cek apakah id di tabel users sama dengan id di Authentication.';
        }
        _profile = row;
      }
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
      _error = '$e';
      String errorMessage = '$e';

      if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Failed host lookup') ||
          errorMessage.contains('ClientException')) {
        errorMessage = 'Koneksi bermasalah. Periksa jaringan internet Anda.';
      } else {
        errorMessage = 'Gagal memuat data laporan. Silakan coba lagi.';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Ambil dari tabel users; kalau kosong, pakai data akun login (auth).
  String _val(String key) {
    final fromTable = _profile?[key];
    if (fromTable != null && fromTable.toString().isNotEmpty)
      return fromTable.toString();
    final user = _db.auth.currentUser;
    if (key == 'email') return user?.email ?? '-';
    final meta = user?.userMetadata?[key];
    return (meta == null || meta.toString().isEmpty) ? '-' : meta.toString();
  }

  Future<void> _logout() async {
    await AuthService().logout();
    Get.offAll(() => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    final name = _val('name');
    final initial = name != '-' && name.isNotEmpty
        ? name[0].toUpperCase()
        : 'A';

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Profil',
                      style: AppTextStyle.heading.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.light,
                        child: Text(
                          initial,
                          style: AppTextStyle.heading.copyWith(
                            fontSize: 32,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        name,
                        style: AppTextStyle.heading.copyWith(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.light,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Admin',
                          style: AppTextStyle.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Data profil dari tabel users belum bisa dimuat:\n$_error',
                          style: AppTextStyle.label.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _Tile(Icons.badge_outlined, 'NIP', _val('nim')),
                    _Tile(Icons.mail_outline, 'Email', _val('email')),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: Text(
                        'Keluar',
                        style: AppTextStyle.button.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(49),
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Tile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.light),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyle.label.copyWith(fontSize: 11)),
              Text(
                value,
                style: AppTextStyle.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
