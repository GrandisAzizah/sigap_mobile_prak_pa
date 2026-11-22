import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_model.dart';
import 'local_db.dart';

// Alias tipe data agar aman saat copy-paste dan tetap type-safe
typedef JsonMap = Map<String, dynamic>;
typedef JsonList = List<JsonMap>;

class ReportService {
  final SupabaseClient _db = Supabase.instance.client;

  static const String _photoBucket = 'report-photos';

  // Mengambil daftar kategori kerusakan dari database Supabase.
  Future<JsonList> getCategories() async {
    final response = await _db
        .from('categories')
        .select('id, name')
        .order('name');

    return JsonList.from(response);
  }

  // Membuat laporan baru dan mengunggah foto ke Supabase Storage.
  Future<void> createReport({
    required String categoryId,
    required String categoryName,
    required String buildingId,
    required String description,
    List<XFile> photos = const [],
  }) async {
    final user = _db.auth.currentUser;

    if (user == null) {
      throw Exception('Pengguna belum login.');
    }

    if (photos.length > 3) {
      throw Exception('Foto maksimal 3.');
    }

    // Simpan data utama laporan ke tabel reports.
    final reportResponse = await _db
        .from('reports')
        .insert({
          'user_id': user.id,
          'category_id': categoryId,
          'building_id': buildingId,
          'title': 'Laporan kerusakan $categoryName',
          'report_detail': description,
        })
        .select('id')
        .single();

    final reportId = reportResponse['id'].toString();

    // Unggah setiap foto ke Storage lalu simpan URL publiknya ke report_photos.
    for (final photo in photos) {
      try {
        final bytes = await photo.readAsBytes();

        final extension = photo.name.contains('.')
            ? photo.name.split('.').last.toLowerCase()
            : 'jpg';

        final fileName =
            '${DateTime.now().microsecondsSinceEpoch}.$extension';

        final path = '${user.id}/$reportId/$fileName';

        await _db.storage.from(_photoBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _getContentType(extension),
          ),
        );

        final photoUrl = _db.storage
            .from(_photoBucket)
            .getPublicUrl(path);

        await _db.from('report_photos').insert({
          'report_id': reportId,
          'photo_url': photoUrl,
        });
      } catch (e) {
        throw Exception(
          'Laporan tersimpan, tetapi foto gagal diunggah. '
          'ID laporan: $reportId. Detail: $e',
        );
      }
    }

    // Perbarui daftar laporan & cache lokal setelah laporan baru dibuat.
    await getMyReports();
  }

  // Menentukan MIME type file foto berdasarkan ekstensi.
  String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  // Mengambil satu data laporan beserta relasi kategori, gedung, kampus, foto, dan riwayat status.
  Future<JsonMap> _fetchReport(String id) async {
    final report = await _db
        .from('reports')
        .select()
        .eq('id', id)
        .single();

    // Ambil nama kategori.
    JsonMap? category;

    if (report['category_id'] != null) {
      category = await _db
          .from('categories')
          .select('id, name')
          .eq('id', report['category_id'])
          .maybeSingle();
    }

    // Ambil data gedung dan kampus.
    JsonMap? building;
    JsonMap? campus;

    if (report['building_id'] != null) {
      building = await _db
          .from('buildings')
          .select('id, name, faculty, campus_id')
          .eq('id', report['building_id'])
          .maybeSingle();

      if (building != null && building['campus_id'] != null) {
        campus = await _db
            .from('campus')
            .select('id, name_campus')
            .eq('id', building['campus_id'])
            .maybeSingle();
      }
    }

    // Ambil daftar URL foto laporan.
    final photos = await _db
        .from('report_photos')
        .select('photo_url')
        .eq('report_id', id);

    // Ambil riwayat perubahan status laporan.
    final history = await _db
        .from('report_status_history')
        .select('status, note, created_at')
        .eq('report_id', id)
        .order('created_at');

    return {
      'report': report,
      'category': category,
      'building': building,
      'campus': campus,
      'photos': photos,
      'history': history,
    };
  }

  // Memetakan hasil query mentah dari Supabase menjadi objek ReportModel.
  ReportModel _mapReport(JsonMap result) {
    final report = JsonMap.from(result['report']);

    final category = result['category'];
    final building = result['building'];
    final campus = result['campus'];

    final categoryName = category is Map
        ? category['name']?.toString() ?? '-'
        : '-';

    final buildingName = building is Map
        ? building['name']?.toString() ?? '-'
        : '-';

    final campusName = campus is Map
        ? campus['name_campus']?.toString() ?? ''
        : '';

    final locationName = campusName.isEmpty
        ? buildingName
        : '$buildingName - $campusName';

    final photos = (result['photos'] as List?) ?? [];
    final history = (result['history'] as List?) ?? [];

    final mappedData = {
      ...report,
      'category_name': categoryName,
      'building_name': locationName,
      'report_photos': photos,
      'report_status_history': history,
    };

    return ReportModel.fromMap(mappedData);
  }

  // Mengambil detail lengkap satu laporan berdasarkan ID.
  Future<ReportModel> getReportDetail(String id) async {
    final result = await _fetchReport(id);
    return _mapReport(result);
  }

  // Mengambil semua laporan milik pengguna yang sedang login, lalu menyimpannya ke cache Hive.
  Future<List<ReportModel>> getMyReports() async {
    final user = _db.auth.currentUser;

    if (user == null) return [];

    final rows = await _db
        .from('reports')
        .select('id')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final List<ReportModel> reports = [];

    for (final row in rows) {
      final result = await _fetchReport(
        row['id'].toString(),
      );

      reports.add(_mapReport(result));
    }

    // Simpan hasil terbaru ke penyimpanan lokal Hive agar bisa dibaca saat offline.
    await _saveCache(reports);

    return reports;
  }

  // Mengambil daftar laporan dari cache lokal Hive (LocalDb) saat offline atau gagal memuat data online.
  Future<List<ReportModel>> getCachedReports() async {
    final rows = LocalDb.getReports();

    return rows.map((item) {
      return ReportModel.fromMap(
        JsonMap.from(item as Map),
      );
    }).toList();
  }

  // Menyimpan daftar laporan ke penyimpanan lokal Hive melalui LocalDb.
  Future<void> _saveCache(List<ReportModel> reports) async {
    final mappedList = reports.map((report) => report.toCacheMap()).toList();
    await LocalDb.saveReports(mappedList);
  }
}