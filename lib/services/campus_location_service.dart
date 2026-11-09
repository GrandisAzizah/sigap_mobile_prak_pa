import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/campus_model.dart';

class CampusLocationService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<CampusModel>> getCampuses() async {
    final rows = await _db
        .from('campus')
        .select('id, name_campus')
        .order('name_campus');

    return (rows as List)
        .map((row) => CampusModel.fromMap(
              Map<String, dynamic>.from(row),
            ))
        .toList();
  }

  Future<List<BuildingModel>> getBuildings(
    String campusId,
  ) async {
    final rows = await _db
        .from('buildings')
        .select('id, campus_id, name, faculty')
        .eq('campus_id', campusId)
        .order('name');

    return (rows as List)
        .map((row) => BuildingModel.fromMap(
              Map<String, dynamic>.from(row),
            ))
        .toList();
  }
}