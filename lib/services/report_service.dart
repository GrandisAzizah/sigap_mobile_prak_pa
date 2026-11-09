import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_model.dart';

class ReportService {
  final SupabaseClient _db = Supabase.instance.client;

  static const _cacheKey = 'sigap_my_reports_cache';

  // Sesuaikan dengan nama bucket Storage di Supabase.
  static const _photoBucket = 'report-photos';

  // Mengambil kategori laporan.
  Future<List<Map<String, dynamic>>> getCategories() async {
    final rows = await _db
        .from('categories')
        .select('id, name')
        .order('name');

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  // Membuat laporan baru.
  Future<void> createReport({
    required String categoryId,
    required String categoryName,
    required String buildingId,
    required String description,
    List<XFile> photos = const [],
  }) async {
    final user = _db.auth.currentUser;

    if (user == null) {
      throw Exception('Sesi pengguna sudah berakhir.');
    }

    // Menyimpan laporan ke database.
    final inserted = await _db
        .from('reports')
        .insert({
          'user_id': user.id,
          'category_id': categoryId,
          'building_id': buildingId,
          'title': 'Laporan kerusakan $categoryName',
          'report_detail': description.trim(),
          // severity dan status_reports menggunakan default database.
        })
        .select('id')
        .single();

    final reportId = inserted['id'].toString();

    // Mengunggah foto ke Supabase Storage.
    final photoRows = <Map<String, dynamic>>[];

    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      final bytes = await photo.readAsBytes();

      final extension = photo.name.contains('.')
          ? photo.name.split('.').last.toLowerCase()
          : 'jpg';

      final safeExtension =
          RegExp(r'^[a-z0-9]+$').hasMatch(extension)
              ? extension
              : 'jpg';

      final path =
          '$reportId/${DateTime.now().microsecondsSinceEpoch}_$i.$safeExtension';

      await _db.storage.from(_photoBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: _getContentType(safeExtension),
            ),
          );

      final photoUrl =
          _db.storage.from(_photoBucket).getPublicUrl(path);

      photoRows.add({
        'report_id': reportId,
        'photo_url': photoUrl,
      });
    }

    // Menyimpan URL foto ke tabel report_photos.
    if (photoRows.isNotEmpty) {
      await _db.from('report_photos').insert(photoRows);
    }

    await getMyReports();
  }

  String _getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Mengambil laporan milik pengguna.
  Future<List<ReportModel>> getMyReports() async {
    final user = _db.auth.currentUser;

    if (user == null) return [];

    final rows = await _db
        .from('reports')
        .select('''
          *,
          report_status_history(status, note, created_at),
          report_photos(photo_url)
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final reports = <ReportModel>[];

    for (final item in (rows as List)) {
      final row = Map<String, dynamic>.from(item);

      final categoryId = row['category_id']?.toString();
      final buildingId = row['building_id']?.toString();

      if (categoryId != null) {
        final category = await _db
            .from('categories')
            .select('name')
            .eq('id', categoryId)
            .maybeSingle();

        row['category_name'] =
            category?['name']?.toString() ?? '-';
      } else {
        row['category_name'] = '-';
      }

      if (buildingId != null) {
        final building = await _db
            .from('buildings')
            .select('name')
            .eq('id', buildingId)
            .maybeSingle();

        row['building_name'] =
            building?['name']?.toString() ?? '-';
      } else {
        row['building_name'] = '-';
      }

      reports.add(ReportModel.fromMap(row));
    }

    await _saveCache(reports);

    return reports;
  }

  // Mengambil laporan dari cache lokal.
  Future<List<ReportModel>> getCachedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);

    if (raw == null) return [];

    final rows = jsonDecode(raw) as List;

    return rows
        .map(
          (item) => ReportModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> _saveCache(List<ReportModel> reports) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _cacheKey,
      jsonEncode(
        reports.map((report) => report.toCacheMap()).toList(),
      ),
    );
  }

  // Mengambil detail satu laporan.
  Future<ReportModel> getReportDetail(String id) async {
    final row = await _db
        .from('reports')
        .select('''
          *,
          report_status_history(status, note, created_at),
          report_photos(photo_url)
        ''')
        .eq('id', id)
        .single();

    final result = Map<String, dynamic>.from(row);

    final categoryId = result['category_id']?.toString();
    final buildingId = result['building_id']?.toString();

    if (categoryId != null) {
      final category = await _db
          .from('categories')
          .select('name')
          .eq('id', categoryId)
          .maybeSingle();

      result['category_name'] =
          category?['name']?.toString() ?? '-';
    }

    if (buildingId != null) {
      final building = await _db
          .from('buildings')
          .select('name')
          .eq('id', buildingId)
          .maybeSingle();

      result['building_name'] =
          building?['name']?.toString() ?? '-';
    }

    return ReportModel.fromMap(result);
  }
}