import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_styles.dart';
import '../../services/local_db.dart';
import 'admin_detail_report_page.dart';
import 'status_chip.dart';

/// Beranda admin: daftar laporan  + pencarian judul + ikon notifikasi.
class AdminReportsPage extends StatefulWidget {
  final int unread;
  final VoidCallback onOpenNotifications;

  const AdminReportsPage({
    super.key,
    required this.unread,
    required this.onOpenNotifications,
  });

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage>
    with SingleTickerProviderStateMixin {
  final _db = Supabase.instance.client;
  final _searchCtrl = TextEditingController();
  RealtimeChannel? _channel;
  late TabController _tabController;

  List<LocalMap> _all = [];
  String _query = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();

    // Laporan baru / perubahan status langsung muncul tanpa tarik-refresh
    _channel = _db
        .channel('admin-reports-list')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reports',
          callback: (_) => _load(silent: true),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_channel != null) _db.removeChannel(_channel!);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _db
          .from('reports')
          .select(adminReportSelect)
          .order('created_at', ascending: false);

      final reports = List<LocalMap>.from(data as List);

      // Simpan daftar laporan terbaru ke Hive agar bisa dibaca saat offline
      await LocalDb.saveAdminReports(reports);

      if (!mounted) return;
      setState(() => _all = reports);
    } catch (e) {
      // Ambil dari cache Hive jika offline / gagal memuat dari server
      final cached = LocalDb.getAdminReports();
      if (!mounted) return;

      if (cached.isNotEmpty) {
        setState(() {
          _all = cached.map((item) => LocalMap.from(item as Map)).toList();
          _error = null;
        });
      } else {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Filter berdasarkan status & pencarian judul
  List<LocalMap> _filtered({required String status}) {
    final q = _query.trim().toLowerCase();
    return _all.where((r) {
      // Cek status
      final currentStatus = (r['status_reports'] ?? 'menunggu')
          .toString()
          .toLowerCase();
      if (currentStatus != status) return false;

      // Cek pencarian
      if (q.isEmpty) return true;
      return (r['title'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openDetail(LocalMap r) async {
    final changed = await Get.to(() => AdminReportDetailPage(report: r));
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final menunggu = _filtered(status: 'menunggu');
    final diproses = _filtered(status: 'diproses');
    final selesai = _filtered(status: 'selesai');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Judul dan ikon notifikasi di kanan atas sebelahan
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Laporan',
                      style: AppTextStyle.heading.copyWith(fontSize: 24),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notifikasi',
                    onPressed: widget.onOpenNotifications,
                    icon: Badge(
                      isLabelVisible: widget.unread > 0,
                      label: Text('${widget.unread}'),
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 28,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyle.body.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari judul laporan...',
                  hintStyle: AppTextStyle.label,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // TabBar 3 Status
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: AppTextStyle.label.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: [
                Tab(text: 'Menunggu (${menunggu.length})'),
                Tab(text: 'Diproses (${diproses.length})'),
                Tab(text: 'Selesai (${selesai.length})'),
              ],
            ),

            // TabBarView
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _ReportList(
                          items: menunggu,
                          query: _query,
                          emptyText: 'Tidak ada laporan yang menunggu',
                          onRefresh: _load,
                          onTap: _openDetail,
                        ),
                        _ReportList(
                          items: diproses,
                          query: _query,
                          emptyText: 'Tidak ada laporan yang sedang diproses',
                          onRefresh: _load,
                          onTap: _openDetail,
                        ),
                        _ReportList(
                          items: selesai,
                          query: _query,
                          emptyText: 'Belum ada laporan yang selesai',
                          onRefresh: _load,
                          onTap: _openDetail,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// BUAT SI TAB ITU LAH INTINYA BIAR JADI 3
// ==========================================

class _ReportList extends StatelessWidget {
  final List<LocalMap> items;
  final String query;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final void Function(LocalMap) onTap;

  const _ReportList({
    required this.items,
    required this.query,
    required this.emptyText,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Text(
                    query.trim().isEmpty
                        ? emptyText
                        : 'Tidak ada laporan dengan kata "${query.trim()}"',
                    textAlign: TextAlign.center,
                    style: AppTextStyle.label,
                  ),
                ),
              ],
            )
          : ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              itemCount: items.length,
              itemBuilder: (_, i) =>
                  _ReportTile(report: items[i], onTap: () => onTap(items[i])),
            ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final LocalMap report;
  final VoidCallback onTap;
  const _ReportTile({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photos = (report['report_photos'] as List?) ?? const [];
    final thumb = photos.isEmpty
        ? null
        : (photos.first as Map)['photo_url'] as String?;
    final building = (report['buildings'] as Map?)?['name'] as String?;
    final room = report['room_detail'] as String?;
    final location = [
      building,
      room,
    ].where((e) => e != null && e.isNotEmpty).join(' • ');
    final reporter = (report['users'] as Map?)?['name'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.light),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: thumb == null
                      ? Container(
                          color: AppColors.light,
                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.secondary,
                          ),
                        )
                      : Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.light,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            (report['report_code'] ?? '-').toString(),
                            style: AppTextStyle.label.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusChip(
                          (report['status_reports'] ?? 'menunggu').toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (report['title'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (location.isNotEmpty)
                      Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.label.copyWith(fontSize: 12),
                      ),
                    Text(
                      '${reporter ?? '-'} • ${formatTanggal(report['created_at'])}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.label.copyWith(fontSize: 11),
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
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat laporan\n$message',
              textAlign: TextAlign.center,
              style: AppTextStyle.label.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
