import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_styles.dart';
import 'status_chip.dart';

// ambil data dari supabase, ini query
const adminReportSelect =
    '*, categories(name), buildings(name), staffs(name_staff), users(name, nim), report_photos(photo_url)';

class AdminReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  const AdminReportDetailPage({super.key, required this.report});

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
  final _db = Supabase.instance.client;
  // widget report ambil data dari halaman sebelumnya (daftar laporan)
  // _status, _staffId dan _note nyimpen pilihan admin
  //sementara sebelum dimasukin ke database
  late String _status = (widget.report['status_reports'] ?? 'menunggu')
      .toString();
  late String? _staffId = widget.report['staff_id'] as String?;
  late final _note = TextEditingController(
    text: widget.report['admin_note'] as String?,
  );

  List<Map<String, dynamic>> _staffs = [];
  bool _saving = false;
  // simpan nilai awal, untuk cek apakah
  //admin beneran ngubah sesuatu supaya tombol simpan aktif
  late final String _initialStatus;
  late final String? _initialStaffId;
  late final String _initialNote;

  @override
  void initState() {
    super.initState();
    _initialStatus = _status;
    _initialStaffId = _staffId;
    _initialNote = _note.text;
    _loadStaffs();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  // fungsi ambil daftar petugas di database
  // petugas kategori sama dengan laporan ada di paling atas
  Future<void> _loadStaffs() async {
    try {
      final data = await _db
          .from('staffs')
          .select('id, name_staff, category_id, is_active, categories(name)')
          .eq('is_active', true)
          .order('name_staff');
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(data as List);
      // Petugas yang bidangnya sama dengan kategori laporan ditaruh paling atas
      final cat = widget.report['category_id'];
      list.sort((a, b) {
        int rank(Map<String, dynamic> s) => s['category_id'] == cat ? 0 : 1;
        return rank(a).compareTo(rank(b));
      });
      setState(() => _staffs = list);
    } catch (_) {}
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
  }

  // Fungsi untuk mengecek apakah ada perubahan
  bool get _hasChanges {
    return _status != _initialStatus ||
        _staffId != _initialStaffId ||
        _note.text != _initialNote;
  }

  // kalo status diproses(diubah) maka harus pilih staf
  Future<void> _save() async {
    if (_status == 'diproses' && _staffId == null) {
      _snack('Pilih petugas yang menangani laporan ini');
      return;
    }
    setState(() => _saving = true);
    try {
      // update db
      await _db
          .from('reports')
          .update({
            'status_reports': _status,
            'staff_id': _staffId,
            'admin_note': _note.text.trim().isEmpty ? null : _note.text.trim(),
          })
          .eq('id', widget.report['id']);
      // tutup halaman dan kasih snackbar hijau kalo sukses
      Get.back(result: true);
      Get.snackbar(
        'Tersimpan',
        'Laporan diperbarui, pelapor akan mendapat notifikasi',
        backgroundColor: AppColors.success, // Warna hijau
        colorText: Colors.white, // Tulisan jadi putih
        snackPosition: SnackPosition.BOTTOM, // Muncul di bawah
        margin: const EdgeInsets.all(16), // Memberi jarak dari pinggir layar
        borderRadius: 8, // Membuat sudutnya agak melengkung
        icon: const Icon(
          Icons.check_circle,
          color: Colors.white,
        ), //tambah ikon centang
        duration: const Duration(seconds: 3), // Durasi muncul (3 detik)
      );
    } catch (e) {
      _snack('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    // liat fotonya
    final photos = ((r['report_photos'] as List?) ?? const [])
        .map((e) => (e as Map)['photo_url'] as String)
        .toList();
    final building = (r['buildings'] as Map?)?['name'] as String?;
    final room = r['room_detail'] as String?;
    final location = [
      building,
      room,
    ].where((e) => e != null && e.isNotEmpty).join(' • ');
    final reporter = r['users'] as Map?;
    final staffValue = _staffs.any((s) => s['id'] == _staffId)
        ? _staffId
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          (r['report_code'] ?? 'Detail Laporan').toString(),
          style: AppTextStyle.heading.copyWith(fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (photos.isNotEmpty)
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photos[i],
                      width: photos.length == 1
                          ? MediaQuery.of(context).size.width - 40
                          : 260,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 260,
                        color: AppColors.light,
                        child: const Icon(
                          //icon kalo foto ga bisa load atas
                          Icons.broken_image_outlined,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                // label status
                StatusChip((r['status_reports'] ?? 'menunggu').toString()),
                const SizedBox(width: 8),
                // label severity
                SeverityChip((r['severity'] ?? 'low').toString()),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              (r['title'] ?? '').toString(),
              style: AppTextStyle.heading.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            _Info(
              'Kategori',
              ((r['categories'] as Map?)?['name'] ?? '-').toString(),
            ),
            _Info('Lokasi', location.isEmpty ? '-' : location),
            _Info(
              'Pelapor',
              '${reporter?['name'] ?? '-'}${reporter?['nim'] == null ? '' : ' (${reporter!['nim']})'}',
            ),
            _Info('Dilaporkan', formatTanggal(r['created_at'])),
            _Info('Deskripsi', (r['report_detail'] ?? '-').toString()),
            const Divider(height: 32),
            Text(
              'Ubah Status',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _status,
              // Kunci dropdown jika status awal dari database sudah 'selesai'
              onChanged: (widget.report['status_reports'] == 'selesai')
                  ? null
                  : (v) => setState(() => _status = v ?? _status),
              items: const ['menunggu', 'diproses', 'selesai']
                  .map(
                    (s) => DropdownMenuItem(value: s, child: Text(kapital(s))),
                  )
                  .toList(),
            ),

            // info
            if (widget.report['status_reports'] == 'selesai')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Laporan yang sudah selesai tidak dapat diubah statusnya.',
                  style: AppTextStyle.label.copyWith(
                    fontSize: 11,
                    color: AppColors.error, // Warna merah
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // bagian assign
            Text(
              'Petugas Perbaikan',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: staffValue,
              isExpanded: true,
              // Jika status 'diproses' & petugas kosong, beri border merah
              decoration: InputDecoration(
                errorText: (_status == 'diproses' && _staffId == null)
                    ? 'Wajib dipilih jika status "Diproses"'
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Belum ditentukan'),
                ),
                ..._staffs
                    .where((s) => s['is_active'] == true || s['id'] == _staffId)
                    .map(
                      (s) => DropdownMenuItem<String?>(
                        value: s['id'] as String,
                        child: Text(
                          '${s['name_staff']} (${(s['categories'] as Map?)?['name'] ?? 'Umum'})'
                          '${s['is_active'] == false ? ' - nonaktif' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
              ],
              onChanged: (v) => setState(() => _staffId = v),
            ),
            const SizedBox(height: 16),
            // catatan admin
            Text(
              'Catatan (opsional)',
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tambahkan catatan penanganan...',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_saving || !_hasChanges) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 92, child: Text(label, style: AppTextStyle.label)),
        Expanded(
          child: Text(value, style: AppTextStyle.body.copyWith(fontSize: 13)),
        ),
      ],
    ),
  );
}
