import 'package:flutter/material.dart';

import '../../app_styles.dart';

String formatTanggal(dynamic iso) {
  final d = DateTime.tryParse(iso?.toString() ?? '')?.toLocal();
  if (d == null) return '-';
  const m = [
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
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

String kapital(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: AppTextStyle.label.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        // teks sedikit digelapkan supaya terbaca di atas latar terang
        color: Color.alphaBlend(Colors.black.withValues(alpha: 0.35), color),
      ),
    ),
  );
}

/// menunggu = info (biru), diproses = warning (kuning), selesai = success (hijau)
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'diproses' => AppColors.warning,
      'selesai' => AppColors.success,
      _ => AppColors.info,
    };
    return _Pill(kapital(status), color);
  }
}

/// low = success, medium = warning, high = error
class SeverityChip extends StatelessWidget {
  final String severity;
  const SeverityChip(this.severity, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      'high' => AppColors.error,
      'medium' => AppColors.warning,
      _ => AppColors.success,
    };
    return _Pill(kapital(severity), color);
  }
}
