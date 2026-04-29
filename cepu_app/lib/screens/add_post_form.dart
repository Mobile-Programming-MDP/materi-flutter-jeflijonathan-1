import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../services/post_service.dart';

class AddPostForm extends StatefulWidget {
  const AddPostForm({super.key});

  @override
  State<AddPostForm> createState() => _AddPostFormState();
}

class _AddPostFormState extends State<AddPostForm> {
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  File? _image;
  Position? _currentPosition;
  bool _isLoading = false;

  final PostService _postService = PostService();

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      } 

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lokasi berhasil didapatkan')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_descriptionController.text.isEmpty || _categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deskripsi dan kategori harus diisi')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      
      // Catatan: Jika ingin menyimpan gambar di Firestore, Anda harus mengunggahnya ke Firebase Storage
      // terlebih dahulu dan mendapatkan URL. Di sini kita akan gunakan path lokal sementara.
      String imageUrl = _image?.path ?? '';

      Post post = Post(
        id: '', // Firestore akan otomatis membuat document ID
        image: imageUrl,
        description: _descriptionController.text,
        category: _categoryController.text,
        latitude: _currentPosition?.latitude ?? 0.0,
        longitude: _currentPosition?.longitude ?? 0.0,
        userId: user?.uid ?? '',
        userFullName: user?.displayName ?? user?.email?.split('@')[0] ?? 'Unknown User',
      );

      await _postService.addPost(post);
      
      if (mounted) {
        Navigator.of(context).pop(); // Tutup bottom sheet / dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post berhasil ditambahkan')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menambahkan post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Memberikan padding untuk form agar tidak terpotong keyboard (bottom inset)
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Tambah Post Baru",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Deskripsi",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: "Kategori",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_image != null ? "Ubah Foto" : "Ambil Foto"),
                ),
                OutlinedButton.icon(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.location_on),
                  label: Text(_currentPosition != null ? "Ubah Lokasi" : "Ambil Lokasi"),
                ),
              ],
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "✓ Foto telah dipilih",
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_currentPosition != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "✓ Lokasi: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("Simpan Post"),
                  ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
