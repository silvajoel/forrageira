import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_request_analysis_dialog.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({super.key});

  @override
  State<AdminRequestsPage> createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, String> _userNameCache = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestsStream() {
    return _firestore
        .collection('analysis_requests')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream() {
    return _firestore.collection('users').snapshots();
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
        return 'Finalizado';
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

  DateTime _createdAtOf(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final createdAt = doc.data()['created_at'];
    if (createdAt is Timestamp) return createdAt.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _fmtDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return '-';
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Text(
          'Solicitacoes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _searchBar(),
        const SizedBox(height: 12),
        _card(
          title: 'Lista de solicitacoes',
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _usersStream(),
            builder: (context, usersSnapshot) {
              final userDocs = usersSnapshot.data?.docs ?? [];

              _userNameCache.clear();
              for (final doc in userDocs) {
                final data = doc.data();
                _userNameCache[doc.id] = (data['name'] ?? '').toString();
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _requestsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Erro ao carregar solicitacoes: ${snapshot.error}',
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  final q = _searchCtrl.text.trim().toLowerCase();

                  final filteredDocs = allDocs.where((doc) {
                    final data = doc.data();
                    final id = doc.id.toLowerCase();
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final notes =
                        (data['notes'] ?? '').toString().toLowerCase();
                    final userId =
                        (data['user_id'] ?? '').toString().toLowerCase();
                    final userName =
                        (_userNameCache[data['user_id']] ?? '').toLowerCase();
                    final status = _normalizeStatus(
                      (data['status'] ?? '').toString(),
                    );

                    final visible =
                        status == 'pending' || status == 'completed';
                    if (!visible) return false;
                    if (q.isEmpty) return true;

                    return id.contains(q) ||
                        name.contains(q) ||
                        notes.contains(q) ||
                        userId.contains(q) ||
                        userName.contains(q);
                  }).toList()
                    ..sort((a, b) {
                      final statusCompare = _statusPriority(
                        (a.data()['status'] ?? '').toString(),
                      ).compareTo(
                        _statusPriority((b.data()['status'] ?? '').toString()),
                      );
                      if (statusCompare != 0) return statusCompare;
                      return _createdAtOf(b).compareTo(_createdAtOf(a));
                    });

                  if (filteredDocs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhuma solicitacao encontrada.'),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Data')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Usuario')),
                        DataColumn(label: Text('Acoes')),
                      ],
                      rows: filteredDocs.map((doc) {
                        final data = doc.data();
                        final rawStatus = (data['status'] ?? '').toString();
                        final userId = (data['user_id'] ?? '').toString();
                        final userName = _userNameCache[userId];

                        return DataRow(
                          cells: [
                            DataCell(Text(_fmtDate(data['created_at']))),
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
                              IconButton(
                                tooltip: 'Abrir solicitacao',
                                onPressed: () => _openRequest(doc.id),
                                icon: const Icon(Icons.open_in_new),
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
          hintText: 'Buscar por nome, usuario, observacoes ou id...',
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
