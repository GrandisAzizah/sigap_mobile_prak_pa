import 'package:geolocator/geolocator.dart';
import '../models/campus_model.dart';

class CampusLocationService {
  // Koordinat awal bersifat dummy/perkiraan. Ganti dengan titik gerbang kampus
  // yang sudah diverifikasi sebelum aplikasi dipakai secara resmi.
  static const campuses = [
    CampusModel(
      id: 'kampus_1',
      name: 'UPN Veteran Yogyakarta Kampus 1',
      address: 'Condongcatur, Sleman',
      latitude: -7.7569,
      longitude: 110.4091,
    ),
    CampusModel(
      id: 'kampus_2',
      name: 'UPN Veteran Yogyakarta Kampus 2',
      address: 'Babarsari, Sleman',
      latitude: -7.7797,
      longitude: 110.4167,
    ),
  ];

  Future<List<CampusModel>> getNearbyCampuses({double radiusKm = 10}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('Aktifkan layanan lokasi pada perangkat.');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi belum diberikan.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return campuses.where((campus) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        campus.latitude,
        campus.longitude,
      );
      return distance <= radiusKm * 1000;
    }).toList();
  }
}
