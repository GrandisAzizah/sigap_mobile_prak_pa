import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  List<Map<String, dynamic>> _categories = [];
  List<CampusModel> _campuses = [];
  List<BuildingModel> _buildings = [];

  Map<String, dynamic>? _selectedCategory;
  CampusModel? _selectedCampus;
  BuildingModel? _selectedBuilding;

  final List<XFile> _photos = [];
  final Map<XFile, Future<Uint8List>> _photoBytes = {};

  bool _loadingCategories = true;
  bool _loadingCampuses = true;
  bool _loadingBuildings = false;
  bool _sending = false;
  bool _permissionDeniedForever = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Mengambil kategori dan daftar kampus terdekat dari Supabase.
  Future<void> _loadInitialData() async {
    await Future.wait([_loadCategories(), _loadCampuses()]);
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _reportService.getCategories();

      if (!mounted) return;

      setState(() {
        _categories = data;
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCategories = false;
        _errorMessage = 'Gagal mengambil kategori: $e';
      });
    }
  }

  Future<void> _loadCampuses() async {
    setState(() {
      _loadingCampuses = true;
      _errorMessage = null;
      _permissionDeniedForever = false;
    });

    try {
      final data = await _locationService.getNearbyCampuses(
        minRadiusMeters: 500,
        maxRadiusMeters: 1000,
      );

      if (!mounted) return;

      setState(() {
        _campuses = data;
        _loadingCampuses = false;

        if (_campuses.length == 1) {
          _selectedCampus = _campuses.first;
          _loadBuildings(_selectedCampus!.id);
        }
      });

      if (data.isEmpty) {
        _showMessage(
          'Tidak ada kampus dalam jarak 500 m - 1 km dari lokasi Anda.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _loadingCampuses = false;
        _errorMessage = message;
        _permissionDeniedForever = message.toLowerCase().contains('permanen');
      });
      _showMessage(message);
    }
  }

  // Mengambil gedung berdasarkan kampus yang dipilih.
  Future<void> _loadBuildings(String campusId) async {
    setState(() {
      _loadingBuildings = true;
      _buildings = [];
      _selectedBuilding = null;
    });

    try {
      final data = await _locationService.getBuildings(campusId);

      if (!mounted) return;

      setState(() {
        _buildings = data;
        _loadingBuildings = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingBuildings = false;
      });

      _showMessage('Gagal mengambil data gedung: $e');
    }
  }

  // Memilih foto dari galeri.
  Future<void> _addPhoto() async {
    if (_photos.length >= 3) {
      _showMessage('Foto laporan maksimal 3.');
      return;
    }

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (image != null && mounted) {
        setState(() {
          _photos.add(image);
          _photoBytes[image] = image.readAsBytes();
        });
      }
    } catch (e) {
      _showMessage('Gagal memilih foto: $e');
    }
  }

  // Menghapus foto yang dipilih.
  void _removePhoto(XFile photo) {
    setState(() {
      _photos.remove(photo);
      _photoBytes.remove(photo);
    });
  }

  // Mengirim laporan dan upload foto ke Supabase.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null ||
        _selectedCampus == null ||
        _selectedBuilding == null) {
      _showMessage('Lengkapi kategori, kampus, dan gedung.');
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await _reportService.createReport(
        categoryId: _selectedCategory!['id'].toString(),
        categoryName: _selectedCategory!['name'].toString(),
        buildingId: _selectedBuilding!.id,
        description: _description.text.trim(),
        photos: List<XFile>.from(_photos),
      );

      if (!mounted) return;

      _showMessage('Laporan berhasil dikirim.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Kategori kerusakan.
            _label('Kategori Kerusakan*'),

            if (_loadingCategories)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                value: _selectedCategory?['id']?.toString(),
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Pilih kategori kerusakan',
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'].toString(),
                    child: Text(category['name'].toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = _categories.firstWhere(
                      (category) => category['id'].toString() == value,
                    );
                  });
                },
                validator: (value) {
                  return value == null ? 'Pilih kategori kerusakan.' : null;
                },
              ),

            const SizedBox(height: 18),

            // Pilihan kampus.
            _label('Kampus*'),

            if (_loadingCampuses)
              const LinearProgressIndicator()
            else if (_campuses.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_off, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage ?? 'Tidak ada kampus dalam jarak 500 m - 1 km dari lokasi Anda.',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_permissionDeniedForever)
                          TextButton(
                            onPressed: () async {
                              await Geolocator.openAppSettings();
                            },
                            child: const Text('Buka Pengaturan'),
                          ),
                        TextButton(
                          onPressed: _loadCampuses,
                          child: const Text('Cek Ulang'),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedCampus?.id,
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Pilih kampus'),
                items: _campuses.map((campus) {
                  final distanceLabel = campus.distanceInMeters != null
                      ? ' (${campus.distanceInMeters!.toStringAsFixed(0)} m)'
                      : '';
                  return DropdownMenuItem<String>(
                    value: campus.id,
                    child: Text(
                      '${campus.name}$distanceLabel',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  final campus = _campuses.firstWhere(
                    (item) => item.id == value,
                  );

                  setState(() {
                    _selectedCampus = campus;
                    _selectedBuilding = null;
                    _buildings = [];
                  });

                  _loadBuildings(campus.id);
                },
                validator: (value) {
                  return value == null ? 'Pilih kampus.' : null;
                },
              ),

            const SizedBox(height: 18),

            // Pilihan gedung.
            _label('Gedung*'),

            if (_loadingBuildings)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                value: _selectedBuilding?.id,
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Pilih gedung'),
                items: _buildings.map((building) {
                  return DropdownMenuItem<String>(
                    value: building.id,
                    child: Text(
                      building.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _selectedCampus == null
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _selectedBuilding = _buildings.firstWhere(
                            (item) => item.id == value,
                          );
                        });
                      },
                validator: (value) {
                  return value == null ? 'Pilih gedung.' : null;
                },
              ),

            const SizedBox(height: 18),

            // Deskripsi kerusakan.
            _label('Deskripsi*'),

            TextFormField(
              controller: _description,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Jelaskan kerusakan yang ditemukan...',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Deskripsi minimal 10 karakter.';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            // Foto laporan.
            _label('Foto (maks. 3)'),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._photos.map((photo) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FutureBuilder<Uint8List>(
                          future: _photoBytes[photo],
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container(
                                width: 90,
                                height: 90,
                                color: AppColors.light,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return Container(
                                width: 90,
                                height: 90,
                                color: AppColors.light,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.error,
                                ),
                              );
                            }

                            return Image.memory(
                              snapshot.data!,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),

                      Positioned(
                        right: 0,
                        top: 0,
                        child: InkWell(
                          onTap: () => _removePhoto(photo),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.light,
                            child: Icon(
                              Icons.close,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),

                if (_photos.length < 3)
                  InkWell(
                    onTap: _sending ? null : _addPhoto,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.light),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 30),

            // Tombol kirim.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _submit,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kirim Laporan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Label setiap bagian formulir.
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyle.heading.copyWith(fontSize: 13)),
    );
  }
}
