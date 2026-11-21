class CampusModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double? distanceInMeters;

  const CampusModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distanceInMeters,
  });

  factory CampusModel.fromMap(Map<String, dynamic> map) {
    return CampusModel(
      id: map['id'].toString(),
      name: map['name_campus']?.toString() ?? '-',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CampusModel copyWith({double? distanceInMeters}) {
    return CampusModel(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
    );
  }
}

class BuildingModel {
  final String id;
  final String campusId;
  final String name;
  final String? faculty;

  const BuildingModel({
    required this.id,
    required this.campusId,
    required this.name,
    this.faculty,
  });

  factory BuildingModel.fromMap(Map<String, dynamic> map) {
    return BuildingModel(
      id: map['id'].toString(),
      campusId: map['campus_id'].toString(),
      name: map['name']?.toString() ?? '-',
      faculty: map['faculty']?.toString(),
    );
  }

  String get displayName {
    if (faculty == null || faculty!.isEmpty) {
      return name;
    }

    return '$name - $faculty';
  }
}