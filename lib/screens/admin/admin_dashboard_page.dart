import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final forageService = context.read<IForageService>();

    return AdminShell(
      selectedMenu: 'dashboard',
      child: StreamBuilder<List<AnalysisRequest>>(
        stream: forageService.watchAllRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          final pendentes = all.where((e) => e.status != 'completed').toList();
          final finalizados = all.where((e) => e.status == 'completed').toList();

          final now = DateTime.now();
          bool sameDay(DateTime a, DateTime b) =>
              a.year == b.year && a.month == b.month && a.day == b.day;
          final concluidosHoje = finalizados.where((e) {
            final d = e.reviewedAt;
            return d != null && sameDay(d, now);
          }).length;

          return ListView(
            children: [
              _searchBar(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _kpi(Icons.person_outline, 'Pendentes', '${pendentes.length} análises'),
                  _kpi(Icons.check_box_outlined, 'Concluídos hoje', '$concluidosHoje análises'),
                  _kpi(Icons.analytics_outlined, 'Total', '${all.length} análises'),
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
          );
        },
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
          DataColumn(label: Text('Forrageira')),
          DataColumn(label: Text('Usuário')),
          DataColumn(label: Text('Coordenadas')),
          DataColumn(label: Text('Ações')),
        ],
        rows: items.map((e) {
          return DataRow(cells: [
            DataCell(_statusPill(e.status)),
            DataCell(Text(e.id)),
            DataCell(Text(_fmtDate(e.createdAt))),
            DataCell(Text(e.name)),
            DataCell(Text(e.userId)),
            DataCell(Text(_fmtCoordinates(e.latitude, e.longitude))),
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

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _fmtCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

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
