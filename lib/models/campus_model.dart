class CampusModel {
  final String id;
  final String name;

  const CampusModel({
    required this.id,
    required this.name,
  });

  factory CampusModel.fromMap(Map<String, dynamic> map) {
    return CampusModel(
      id: map['id'].toString(),
      name: map['name_campus']?.toString() ?? '-',
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