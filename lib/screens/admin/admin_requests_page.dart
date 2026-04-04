import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final searchCtrl = TextEditingController();

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forageService = context.read<IForageService>();

    return AdminShell(
      selectedMenu: 'pendentes',
      child: ListView(
        children: [
          _title('Solicitações Pendentes'),
          const SizedBox(height: 12),
          _searchBar(),
          const SizedBox(height: 12),
          _card(
            title: 'Lista de solicitações',
            child: StreamBuilder<List<AnalysisRequest>>(
              stream: forageService.watchAllRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                final pending = all.where((e) => e.status != 'completed').toList();
                final q = searchCtrl.text.trim().toLowerCase();
                final items = pending.where((r) {
                  if (q.isEmpty) return true;
                  return r.name.toLowerCase().contains(q) ||
                      r.userId.toLowerCase().contains(q) ||
                      r.id.toLowerCase().contains(q);
                }).toList();

                return _RequestsTable(
                  items: items,
                  onOpen: (id) =>
                      Navigator.pushNamed(context, '/admin/request', arguments: id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) =>
      Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: TextField(
        controller: searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar por nome, usuário ou id...',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _RequestsTable extends StatelessWidget {
  final List<AnalysisRequest> items;
  final void Function(String id) onOpen;

  const _RequestsTable({
    required this.items,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Forrageira')),
          DataColumn(label: Text('Usuário')),
          DataColumn(label: Text('Ações')),
        ],
        rows: items.map((e) {
          return DataRow(cells: [
            DataCell(_statusPill(e.status)),
            DataCell(Text(e.id)),
            DataCell(Text(_fmtDate(e.createdAt ?? DateTime.now()))),
            DataCell(Text(e.name)),
            DataCell(Text(e.userId)),
            DataCell(
              ElevatedButton(
                onPressed: () => onOpen(e.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F5B3F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Abrir'),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _statusPill(String status) {
    final isCompleted = status == 'completed';
    final text = isCompleted ? 'Finalizado' : 'Pendente';
    final dot = isCompleted ? const Color(0xFF43A047) : const Color(0xFFE53935);

    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(text),
    ]);
  }
}
