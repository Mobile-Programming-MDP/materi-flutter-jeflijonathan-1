import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  String? id;
  final String title;
  final String description;
  String? image_base_64;
  double? latitude;
  double? longitude;
  Timestamp? created_at;
  Timestamp? updated_at;

  Note({
    this.id,
    required this.title,
    required this.description,
    this.image_base_64,
    this.latitude,
    this.longitude,
    this.created_at,
    this.updated_at,
  });

  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      image_base_64: map['image_base_64'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      created_at: map['created_at'],
      updated_at: map['updated_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'image_base_64': image_base_64,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }
}
