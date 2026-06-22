import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/species_service.dart';

class AdminSpeciesPage extends StatefulWidget {
  const AdminSpeciesPage({super.key});

  @override
  State<AdminSpeciesPage> createState() => _AdminSpeciesPageState();
}

class _AdminSpeciesPageState extends State<AdminSpeciesPage> {
  final _species = SpeciesService();

  bool _showOnlyActive = true;
  bool _saving = false;

  Stream<List<Map<String, dynamic>>> _speciesStream() {
    return _species.watchSpecies();
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
                const SnackBar(content: Text('Preencha nome e descrição.')),
              );
              return;
            }

            setModalState(() => _saving = true);

            try {
              if (docId == null) {
                await _species.create(name: name, description: description);
              } else {
                await _species.update(
                  id: docId,
                  name: name,
                  description: description,
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
                SnackBar(content: Text('Erro ao salvar espécie: $e')),
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
    try {
      await _species.setActive(id: docId, active: nextActive);

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
        SnackBar(content: Text('Erro ao atualizar espécie: $e')),
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
    if (value is String && value.isNotEmpty) {
      final d = DateTime.tryParse(value)?.toLocal();
      if (d != null) return DateFormat('dd/MM/yyyy HH:mm').format(d);
    }
    return '-';
  }

  Widget _statusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0x1A1F5B3F) : const Color(0x1AF59E0B),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'Ativa' : 'Inativa',
        style: TextStyle(
          color: active ? const Color(0xFF1F5B3F) : const Color(0xFF92400E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
          child: StreamBuilder<List<Map<String, dynamic>>>(
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

              final all = snapshot.data ?? const <Map<String, dynamic>>[];
              final docs = _showOnlyActive
                  ? all.where((s) => s['active'] == true).toList()
                  : all;

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
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Atualizado em')),
                    DataColumn(label: Text('Ações')),
                  ],
                  rows: docs.map((data) {
                    final id = (data['id'] ?? '').toString();
                    final name = (data['name'] ?? '').toString();
                    final description = (data['description'] ?? '').toString();
                    final active = data['active'] == true;
                    final updatedAt = data['updated_at'];

                    return DataRow(
                      cells: [
                        DataCell(Text(name.isEmpty ? '-' : name)),
                        DataCell(_statusChip(active)),
                        DataCell(Text(_fmtDate(updatedAt))),
                        DataCell(
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _openSpeciesDialog(
                                  docId: id,
                                  initialName: name,
                                  initialDescription: description,
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Editar'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => _confirmDeactivateOrReactivate(
                                  docId: id,
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
