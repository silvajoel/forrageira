import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:forrageira/services/audit_log_service.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminSpeciesPage extends StatefulWidget {
  const AdminSpeciesPage({super.key});

  @override
  State<AdminSpeciesPage> createState() => _AdminSpeciesPageState();
}

class _AdminSpeciesPageState extends State<AdminSpeciesPage> {
  final _species = FirebaseFirestore.instance.collection('species');
  final _audit = AuditLogService();

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenu: 'banco',
      child: ListView(
        children: [
          Row(
            children: [
              const Text('Banco de Espécies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
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
              stream: _species.orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nome')),
                      DataColumn(label: Text('Descrição')),
                      DataColumn(label: Text('Ações')),
                    ],
                    rows: docs.map((d) {
                      final name = (d.data()['name'] ?? '').toString();
                      final description = (d.data()['description'] ?? '').toString();
                      return DataRow(cells: [
                        DataCell(Text(name)),
                        DataCell(SizedBox(width: 420, child: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis))),
                        DataCell(Row(
                          children: [
                            TextButton(
                              onPressed: () => _openSpeciesDialog(editId: d.id, nome: name, descricao: description),
                              child: const Text('Editar'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await _species.doc(d.id).delete();
                                await _audit.log(
                                  action: 'Excluiu especie',
                                  targetId: d.id,
                                  metadata: {'name': name},
                                );
                              },
                              child: const Text('Excluir'),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSpeciesDialog({String? editId, String? nome, String? descricao}) async {
    final nomeCtrl = TextEditingController(text: nome ?? '');
    final descCtrl = TextEditingController(text: descricao ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(editId == null ? 'Nova espécie' : 'Editar espécie'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Descrição', alignLabelWithHint: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final n = nomeCtrl.text.trim();
              final d = descCtrl.text.trim();
              if (n.isEmpty || d.isEmpty) return;

              if (editId == null) {
                await _species.add({
                  'name': n,
                  'description': d,
                  'created_at': FieldValue.serverTimestamp(),
                });
                await _audit.log(action: 'Cadastrou especie', metadata: {'name': n});
              } else {
                await _species.doc(editId).update({
                  'name': n,
                  'description': d,
                });
                await _audit.log(action: 'Editou especie', targetId: editId, metadata: {'name': n});
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
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
