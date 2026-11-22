import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_styles.dart';
import 'admin_detail_report_page.dart'; // AdminReportDetailPage
import 'status_chip.dart'; // StatusChip & kapital()

/// Query khusus peta: ikut mengambil koordinat gedung & kampus sebagai cadangan
/// kalau kolom latitude/longitude di laporan masih kosong.
const _mapSelect =
    '*, categories(name), staffs(name_staff), users(name, nim), report_photos(photo_url), '
    'buildings(name, latitude, longitude, campus(latitude, longitude))';

// warna pentungan di peta
class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _all = [];
  String _filter = 'semua';
  bool _loading = true;
  String? _error;

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
    try {
      final data = await _db
          .from('reports')
          .select(_mapSelect)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() => _all = List<Map<String, dynamic>>.from(data as List));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _num(dynamic v) => v is num ? v.toDouble() : null;

  // Koordinat laporan; kalau kosong pakai koordinat gedung, lalu kampus.
  LatLng? _coord(Map<String, dynamic> r) {
    final b = r['buildings'] as Map?;
    final c = b?['campus'] as Map?;
    final lat =
        _num(r['latitude']) ?? _num(b?['latitude']) ?? _num(c?['latitude']);
    final lng =
        _num(r['longitude']) ?? _num(b?['longitude']) ?? _num(c?['longitude']);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  List<({Map<String, dynamic> r, LatLng p})> get _visible {
    final out = <({Map<String, dynamic> r, LatLng p})>[];
    for (final r in _all) {
      final p = _coord(r);
      if (p == null) continue;
      final status = (r['status_reports'] ?? 'menunggu')
          .toString()
          .toLowerCase();
      if (_filter != 'semua' && status != _filter) continue;

      out.add((r: r, p: p));
    }
    return out;
  }

  Color _color(String status) {
    switch (status) {
      case 'diproses':
        return AppColors.warning;
      case 'selesai':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  Future<void> _openDetail(Map<String, dynamic> r) async {
    final changed = await Get.to(() => AdminReportDetailPage(report: r));
    if (changed == true) _load();
  }

  void _showSheet(Map<String, dynamic> r) {
    final building = (r['buildings'] as Map?)?['name'] as String?;
    final room = r['room_detail'] as String?;
    final location = [
      building,
      room,
    ].where((e) => e != null && e.isNotEmpty).join(' • ');

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (r['report_code'] ?? '-').toString(),
                    style: AppTextStyle.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusChip((r['status_reports'] ?? 'menunggu').toString()),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              (r['title'] ?? '').toString(),
              style: AppTextStyle.heading.copyWith(fontSize: 16),
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(location, style: AppTextStyle.label),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _openDetail(r);
              },
              child: const Text('Buka detail'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMultipleReportsSheet(List<Map<String, dynamic>> reports) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ada ${reports.length} laporan di sini',
              style: AppTextStyle.heading.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final r = reports[index];
                return ListTile(
                  leading: Icon(
                    Icons.circle,
                    color: _color(r['status_reports'].toString()),
                  ),
                  title: Text(r['title'] ?? '-'),
                  subtitle: Text(r['status_reports'] ?? '-'),
                  onTap: () {
                    Get.back(); // tutup sheet list
                    _openDetail(r); // buka detail laporan
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;
    final pts = items.map((e) => e.p).toList();

    final MapOptions options;
    if (pts.isEmpty) {
      options = MapOptions(
        initialCenter: const LatLng(-2.5489, 118.0149),
        initialZoom: 4.5,
      );
    } else if (pts.length == 1) {
      options = MapOptions(initialCenter: pts.first, initialZoom: 16);
    } else {
      options = MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: pts,
          padding: const EdgeInsets.fromLTRB(48, 150, 48, 90),
          maxZoom: 17,
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            key: ValueKey(
              '$_filter-${items.length}',
            ), // refit saat filter/data berubah
            options: options,
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sigap',
              ),
              MarkerLayer(
                markers: [
                  for (final e in items)
                    Marker(
                      point: e.p,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () {
                          // Cari berapa laporan di titik yang sama
                          final sameLocation = items
                              .where(
                                (item) =>
                                    item.p.latitude == e.p.latitude &&
                                    item.p.longitude == e.p.longitude,
                              )
                              .toList();

                          if (sameLocation.length > 1) {
                            // Kalau lebih dari 1, tampilkan pilihan (bottom sheet)
                            _showMultipleReportsSheet(
                              sameLocation.map((e) => e.r).toList(),
                            );
                          } else {
                            // Kalau cuma 1, langsung buka sheet biasa
                            _showSheet(e.r);
                          }
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 44,
                              color: _color(
                                (e.r['status_reports'] ?? 'menunggu')
                                    .toString(),
                              ),
                            ),
                            // Tambahkan badge angka jika lebih dari 1 pin di titik ini
                            if (items.where((item) => item.p == e.p).length > 1)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${items.where((item) => item.p == e.p).length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Panel atas: judul, filter
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Peta Sebaran Laporan',
                            style: AppTextStyle.heading.copyWith(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Muat ulang',
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primary,
                          ),
                          onPressed: _load,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final f in const [
                          ['semua', 'Semua'],
                          ['menunggu', 'Menunggu'],
                          ['diproses', 'Diproses'],
                          ['selesai', 'Selesai'],
                        ])
                          ChoiceChip(
                            label: Text(f[1]),
                            selected: _filter == f[0],
                            selectedColor: AppColors.light,
                            onSelected: (_) => setState(() => _filter = f[0]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _loading
                          ? 'Memuat...'
                          : _error != null
                          ? 'Gagal memuat: $_error'
                          : '${items.length} dari ${_all.length} laporan punya lokasi',
                      style: AppTextStyle.label.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legenda warna marker
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final s in const [
                    'menunggu',
                    'diproses',
                    'selesai',
                  ]) ...[
                    Icon(Icons.circle, size: 12, color: _color(s)),
                    const SizedBox(width: 4),
                    Text(
                      kapital(s),
                      style: AppTextStyle.label.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
          ),

          if (!_loading && _error == null && items.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Belum ada laporan dengan lokasi',
                  style: AppTextStyle.label,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
