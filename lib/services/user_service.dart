import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    String role = 'user',
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'role': role,        // 'user' ou 'admin'
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'email': email,
    });
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }
}