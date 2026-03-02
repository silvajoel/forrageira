import 'package:flutter/material.dart';
import '../../data/admin_store.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  final store = AdminStore.instance;

  @override
  void initState() {
    super.initState();
    store.addListener(_onChange);
  }

  @override
  void dispose() {
    store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final history = store.history;

    return AdminShell(
      selectedMenu: 'historico',
      child: ListView(
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
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('Espécie')),
                  DataColumn(label: Text('Finalizado em')),
                  DataColumn(label: Text('Admin')),
                ],
                rows: history.map((r) {
                  final especieNome = store.species.where((s) => s.id == r.especieId).map((s) => s.nome).firstOrNull ?? '-';
                  final dt = r.reviewedAt == null ? '-' : _fmt(r.reviewedAt!);
                  return DataRow(cells: [
                    DataCell(Text(r.id)),
                    DataCell(Text(r.cliente)),
                    DataCell(Text(especieNome)),
                    DataCell(Text(dt)),
                    DataCell(Text(r.reviewedBy ?? '-')),
                  ]);
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _card(
            title: 'Log do Admin (ações executadas)',
            child: Column(
              children: store.logs.take(20).map((l) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_note),
                  title: Text(l.action),
                  subtitle: Text('${l.admin} • ${_fmt(l.at)}'),
                );
              }).toList(),
            ),
          ),
        ],
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}