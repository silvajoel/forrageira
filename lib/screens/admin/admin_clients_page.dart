import 'package:flutter/material.dart';
import '../../data/admin_store.dart';
import '../../widgets/admin/admin_shell.dart';

class AdminClientsPage extends StatefulWidget {
  const AdminClientsPage({super.key});

  @override
  State<AdminClientsPage> createState() => _AdminClientsPageState();
}

class _AdminClientsPageState extends State<AdminClientsPage> {
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
      selectedMenu: 'clientes',
      child: ListView(
        children: [
          _header(context),
          const SizedBox(height: 12),
          _card(
            title: 'Clientes',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('E-mail')),
                  DataColumn(label: Text('Ativo')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: store.clients.map((c) {
                  return DataRow(cells: [
                    DataCell(Text(c.nome)),
                    DataCell(Text(c.email)),
                    DataCell(Icon(c.ativo ? Icons.check_circle : Icons.cancel, color: c.ativo ? Colors.green : Colors.red)),
                    DataCell(Row(
                      children: [
                        TextButton(
                          onPressed: () => _openClientDialog(editId: c.id, nome: c.nome, email: c.email, ativo: c.ativo),
                          child: const Text('Editar'),
                        ),
                        TextButton(
                          onPressed: () => store.updateClient(c.id, nome: c.nome, email: c.email, ativo: !c.ativo),
                          child: Text(c.ativo ? 'Desativar' : 'Ativar'),
                        ),
                        TextButton(
                          onPressed: () => _confirmDelete(c.id),
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

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Text('Gestão de Clientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {
            // mock: depois vira "criar admin"
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Criar novo admin (mock)')),
            );
          },
          icon: const Icon(Icons.admin_panel_settings_outlined),
          label: const Text('Criar novo admin'),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => _openClientDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Novo cliente'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F5B3F),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir cliente'),
        content: const Text('Tem certeza que deseja excluir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (ok == true) store.deleteClient(id);
  }

  Future<void> _openClientDialog({String? editId, String? nome, String? email, bool? ativo}) async {
    final nomeCtrl = TextEditingController(text: nome ?? '');
    final emailCtrl = TextEditingController(text: email ?? '');
    bool active = ativo ?? true;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(editId == null ? 'Novo cliente' : 'Editar cliente'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'E-mail')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Ativo'),
                    const Spacer(),
                    Switch(value: active, onChanged: (v) => setLocal(() => active = v)),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final n = nomeCtrl.text.trim();
                final e = emailCtrl.text.trim();
                if (n.isEmpty || e.isEmpty) return;

                if (editId == null) {
                  store.addClient(n, e);
                } else {
                  store.updateClient(editId, nome: n, email: e, ativo: active);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            )
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