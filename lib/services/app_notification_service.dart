import 'package:forrageira/models/app_notification.dart';

import 'api_client.dart';
import '../utils/polling.dart';

/// Notificacoes in-app sobre a API REST (servidor UFSJ).
///
/// A CRIACAO de notificacoes (nova analise, concluida, reaberta) e o push
/// agora acontecem no backend (PHP), junto da operacao correspondente. Aqui
/// ficam apenas leitura e marcacao como lida.
class AppNotificationService {
  final ApiClient _api;
  final Duration _pollInterval;

  AppNotificationService({ApiClient? api, Duration? pollInterval})
      : _api = api ?? ApiClient(),
        _pollInterval = pollInterval ?? const Duration(seconds: 25);

  Stream<List<AppNotification>> watchUserNotifications({
    required String userId,
    int limit = 50,
  }) {
    return pollingStream(
      () => _fetch(scope: 'user', limit: limit),
      interval: _pollInterval,
    );
  }

  Stream<List<AppNotification>> watchAdminRoleNotifications({int limit = 50}) {
    return pollingStream(
      () => _fetch(scope: 'admin', limit: limit),
      interval: _pollInterval,
    );
  }

  Future<List<AppNotification>> _fetch({
    required String scope,
    required int limit,
  }) async {
    final data = await _api.get('/notifications', query: {
      'scope': scope,
      'limit': limit,
    });
    final list = (data as List?) ?? const [];
    return list
        .map((e) => AppNotification.fromApi(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    await _api.patch('/notifications/$notificationId/read');
  }

  /// Marca como lidas todas as do usuario (e, se [includeAdminRole], as de admin).
  Future<void> markAllAsRead({
    required String userId,
    required bool includeAdminRole,
  }) async {
    await _api.post('/notifications/read-all', body: {
      'includeAdminRole': includeAdminRole,
    });
  }
}
