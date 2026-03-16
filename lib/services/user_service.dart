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
      'role': role,
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

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsers() {
    // return _db
    //    .collection('users')
    //    .orderBy('createdAt', descending: true)
    //    .snapshots();
    return _db.collection('users').snapshots();
  }

  Future<void> createClient({
    required String name,
    required String email,
    bool active = true,
    String role = 'user',
  }) async {
    final doc = _db.collection('users').doc();

    await doc.set({
      'name': name,
      'email': email,
      'role': role,
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUser({
    required String uid,
    required String name,
    required String email,
    required bool active,
  }) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'email': email,
      'active': active,
    });
  }

  Future<void> setRole({
    required String uid,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).update({
      'role': role,
    });
  }

  Future<void> setActive({
    required String uid,
    required bool active,
  }) async {
    await _db.collection('users').doc(uid).update({
      'active': active,
    });
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }
}