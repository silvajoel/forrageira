import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  final _firestore = FirebaseFirestore.instance;

  static const _green = Color(0xFF1F5B3F);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _surface = Color(0xFFF7F9FB);
  static const _border = Color(0x14000000);

  // Cache de nomes de usuário para evitar múltiplas leituras
  final Map<String, String> _userNameCache = {};

  Future<String> _fetchUserName(String uid) async {
    if (uid.isEmpty) return '-';
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final name = (doc.data()?['name'] ??
          doc.data()?['email'] ??
          uid)
          .toString();
      _userNameCache[uid] = name;
      return name;
    } catch (_) {
      return uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Título ──────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_edu_outlined,
                    color: _green, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Histórico de Laudos',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Card: Análises finalizadas ───────────────────────
          _card(
            icon: Icons.check_circle_outline,
            title: 'Análises finalizadas',
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('analysis_requests')
                  .where('status', isEqualTo: 'completed')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _loading();
                }
                if (snapshot.hasError) {
                  return _errorBox(
                      'Erro ao carregar análises: ${snapshot.error}');
                }

                final docs =
                List<QueryDocumentSnapshot<Map<String, dynamic>>>.of(
                    snapshot.data?.docs ?? []);

                if (docs.isEmpty) {
                  return _emptyBox('Nenhuma análise finalizada encontrada.');
                }

                // Ordena localmente: completed_at desc, nulos por último
                docs.sort((a, b) {
                  final aTs = a.data()['completed_at'];
                  final bTs = b.data()['completed_at'];
                  if (aTs is Timestamp && bTs is Timestamp) {
                    return bTs.compareTo(aTs);
                  }
                  if (aTs is Timestamp) return -1;
                  if (bTs is Timestamp) return 1;
                  return 0;
                });

                return _AnalysisTable(
                  docs: docs,
                  fetchUserName: _fetchUserName,
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Card: Log do Admin ───────────────────────────────
          _card(
            icon: Icons.manage_search_outlined,
            title: 'Log do Admin (ações executadas)',
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('logs')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _loading();
                }
                if (snapshot.hasError) {
                  return _errorBox(
                      'Erro ao carregar logs: ${snapshot.error}');
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) return _emptyBox('Nenhum log encontrado.');

                return Column(
                  children: [
                    for (int i = 0; i < docs.length; i++) ...[
                      _LogTile(data: docs[i].data()),
                      if (i < docs.length - 1)
                        const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0x0C000000)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 16,
              offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border:
              Border(bottom: BorderSide(color: Color(0x0F000000))),
            ),
            child: Row(
              children: [
                Icon(icon, color: _green, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _loading() => const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _errorBox(String message) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3F3),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFFCDD2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message,
              style:
              const TextStyle(fontSize: 12, color: Colors.red)),
        ),
      ],
    ),
  );

  Widget _emptyBox(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined,
              size: 40, color: Colors.black26),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: Colors.black45)),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════
//  Tabela de análises finalizadas
// ══════════════════════════════════════════════════════════════
class _AnalysisTable extends StatelessWidget {
  const _AnalysisTable({
    required this.docs,
    required this.fetchUserName,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Future<String> Function(String uid) fetchUserName;

  static const _green = Color(0xFF1F5B3F);
  static const _greenLight = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 700),
        child: Column(
          children: [
            // Cabeçalho
            Container(
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  _Th('Solicitação', flex: 3),
                  _Th('Usuário', flex: 3),
                  _Th('Espécie', flex: 3),
                  _Th('Finalizado em', flex: 3),
                  _Th('Encerrado por', flex: 4),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x0F000000)),
            // Linhas
            for (int i = 0; i < docs.length; i++)
              _AnalysisRow(
                doc: docs[i],
                isEven: i.isEven,
                fetchUserName: fetchUserName,
              ),
          ],
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.label, {this.flex = 2});
  final String label;
  final int flex;

  static const _green = Color(0xFF1F5B3F);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _green)),
      ),
    );
  }
}

