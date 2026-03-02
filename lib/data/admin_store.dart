import 'package:flutter/foundation.dart';
import 'models.dart';

class AdminStore extends ChangeNotifier {
  static final AdminStore instance = AdminStore._();
  AdminStore._() {
    _seed();
  }

  String adminNome = 'Admin';
  String adminEmail = 'admin@forrageira.com';

  final List<AnalysisRequest> _requests = [];
  final List<Client> _clients = [];
  final List<Species> _species = [];
  final List<AuditLog> _logs = [];

  List<AnalysisRequest> get requests => List.unmodifiable(_requests);
  List<AnalysisRequest> get pendingRequests =>
      List.unmodifiable(_requests.where((r) => r.status != RequestStatus.finalizado));
  List<AnalysisRequest> get history =>
      List.unmodifiable(_requests.where((r) => r.status == RequestStatus.finalizado));

  List<Client> get clients => List.unmodifiable(_clients);
  List<Species> get species => List.unmodifiable(_species);
  List<AuditLog> get logs => List.unmodifiable(_logs.reversed);

  int get pendentesCount => _requests.where((r) => r.status != RequestStatus.finalizado).length;
  int get concluidosHojeCount {
    final now = DateTime.now();
    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    return _requests.where((r) => r.reviewedAt != null && sameDay(r.reviewedAt!, now)).length;
  }

  Duration get tempoMedioMock => const Duration(hours: 2, minutes: 15);

  AnalysisRequest? getRequestById(String id) {
    try { return _requests.firstWhere((e) => e.id == id); } catch (_) { return null; }
  }

  // ------- Requests -------
  void startReview(String requestId) {
    final r = getRequestById(requestId);
    if (r == null) return;
    r.status = RequestStatus.emAnalise;
    _logs.add(AuditLog(at: DateTime.now(), admin: adminNome, action: 'Iniciou análise ${r.id}', refId: r.id));
    notifyListeners();
  }

  void finalizeRequest({
    required String requestId,
    required String especieId,
    required String parecer,
  }) {
    final r = getRequestById(requestId);
    if (r == null) return;

    r.especieId = especieId;
    r.parecer = parecer;
    r.status = RequestStatus.finalizado;
    r.reviewedAt = DateTime.now();
    r.reviewedBy = adminNome;

    _logs.add(AuditLog(at: DateTime.now(), admin: adminNome, action: 'Finalizou análise ${r.id}', refId: r.id));
    notifyListeners();
  }

  // ------- Clients -------
  void addClient(String nome, String email) {
    final id = 'C${DateTime.now().millisecondsSinceEpoch}';
    _clients.add(Client(id: id, nome: nome, email: email));
    _logs.add(AuditLog(at: DateTime.now(), admin: adminNome, action: 'Criou cliente $nome', refId: id));
    notifyListeners();
  }

  void updateClient(String id, {required String nome, required String email, required bool ativo}) {
    final c = _clients.where((e) => e.id == id).first;
    c.nome = nome;
    c.email = email;
    c.ativo = ativo;
    _logs.add(AuditLog(at: DateTime.now(), admin: adminNome, action: 'Editou cliente $nome', refId: id));
    notifyListeners();
  }

  void deleteClient(String id) {
    _clients.removeWhere((e) => e.id == id);
    _logs.add(AuditLog(at: DateTime.now(), admin: adminNome, action: 'Excluiu cliente $id', refId: id));
    notifyListeners();
  }

  // ------- Species -------
  void addSpecies(String nome, String descricao) {
    final id = 'S${DateTime.now().millisecondsSinceEpoch}';
    _species.add(Species(id: id, nome: nome, descricao: descricao));
    _logs.add(AuditLog(at: DateTime.now(), admin: adminNome, action: 'Cadastrou espécie $nome', refId: id));
    notifyListeners();
  }

  void updateSpecies(String id, {required String nome, required String descricao}) {
    final s = _species.where((e) => e.id == id).first;
    s.nome = nome;
    s.descricao = descricao;
    _logs.add(AuditLog(at: DateTime.now(), admin: adminNome, action: 'Editou espécie $nome', refId: id));
    notifyListeners();
  }

  void deleteSpecies(String id) {
    _species.removeWhere((e) => e.id == id);
    _logs.add(AuditLog(at: DateTime.now(), admin: adminNome, action: 'Excluiu espécie $id', refId: id));
    notifyListeners();
  }

  // ------- Settings -------
  void updateMyAccount({required String nome, required String email}) {
    adminNome = nome;
    adminEmail = email;
    _logs.add(AuditLog(at: DateTime.now(), admin: adminNome, action: 'Atualizou dados da conta'));
    notifyListeners();
  }

  // seed
  void _seed() {
    _clients.addAll([
      Client(id: 'C1', nome: 'João Silva', email: 'joao@exemplo.com', ativo: true),
      Client(id: 'C2', nome: 'Maria Lima', email: 'maria@exemplo.com', ativo: true),
    ]);

    _species.addAll([
      Species(id: 'S1', nome: 'Capim Mombaça', descricao: 'Forrageira de alta produtividade, boa para pastejo rotacionado.'),
      Species(id: 'S2', nome: 'Brachiaria', descricao: 'Boa adaptação e resistência, comum em diversas regiões.'),
    ]);

    for (int i = 0; i < 12; i++) {
      _requests.add(AnalysisRequest(
        id: '#25${(90 + i).toString().padLeft(2, '0')}',
        createdAt: DateTime.now().subtract(Duration(hours: i * 2)),
        cliente: i.isEven ? 'João Silva' : 'Maria Lima',
        propriedade: 'Faz. Recanto',
        localidade: 'Goiatuba-GO',
        descricao: 'Imagem enviada + descrição (mock) da forrageira.',
        status: (i % 5 == 0) ? RequestStatus.emAnalise : RequestStatus.pendente,
      ));
    }
  }
}