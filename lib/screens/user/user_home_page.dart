
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_styles.dart';
import 'create_report_page.dart';

class UserHomePage extends StatelessWidget {
  final VoidCallback onOpenReports;
  final VoidCallback onOpenProfile;

  const UserHomePage({
    super.key,
    required this.onOpenReports,
    required this.onOpenProfile,
  });

  // Mengambil nama pengguna dari tabel users di Supabase.
  // Jika tidak ditemukan, nama diambil dari metadata akun.
  Future<String> _getName() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return 'Pengguna';

    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', user.id)
          .maybeSingle();

      final name = row?['name']?.toString();

      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (_) {}

    final metadataName = user.userMetadata?['name']?.toString();

    if (metadataName != null && metadataName.trim().isNotEmpty) {
      return metadataName.trim();
    }

    return 'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getName(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Pengguna';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Header aplikasi.
              Text(
                'SIGAP',
                style: AppTextStyle.heading.copyWith(
                  color: AppColors.primary,
                  fontSize: 22,
                ),
              ),

              const SizedBox(height: 8),

              // Sapaan berdasarkan nama pengguna.
              Text(
                'Halo, $name 👋',
                style: AppTextStyle.heading.copyWith(
                  fontSize: 19,
                ),
              ),

              Text(
                'Selamat datang kembali!',
                style: AppTextStyle.label,
              ),

              const SizedBox(height: 24),

              // Banner utama dengan gambar rektorat.
              _buildBanner(context),

              const SizedBox(height: 28),

              // Menu utama.
              Text(
                'Menu Utama',
                style: AppTextStyle.heading.copyWith(
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 20,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  // Menu membuat laporan baru.
                  _menu(
                    Icons.add_circle_outline_rounded,
                    'Buat Laporan',
                    'Laporkan kerusakan',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateReportPage(),
                        ),
                      );
                    },
                  ),

                  // Menu melihat laporan pengguna.
                  _menu(
                    Icons.assignment_outlined,
                    'Laporan Saya',
                    'Pantau laporan',
                    onOpenReports,
                  ),

                  // Menu panduan aplikasi.
                  _menu(
                    Icons.menu_book_outlined,
                    'Panduan',
                    'Petunjuk penggunaan',
                    () => _showGuide(context),
                  ),

                  // Menu kontak admin.
                  _menu(
                    Icons.support_agent_rounded,
                    'Kontak Admin',
                    'Hubungi pengelola',
                    () => _showAdminContact(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Banner dengan background gambar rektorat.
  Widget _buildBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 230,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gambar rektorat sebagai background.
          Image.asset(
            'assets/images/rektorat.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.primary,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white,
                  size: 35,
                ),
              );
            },
          ),

          // Overlay gradasi agar teks terbaca.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.95),
                  AppColors.primary.withValues(alpha: 0.65),
                  AppColors.secondary.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),

          // Konten banner.
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SIGAP',
                  style: AppTextStyle.heading.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Ada fasilitas kampus yang rusak?',
                  style: AppTextStyle.heading.copyWith(
                    color: Colors.white,
                    fontSize: 19,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Laporkan kerusakan agar segera ditindaklanjuti.',
                  style: AppTextStyle.body.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 16),

                // Tombol menuju halaman pembuatan laporan.
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateReportPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                    size: 18,
                  ),
                  label: const Text('Buat Laporan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Komponen menu minimalis tanpa card.
  Widget _menu(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ikon dengan latar berwarna lembut.
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),

          const SizedBox(height: 9),

          // Nama menu.
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyle.heading.copyWith(
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 4),

          // Keterangan menu.
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyle.label.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Menampilkan panduan penggunaan SIGAP.
  void _showGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Panduan Penggunaan SIGAP'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '1. Buat Laporan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Pilih menu Buat Laporan untuk melaporkan kerusakan fasilitas kampus.',
              ),

              SizedBox(height: 12),

              Text(
                '2. Isi Detail Laporan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Lengkapi informasi kerusakan, lokasi, kategori, dan foto pendukung.',
              ),

              SizedBox(height: 12),

              Text(
                '3. Pantau Laporan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Buka menu Laporan Saya untuk melihat perkembangan status laporan.',
              ),

              SizedBox(height: 12),

              Text(
                '4. Tunggu Tindak Lanjut',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Admin dan petugas akan memproses laporan sesuai kondisi kerusakan.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  // Menampilkan informasi kontak admin.
  void _showAdminContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kontak Admin'),
        content: const Text(
          'Jika mengalami kendala dalam menggunakan SIGAP, '
          'silakan hubungi administrator kampus melalui kontak resmi '
          'yang telah disediakan oleh pihak pengelola.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
