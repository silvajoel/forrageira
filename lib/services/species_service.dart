import 'api_client.dart';
import '../utils/polling.dart';

/// Catalogo de especies sobre a API REST (servidor UFSJ).
///
/// O backend grava automaticamente as entradas em `logs` ao criar/atualizar/
/// inativar uma especie, entao o cliente nao precisa mais registrar logs.
class SpeciesService {
  final ApiClient _api;

  SpeciesService({ApiClient? api}) : _api = api ?? ApiClient();

  Stream<List<Map<String, dynamic>>> watchSpecies({bool onlyActive = false}) {
    return pollingStream<List<Map<String, dynamic>>>(
      () => fetchSpecies(onlyActive: onlyActive),
    );
  }

  Future<List<Map<String, dynamic>>> fetchSpecies({bool onlyActive = false}) async {
    final data = await _api.get(
      '/species',
      query: onlyActive ? {'active': 1} : null,
    );
    final list = (data as List?) ?? const [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> create({required String name, required String description}) async {
    await _api.post('/species', body: {'name': name, 'description': description});
  }

  Future<void> update({
    required String id,
    String? name,
    String? description,
    bool? active,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (active != null) body['active'] = active;
    await _api.put('/species/$id', body: body);
  }

  Future<void> setActive({required String id, required bool active}) =>
      update(id: id, active: active);
}
