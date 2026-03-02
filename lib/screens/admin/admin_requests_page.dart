import 'package:flutter/material.dart';
import '../../data/admin_store.dart';
import '../../data/models.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final store = AdminStore.instance;
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    store.addListener(_onChange);
  }

  @override
  void dispose() {
    store.removeListener(_onChange);
    searchCtrl.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final q = searchCtrl.text.trim().toLowerCase();
    final items = store.pendingRequests.where((r) {
      if (q.isEmpty) return true;
      return r.cliente.toLowerCase().contains(q) ||
          r.localidade.toLowerCase().contains(q) ||
          r.propriedade.toLowerCase().contains(q) ||
          r.id.toLowerCase().contains(q);
    }).toList();

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
            child: _RequestsTable(
              items: items,
              onOpen: (id) => Navigator.pushNamed(context, '/admin/request', arguments: id),
              onStart: (id) => store.startReview(id),
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
          hintText: 'Buscar por cliente, localidade, id...',
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
  final void Function(String id) onStart;

  const _RequestsTable({
    required this.items,
    required this.onOpen,
    required this.onStart,
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
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Propriedade')),
          DataColumn(label: Text('Localidade')),
          DataColumn(label: Text('Ações')),
        ],
        rows: items.map((e) {
          return DataRow(cells: [
            DataCell(_statusPill(e.status)),
            DataCell(Text(e.id)),
            DataCell(Text(_fmt(e.createdAt))),
            DataCell(Text(e.cliente)),
            DataCell(Text(e.propriedade)),
            DataCell(Text(e.localidade)),
            DataCell(Row(
              children: [
                TextButton(
                  onPressed: () => onStart(e.id),
                  child: const Text('Iniciar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => onOpen(e.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5B3F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text('Abrir'),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _statusPill(RequestStatus s) {
    final text = switch (s) {
      RequestStatus.pendente => 'Pendente',
      RequestStatus.emAnalise => 'Em análise',
      RequestStatus.finalizado => 'Finalizado',
    };
    final dot = switch (s) {
      RequestStatus.pendente => const Color(0xFFE53935),
      RequestStatus.emAnalise => const Color(0xFFFFB300),
      RequestStatus.finalizado => const Color(0xFF43A047),
    };

    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(text),
    ]);
  }
}