import 'package:flutter/material.dart';
import '../../data/admin_store.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminSpeciesPage extends StatefulWidget {
  const AdminSpeciesPage({super.key});

  @override
  State<AdminSpeciesPage> createState() => _AdminSpeciesPageState();
}

class _AdminSpeciesPageState extends State<AdminSpeciesPage> {
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('Descrição')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: store.species.map((s) {
                  return DataRow(cells: [
                    DataCell(Text(s.nome)),
                    DataCell(SizedBox(width: 420, child: Text(s.descricao, maxLines: 2, overflow: TextOverflow.ellipsis))),
                    DataCell(Row(
                      children: [
                        TextButton(
                          onPressed: () => _openSpeciesDialog(editId: s.id, nome: s.nome, descricao: s.descricao),
                          child: const Text('Editar'),
                        ),
                        TextButton(
                          onPressed: () => store.deleteSpecies(s.id),
                          child: const Text('Excluir'),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
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
            onPressed: () {
              final n = nomeCtrl.text.trim();
              final d = descCtrl.text.trim();
              if (n.isEmpty || d.isEmpty) return;

              if (editId == null) {
                store.addSpecies(n, d);
              } else {
                store.updateSpecies(editId, nome: n, descricao: d);
              }
              Navigator.pop(context);
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