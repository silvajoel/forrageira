import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthService extends ChangeNotifier {
  static const String _lastKnownSessionKey = 'last_known_authenticated_user';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClient _api = ApiClient();

  User? _currentUser;
  bool isLoading = true;

  User? get currentUser => _currentUser;

  AuthService() {
    _authCheck();
  }

  void _authCheck() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      isLoading = false;
      _persistLastKnownSession(user != null);
      notifyListeners();
    });
  }

  Future<void> _persistLastKnownSession(bool isAuthenticated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lastKnownSessionKey, isAuthenticated);
  }

  static Future<bool> getLastKnownAuthenticatedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lastKnownSessionKey) ?? false;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getUsername() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    try {
      final data = await _api.get('/users/me');
      if (data is Map<String, dynamic>) return data['name'] as String?;
    } catch (_) {}
    return null;
  }

  /// Garante a linha do usuario no banco (FK das analises). Idempotente.
  Future<void> _ensureSynced(User user) async {
    try {
      await _api.post('/auth/sync', body: {
        'name': user.displayName ?? '',
        'email': user.email ?? '',
      });
    } catch (e) {
      debugPrint('Falha ao sincronizar usuario: $e');
    }
  }

  Future<User?> login(String email, String senha) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: senha,
    );
    if (cred.user != null) await _ensureSynced(cred.user!);
    return cred.user;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);
    if (cred.user != null) await _ensureSynced(cred.user!);
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

  // Fluxo atual do app
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Fluxo específico do WEB ADMIN
  Future<void> updateLoginEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-authenticated',
        message: 'Usuário não autenticado.',
      );
    }

    final currentEmail = user.email?.trim().toLowerCase();
    final normalizedNewEmail = newEmail.trim().toLowerCase();

    if (currentEmail == null || currentEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-current-email',
        message: 'E-mail atual não encontrado.',
      );
    }

    if (normalizedNewEmail.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-new-email',
        message: 'Informe o novo e-mail.',
      );
    }

    if (normalizedNewEmail == currentEmail) {
      throw FirebaseAuthException(
        code: 'same-email',
        message: 'O novo e-mail é igual ao atual.',
      );
    }

    // A unicidade do e-mail e garantida pelo Firebase Auth no
    // verifyBeforeUpdateEmail abaixo (lanca 'email-already-in-use').
    final credential = EmailAuthProvider.credential(
      email: currentEmail,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);

    await user.verifyBeforeUpdateEmail(
      normalizedNewEmail,
      ActionCodeSettings(
        url: 'https://forrageira-963b0.web.app/#/admin-login',
        handleCodeInApp: false,
      ),
    );

    await user.reload();
    _currentUser = _auth.currentUser;
    notifyListeners();
  }

  Future<bool> canSendAdminResetPassword(String email) async {
    try {
      final data = await _api.get('/auth/admin-eligible', query: {
        'email': email.trim().toLowerCase(),
      });
      return data is Map<String, dynamic> && data['eligible'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendPasswordResetForWeb(String email) async {
    await _auth.setLanguageCode('pt-BR');

    await _auth.sendPasswordResetEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: 'https://forrageira-963b0.web.app/#/reset-password',
        handleCodeInApp: false,
      ),
    );
  }

  Future<String> verifyResetCode(String oobCode) async {
    return await _auth.verifyPasswordResetCode(oobCode);
  }

  Future<void> confirmNewPassword({
    required String oobCode,
    required String newPassword,
  }) async {
    await _auth.confirmPasswordReset(
      code: oobCode,
      newPassword: newPassword,
    );
  }
  Future<void> syncCurrentUserEmailToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final authEmail = user.email?.trim().toLowerCase();
    if (authEmail == null || authEmail.isEmpty) return;

    await _api.patch('/users/${user.uid}', body: {'email': authEmail});

    await user.reload();
    _currentUser = _auth.currentUser;
    notifyListeners();
  }

  Future<void> updateUsername(String username) async {
    if (_currentUser == null) return;

    final uid = _currentUser!.uid;

    await _currentUser!.updateDisplayName(username);
    await _api.patch('/users/$uid', body: {'name': username});

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
