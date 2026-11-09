import 'dart:typed_data';

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

  List<Map<String, dynamic>> _categories = [];
  List<CampusModel> _campuses = [];
  List<BuildingModel> _buildings = [];

  String? _categoryId;
  CampusModel? _selectedCampus;
  BuildingModel? _selectedBuilding;

  final List<XFile> _photos = [];
  final Map<XFile, Future<Uint8List>> _photoBytes = {};

  bool _loading = true;
  bool _loadingBuildings = false;
  bool _sending = false;

  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final categories = await _reportService.getCategories();
      final campuses = await _locationService.getCampuses();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _campuses = campuses;
        _loading = false;

        if (categories.isEmpty) {
          _loadError = 'Data kategori belum tersedia.';
        } else if (campuses.isEmpty) {
          _loadError = 'Data kampus belum tersedia.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _onCampusChanged(CampusModel? campus) async {
    setState(() {
      _selectedCampus = campus;
      _selectedBuilding = null;
      _buildings = [];
      _loadingBuildings = campus != null;
    });

    if (campus == null) return;

    try {
      final buildings =
          await _locationService.getBuildings(campus.id);

      if (!mounted) return;

      setState(() {
        _buildings = buildings;
        _loadingBuildings = false;
      });

      if (buildings.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada gedung pada kampus ini.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingBuildings = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil data gedung: $e'),
        ),
      );
    }
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 3) return;

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
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: $e')),
      );
    }
  }

  void _removePhoto(XFile photo) {
    setState(() {
      _photos.remove(photo);
      _photoBytes.remove(photo);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBuilding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih gedung terlebih dahulu.'),
        ),
      );
      return;
    }

    final category = _categories.firstWhere(
      (item) => item['id'].toString() == _categoryId,
    );

    setState(() => _sending = true);

    try {
      await _reportService.createReport(
        categoryId: _categoryId!,
        categoryName: category['name'].toString(),
        buildingId: _selectedBuilding!.id,
        description: _description.text.trim(),
        photos: _photos,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim.'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim laporan: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
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
      appBar: AppBar(
        title: const Text('Buat Laporan'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildLoadError()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      _label('Kategori Kerusakan*'),
                      DropdownButtonFormField<String>(
                        value: _categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Pilih kategori',
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'].toString(),
                            child: Text(
                              category['name'].toString(),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _categoryId = value);
                        },
                        validator: (value) {
                          return value == null
                              ? 'Pilih kategori kerusakan.'
                              : null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _label('Kampus*'),
                      DropdownButtonFormField<CampusModel>(
                        value: _selectedCampus,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Pilih kampus',
                        ),
                        items: _campuses.map((campus) {
                          return DropdownMenuItem(
                            value: campus,
                            child: Text(campus.name),
                          );
                        }).toList(),
                        onChanged: _onCampusChanged,
                        validator: (value) {
                          return value == null
                              ? 'Pilih kampus.'
                              : null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _label('Gedung*'),
                      if (_loadingBuildings)
                        const LinearProgressIndicator()
                      else
                        DropdownButtonFormField<BuildingModel>(
                          value: _selectedBuilding,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Pilih gedung',
                          ),
                          items: _buildings.map((building) {
                            return DropdownMenuItem(
                              value: building,
                              child: Text(
                                building.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _selectedCampus == null
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedBuilding = value;
                                  });
                                },
                          validator: (value) {
                            return value == null
                                ? 'Pilih gedung.'
                                : null;
                          },
                        ),

                      const SizedBox(height: 16),

                      _label('Deskripsi*'),
                      TextFormField(
                        controller: _description,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText:
                              'Jelaskan kerusakan yang ditemukan...',
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().length < 10) {
                            return 'Deskripsi minimal 10 karakter.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _label('Foto (maks. 3)'),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ..._photos.map((photo) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  child: FutureBuilder<Uint8List>(
                                    future: _photoBytes[photo],
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Container(
                                          width: 76,
                                          height: 76,
                                          color: AppColors.light,
                                          child: const Center(
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      }

                                      if (snapshot.hasError ||
                                          !snapshot.hasData) {
                                        return Container(
                                          width: 76,
                                          height: 76,
                                          color: AppColors.light,
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                            color: AppColors.error,
                                          ),
                                        );
                                      }

                                      return Image.memory(
                                        snapshot.data!,
                                        width: 76,
                                        height: 76,
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
                                      radius: 11,
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),

                          if (_photos.length < 3)
                            InkWell(
                              onTap: _addPhoto,
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.light,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppColors.primary,
                                  size: 30,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 35),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _submit,
                          child: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Kirim Laporan'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _loadError = null;
                });
                _loadFormData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: AppTextStyle.heading.copyWith(
          fontSize: 13,
        ),
      ),
    );
  }
}