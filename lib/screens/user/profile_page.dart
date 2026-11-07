
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
  // Service untuk menyimpan pengaturan aplikasi.
  final _settings = SettingsService();

  // Controller untuk mengelola input nama pengguna.
  final _nameController = TextEditingController();

  // Status pengaturan notifikasi.
  bool _notifications = true;
  bool _sound = true;
  bool _vibration = true;

  // Status proses pemuatan dan penyimpanan data.
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    // Mengambil data profil dan pengaturan saat halaman dibuka.
    _loadProfile();
  }

  // Mengambil nama pengguna dari tabel users di Supabase.
  // Pengaturan notifikasi diambil dari SettingsService.
  Future<void> _loadProfile() async {
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;

    try {
      if (user != null) {
        final profile = await db
            .from('users')
            .select('name')
            .eq('id', user.id)
            .maybeSingle();

        // Mengisi input nama berdasarkan data dari database.
        _nameController.text =
            profile?['name']?.toString() ??
            user.userMetadata?['name']?.toString() ??
            '';
      }

      // Mengambil preferensi notifikasi yang tersimpan.
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

  // Menyimpan perubahan nama ke Supabase.
  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();

    // Memastikan nama tidak kosong.
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final db = Supabase.instance.client;
      final user = db.auth.currentUser;

      if (user == null) {
        throw Exception('Pengguna belum login.');
      }

      // Memperbarui nama pada metadata Supabase Auth.
      await db.auth.updateUser(
        UserAttributes(
          data: {'name': name},
        ),
      );

      // Memperbarui nama pada tabel public.users.
      await db
          .from('users')
          .update({'name': name})
          .eq('id', user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
        ),
      );

      // Memperbarui tampilan nama pada halaman profil.
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profil: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // Menampilkan dialog untuk mengubah password.
  Future<void> _changePassword() async {
    final controller = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password baru',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    // Password minimal terdiri dari 8 karakter.
    if (password == null || password.isEmpty) {
      controller.dispose();
      return;
    }

    if (password.length < 8) {
      controller.dispose();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 8 karakter.'),
        ),
      );
      return;
    }

    try {
      // Memperbarui password melalui Supabase Auth.
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diubah.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah password: $e'),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  // Membersihkan controller ketika halaman tidak digunakan.
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menampilkan loading selama data profil diambil.
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Bagian foto dan nama pengguna.
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.light,
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  _nameController.text,
                  style: AppTextStyle.heading.copyWith(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Bagian informasi akun.
          Text(
            'Informasi Akun',
            style: AppTextStyle.heading.copyWith(
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 12),

          // Input untuk mengubah nama pengguna.
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),

          const SizedBox(height: 12),

          // Tombol untuk mengubah password.
          OutlinedButton.icon(
            onPressed: _changePassword,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Ubah Password'),
          ),

          const SizedBox(height: 12),

          // Tombol untuk menyimpan perubahan profil.
          ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            child: Text(
              _saving
                  ? 'Menyimpan...'
                  : 'Simpan Perubahan',
            ),
          ),

          const SizedBox(height: 28),

          // Bagian pengaturan notifikasi.
          Text(
            'Pengaturan Notifikasi',
            style: AppTextStyle.heading.copyWith(
              fontSize: 16,
            ),
          ),

          // Mengaktifkan atau menonaktifkan notifikasi.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Aktifkan Notifikasi'),
            subtitle: const Text(
              'Pemberitahuan perubahan status laporan',
            ),
            value: _notifications,
            onChanged: (value) async {
              setState(() => _notifications = value);

              await _settings.setNotifications(value);
            },
          ),

          // Mengatur suara notifikasi.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Suara Notifikasi'),
            value: _sound,
            onChanged: _notifications
                ? (value) async {
                    setState(() => _sound = value);

                    await _settings.setSound(value);
                  }
                : null,
          ),

          // Mengatur getaran notifikasi.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Getaran'),
            value: _vibration,
            onChanged: _notifications
                ? (value) async {
                    setState(() => _vibration = value);

                    await _settings.setVibration(value);
                  }
                : null,
          ),

          const SizedBox(height: 20),

          // Tombol untuk keluar dari akun.
          OutlinedButton.icon(
            onPressed: () async {
              await AuthService().logout();

              Get.offAll(
                () => const LoginPage(),
              );
            },
            icon: const Icon(
              Icons.logout,
              color: AppColors.error,
            ),
            label: const Text('Keluar dari Akun'),
          ),
        ],
      ),
    );
  }
}
