enum RequestStatus { pendente, emAnalise, finalizado }

class AnalysisRequest {
  final String id;
  final DateTime createdAt;
  final String cliente;
  final String propriedade;
  final String localidade;
  final String descricao;
  RequestStatus status;

  // resultado do admin
  String? especieId;
  String? parecer;
  DateTime? reviewedAt;
  String? reviewedBy;

  AnalysisRequest({
    required this.id,
    required this.createdAt,
    required this.cliente,
    required this.propriedade,
    required this.localidade,
    required this.descricao,
    this.status = RequestStatus.pendente,
    this.especieId,
    this.parecer,
    this.reviewedAt,
    this.reviewedBy,
  });
}

class Client {
  final String id;
  String nome;
  String email;
  bool ativo;

  Client({required this.id, required this.nome, required this.email, this.ativo = true});
}

class Species {
  final String id;
  String nome;
  String descricao;

  Species({required this.id, required this.nome, required this.descricao});
}

class AuditLog {
  final DateTime at;
  final String admin;
  final String action; // ex: "Finalizou análise #2590"
  final String? refId;

  AuditLog({required this.at, required this.admin, required this.action, this.refId});
}