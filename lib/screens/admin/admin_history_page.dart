import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Histórico de Laudos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),

        _card(
          title: 'Análises finalizadas',
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('analysis_requests')
                .where('status', isEqualTo: 'completed')
                .orderBy('completed_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erro ao carregar análises: ${snapshot.error}'),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma análise finalizada encontrada.'),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Usuário')),
                    DataColumn(label: Text('Espécie')),
                    DataColumn(label: Text('Finalizado em')),
                    DataColumn(label: Text('Admin')),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data();
                    final userName = (data['user_name'] ?? data['client_name'] ?? '-').toString();
                    final speciesName = (data['species_name'] ?? data['species'] ?? '-').toString();
                    final adminName = (data['reviewed_by_name'] ?? data['completed_by_name'] ?? '-').toString();

                    final completedAt = data['completed_at'];
                    final completedText = completedAt is Timestamp
                        ? _fmt(completedAt.toDate())
                        : '-';

                    return DataRow(
                      cells: [
                        DataCell(Text(doc.id)),
                        DataCell(Text(userName)),
                        DataCell(Text(speciesName)),
                        DataCell(Text(completedText)),
                        DataCell(Text(adminName)),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        _card(
          title: 'Log do Admin (ações executadas)',
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('logs')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erro ao carregar logs: ${snapshot.error}'),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhum log encontrado.'),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final action = (data['action'] ?? '-').toString();
                  final admin = (data['admin_name'] ?? '-').toString();
                  final details = (data['details'] ?? '').toString();
                  final table = (data['table'] ?? '').toString();
                  final type = (data['type'] ?? '').toString();

                  final createdAt = data['created_at'];
                  final when = createdAt is Timestamp
                      ? _fmt(createdAt.toDate())
                      : '-';

                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.event_note),
                    title: Text(action),
                    subtitle: Text(
                      '$admin • $when'
                          '${table.isNotEmpty ? ' • $table' : ''}'
                          '${type.isNotEmpty ? ' • $type' : ''}'
                          '${details.isNotEmpty ? '\n$details' : ''}',
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _fmt(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _card({required String title, required Widget child}) {
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
