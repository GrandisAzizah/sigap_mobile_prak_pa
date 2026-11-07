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
  final _usernameController = TextEditingController();
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

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    _nameController.text = user?.userMetadata?['name']?.toString() ?? '';
    _usernameController.text = user?.userMetadata?['username']?.toString() ?? '';
    _notifications = await _settings.notificationsEnabled;
    _sound = await _settings.soundEnabled;
    _vibration = await _settings.vibrationEnabled;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final db = Supabase.instance.client;
      final user = db.auth.currentUser;
      if (user == null) throw Exception('Pengguna belum login.');

      // Metadata Auth diperbarui. Kolom tabel users juga diperbarui agar
      // data profil yang dibaca aplikasi tetap konsisten.
      await db.auth.updateUser(UserAttributes(data: {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
      }));
      await db.from('users').update({
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
      }).eq('id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password baru'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Simpan')),
        ],
      ),
    );
    if (password == null || password.length < 8) return;
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: password));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah password: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil & Pengaturan'), centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Center(child: Column(children: [
          const CircleAvatar(radius: 38, backgroundColor: AppColors.light,
            child: Icon(Icons.person, color: AppColors.primary, size: 40)),
          const SizedBox(height: 10),
          Text(_nameController.text, style: AppTextStyle.heading.copyWith(fontSize: 18)),
        ])),
        const SizedBox(height: 24),
        Text('Informasi Akun', style: AppTextStyle.heading.copyWith(fontSize: 16)),
        const SizedBox(height: 12),
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nama')),
        const SizedBox(height: 12),
        TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _changePassword,
          icon: const Icon(Icons.lock_outline), label: const Text('Ubah Password')),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saving ? null : _saveProfile,
          child: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan')),
        const SizedBox(height: 28),
        Text('Pengaturan Notifikasi', style: AppTextStyle.heading.copyWith(fontSize: 16)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Aktifkan Notifikasi'),
          subtitle: const Text('Pemberitahuan perubahan status laporan'),
          value: _notifications,
          onChanged: (value) async {
            setState(() => _notifications = value);
            await _settings.setNotifications(value);
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Suara Notifikasi'),
          value: _sound,
          onChanged: _notifications ? (value) async {
            setState(() => _sound = value);
            await _settings.setSound(value);
          } : null,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Getaran'),
          value: _vibration,
          onChanged: _notifications ? (value) async {
            setState(() => _vibration = value);
            await _settings.setVibration(value);
          } : null,
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await AuthService().logout();
            Get.offAll(() => const LoginPage());
          },
          icon: const Icon(Icons.logout, color: AppColors.error),
          label: const Text('Keluar dari Akun'),
        ),
      ]),
    );
  }
}
