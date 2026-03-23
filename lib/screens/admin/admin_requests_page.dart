import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

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
  final Map<String, String> _locationCache = {};

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
    final s = raw.trim().toLowerCase();

    if (s.isEmpty) return 'pending';
    if (s == 'pending' || s == 'pendente') return 'pending';
    if (s == 'completed' || s == 'finalizado') return 'completed';

    return s;
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

  String _fmtDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    return '-';
  }

  Future<String> _resolveLocation(
      dynamic latitude,
      dynamic longitude,
      ) async {
    final double? lat = _toDouble(latitude);
    final double? lng = _toDouble(longitude);

    if (lat == null || lng == null) return '-';

    final key = '$lat,$lng';
    if (_locationCache.containsKey(key)) {
      return _locationCache[key]!;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isEmpty) {
        _locationCache[key] = '$lat, $lng';
        return _locationCache[key]!;
      }

      final p = placemarks.first;

      final parts = <String>[
        if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
        if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
        if ((p.administrativeArea ?? '').trim().isNotEmpty)
          p.administrativeArea!.trim(),
      ];

      final text = parts.isNotEmpty ? parts.join(' - ') : '$lat, $lng';
      _locationCache[key] = text;
      return text;
    } catch (_) {
      _locationCache[key] = '$lat, $lng';
      return _locationCache[key]!;
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
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
          'Solicitações Pendentes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _searchBar(),
        const SizedBox(height: 12),
        _card(
          title: 'Lista de solicitações',
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

                    final visible = status == 'pending' ||
                        status == 'completed';

                    if (!visible) return false;
                    if (q.isEmpty) return true;

                    return id.contains(q) ||
                        name.contains(q) ||
                        notes.contains(q) ||
                        userId.contains(q) ||
                        userName.contains(q);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhuma solicitação encontrada.'),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [

                        DataColumn(label: Text('Status')),
                        //DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Data')),
                        DataColumn(label: Text('Nome')),
                        DataColumn(label: Text('Usuário')),
                        DataColumn(label: Text('Local')),
                        DataColumn(label: Text('Observações')),
                        DataColumn(label: Text('Ações')),


                      ],
                      rows: filteredDocs.map((doc) {
                        final data = doc.data();
                        final rawStatus = (data['status'] ?? '').toString();
                        final name = (data['name'] ?? '').toString();
                        final userId = (data['user_id'] ?? '').toString();
                        final userName = _userNameCache[userId];
                        final notes = (data['notes'] ?? '').toString();

                        return DataRow(
                          cells: [
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
                            //DataCell(Text(doc.id)),
                            DataCell(Text(_fmtDate(data['created_at']))),
                            DataCell(Text(name.isEmpty ? '-' : name)),
                            DataCell(
                              Text(
                                (userName ?? '').trim().isNotEmpty
                                    ? userName!
                                    : userId,
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 260,
                                child: FutureBuilder<String>(
                                  future: _resolveLocation(
                                    data['latitude'],
                                    data['longitude'],
                                  ),
                                  builder: (context, locSnap) {
                                    if (locSnap.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Text('Carregando...');
                                    }
                                    return Text(
                                      locSnap.data ?? '-',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 240,
                                child: Text(
                                  notes.isEmpty ? '-' : notes,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: _normalizeStatus(rawStatus) == 'completed'
                                        ? 'Visualizar análise finalizada'
                                        : 'Analisar solicitação',
                                    onPressed: () => _openRequest(doc.id),
                                    icon: Icon(
                                      _normalizeStatus(rawStatus) == 'completed'
                                          ? Icons.visibility_outlined
                                          : Icons.search,
                                    ),
                                  ),
                                  if (_normalizeStatus(rawStatus) == 'completed')
                                    const Text(
                                      'Bloqueada',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
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
          hintText: 'Buscar por nome, observações, usuário ou id...',
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