
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_styles.dart';
import '../../services/settings_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _settings = SettingsService();
  final _nameController = TextEditingController();

  String _email = '';

  bool _notifications = true;
  bool _sound = true;
  bool _vibration = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Mengambil data akun dan pengaturan aplikasi.
  Future<void> _loadProfile() async {
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;

    try {
      if (user != null) {
        _email = user.email ?? '';

        final profile = await db
            .from('users')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();

        _nameController.text =
            profile?['name']?.toString() ??
            user.userMetadata?['name']?.toString() ??
            '';
      }

      _notifications = await _settings.notificationsEnabled;
      _sound = await _settings.soundEnabled;
      _vibration = await _settings.vibrationEnabled;
    } catch (e) {
      debugPrint('Gagal memuat profil: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Menyimpan perubahan nama pengguna.
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Nama tidak boleh kosong.');
      return;
    }

    setState(() => _saving = true);

    try {
      final db = Supabase.instance.client;
      final user = db.auth.currentUser;

      if (user == null) {
        throw Exception('Pengguna belum login.');
      }

      await db.auth.updateUser(
        UserAttributes(data: {'name': name}),
      );

      await db
          .from('users')
          .update({'name': name})
          .eq('id', user.id);

      if (!mounted) return;
      _showMessage('Profil berhasil diperbarui.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal memperbarui profil: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // Menampilkan dialog untuk mengganti password.
  Future<void> _changePassword() async {
    final controller = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Ubah Password',
            style: AppTextStyle.heading.copyWith(fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password baru',
              hintText: 'Minimal 8 karakter',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, controller.text);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (password == null || password.isEmpty) return;

    if (password.length < 8) {
      _showMessage('Password minimal 8 karakter.');
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;
      _showMessage('Password berhasil diubah.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal mengubah password: $e');
    }
  }

  // Mengatur preferensi notifikasi.
  Future<void> _setNotifications(bool value) async {
    setState(() => _notifications = value);
    await _settings.setNotifications(value);
  }

  Future<void> _setSound(bool value) async {
    setState(() => _sound = value);
    await _settings.setSound(value);
  }

  Future<void> _setVibration(bool value) async {
    setState(() => _vibration = value);
    await _settings.setVibration(value);
  }

  // Keluar dari akun.
  Future<void> _logout() async {
    try {
      await AuthService().logout();

      if (!mounted) return;
      Get.offAll(() => const LoginPage());
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal keluar dari akun: $e');
    }
  }

  // Menampilkan pesan.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAccountSection(),

                    const SizedBox(height: 26),

                    _buildSecuritySection(),

                    const SizedBox(height: 26),

                    _buildNotificationSection(),

                    const SizedBox(height: 28),

                    _buildLogoutButton(),

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        'SIGAP • Sistem Informasi Pengaduan',
                        style: AppTextStyle.body.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header halaman profil.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PENGATURAN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Profil Saya',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _email.isEmpty ? 'Kelola informasi akun Anda' : _email,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Kelola akun SIGAP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bagian informasi akun.
  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Informasi Akun',
          'Perbarui informasi pribadi Anda.',
        ),

        const SizedBox(height: 16),

        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Nama Lengkap'),

              const SizedBox(height: 8),

              TextField(
                controller: _nameController,
                decoration: _inputDecoration(
                  'Masukkan nama lengkap',
                ),
              ),

              const SizedBox(height: 18),

              _fieldLabel('Alamat Email'),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _email.isEmpty ? '-' : _email,
                  style: AppTextStyle.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _saving ? 'Menyimpan...' : 'Simpan Profil',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bagian keamanan akun.
  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Keamanan',
          'Lindungi akun dengan password yang aman.',
        ),

        const SizedBox(height: 16),

        _panel(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 7,
            ),
            title: Text(
              'Ubah Password',
              style: AppTextStyle.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Ganti password akun Anda',
              style: AppTextStyle.body.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            onTap: _changePassword,
          ),
        ),
      ],
    );
  }

  // Bagian pengaturan notifikasi.
  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Preferensi Notifikasi',
          'Atur bagaimana aplikasi memberikan pemberitahuan.',
        ),

        const SizedBox(height: 16),

        _panel(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Column(
            children: [
              _notificationTile(
                title: 'Notifikasi',
                subtitle: 'Pemberitahuan status laporan',
                value: _notifications,
                onChanged: _setNotifications,
              ),

              const Divider(
                height: 1,
                color: AppColors.light,
              ),

              _notificationTile(
                title: 'Suara',
                subtitle: 'Suara saat notifikasi diterima',
                value: _sound,
                onChanged: _notifications ? _setSound : null,
              ),

              const Divider(
                height: 1,
                color: AppColors.light,
              ),

              _notificationTile(
                title: 'Getaran',
                subtitle: 'Getaran saat notifikasi diterima',
                value: _vibration,
                onChanged: _notifications ? _setVibration : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Baris pengaturan notifikasi.
  Widget _notificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: AppTextStyle.body.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // Tombol keluar akun.
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(
            color: AppColors.error,
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Keluar dari Akun',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Judul dan deskripsi setiap bagian.
  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyle.heading.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: AppTextStyle.body.copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Panel untuk mengelompokkan informasi.
  Widget _panel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // Label input.
  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: AppTextStyle.body.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Tampilan input.
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyle.body.copyWith(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }
}
