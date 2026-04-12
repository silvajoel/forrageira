import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/services/audit_log_service.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:provider/provider.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  final _audit = AuditLogService();
  final _firestore = FirebaseFirestore.instance;

  final Map<String, String> _userCache = {};

  // =========================
  // 👤 BUSCAR NOME USUÁRIO
  // =========================
  Future<String> _getUserName(String uid) async {
    if (uid.isEmpty) return 'Usuário';

    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      final name = (data?['name'] ??
          data?['display_name'] ??
          data?['email'] ??
          'Usuário')
          .toString();

      _userCache[uid] = name;
      return name;
    } catch (_) {
      return 'Usuário';
    }
  }

  @override
  Widget build(BuildContext context) {
    final forageService = context.read<IForageService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Histórico de Laudos'),
        elevation: 0,
      ),
      body: StreamBuilder<List<AnalysisRequest>>(
        stream: forageService.watchAllRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = (snapshot.data ?? [])
              .where((e) => e.status == 'completed')
              .toList();

          if (history.isEmpty) {
            return const Center(child: Text('Nenhuma análise encontrada.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card(
                title: 'Análises finalizadas',
                icon: Icons.check_circle_outline,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                    MaterialStateProperty.all(const Color(0xFFEAECEF)),
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Forrageira')),
                      DataColumn(label: Text('Usuário')),
                      DataColumn(label: Text('Espécie')),
                      DataColumn(label: Text('Finalizado em')),
                    ],
                    rows: history.map((r) {
                      final dt = r.reviewedAt == null
                          ? '-'
                          : _fmt(r.reviewedAt!);

                      return DataRow(
                        cells: [
                          DataCell(Text(r.id)),
                          DataCell(Text(r.name)),

                          // 👤 USUÁRIO MELHORADO
                          DataCell(_UserNameCell(
                            userId: r.userId,
                            getUserName: _getUserName,
                          )),

                          DataCell(Text(r.speciesName ?? '-')),
                          DataCell(Text(dt)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _card(
                title: 'Log do Admin',
                icon: Icons.event_note,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _audit.watchRecent(),
                  builder: (context, logSnapshot) {
                    if (logSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    final logs = logSnapshot.data?.docs ?? [];

                    if (logs.isEmpty) {
                      return const Text('Nenhum log encontrado.');
                    }

                    return Column(
                      children: logs.map((doc) {
                        final data = doc.data();

                        final createdAt =
                        (data['created_at'] as Timestamp?)?.toDate();

                        final actor =
                        (data['actor_email'] ?? 'admin').toString();

                        final action =
                        (data['action'] ?? '').toString();

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history),
                          title: Text(action),
                          subtitle: Text(
                            '$actor • ${createdAt == null ? '-' : _fmt(createdAt)}',
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // 🕒 FORMATADOR DATA
  // =========================
  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';

  // =========================
  // 🎨 CARD UI MELHORADO
  // =========================
  Widget _card({
    required String title,
    required Widget child,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// =========================
// 👤 WIDGET USUÁRIO (ANTI-LOOP)
// =========================
class _UserNameCell extends StatefulWidget {
  final String userId;
  final Future<String> Function(String) getUserName;

  const _UserNameCell({
    required this.userId,
    required this.getUserName,
  });

  @override
  State<_UserNameCell> createState() => _UserNameCellState();
}

class _UserNameCellState extends State<_UserNameCell> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getUserName(widget.userId);
  }

  @override
  void didUpdateWidget(covariant _UserNameCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId) {
      _future = widget.getUserName(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('...');
        }
        return Text(snapshot.data!);
      },
    );
  }
}