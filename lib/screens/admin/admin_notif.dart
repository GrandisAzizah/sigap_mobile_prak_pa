import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_styles.dart';
import 'admin_detail_report_page.dart';
import 'status_chip.dart';

/// Halaman notifikasi admin (dibuka dari ikon lonceng di halaman Laporan).
/// Ketuk notifikasi untuk membuka detail laporannya.
class AdminNotificationsPage extends StatefulWidget {
  final VoidCallback onChanged; // setelah ada yang dibaca (update badge)
  final Listenable refresh; // berubah saat ada notifikasi baru masuk
  const AdminNotificationsPage({
    super.key,
    required this.onChanged,
    required this.refresh,
  });

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    widget.refresh.addListener(_reload);
  }

  @override
  void dispose() {
    widget.refresh.removeListener(_reload);
    super.dispose();
  }

  void _reload() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _db
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('sent_at', ascending: false)
          .limit(100);
      if (!mounted) return;
      setState(() => _items = List<Map<String, dynamic>>.from(data as List));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
      for (final n in _items) {
        n['is_read'] = true;
      }
      if (mounted) setState(() {});
      widget.onChanged();
    } catch (e) {
      Get.snackbar('Gagal', '$e');
    }
  }

  Future<void> _open(Map<String, dynamic> n) async {
    if (n['is_read'] != true) {
      try {
        await _db
            .from('notifications')
            .update({'is_read': true})
            .eq('id', n['id']);
        n['is_read'] = true;
        if (mounted) setState(() {});
        widget.onChanged();
      } catch (_) {}
    }
    final rid = n['report_id'];
    if (rid == null) return;
    try {
      final r = await _db
          .from('reports')
          .select(adminReportSelect)
          .eq('id', rid)
          .maybeSingle();
      if (r == null) {
        Get.snackbar('Tidak ditemukan', 'Laporan ini sudah dihapus');
        return;
      }
      await Get.to(() => AdminReportDetailPage(report: r));
    } catch (e) {
      Get.snackbar('Gagal membuka laporan', '$e');
    }
  }

  String _ago(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatTanggal(iso);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _items.any((n) => n['is_read'] != true);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Text(
                      'Notifikasi',
                      style: AppTextStyle.heading.copyWith(fontSize: 22),
                    ),
                  ),
                  if (hasUnread)
                    TextButton(
                      onPressed: _markAllRead,
                      child: Text(
                        'Tandai semua dibaca',
                        style: AppTextStyle.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
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
                              'Gagal memuat notifikasi\n$_error',
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
                      child: _items.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'Belum ada notifikasi',
                                    style: AppTextStyle.label,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              itemCount: _items.length,
                              itemBuilder: (_, i) => _NotifTile(
                                n: _items[i],
                                ago: _ago(_items[i]['sent_at']),
                                onTap: () => _open(_items[i]),
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

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> n;
  final String ago;
  final VoidCallback onTap;
  const _NotifTile({required this.n, required this.ago, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = n['is_read'] != true;
    final urgent = (n['title'] ?? '').toString().contains('mendesak');
    final color = urgent ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: unread
            ? AppColors.light.withValues(alpha: 0.6)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.light),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  urgent
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_active_outlined,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (n['title'] ?? '').toString(),
                      style: AppTextStyle.body.copyWith(
                        fontSize: 14,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (n['body_notifications'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.label.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(ago, style: AppTextStyle.label.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
