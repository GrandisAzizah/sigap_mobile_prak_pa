import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_styles.dart';
import '../../models/campus_model.dart';
import '../../services/campus_location_service.dart';
import '../../services/report_service.dart';

class CreateReportPage extends StatefulWidget {
  const CreateReportPage({super.key});

  @override
  State<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends State<CreateReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _locationService = CampusLocationService();
  final _reportService = ReportService();
  final _picker = ImagePicker();

  final _categories = ['Listrik', 'Air', 'Ruang kelas', 'Toilet', 'Perabot', 'Lainnya'];
  String? _category;
  CampusModel? _selectedCampus;
  List<CampusModel> _nearbyCampuses = [];
  final List<XFile> _photos = [];
  bool _loadingLocations = true;
  bool _sending = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadNearbyCampuses();
  }

  Future<void> _loadNearbyCampuses() async {
    try {
      final campuses = await _locationService.getNearbyCampuses(radiusKm: 10);
      if (!mounted) return;
      setState(() {
        _nearbyCampuses = campuses;
        _loadingLocations = false;
        _locationError = campuses.isEmpty
            ? 'Tidak ada kampus dalam radius 10 km dari lokasi perangkat.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocations = false;
        _locationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 3) return;
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null && mounted) setState(() => _photos.add(image));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCampus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih lokasi kampus terlebih dahulu.')));
      return;
    }
    setState(() => _sending = true);
    try {
      // Foto belum diunggah pada versi awal. Tambahkan upload Supabase Storage
      // sebelum menyimpan URL foto ke kolom photo_urls.
      await _reportService.createReport(
        category: _category!,
        locationName: _selectedCampus!.name,
        description: _description.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim laporan: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan'), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(18), children: [
          _label('Kategori Kerusakan*'),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(hintText: 'Pilih kategori'),
            items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => _category = value),
            validator: (value) => value == null ? 'Pilih kategori kerusakan.' : null,
          ),
          const SizedBox(height: 16),
          _label('Lokasi*'),
          if (_loadingLocations)
            const LinearProgressIndicator()
          else if (_locationError != null)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_locationError!, style: const TextStyle(color: AppColors.error)),
              TextButton.icon(onPressed: () {
                setState(() => _loadingLocations = true);
                _loadNearbyCampuses();
              }, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
            ])
          else
            DropdownButtonFormField<CampusModel>(
              value: _selectedCampus,
              decoration: const InputDecoration(hintText: 'Pilih lokasi kampus'),
              items: _nearbyCampuses.map((c) =>
                DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (value) => setState(() => _selectedCampus = value),
              validator: (value) => value == null ? 'Pilih lokasi.' : null,
            ),
          const SizedBox(height: 16),
          _label('Deskripsi*'),
          TextFormField(
            controller: _description,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Jelaskan kerusakan yang ditemukan...'),
            validator: (value) => value == null || value.trim().length < 10
              ? 'Deskripsi minimal 10 karakter.' : null,
          ),
          const SizedBox(height: 16),
          _label('Foto (maks. 3)'),
          Wrap(spacing: 10, runSpacing: 10, children: [
            ..._photos.map((photo) => Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: Image.file(File(photo.path), width: 76, height: 76, fit: BoxFit.cover)),
              Positioned(right: 0, top: 0, child: InkWell(
                onTap: () => setState(() => _photos.remove(photo)),
                child: const CircleAvatar(radius: 11, child: Icon(Icons.close, size: 14)))),
            ])),
            if (_photos.length < 3)
              InkWell(onTap: _addPhoto, child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(border: Border.all(color: AppColors.light),
                  borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.add, color: AppColors.primary, size: 30))),
          ]),
          const SizedBox(height: 35),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _sending ? null : _submit,
            child: _sending
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Kirim Laporan'),
          )),
        ]),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppTextStyle.heading.copyWith(fontSize: 13)),
  );
}
