import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_styles.dart';

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  final _db = Supabase.instance.client;

  List<Map<String, dynamic>> _staffs = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------- READ ----------
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Ambil daftar petugas dan nama kategorinya (join ke categories)
      final staffs = await _db
          .from('staffs')
          .select(
            'id, name_staff, phone, category_id, is_active, categories(name)',
          )
          .order('name_staff');

      // Ambil semua kategori untuk dropdown di form
      final cats = await _db
          .from('categories')
          .select('id, name')
          .order('name');
      setState(() {
        _staffs = List<Map<String, dynamic>>.from(staffs as List);
        _categories = List<Map<String, dynamic>>.from(cats as List);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- CREATE / UPDATE ----------
  Future<bool> _save({
    String? id,
    required String name,
    String? phone,
    String? categoryId,
    required bool active,
  }) async {
    final data = {
      'name_staff': name,
      'phone': phone,
      'category_id': categoryId,
      'is_active': active,
    };
    try {
      if (id == null) {
        await _db.from('staffs').insert(data);
      } else {
        await _db.from('staffs').update(data).eq('id', id);
      }
      return true;
    } catch (e) {
      Get.snackbar('Gagal menyimpan', '$e');
      return false;
    }
  }

  Future<void> _openForm([Map<String, dynamic>? staff]) async {
    final name = TextEditingController(text: staff?['name_staff'] as String?);
    final phone = TextEditingController(text: staff?['phone'] as String?);
    String? categoryId = staff?['category_id'] as String?;
    if (!_categories.any((c) => c['id'] == categoryId)) categoryId = null;
    bool active = (staff?['is_active'] ?? true) as bool;
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    final saved = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            staff == null ? 'Tambah Petugas' : 'Edit Petugas',
            style: AppTextStyle.heading.copyWith(fontSize: 18),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama petugas',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'No. HP (opsional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bidang kerja',
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['id'] as String,
                            child: Text(c['name'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => categoryId = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Aktif', style: AppTextStyle.body),
                    value: active,
                    onChanged: (v) => setLocal(() => active = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Get.back(result: false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => saving = true);
                      final ok = await _save(
                        id: staff?['id'] as String?,
                        name: name.text.trim(),
                        phone: phone.text.trim().isEmpty
                            ? null
                            : phone.text.trim(),
                        categoryId: categoryId,
                        active: active,
                      );
                      if (ok) {
                        Get.back(result: true);
                      } else {
                        setLocal(() => saving = false);
                      }
                    },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      Get.snackbar(
        'Tersimpan',
        staff == null ? 'Petugas ditambahkan' : 'Petugas diperbarui',
      );
      _load();
    }
  }

  // ---------- DELETE ----------
  Future<void> _confirmDelete(Map<String, dynamic> s) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          'Hapus petugas?',
          style: AppTextStyle.heading.copyWith(fontSize: 18),
        ),
        content: Text(
          '${s['name_staff']} akan dihapus. Laporan yang ditangani petugas ini '
          'akan kembali menjadi "Belum ditentukan".',
          style: AppTextStyle.body.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Get.back(result: true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _db.from('staffs').delete().eq('id', s['id']);
      Get.snackbar('Terhapus', '${s['name_staff']} dihapus');
      _load();
    } catch (e) {
      Get.snackbar('Gagal menghapus', '$e');
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        tooltip: 'Tambah petugas',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Petugas',
                style: AppTextStyle.heading.copyWith(fontSize: 24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                _loading ? 'Memuat...' : '${_staffs.length} petugas terdaftar',
                style: AppTextStyle.label,
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Gagal memuat petugas\n$_error',
                              textAlign: TextAlign.center,
                              style: AppTextStyle.label.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _load,
                              child: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _staffs.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 100),
                                Center(
                                  child: Text(
                                    'Belum ada petugas.\nKetuk + untuk menambah.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyle.label,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                              itemCount: _staffs.length,
                              itemBuilder: (_, i) => _StaffTile(
                                staff: _staffs[i],
                                onEdit: () => _openForm(_staffs[i]),
                                onDelete: () => _confirmDelete(_staffs[i]),
                              ),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  final Map<String, dynamic> staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _StaffTile({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = (staff['is_active'] ?? true) as bool;
    final category =
        (staff['categories'] as Map?)?['name'] as String? ?? 'Umum';
    final phone = staff['phone'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.light),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.light,
              child: Icon(
                Icons.engineering_outlined,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (staff['name_staff'] ?? '').toString(),
                    style: AppTextStyle.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$category${(phone ?? '').isEmpty ? '' : ' • $phone'}',
                    style: AppTextStyle.label.copyWith(fontSize: 12),
                  ),
                  if (!active)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Nonaktif',
                          style: AppTextStyle.label.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
