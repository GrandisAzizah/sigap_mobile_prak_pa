import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';

class ReportService {
  final SupabaseClient _db = Supabase.instance.client;
  static const _cacheKey = 'sigap_my_reports_cache';

  // Ambil laporan milik akun aktif beserta riwayat perubahan status oleh admin.
  Future<List<ReportModel>> getMyReports() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    final rows = await _db
        .from('reports')
        .select('*, report_status_history(status, note, changed_at)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final reports = (rows as List)
        .map((row) => ReportModel.fromMap(row as Map<String, dynamic>))
        .toList();

    await _saveCache(reports);
    return reports;
  }

  // Cache membantu pengguna membaca laporan terakhir saat koneksi terputus.
  Future<List<ReportModel>> getCachedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];
    final rows = jsonDecode(raw) as List;
    return rows.map((e) => ReportModel.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveCache(List<ReportModel> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(reports.map((e) => e.toCacheMap()).toList()),
    );
  }

  // Data laporan disimpan di server. Cache lokal diperbarui setelah berhasil dikirim.
  Future<void> createReport({
    required String category,
    required String locationName,
    required String description,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Sesi pengguna sudah berakhir.');

    await _db.from('reports').insert({
      'user_id': user.id,
      'category': category,
      'location_name': locationName,
      'description': description,
      'status': 'Menunggu',
    });

    await getMyReports();
  }

  Future<ReportModel> getReportDetail(String id) async {
    final row = await _db
        .from('reports')
        .select('*, report_status_history(status, note, changed_at)')
        .eq('id', id)
        .single();
    return ReportModel.fromMap(row);
  }
}
