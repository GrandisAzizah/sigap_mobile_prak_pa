import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_styles.dart';
import 'create_report_page.dart';

class UserHomePage extends StatelessWidget {
  final VoidCallback onOpenReports;
  final VoidCallback onOpenProfile;
  const UserHomePage({super.key, required this.onOpenReports, required this.onOpenProfile});

  Future<String> _getName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Pengguna';
    try {
      final row = await Supabase.instance.client
          .from('users').select('name').eq('id', user.id).maybeSingle();
      final name = row?['name']?.toString();
      if (name != null && name.trim().isNotEmpty) return name.trim();
    } catch (_) {}
    return user.userMetadata?['name']?.toString() ?? 'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getName(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Pengguna';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 10),
            Text('SIGAP', style: AppTextStyle.heading.copyWith(
              color: AppColors.primary, fontSize: 22)),
            const SizedBox(height: 8),
            Text('Halo, $name 👋', style: AppTextStyle.heading.copyWith(fontSize: 19)),
            Text('Selamat datang kembali!', style: AppTextStyle.label),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(20)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.campaign_rounded, color: Colors.white, size: 34),
                const SizedBox(height: 12),
                Text('Ada fasilitas kampus yang rusak?',
                  style: AppTextStyle.heading.copyWith(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 7),
                Text('Laporkan kerusakan agar segera ditindaklanjuti.',
                  style: AppTextStyle.body.copyWith(color: Colors.white)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateReportPage())),
                  icon: const Icon(Icons.add),
                  label: const Text('Buat Laporan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: AppColors.primary)),
              ]),
            ),
            const SizedBox(height: 25),
            Text('Menu Utama', style: AppTextStyle.heading.copyWith(fontSize: 17)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _menu(context, Icons.assignment_outlined,
                'Laporan Saya', 'Lihat laporan yang dibuat', onOpenReports)),
              const SizedBox(width: 12),
              Expanded(child: _menu(context, Icons.person_outline,
                'Profil Saya', 'Pengaturan akun', () {})),
            ]),
            const SizedBox(height: 20),
            Text('Tentang SIGAP', style: AppTextStyle.heading.copyWith(fontSize: 17)),
            const SizedBox(height: 8),
            Text('SIGAP membantu civitas akademika melaporkan kerusakan fasilitas kampus dengan mudah dan terorganisir.',
              style: AppTextStyle.body.copyWith(color: AppColors.textSecondary, height: 1.5)),
          ]),
        );
      },
    );
  }

  Widget _menu(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.light)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.primary, size: 27),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyle.heading.copyWith(fontSize: 13)),
          const SizedBox(height: 5),
          Text(subtitle, style: AppTextStyle.label.copyWith(fontSize: 10)),
        ]),
      ),
    );
  }
}
