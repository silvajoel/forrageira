import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/analysis_request.dart';
import '../../services/i_forage_service.dart';
import '../../services/user_service.dart';
import 'admin_request_analysis_dialog.dart';

class AdminRequestsPage extends StatefulWidget {
  final String initialStatusFilter;
  final ValueChanged<String>? onStatusFilterChanged;

  const AdminRequestsPage({
    super.key,
    this.initialStatusFilter = 'todos',
    this.onStatusFilterChanged,
  });

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final _userService = UserService();
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, String> _userNameCache = {};

  late String _statusFilter;

  @override
  void initState() {
    super.initState();
    _statusFilter = _normalizeFilter(widget.initialStatusFilter);
  }

  @override
  void didUpdateWidget(covariant AdminRequestsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextFilter = _normalizeFilter(widget.initialStatusFilter);
    if (nextFilter != _statusFilter) {
      setState(() => _statusFilter = nextFilter);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _normalizeFilter(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'pending':
      case 'pendente':
      case 'pendentes':
        return 'pending';
      case 'completed':
      case 'concluida':
      case 'concluídas':
      case 'concluidas':
      case 'finalizado':
        return 'completed';
      default:
        return 'todos';
    }
  }

  String _normalizeStatus(String raw) {
    final value = raw.trim().toLowerCase();

    if (value.isEmpty) return 'pending';
    if (value == 'pending' || value == 'pendente') return 'pending';
    if (value == 'completed' || value == 'finalizado') return 'completed';

    return value;
  }

  int _statusPriority(String raw) {
    switch (_normalizeStatus(raw)) {
      case 'pending':
        return 0;
      case 'completed':
        return 1;
      default:
        return 2;
    }
  }

  String _statusLabel(String raw) {
    switch (_normalizeStatus(raw)) {
      case 'completed':
        return 'Concluída';
      default:
        return 'Pendente';
    }
  }

  Color _statusColor(String raw) {
    switch (_normalizeStatus(raw)) {
      case 'completed':
        return const Color(0xFF43A047);
      default:
        return const Color(0xFFFFB300);
    }
  }

  DateTime _createdAtOf(AnalysisRequest r) {
    return r.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _fmtDate(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd/MM/yyyy').format(value);
  }

  Future<void> _openRequest(String requestId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AdminRequestAnalysisDialog(requestId: requestId),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _changeStatusFilter(String value) {
    setState(() => _statusFilter = value);
    widget.onStatusFilterChanged?.call(value);
  }

  String _filterLabel(String value) {
    switch (value) {
      case 'pending':
        return 'Pendentes';
      case 'completed':
        return 'Concluídas';
      default:
        return 'Todas';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Solicitações',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _searchBar(),
        const SizedBox(height: 12),
        _statusFilters(),
        const SizedBox(height: 12),
        _card(
          title: 'Lista de solicitações',
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _userService.streamUsers(),
            builder: (context, usersSnapshot) {
              final users = usersSnapshot.data ?? const [];

              _userNameCache.clear();
              for (final u in users) {
                final id = (u['id'] ?? '').toString();
                if (id.isEmpty) continue;
                _userNameCache[id] = (u['name'] ?? '').toString();
              }

              return StreamBuilder<List<AnalysisRequest>>(
                stream: context.read<IForageService>().watchAllRequests(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Erro ao carregar solicitações: ${snapshot.error}',
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final all = snapshot.data ?? const <AnalysisRequest>[];
                  final q = _searchCtrl.text.trim().toLowerCase();

                  final filtered = all.where((r) {
                    final id = r.id.toLowerCase();
                    final name = r.name.toLowerCase();
                    final notes = r.notes.toLowerCase();
                    final userId = r.userId.toLowerCase();
                    final userName =
                        (_userNameCache[r.userId] ?? '').toLowerCase();
                    final status = _normalizeStatus(r.status);

                    final visible =
                        status == 'pending' || status == 'completed';
                    if (!visible) return false;

                    final matchStatus =
                        _statusFilter == 'todos' || status == _statusFilter;
                    if (!matchStatus) return false;
                    if (q.isEmpty) return true;

                    return id.contains(q) ||
                        name.contains(q) ||
                        notes.contains(q) ||
                        userId.contains(q) ||
                        userName.contains(q);
                  }).toList()
                    ..sort((a, b) {
                      final statusCompare = _statusPriority(a.status)
                          .compareTo(_statusPriority(b.status));
                      if (statusCompare != 0) return statusCompare;
                      return _createdAtOf(b).compareTo(_createdAtOf(a));
                    });

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Nenhuma solicitação encontrada para o filtro ${_filterLabel(_statusFilter).toLowerCase()}.',
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Data')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Usuário')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: filtered.map((r) {
                        final rawStatus = r.status;
                        final userId = r.userId;
                        final userName = _userNameCache[userId];

                        return DataRow(
                          cells: [
                            DataCell(Text(_fmtDate(r.createdAt))),
                            DataCell(
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _statusColor(rawStatus),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_statusLabel(rawStatus)),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                (userName ?? '').trim().isNotEmpty
                                    ? userName!
                                    : userId,
                              ),
                            ),
                            DataCell(
                              OutlinedButton.icon(
                                onPressed: () => _openRequest(r.id),
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: const Text('Abrir'),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statusFilters() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _filterChip('Todas', 'todos'),
        _filterChip('Pendentes', 'pending'),
        _filterChip('Concluídas', 'completed'),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _changeStatusFilter(value),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar por nome, usuário, observações ou id...',
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
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
