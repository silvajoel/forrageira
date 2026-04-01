import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

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

  /// Atualiza o e-mail no Firebase Auth.
  ///
  /// - Se o e-mail mudou, envia um e-mail de verificação para o novo endereço.
  ///   O e-mail só será efetivado no Auth após o usuário clicar no link.
  /// - Atualiza o Firestore imediatamente (otimista), independente da verificação.
  /// - Lança [FirebaseAuthException] com code 'requires-recent-login' se a
  ///   sessão estiver antiga — trate isso na UI pedindo re-autenticação.
  Future<void> updateEmail({
    required String uid,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário autenticado.',
      );
    }

    final currentEmail = user.email ?? '';

    // Só aciona o Auth se o e-mail realmente mudou
    if (currentEmail != newEmail) {
      // Envia link de verificação para o novo e-mail.
      // O Auth só efetiva a troca após o clique no link.
      await user.verifyBeforeUpdateEmail(newEmail);
    }

    // Atualiza o Firestore imediatamente (o Auth será atualizado após verificação)
    await _db.collection('users').doc(uid).update({'email': newEmail});
  }

  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsers() {
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
    await _db.collection('users').doc(uid).update({'role': role});
  }

  Future<void> setActive({
    required String uid,
    required bool active,
  }) async {
    await _db.collection('users').doc(uid).update({'active': active});
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }
}