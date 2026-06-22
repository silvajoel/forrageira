import 'api_client.dart';
import '../utils/polling.dart';

/// Logs de auditoria administrativa sobre a API REST (servidor UFSJ).
///
/// Operacoes de analise (finalizar/reabrir) ja sao auditadas no backend.
/// Este servico cobre as acoes acionadas pela UI admin (ex.: gestao de
/// clientes) e a leitura do historico.
class AuditLogService {
  final ApiClient _api;

  AuditLogService({ApiClient? api}) : _api = api ?? ApiClient();

  Future<void> log({
    required String action,
    String? targetId,
    Map<String, dynamic>? metadata,
  }) async {
    await _api.post('/audit-logs', body: {
      'action': action,
      'target_id': targetId,
      'metadata': metadata ?? <String, dynamic>{},
    });
  }

  /// Historico recente (polling). Cada item e o JSON serializado do log.
  Stream<List<Map<String, dynamic>>> watchRecent({int limit = 30}) {
    return pollingStream<List<Map<String, dynamic>>>(() => fetchRecent(limit: limit));
  }

  Future<List<Map<String, dynamic>>> fetchRecent({int limit = 30}) async {
    final data = await _api.get('/audit-logs', query: {'limit': limit});
    final list = (data as List?) ?? const [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }
}
