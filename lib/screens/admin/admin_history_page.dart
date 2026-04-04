import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/services/audit_log_service.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  final _audit = AuditLogService();

  @override
  Widget build(BuildContext context) {
    final forageService = context.read<IForageService>();

    return AdminShell(
      selectedMenu: 'historico',
      child: StreamBuilder<List<AnalysisRequest>>(
        stream: forageService.watchAllRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = (snapshot.data ?? []).where((e) => e.status == 'completed').toList();

          return ListView(
            children: [
              const Text('Histórico de Laudos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              _card(
                title: 'Análises finalizadas',
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Forrageira')),
                      DataColumn(label: Text('Usuário')),
                      DataColumn(label: Text('Espécie')),
                      DataColumn(label: Text('Finalizado em')),
                    ],
                    rows: history.map((r) {
                      final dt = r.reviewedAt == null ? '-' : _fmt(r.reviewedAt!);
                      return DataRow(cells: [
                        DataCell(Text(r.id)),
                        DataCell(Text(r.name)),
                        DataCell(Text(r.userId)),
                        DataCell(Text(r.speciesName ?? '-')),
                        DataCell(Text(dt)),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _card(
                title: 'Log do Admin (ações executadas)',
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _audit.watchRecent(),
                  builder: (context, logSnapshot) {
                    if (logSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final logs = logSnapshot.data?.docs ?? [];
                    if (logs.isEmpty) {
                      return const Text('Nenhum log encontrado.');
                    }
                    return Column(
                      children: logs.map((doc) {
                        final data = doc.data();
                        final createdAt = (data['created_at'] as Timestamp?)?.toDate();
                        final actor = (data['actor_email'] ?? 'admin').toString();
                        final action = (data['action'] ?? '').toString();
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.event_note),
                          title: Text(action),
                          subtitle: Text('$actor • ${createdAt == null ? '-' : _fmt(createdAt)}'),
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

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}
