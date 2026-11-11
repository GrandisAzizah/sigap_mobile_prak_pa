
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
    final historyRows =
        (map['report_status_history'] as List<dynamic>?) ?? [];

    final photoRows =
        (map['report_photos'] as List<dynamic>?) ?? [];

    return ReportModel(
      id: map['id']?.toString() ?? '',
      reportCode: map['report_code']?.toString() ?? '-',

      // Membaca nama kategori.
      category: map['category_name']?.toString() ?? '-',

      // Membaca nama gedung dan kampus.
      locationName: map['building_name']?.toString() ?? '-',

      description: map['report_detail']?.toString() ?? '-',

      status: map['status_reports']?.toString() ?? 'menunggu',

      createdAt: DateTime.tryParse(
            map['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),

      photoUrls: photoRows
          .map((item) => item['photo_url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList(),

      history: historyRows.map((item) {
        return ReportStatusHistory.fromMap(
          Map<String, dynamic>.from(item),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toCacheMap() => {
        'id': id,
        'report_code': reportCode,
        'category_name': category,
        'building_name': locationName,
        'report_detail': description,
        'status_reports': status,
        'created_at': createdAt.toIso8601String(),
        'report_photos': photoUrls
            .map((url) => {'photo_url': url})
            .toList(),
        'report_status_history':
            history.map((item) => item.toMap()).toList(),
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

  factory ReportStatusHistory.fromMap(
    Map<String, dynamic> map,
  ) {
    return ReportStatusHistory(
      status: map['status']?.toString() ?? '-',
      note: map['note']?.toString(),
      changedAt: DateTime.tryParse(
            map['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status,
        'note': note,
        'created_at': changedAt.toIso8601String(),
      };
}
