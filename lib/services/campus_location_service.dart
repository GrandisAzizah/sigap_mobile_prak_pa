import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/campus_model.dart';

class CampusLocationService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<CampusModel>> getCampuses() async {
    final rows = await _db
        .from('campus')
        .select('id, name_campus, latitude, longitude')
        .order('name_campus');

    return (rows as List)
        .map((row) => CampusModel.fromMap(
              Map<String, dynamic>.from(row),
            ))
        .toList();
  }

  Future<List<CampusModel>> getNearbyCampuses({
    double minRadiusMeters = 500,
    double maxRadiusMeters = 1000,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi (GPS) tidak aktif. Aktifkan GPS terlebih dahulu.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen. Buka pengaturan aplikasi.');
    }

    final userPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final allCampuses = await getCampuses();

    return allCampuses
        .map((campus) {
          if (campus.latitude == 0.0 && campus.longitude == 0.0) {
            return null;
          }

          final distanceInMeters = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            campus.latitude,
            campus.longitude,
          );

          if (distanceInMeters >= minRadiusMeters &&
              distanceInMeters <= maxRadiusMeters) {
            return campus.copyWith(distanceInMeters: distanceInMeters);
          }
          return null;
        })
        .whereType<CampusModel>()
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