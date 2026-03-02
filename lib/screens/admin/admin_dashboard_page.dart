import 'package:flutter/material.dart';
import '../../data/admin_store.dart';
import '../../data/models.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
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
    final pendentes = store.pendingRequests;

    return AdminShell(
      selectedMenu: 'dashboard',
      child: ListView(
        children: [
          _searchBar(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _kpi(Icons.person_outline, 'Pendentes:', '${store.pendentesCount} análises'),
              _kpi(Icons.check_box_outlined, 'Concluídos hoje', '${store.concluidosHojeCount} análises'),
              _kpi(Icons.access_time, 'Tempo médio', _fmtDuration(store.tempoMedioMock)),
            ],
          ),
          const SizedBox(height: 16),
          _card(
            title: 'Fila de trabalho (pendentes)',
            child: _RequestsTable(
              items: pendentes,
              onOpen: (id) {
                Navigator.pushNamed(context, '/admin/request', arguments: id);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: const TextField(
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar por cliente ...',
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _kpi(IconData icon, String title, String value) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 34, color: const Color(0xFF1F5B3F)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.black54)),
          ],
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
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')} min';
  }
}

class _RequestsTable extends StatelessWidget {
  final List<AnalysisRequest> items;
  final void Function(String id) onOpen;

  const _RequestsTable({required this.items, required this.onOpen});

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
            DataCell(Text('${e.createdAt.day}/${e.createdAt.month}/${e.createdAt.year}')),
            DataCell(Text(e.cliente)),
            DataCell(Text(e.propriedade)),
            DataCell(Text(e.localidade)),
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