import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminSpeciesPage extends StatefulWidget {
  const AdminSpeciesPage({super.key});

  @override
  State<AdminSpeciesPage> createState() => _AdminSpeciesPageState();
}

class _AdminSpeciesPageState extends State<AdminSpeciesPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _showOnlyActive = true;
  bool _saving = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _speciesStream() {
    return _firestore
        .collection('species')
        .orderBy('name')
        .snapshots();
  }

  Future<Map<String, dynamic>?> _getCurrentAdminProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> _writeLog({
    required String action,
    required String type,
    required String typeId,
    required String details,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final profile = await _getCurrentAdminProfile();
    final adminName = (profile?['name'] ?? 'Admin').toString();

    await _firestore.collection('logs').add({
      'action': action,
      'admin_id': uid,
      'admin_name': adminName,
      'created_at': FieldValue.serverTimestamp(),
      'details': details,
      'table': 'species',
      'type': type,
      'type_id': typeId,
    });
  }

  Future<void> _openSpeciesDialog({
    String? docId,
    String? initialName,
    String? initialDescription,
  }) async {
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final descCtrl = TextEditingController(text: initialDescription ?? '');

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> save() async {
            final name = nameCtrl.text.trim();
            final description = descCtrl.text.trim();

            if (name.isEmpty || description.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preencha nome e descrição.'),
                ),
              );
              return;
            }

            setModalState(() => _saving = true);

            try {
              final uid = _auth.currentUser?.uid ?? '';

              if (docId == null) {
                final docRef = await _firestore.collection('species').add({
                  'name': name,
                  'description': description,
                  'active': true,
                  'created_at': FieldValue.serverTimestamp(),
                  'created_by': uid,
                  'updated_at': FieldValue.serverTimestamp(),
                  'updated_by': uid,
                });

                await _writeLog(
                  action: 'Espécie criada',
                  type: 'create',
                  typeId: docRef.id,
                  details: 'Espécie "$name" cadastrada.',
                );
              } else {
                await _firestore.collection('species').doc(docId).update({
                  'name': name,
                  'description': description,
                  'updated_at': FieldValue.serverTimestamp(),
                  'updated_by': uid,
                });

                await _writeLog(
                  action: 'Espécie atualizada',
                  type: 'update',
                  typeId: docId,
                  details: 'Espécie "$name" atualizada.',
                );
              }

              if (!mounted) return;
              Navigator.of(context).pop();

              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    docId == null
                        ? 'Espécie criada com sucesso.'
                        : 'Espécie atualizada com sucesso.',
                  ),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao salvar espécie: $e'),
                ),
              );
            } finally {
              if (mounted) {
                setModalState(() => _saving = false);
              }
            }
          }

          return AlertDialog(
            title: Text(docId == null ? 'Nova espécie' : 'Editar espécie'),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _saving ? null : save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F5B3F),
                  foregroundColor: Colors.white,
                ),
                child: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSpeciesStatus({
    required String docId,
    required String name,
    required bool nextActive,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';

    try {
      await _firestore.collection('species').doc(docId).update({
        'active': nextActive,
        'updated_at': FieldValue.serverTimestamp(),
        'updated_by': uid,
      });

      await _writeLog(
        action: nextActive ? 'Espécie reativada' : 'Espécie desativada',
        type: 'update',
        typeId: docId,
        details: 'Espécie "$name" ficou ${nextActive ? 'ativa' : 'inativa'}.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextActive
                ? 'Espécie reativada com sucesso.'
                : 'Espécie desativada com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar espécie: $e'),
        ),
      );
    }
  }

  Future<void> _confirmDeactivateOrReactivate({
    required String docId,
    required String name,
    required bool isActive,
  }) async {
    final nextActive = !isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(nextActive ? 'Reativar espécie' : 'Desativar espécie'),
        content: Text(
          nextActive
              ? 'Deseja reativar a espécie "$name"?'
              : 'Deseja desativar a espécie "$name"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F5B3F),
              foregroundColor: Colors.white,
            ),
            child: Text(nextActive ? 'Reativar' : 'Desativar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _toggleSpeciesStatus(
        docId: docId,
        name: name,
        nextActive: nextActive,
      );
    }
  }

  String _fmtDate(dynamic value) {
    if (value is Timestamp) {
      final d = value.toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Banco de Espécies',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showOnlyActive = !_showOnlyActive;
                });
              },
              icon: Icon(
                _showOnlyActive ? Icons.visibility : Icons.visibility_off,
              ),
              label: Text(
                _showOnlyActive ? 'Mostrando ativas' : 'Mostrando todas',
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => _openSpeciesDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Nova espécie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F5B3F),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          title: 'Espécies cadastradas',
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _speciesStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Erro ao carregar espécies: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final allDocs = snapshot.data?.docs ?? [];
              final docs = _showOnlyActive
                  ? allDocs.where((doc) => doc.data()['active'] == true).toList()
                  : allDocs;

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nenhuma espécie cadastrada.'),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Nome')),
                    DataColumn(label: Text('Descrição')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Criado em')),
                    DataColumn(label: Text('Atualizado em')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data();
                    final name = (data['name'] ?? '').toString();
                    final description = (data['description'] ?? '').toString();
                    final active = data['active'] == true;
                    final createdAt = data['created_at'];
                    final updatedAt = data['updated_at'];

                    return DataRow(
                      cells: [
                        DataCell(Text(name.isEmpty ? '-' : name)),
                        DataCell(
                          SizedBox(
                            width: 420,
                            child: Text(
                              description.isEmpty ? '-' : description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0x1A1F5B3F)
                                  : const Color(0x1AF59E0B),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              active ? 'Ativa' : 'Inativa',
                              style: TextStyle(
                                color: active
                                    ? const Color(0xFF1F5B3F)
                                    : const Color(0xFF92400E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(_fmtDate(createdAt))),
                        DataCell(Text(_fmtDate(updatedAt))),
                        DataCell(
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _openSpeciesDialog(
                                  docId: doc.id,
                                  initialName: name,
                                  initialDescription: description,
                                ),
                                child: const Text('Editar'),
                              ),
                              TextButton(
                                onPressed: () => _confirmDeactivateOrReactivate(
                                  docId: doc.id,
                                  name: name,
                                  isActive: active,
                                ),
                                child: Text(active ? 'Desativar' : 'Reativar'),
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
          ),
        ),
      ],
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