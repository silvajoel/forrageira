import 'package:firebase_auth/firebase_auth.dart';

import 'api_client.dart';
import '../utils/polling.dart';

/// Perfis de usuario sobre a API REST (servidor UFSJ).
///
/// O Firebase Auth continua sendo a fonte de identidade (login e troca de
/// e-mail); apenas os DADOS do perfil deixam o Firestore e passam a viver no
/// MariaDB via API.
class UserService {
  final ApiClient _api;
  final FirebaseAuth _auth;

  UserService({ApiClient? api, FirebaseAuth? auth})
      : _api = api ?? ApiClient(),
        _auth = auth ?? FirebaseAuth.instance;

  /// Cria/sincroniza o perfil do usuario autenticado (id = uid do token).
  /// Usado no cadastro e no primeiro login.
  Future<Map<String, dynamic>?> createUserProfile({
    required String uid,
    required String name,
    required String email,
    String role = 'user',
  }) async {
    final data = await _api.post('/auth/sync', body: {
      'name': name,
      'email': email,
    });
    return data as Map<String, dynamic>?;
  }

  /// Garante que existe a linha do usuario logado no banco. Idempotente.
  Future<Map<String, dynamic>?> syncCurrentUser() async {
    final data = await _api.post('/auth/sync');
    return data as Map<String, dynamic>?;
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _api.patch('/users/$uid', body: {'name': name, 'email': email});
  }

  /// Atualiza o e-mail no Firebase Auth (com verificacao) e no banco.
  ///
  /// Lanca [FirebaseAuthException] 'requires-recent-login' se a sessao estiver
  /// antiga — trate na UI pedindo re-autenticacao.
  Future<void> updateEmail({
    required String uid,
    required String newEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuario autenticado.',
      );
    }

    final currentEmail = user.email ?? '';
    if (currentEmail != newEmail) {
      await user.verifyBeforeUpdateEmail(newEmail);
    }
    await _api.patch('/users/$uid', body: {'email': newEmail});
  }

  /// Perfil do usuario autenticado. (O token identifica o usuario; [uid] e
  /// mantido por compatibilidade.)
  Future<Map<String, dynamic>?> getProfile(String uid) async {
    try {
      final data = await _api.get('/users/me');
      return data as Map<String, dynamic>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getProfileWithRetry(String uid) async {
    final firstProfile = await getProfile(uid);

    if (firstProfile == null || !isProfileActive(firstProfile)) {
      await Future.delayed(const Duration(milliseconds: 700));
      try {
        final refreshed = await getProfile(uid);
        if (refreshed != null) return refreshed;
      } catch (_) {
        return firstProfile;
      }
    }
    return firstProfile;
  }

  /// So inativa quando [active] e explicitamente `false`.
  static bool isProfileActive(Map<String, dynamic> profile) {
    return profile['active'] != false;
  }

  /// Data de cadastro do perfil (ISO-8601 vindo da API).
  static DateTime? userCreatedTimestamp(Map<String, dynamic> profile) {
    final v = profile['created_at'] ?? profile['createdAt'];
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v)?.toLocal();
    }
    return null;
  }

  /// Valor do campo de papel (aceita `role`/`Role`, remove caracteres invisiveis).
  static String? roleValue(Map<String, dynamic>? profile) {
    if (profile == null) return null;
    dynamic raw;
    for (final e in profile.entries) {
      if (e.key.trim().toLowerCase() == 'role') {
        raw = e.value;
        break;
      }
    }
    if (raw == null) return null;
    var s = raw.toString().trim();
    // Remove zero-width chars (U+200B..U+200D, U+FEFF) sem literais invisiveis.
    final invisible =
        RegExp('[${String.fromCharCodes(const [0x200B, 0x200C, 0x200D, 0xFEFF])}]');
    s = s.replaceAll(invisible, '');
    return s.toLowerCase();
  }

  static bool isAdminRole(Map<String, dynamic>? profile) {
    return roleValue(profile) == 'admin';
  }

  /// Stream do perfil do usuario logado (polling).
  Stream<Map<String, dynamic>?> streamProfile(String uid) {
    return pollingStream<Map<String, dynamic>?>(() => getProfile(uid));
  }

  /// Stream da lista de usuarios (admin, polling).
  Stream<List<Map<String, dynamic>>> streamUsers() {
    return pollingStream<List<Map<String, dynamic>>>(() => fetchUsers());
  }

  /// Lista de usuarios (one-shot, para pull-to-refresh).
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final data = await _api.get('/users');
    final list = (data as List?) ?? const [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> createClient({
    required String name,
    required String email,
    bool active = true,
    String role = 'user',
  }) async {
    await _api.post('/users', body: {
      'name': name,
      'email': email,
      'role': role,
      'active': active,
    });
  }

  Future<void> updateUser({
    required String uid,
    required String name,
    required String email,
    required bool active,
  }) async {
    await _api.patch('/users/$uid', body: {
      'name': name,
      'email': email,
      'active': active,
    });
  }

  Future<void> setRole({required String uid, required String role}) async {
    await _api.patch('/users/$uid', body: {'role': role});
  }

  Future<void> setActive({required String uid, required bool active}) async {
    await _api.patch('/users/$uid', body: {'active': active});
  }

  Future<void> deleteUser(String uid) async {
    await _api.delete('/users/$uid');
  }
}
