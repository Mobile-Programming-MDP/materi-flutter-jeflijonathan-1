import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/models/note.dart';
import 'package:notes/services/note_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:notes/screens/google_map_picker_screen.dart';

class NoteDialog extends StatefulWidget {
  final Note? note;
  const NoteDialog({super.key, this.note});
  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  String? _base64Image;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.description;
      _base64Image = widget.note!.imageBase64;
      _latitudeController.text = widget.note!.latitude ?? '';
      _longitudeController.text = widget.note!.longitude ?? '';
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      String base64String = base64Encode(bytes);
      setState(() {
        _base64Image = base64String;
        //_imageFile = File(pickedFile.path);
      });
      print("Base64 String: $base64String");
    } else {
      print("No image selected.");
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Layanan lokasi dinonaktifkan.")),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Izin lokasi ditolak.")));
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Failed to retrieve location: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal mengambil lokasi.")));
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _pickFromMap() async {
    double? lat = double.tryParse(_latitudeController.text);
    double? lng = double.tryParse(_longitudeController.text);
    LatLng? initial = (lat != null && lng != null) ? LatLng(lat, lng) : null;

    if (!mounted) return;
    final LatLng? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoogleMapPickerScreen(initialLocation: initial),
      ),
    );

    if (result != null) {
      setState(() {
        _latitudeController.text = result.latitude.toString();
        _longitudeController.text = result.longitude.toString();
      });
    }
  }

  Future<void> openMap() async {
    if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_latitudeController.text},${_longitudeController.text}',
    );
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal membuka peta.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Add Notes' : 'Update Notes'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Title: ', textAlign: TextAlign.start),
            TextField(controller: _titleController),
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text('Description: '),
            ),
            TextField(controller: _descriptionController),
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text('Image: '),
            ),
            if (_base64Image != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Image.memory(
                    base64Decode(_base64Image!),
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                ),
              ),
            TextButton(onPressed: _pickImage, child: const Text('Pick Image')),
            const Divider(),
            Row(
              children: [
                Row(children: [const Text('Get Location: ')]),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _pickFromMap,
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('Pick from Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Warna latar
                    foregroundColor: Colors.white, // Warna teks & ikon
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Sudut tumpul
                    ),
                    elevation: 3, // Efek bayangan
                  ),
                ),
              ],
            ),
            const Text('Location: '),
            if (_latitudeController.text.isNotEmpty &&
                _longitudeController.text.isNotEmpty)
              Text(
                'latitude (${_latitudeController.text})',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            Text(
              'longitude (${_longitudeController.text})',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            if (_latitudeController.text.isNotEmpty &&
                _longitudeController.text.isNotEmpty)
              Center(
                child: TextButton(
                  onPressed: openMap,
                  child: const Text('Open in Maps'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.note == null) {
              NoteService.addNote(
                Note(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  imageBase64: _base64Image,
                  latitude: _latitudeController.text,
                  longitude: _longitudeController.text,
                ),
              ).whenComplete(() {
                Navigator.of(context).pop();
              });
            } else {
              NoteService.updateNote(
                Note(
                  id: widget.note!.id,
                  title: _titleController.text,
                  description: _descriptionController.text,
                  createdAt: widget.note!.createdAt,
                  updatedAt: widget.note!.updatedAt,
                  imageBase64: _base64Image,
                  latitude: _latitudeController.text,
                  longitude: _longitudeController.text,
                ),
              ).whenComplete(() => Navigator.of(context).pop());
            }
          },
          child: Text(widget.note == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