// ── Linha individual com FutureBuilder para o nome do usuário ──
class _AnalysisRow extends StatefulWidget {
  const _AnalysisRow({
    required this.doc,
    required this.isEven,
    required this.fetchUserName,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final bool isEven;
  final Future<String> Function(String uid) fetchUserName;

  @override
  State<_AnalysisRow> createState() => _AnalysisRowState();
}

class _AnalysisRowState extends State<_AnalysisRow> {
  late Future<String> _userNameFuture;

  @override
  void initState() {
    super.initState();
    final uid = _extractUserId(widget.doc.data());
    _userNameFuture = widget.fetchUserName(uid);
  }

  // user_id pode estar direto no doc OU dentro de metadata
  String _extractUserId(Map<String, dynamic> data) {
    final direct = (data['user_id'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final meta = data['metadata'];
    if (meta is Map) {
      final fromMeta = (meta['user_id'] ?? '').toString().trim();
      if (fromMeta.isNotEmpty) return fromMeta;
    }
    return '';
  }

  // species_name pode estar direto OU dentro de metadata
  String _extractSpecies(Map<String, dynamic> data) {
    final direct =
    (data['species_name'] ?? data['species'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;
    final meta = data['metadata'];
    if (meta is Map) {
      final fromMeta =
      (meta['species_name'] ?? meta['species'] ?? '').toString().trim();
      if (fromMeta.isNotEmpty) return fromMeta;
    }
    return '-';
  }

  // E-mail/nome de quem encerrou a análise
  String _extractAdminEmail(Map<String, dynamic> data) {
    return (data['actor_email'] ??
        data['reviewed_by_email'] ??
        data['completed_by_email'] ??
        data['reviewed_by_name'] ??
        data['completed_by_name'] ??
        '-')
        .toString()
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();
    final species = _extractSpecies(data);
    final adminEmail = _extractAdminEmail(data);

    // Data: prefere completed_at, fallback updated_at com asterisco
    final tsCompleted = data['completed_at'];
    final tsUpdated = data['updated_at'];
    final completedText = tsCompleted is Timestamp
        ? _fmt(tsCompleted.toDate())
        : tsUpdated is Timestamp
        ? '${_fmt(tsUpdated.toDate())} *'
        : '-';

    final shortId = widget.doc.id.length > 10
        ? '${widget.doc.id.substring(0, 10)}…'
        : widget.doc.id;

    return Container(
      decoration: BoxDecoration(
        color: widget.isEven ? Colors.white : const Color(0xFFFAFBFC),
        border: const Border(
            bottom: BorderSide(color: Color(0x08000000))),
      ),
      child: Row(
        children: [
          // ID
          Expanded(
            flex: 3,
            child: Tooltip(
              message: widget.doc.id,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                child: Text(shortId,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.black45)),
              ),
            ),
          ),
          // Usuário — busca assíncrona
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              child: FutureBuilder<String>(
                future: _userNameFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 14,
                      height: 14,
                      child:
                      CircularProgressIndicator(strokeWidth: 1.5),
                    );
                  }
                  return Text(snap.data ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13));
                },
              ),
            ),
          ),
          // Espécie
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              child: Text(species,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
          // Finalizado em
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 11),
              child: Text(completedText,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
            ),
          ),
          // Encerrado por (e-mail do admin)
          Expanded(
            flex: 4,
            child: Tooltip(
              message: adminEmail,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 13, color: Colors.black38),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(adminEmail,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
}

// ══════════════════════════════════════════════════════════════
//  Log tile — campos corretos da coleção `logs`
//  Estrutura: action, actor_email, actor_uid, created_at,
//             metadata { species_name, user_id }, target_id
// ══════════════════════════════════════════════════════════════
class _LogTile extends StatelessWidget {
  const _LogTile({required this.data});
  final Map<String, dynamic> data;

  static const _green = Color(0xFF1F5B3F);

  @override
  Widget build(BuildContext context) {
    final action = (data['action'] ?? '-').toString();
    // actor_email é o campo correto no Firestore (visto na imagem)
    final actorEmail =
    (data['actor_email'] ?? data['admin_name'] ?? '-').toString();
    final createdAt = data['created_at'];
    final when =
    createdAt is Timestamp ? _fmt(createdAt.toDate()) : '-';

    final meta = data['metadata'];
    final speciesName = meta is Map
        ? (meta['species_name'] ?? '').toString().trim()
        : '';
    final targetUserId = meta is Map
        ? (meta['user_id'] ?? '').toString().trim()
        : '';
    final targetId = (data['target_id'] ?? '').toString().trim();
    final type = (data['type'] ?? '').toString();
    final table = (data['table'] ?? '').toString();

    final iconColor = _iconColor(action, type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
            Icon(Icons.event_note_outlined, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ação + data/hora
                Row(
                  children: [
                    Expanded(
                      child: Text(action,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Text(when,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black45)),
                  ],
                ),
                const SizedBox(height: 4),
                // Chips de contexto
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _chip(actorEmail, Icons.person_outline),
                    if (speciesName.isNotEmpty)
                      _chip(speciesName, Icons.eco_outlined),
                    if (targetUserId.isNotEmpty)
                      _chip('user: ${_short(targetUserId)}',
                          Icons.account_circle_outlined),
                    if (targetId.isNotEmpty)
                      _chip('ref: ${_short(targetId)}', Icons.link),
                    if (table.isNotEmpty)
                      _chip(table, Icons.table_chart_outlined),
                    if (type.isNotEmpty)
                      _chip(type, Icons.label_outline),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _iconColor(String action, String type) {
    final a = action.toLowerCase();
    final t = type.toLowerCase();
    if (t == 'delete' || a.contains('deletou') || a.contains('removeu')) {
      return Colors.red;
    }
    if (t == 'create' || a.contains('criou') || a.contains('cadastrou')) {
      return _green;
    }
    if (t == 'update' || a.contains('atualizou') || a.contains('finalizou')) {
      return Colors.orange;
    }
    return Colors.blueGrey;
  }

  static Widget _chip(String label, IconData icon) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: Colors.black38),
      const SizedBox(width: 3),
      Text(label,
          style: const TextStyle(fontSize: 11, color: Colors.black54)),
    ],
  );

  static String _short(String id) =>
      id.length > 8 ? '${id.substring(0, 8)}…' : id;

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
}