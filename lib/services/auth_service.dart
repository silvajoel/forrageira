import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  bool isLoading = true;

  User? get currentUser => _currentUser;

  AuthService() {
    _authCheck();
  }

  void _authCheck() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user; // salva no estado
      isLoading = false;
      notifyListeners();
    });
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getUsername() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();

    return doc.data()?['name'];
  }

  Future<User?> login(String email, String senha) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
    return cred.user;
  }

  Future<User?> register(String email, String senha) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'A senha é muito fraca!',
        );
      } else if (e.code == 'email-already-in-use') {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Este email já está cadastrado',
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername(String username) async {
    if (_currentUser == null) return;

    final uid = _currentUser!.uid;

    // Atualiza no Firebase Auth
    await _currentUser!.updateDisplayName(username);

    // Atualiza no Firestore
    await _firestore.collection('users').doc(uid).update({'name': username});

    // Recarrega usuário
    await _currentUser!.reload();
    _currentUser = _auth.currentUser;

    notifyListeners();
  }

  Future<void> deleteAccount(String email, String senha) async {
    if (_currentUser == null) return;

    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: senha,
    );

    await _currentUser!.reauthenticateWithCredential(credential);
    await _currentUser!.delete();
    await _auth.signOut();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    if (_currentUser == null) return;

    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );

    await _currentUser!.reauthenticateWithCredential(credential);
    await _currentUser!.updatePassword(newPassword);
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
