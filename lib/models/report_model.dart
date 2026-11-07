class ReportModel {
  final String id;
  final String reportCode;
  final String category;
  final String locationName;
  final String description;
  final String status;
  final DateTime createdAt;
  final List<String> photoUrls;
  final List<ReportStatusHistory> history;

  const ReportModel({
    required this.id,
    required this.reportCode,
    required this.category,
    required this.locationName,
    required this.description,
    required this.status,
    required this.createdAt,
    this.photoUrls = const [],
    this.history = const [],
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    final historyRows = (map['report_status_history'] as List<dynamic>?) ?? [];
    return ReportModel(
      id: map['id'].toString(),
      reportCode: map['report_code']?.toString() ?? '-',
      category: map['category']?.toString() ?? '-',
      locationName: map['location_name']?.toString() ?? '-',
      description: map['description']?.toString() ?? '-',
      status: map['status']?.toString() ?? 'Menunggu',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      photoUrls: ((map['photo_urls'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList(),
      history: historyRows.map((e) => ReportStatusHistory.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toCacheMap() => {
    'id': id,
    'report_code': reportCode,
    'category': category,
    'location_name': locationName,
    'description': description,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'photo_urls': photoUrls,
    'report_status_history': history.map((e) => e.toMap()).toList(),
  };
}

class ReportStatusHistory {
  final String status;
  final String? note;
  final DateTime changedAt;

  const ReportStatusHistory({
    required this.status,
    this.note,
    required this.changedAt,
  });

  factory ReportStatusHistory.fromMap(Map<String, dynamic> map) {
    return ReportStatusHistory(
      status: map['status']?.toString() ?? '-',
      note: map['note']?.toString(),
      changedAt: DateTime.tryParse(map['changed_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'status': status,
    'note': note,
    'changed_at': changedAt.toIso8601String(),
  };
}
