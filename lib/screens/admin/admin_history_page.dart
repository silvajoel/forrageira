import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHistoryPage extends StatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  State<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends State<AdminHistoryPage> {
  final _firestore = FirebaseFirestore.instance;

  static const _green = Color(0xFF1F5B3F);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _surface = Color(0xFFF7F9FB);
  static const _border = Color(0x14000000);

  // PAGINAÇÃO
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 10;

  // CACHE DE USUÁRIOS
  final Map<String, String> _userNameCache = {};

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  // 🔥 PAGINAÇÃO FIRESTORE
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    Query<Map<String, dynamic>> query = _firestore
        .collection('analysis_requests')
        .where('status', isEqualTo: 'completed')
        .orderBy('completed_at', descending: true)
        .limit(_limit);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
      _docs.addAll(snapshot.docs);
    }

    if (snapshot.docs.length < _limit) {
      _hasMore = false;
    }

    setState(() => _isLoading = false);
  }

  // 👤 NOME DO USUÁRIO
  Future<String> _fetchUserName(String uid) async {
    if (uid.isEmpty) return 'Usuário';

    if (_userNameCache.containsKey(uid)) {
      return _userNameCache[uid]!;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      final name = (data?['name'] ??
          data?['display_name'] ??
          data?['email'] ??
          'Usuário')
          .toString();

      _userNameCache[uid] = name;
      return name;
    } catch (_) {
      return 'Usuário';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history, color: _green),
              ),
              const SizedBox(width: 12),
              const Text('Histórico de Laudos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          // 🔥 ANÁLISES PAGINADAS
          _card(
            icon: Icons.check_circle_outline,
            title: 'Análises finalizadas',
            child: Column(
              children: [
                if (_docs.isEmpty && _isLoading) _loading(),

                if (_docs.isEmpty && !_isLoading)
                  _emptyBox('Nenhuma análise encontrada'),

                if (_docs.isNotEmpty)
                  _AnalysisTable(
                    docs: _docs,
                    fetchUserName: _fetchUserName,
                  ),

                const SizedBox(height: 12),

                if (_hasMore)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loadMore,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Carregar mais'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // LOGS (mantido)
          _card(
            icon: Icons.list_alt,
            title: 'Logs',
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('logs')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return _loading();

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) return _emptyBox('Nenhum log');

                return Column(
                  children: docs
                      .map((d) => _LogTile(data: d.data()))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: _green),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }

  Widget _loading() => const Padding(
    padding: EdgeInsets.all(24),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _emptyBox(String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(text),
  );
}

// ================= TABLE =================

class _AnalysisTable extends StatelessWidget {
  const _AnalysisTable({
    required this.docs,
    required this.fetchUserName,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final Future<String> Function(String uid) fetchUserName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: docs
          .map((doc) => _AnalysisRow(
        doc: doc,
        fetchUserName: fetchUserName,
      ))
          .toList(),
    );
  }
}

// ================= ROW =================

class _AnalysisRow extends StatefulWidget {
  const _AnalysisRow({
    required this.doc,
    required this.fetchUserName,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final Future<String> Function(String uid) fetchUserName;

  @override
  State<_AnalysisRow> createState() => _AnalysisRowState();
}

class _AnalysisRowState extends State<_AnalysisRow> {
  late Future<String> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void didUpdateWidget(covariant _AnalysisRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.doc.id != widget.doc.id) {
      _loadUser();
    }
  }

  void _loadUser() {
    final uid = widget.doc.data()['user_id'] ?? '';
    _userNameFuture = widget.fetchUserName(uid);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data();

    return ListTile(
      title: FutureBuilder<String>(
        future: _userNameFuture,
        builder: (_, snap) =>
            Text(snap.data ?? 'Carregando...'),
      ),
      subtitle: Text(data['species_name'] ?? '-'),
      trailing: Text(
        data['completed_at'] is Timestamp
            ? (data['completed_at'] as Timestamp)
            .toDate()
            .toString()
            : '-',
      ),
    );
  }
}

// ================= LOG =================

class _LogTile extends StatelessWidget {
  const _LogTile({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(data['action'] ?? '-'),
      subtitle: Text(data['actor_email'] ?? '-'),
    );
  }
}