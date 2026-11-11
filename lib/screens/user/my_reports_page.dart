
import 'package:flutter/material.dart';
import '../../app_styles.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import 'report_detail_page.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  final _service = ReportService();
  String _filter = 'Semua';

  Future<List<ReportModel>> _load() async {
    try {
      return await _service.getMyReports();
    } catch (_) {
      // Jika internet gagal, tampilkan cache laporan terakhir.
      return _service.getCachedReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Saya'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: ['Semua', 'Diproses', 'Selesai'].map((filter) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: ChoiceChip(
                      label: Center(child: Text(filter)),
                      selected: _filter == filter,
                      onSelected: (_) {
                        setState(() => _filter = filter);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<ReportModel>>(
              future: _load(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final reports = snapshot.data ?? [];

                final filtered = reports.where((r) {
                  if (_filter == 'Semua') return true;

                  if (_filter == 'Diproses') {
                    return r.status == 'Diproses' ||
                        r.status == 'Menunggu';
                  }

                  return r.status == 'Selesai';
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Belum ada laporan.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final report = filtered[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),

                          // Menampilkan foto pertama laporan.
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 55,
                              height: 55,
                              color: AppColors.light,
                              child: report.photoUrls.isNotEmpty
                                  ? Image.network(
                                      report.photoUrls.first,
                                      width: 55,
                                      height: 55,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Icon(
                                          Icons.image_outlined,
                                          color: AppColors.primary,
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.image_outlined,
                                      color: AppColors.primary,
                                    ),
                            ),
                          ),

                          title: Text(
                            report.reportCode,
                            style: AppTextStyle.heading.copyWith(
                              fontSize: 13,
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _date(report.createdAt),
                                style: AppTextStyle.label.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 5),
                              _status(report.status),
                            ],
                          ),

                          trailing: const Icon(
                            Icons.chevron_right,
                          ),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReportDetailPage(
                                  reportId: report.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(String status) {
    final color = status == 'Selesai'
        ? AppColors.success
        : status == 'Diproses'
            ? AppColors.warning
            : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _date(DateTime date) {
    return '${date.day} ${_month(date.month)} ${date.year}';
  }

  String _month(int month) {
    return const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ][month - 1];
  }
}
