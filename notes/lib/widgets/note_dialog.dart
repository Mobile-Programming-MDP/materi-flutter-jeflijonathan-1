import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/models/note.dart';

class NoteDialog extends StatefulWidget {
  final Note? note;
  const NoteDialog({super.key, this.note});

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  String? _base64String;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.description;
      _base64String = widget.note!.image_base_64;
      // Load image from base64 if available
    }
  }

  Future<void> _pickImage() async {
    final PickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (PickedFile != null) {
      // 2. Read image as base64
      final bytes = await File(PickedFile.path).readAsBytes();
      _base64String = base64Encode(bytes);

      setState(() {
        _base64String = _base64String;
        _imageFile = File(PickedFile.path);
      });

      print("Base64 String: $_base64String");
    } else {
      print('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Add Note' : 'Edit Note'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Pick Image'),
            ),
            if (_imageFile != null)
              Image.file(_imageFile!, height: 100, width: 100),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Handle save logic here
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
