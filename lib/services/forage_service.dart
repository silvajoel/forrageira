import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';

import 'api_client.dart';
import 'i_forage_service.dart';
import '../utils/polling.dart';

/// Implementacao do servico de analises sobre a API REST (servidor UFSJ).
///
/// As notificacoes e o push sao disparados no backend (PHP); aqui nao ha mais
/// chamadas diretas a notificacao. O tempo real do Firestore foi substituido
/// por [pollingStream].
class ForageService extends ChangeNotifier implements IForageService {
  final ApiClient _api;
  final Duration _pollInterval;

  ForageService({ApiClient? api, Duration? pollInterval})
      : _api = api ?? ApiClient(),
        _pollInterval = pollInterval ?? const Duration(seconds: 25);

  @override
  Future<void> createAnalysisRequest({
    required String name,
    required String notes,
    required String userId,
    required double latitude,
    required double longitude,
    List<String>? imageUrls,
  }) async {
    await _api.post('/analysis', body: {
      'name': name,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrls': imageUrls ?? const [],
    });
    notifyListeners();
  }

  @override
  Future<void> finalizeAnalysisRequest({
    required String requestId,
    required String speciesName,
    required String careInstructions,
    required String adminNotes,
  }) async {
    await _api.post('/analysis/$requestId/finalize', body: {
      'species_name': speciesName,
      'care_instructions': careInstructions,
      'admin_notes': adminNotes,
    });
    notifyListeners();
  }

  /// Reabre uma analise para ajustes (admin). O backend notifica o usuario.
  Future<void> reopenAnalysisRequest({
    required String requestId,
    String reason = '',
  }) async {
    await _api.post('/analysis/$requestId/reopen', body: {'reason': reason});
    notifyListeners();
  }

  @override
  Stream<List<AnalysisRequest>> watchUserForages(String userId, {int limit = 3}) {
    return pollingStream(
      () => _fetchUserForages(userId, limit: limit),
      interval: _pollInterval,
    );
  }

  @override
  Stream<List<AnalysisRequest>> watchAllUserForages(String userId, {int limit = 20}) {
    return pollingStream(
      () => _fetchUserForages(userId, limit: limit),
      interval: _pollInterval,
    );
  }

  @override
  Stream<List<AnalysisRequest>> watchAllRequests({int limit = 100}) {
    return pollingStream(
      () => _fetchRequests(query: {'limit': limit}),
      interval: _pollInterval,
    );
  }

  @override
  Future<AnalysisRequest> getById(String id) async {
    final data = await _api.get('/analysis/$id');
    return AnalysisRequestApi.fromApi(data as Map<String, dynamic>);
  }

  @override
  Future<List<AnalysisRequest>> fetchUserForages(String userId, {int limit = 20}) =>
      _fetchUserForages(userId, limit: limit);

  Future<List<AnalysisRequest>> fetchAllRequests({int limit = 100}) =>
      _fetchRequests(query: {'limit': limit});

  Future<List<AnalysisRequest>> _fetchUserForages(String userId, {required int limit}) {
    return _fetchRequests(query: {'user_id': userId, 'limit': limit});
  }

  Future<List<AnalysisRequest>> _fetchRequests({Map<String, dynamic>? query}) async {
    final data = await _api.get('/analysis', query: query);
    final list = (data as List?) ?? const [];
    return list
        .map((e) => AnalysisRequestApi.fromApi(e as Map<String, dynamic>))
        .toList();
  }
}
