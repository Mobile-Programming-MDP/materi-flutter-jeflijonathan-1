import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addPost(Post post) async {
    try {
      await _firestore.collection('posts').add(post.toMap());
    } catch (e) {
      throw Exception('Gagal menambahkan post: $e');
    }
  }

  Stream<List<Post>> getPosts() {
    return _firestore.collection('posts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Post.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
