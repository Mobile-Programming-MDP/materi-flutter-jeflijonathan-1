import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notes/models/note.dart';

class NoteService {
  static final FirebaseFirestore _database = FirebaseFirestore.instance;
  static final CollectionReference _notesCollection = _database.collection(
    'notes',
  );

  static Stream<List<Note>> getNotes() {
    return _notesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Note(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          image_base_64: data['image_base_64'],
          latitude: data['latitude'],
          longitude: data['longitude'],
          created_at: data['created_at'] != null
              ? (data['created_at'] as Timestamp)
              : null,
          updated_at: data['updated_at'] != null
              ? (data['updated_at'] as Timestamp)
              : null,
        );
      }).toList();
    });
  }

  static Future<void> addNote(Note noteData) async {
    try {
      Map<String, dynamic> newNote = {
        'title': noteData.title,
        'description': noteData.description,
        'image_base_64': noteData.image_base_64,
        'latitude': noteData.latitude,
        'longitude': noteData.longitude,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      await _notesCollection.add(newNote);
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  static Future<void> updateNote(String id, Note noteData) async {
    try {
      Map<String, dynamic> updatedNote = {
        'title': noteData.title,
        'description': noteData.description,
        'image_base_64': noteData.image_base_64,
        'latitude': noteData.latitude,
        'longitude': noteData.longitude,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      await _notesCollection.doc(id).update(updatedNote);
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  static Future<void> deleteNote(String id) async {
    try {
      await _notesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }
}
