
import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_model.dart';

class ReportService {
  final SupabaseClient _db = Supabase.instance.client;

  static const String _cacheKey = 'sigap_my_reports_cache';
  static const String _photoBucket = 'report-photos';

  // Mengambil kategori dari database.
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _db
        .from('categories')
        .select('id, name')
        .order('name');

    return List<Map<String, dynamic>>.from(response);
  }

  // Membuat laporan dan mengunggah foto.
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

    // Simpan laporan.
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

    // Upload foto ke Storage dan simpan URL.
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

    await getMyReports();
  }

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

  // Mengambil satu laporan beserta data relasinya.
  Future<Map<String, dynamic>> _fetchReport(String id) async {
    final report = await _db
        .from('reports')
        .select()
        .eq('id', id)
        .single();

    // Ambil kategori.
    Map<String, dynamic>? category;

    if (report['category_id'] != null) {
      category = await _db
          .from('categories')
          .select('id, name')
          .eq('id', report['category_id'])
          .maybeSingle();
    }

    // Ambil gedung.
    Map<String, dynamic>? building;
    Map<String, dynamic>? campus;

    if (report['building_id'] != null) {
      building = await _db
          .from('buildings')
          .select('id, name, faculty, campus_id')
          .eq('id', report['building_id'])
          .maybeSingle();

      // Ambil kampus.
      if (building != null && building['campus_id'] != null) {
        campus = await _db
            .from('campus')
            .select('id, name_campus')
            .eq('id', building['campus_id'])
            .maybeSingle();
      }
    }

    // Ambil foto.
    final photos = await _db
        .from('report_photos')
        .select('photo_url')
        .eq('report_id', id);

    // Ambil riwayat status.
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

  // Mengubah data hasil query menjadi ReportModel.
  ReportModel _mapReport(Map<String, dynamic> result) {
    final report = Map<String, dynamic>.from(result['report']);

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

    // PENTING:
    // Key di bawah harus sesuai dengan ReportModel.
    final mappedData = {
      ...report,
      'category_name': categoryName,
      'building_name': locationName,
      'report_photos': photos,
      'report_status_history': history,
    };

    return ReportModel.fromMap(mappedData);
  }

  // Mengambil detail satu laporan.
  Future<ReportModel> getReportDetail(String id) async {
    final result = await _fetchReport(id);

    final report = _mapReport(result);

    return report;
  }

  // Mengambil semua laporan milik pengguna.
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

    await _saveCache(reports);

    return reports;
  }

  // Mengambil laporan dari cache.
  Future<List<ReportModel>> getCachedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);

    if (raw == null) return [];

    final rows = jsonDecode(raw) as List;

    return rows.map((item) {
      return ReportModel.fromMap(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  // Menyimpan laporan ke cache.
  Future<void> _saveCache(List<ReportModel> reports) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _cacheKey,
      jsonEncode(
        reports.map((report) => report.toCacheMap()).toList(),
      ),
    );
  }
}
