import 'package:flutter/material.dart';
import '../../app_styles.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';

class ReportDetailPage extends StatelessWidget {
  final String reportId;
  const ReportDetailPage({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Laporan'), centerTitle: true),
      body: FutureBuilder<ReportModel>(
        future: ReportService().getReportDetail(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Detail laporan tidak dapat dimuat.'));
          }
          final report = snapshot.data!;
          return ListView(padding: const EdgeInsets.all(18), children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(report.reportCode, style: AppTextStyle.heading.copyWith(fontSize: 16)),
              _status(report.status),
            ]),
            const SizedBox(height: 16),
            if (report.photoUrls.isNotEmpty)
              SizedBox(height: 150, child: ListView(scrollDirection: Axis.horizontal,
                children: report.photoUrls.map((url) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Image.network(url, width: 220, fit: BoxFit.cover)),
                )).toList()))
            else
              Container(height: 130, decoration: BoxDecoration(color: AppColors.light,
                borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.image_outlined, size: 45, color: AppColors.primary)),
            const SizedBox(height: 20),
            _info(Icons.category_outlined, 'Kategori', report.category),
            _info(Icons.location_on_outlined, 'Lokasi', report.locationName),
            _info(Icons.description_outlined, 'Deskripsi', report.description),
            _info(Icons.calendar_month_outlined, 'Tanggal dibuat', report.createdAt.toString().substring(0, 16)),
            const SizedBox(height: 22),
            Text('Riwayat Status', style: AppTextStyle.heading.copyWith(fontSize: 17)),
            const SizedBox(height: 12),
            if (report.history.isEmpty)
              const Text('Belum ada pembaruan status dari admin.')
            else
              ...report.history.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: AppColors.primary),
                title: Text(item.status, style: AppTextStyle.heading.copyWith(fontSize: 13)),
                subtitle: Text('${item.changedAt} ${item.note ?? ''}'),
              )),
          ]);
        },
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.primary, size: 21),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyle.heading.copyWith(fontSize: 12)),
        const SizedBox(height: 3),
        Text(value, style: AppTextStyle.body.copyWith(fontSize: 13)),
      ])),
    ]),
  );

  Widget _status(String status) {
    final color = status == 'Selesai' ? AppColors.success :
      status == 'Diproses' ? AppColors.warning : AppColors.secondary;
    return Chip(label: Text(status), backgroundColor: color.withValues(alpha: .2));
  }
}
