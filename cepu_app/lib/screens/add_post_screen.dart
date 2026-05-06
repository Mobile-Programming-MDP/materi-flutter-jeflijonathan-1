import 'dart:convert';
import 'package:cepu_app/models/post.dart';
import 'package:cepu_app/screens/map_picker_screen.dart';
import 'package:cepu_app/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _base64Image;
  String? _latitude;
  String? _longitude;
  bool _isLoading = false;

  final List<String> categories = [
    'Jalan Rusak',
    'Lampu Jalan Mati',
    'Lawan Arah',
    'Merokok di Jalan',
    'Tidak Pakai Helm',
    'Parkir Liar',
    'Sampah Menumpuk',
  ];

  String? _category;

  Future<void> pickImageAndConvert() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final compressedImage = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 50,
      );
      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Layanan lokasi dinonaktifkan.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin lokasi ditolak.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak secara permanen.';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      debugPrint('Failed to retrieve location: $e');
      rethrow;
    }
  }

  Future<void> _pickLocationOnMap() async {
    LatLng? current;
    if (_latitude != null && _longitude != null) {
      current = LatLng(double.parse(_latitude!), double.parse(_longitude!));
    }

    final LatLng? picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(initialLocation: current),
      ),
    );

    if (picked != null) {
      setState(() {
        _latitude = picked.latitude.toString();
        _longitude = picked.longitude.toString();
      });
    }
  }

  void _showCategorySelect() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Pilih Kategori",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return ListTile(
                      title: Text(cat),
                      leading: Icon(Icons.label_outline, color: Theme.of(context).primaryColor),
                      onTap: () {
                        setState(() {
                          _category = cat;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitPost() async {
    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih gambar terlebih dahulu.")),
      );
      return;
    }

    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih kategori.")),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan masukkan deskripsi.")),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan tentukan lokasi terlebih dahulu.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final fullName = FirebaseAuth.instance.currentUser?.displayName;

      await PostService.addPost(
        Post(
          image: _base64Image,
          description: _descriptionController.text.trim(),
          category: _category,
          latitude: _latitude,
          longitude: _longitude,
          userId: userId,
          fullName: fullName,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laporan berhasil dikirim!")),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengirim laporan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Laporan Baru"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Picker
                  GestureDetector(
                    onTap: pickImageAndConvert,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                      ),
                      child: _base64Image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(base64Decode(_base64Image!), fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text("Ambil Foto Kejadian", style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Selector
                  const Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showCategorySelect,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _category ?? "Pilih Kategori",
                            style: TextStyle(
                              color: _category == null ? Colors.grey : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Location Selector
                  const Text("Lokasi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: Text(
                            (_latitude != null && _longitude != null)
                                ? "${double.parse(_latitude!).toStringAsFixed(4)}, ${double.parse(_longitude!).toStringAsFixed(4)}"
                                : "Lokasi belum dipilih",
                            style: TextStyle(
                              color: (_latitude != null && _longitude != null) ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isLoading ? null : _getLocation,
                        icon: const Icon(Icons.my_location),
                        tooltip: "Gunakan Lokasi Saat Ini",
                      ),
                      IconButton.filled(
                        onPressed: _isLoading ? null : _pickLocationOnMap,
                        icon: const Icon(Icons.map_outlined),
                        tooltip: "Pilih di Peta",
                        style: IconButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Ceritakan detail kejadian...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("Kirim Laporan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
