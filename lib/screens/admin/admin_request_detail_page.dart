import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminRequestDetailPage extends StatefulWidget {
  final String requestId;

  const AdminRequestDetailPage({
    super.key,
    required this.requestId,
  });

  @override
  State<AdminRequestDetailPage> createState() => _AdminRequestDetailPageState();
}

class _AdminRequestDetailPageState extends State<AdminRequestDetailPage> {
  final _firestore = FirebaseFirestore.instance;
  final parecerCtrl = TextEditingController();

  String? especieId;
  bool _saving = false;

  @override
  void dispose() {
    parecerCtrl.dispose();
    careCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _loadRequest() async {
    final doc = await _firestore
        .collection('analysis_requests')
        .doc(widget.requestId)
        .get();

    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  Future<String> _loadUserName(String? userId) async {
    if (userId == null || userId.isEmpty) return '-';

    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return userId;

    final data = userDoc.data() ?? {};
    return (data['name'] ?? userId).toString();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadSpecies() async {
    final snap = await _firestore.collection('species').orderBy('name').get();
    return snap.docs;
  }

  String _fmtDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  Future<void> _finalizar() async {
    if (especieId == null || especieId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma espécie.')),
      );
      return;
    }

    if (parecerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um parecer.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _firestore.collection('analysis_requests').doc(widget.requestId).update({
        'status': 'completed',
        'species_id': especieId,
        'parecer': parecerCtrl.text.trim(),
        'completed_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação finalizada com sucesso.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao finalizar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F5B3F),
        foregroundColor: Colors.white,
        title: const Text('Detalhe da solicitação'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadRequest(),
        builder: (context, requestSnap) {
          if (requestSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (requestSnap.hasError) {
            return Center(
              child: Text('Erro ao carregar solicitação: ${requestSnap.error}'),
            );
          }

          final req = requestSnap.data;
          if (req == null) {
            return const Center(child: Text('Solicitação não encontrada.'));
          }

          final existingParecer = (req['parecer'] ?? '').toString();
          if (parecerCtrl.text.isEmpty && existingParecer.isNotEmpty) {
            parecerCtrl.text = existingParecer;
          }

          especieId ??= (req['species_id'] ?? '').toString().isNotEmpty
              ? (req['species_id'] ?? '').toString()
              : null;

          final imageUrl = (req['image_url'] ?? req['photo_url'] ?? req['image'] ?? '').toString();

          return FutureBuilder(
            future: Future.wait<dynamic>([
              _loadUserName((req['user_id'] ?? '').toString()),
              _loadSpecies(),
            ]),
            builder: (context, extraSnap) {
              if (extraSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (extraSnap.hasError) {
                return Center(
                  child: Text('Erro ao carregar detalhes complementares: ${extraSnap.error}'),
                );
              }

              final values = extraSnap.data!;
              final userName = values[0] as String;
              final speciesDocs = values[1] as List<QueryDocumentSnapshot<Map<String, dynamic>>>;

              if (especieId == null && speciesDocs.isNotEmpty) {
                especieId = speciesDocs.first.id;
              }

              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Análise ${req['id']}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: 'Dados enviados',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _kv('Nome', (req['name'] ?? '-').toString()),
                        _kv('Usuário', userName),
                        _kv('Data', _fmtDate(req['created_at'])),
                        _kv('Latitude', (req['latitude'] ?? '-').toString()),
                        _kv('Longitude', (req['longitude'] ?? '-').toString()),
                        const SizedBox(height: 8),
                        const Text(
                          'Observações:',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (req['notes'] ?? '-').toString(),
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          height: 260,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x22000000)),
                          ),
                          child: imageUrl.isEmpty
                              ? const Center(child: Text('Imagem não disponível'))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return const Center(
                                        child: Text('Não foi possível carregar a imagem'),
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: 'Resultado da análise',
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: especieId,
                          items: speciesDocs.map((doc) {
                            final data = doc.data();
                            final nome = (data['name'] ?? data['nome'] ?? doc.id).toString();
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(nome),
                            );
                          }).toList(),
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => especieId = value),
                          decoration: const InputDecoration(
                            labelText: 'Espécie identificada',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: parecerCtrl,
                          maxLines: 6,
                          enabled: !_saving,
                          decoration: const InputDecoration(
                            labelText: 'Parecer / Observações',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _finalizar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F5B3F),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Finalizar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
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

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$k:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
