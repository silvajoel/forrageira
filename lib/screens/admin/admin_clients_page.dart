import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/admin/admin_shell.dart';

class AdminClientsPage extends StatefulWidget {
  const AdminClientsPage({super.key});

  @override
  State<AdminClientsPage> createState() => _AdminClientsPageState();
}

class _AdminClientsPageState extends State<AdminClientsPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final TextEditingController _searchCtrl = TextEditingController();

  final ValueNotifier<String> _searchNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _roleFilterNotifier = ValueNotifier<String>('todos');

  bool _savingAction = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchNotifier.dispose();
    _roleFilterNotifier.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilters(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
        required String search,
        required String roleFilter,
      }) {
    final query = search.trim().toLowerCase();

    return docs.where((doc) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final role = (data['role'] ?? 'user').toString().toLowerCase();

      final matchSearch =
          query.isEmpty || name.contains(query) || email.contains(query);

      final matchRole = roleFilter == 'todos' || role == roleFilter;

      return matchSearch && matchRole;
    }).toList();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchNotifier.value = value;
    });
  }

  Future<void> _makeAdmin(String userId, Map<String, dynamic> userData) async {
    final name = (userData['name'] ?? 'este usuário').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined),
              SizedBox(width: 10),
              Text('Confirmar promoção'),
            ],
          ),
          content: Text(
            'Deseja realmente tornar "$name" um administrador?\n\n'
                'Esse usuário passará a ter acesso às funções administrativas do sistema.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
              label: const Text('Tornar admin'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() => _savingAction = true);

      await _db.collection('users').doc(userId).update({
        'role': 'admin',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário promovido para administrador com sucesso.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao tornar admin: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingAction = false);
      }
    }
  }

  Future<void> _toggleActive(String userId, Map<String, dynamic> userData) async {
    final isActive = userData['active'] == true;
    final name = (userData['name'] ?? 'este usuário').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Icon(isActive ? Icons.block_outlined : Icons.check_circle_outline),
              const SizedBox(width: 10),
              Text(isActive ? 'Desativar usuário' : 'Ativar usuário'),
            ],
          ),
          content: Text(
            isActive
                ? 'Deseja realmente desativar "$name"?'
                : 'Deseja realmente ativar "$name"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isActive ? 'Desativar' : 'Ativar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() => _savingAction = true);

      await _db.collection('users').doc(userId).update({
        'active': !isActive,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive
                ? 'Usuário desativado com sucesso.'
                : 'Usuário ativado com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingAction = false);
      }
    }
  }

  Future<void> _deleteUser(String userId, Map<String, dynamic> userData) async {
    final currentUid = _auth.currentUser?.uid;
    final name = (userData['name'] ?? 'este usuário').toString();

    if (userId == currentUid) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(Icons.person_off_outlined, color: Colors.orange),
                SizedBox(width: 10),
                Text('Ação não permitida'),
              ],
            ),
            content: const Text(
              'Você não pode excluir sua própria conta por esta tela.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      final hasAnalysis = await _userHasAnalysisRequests(userId);

      if (hasAnalysis) {
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('Exclusão não permitida'),
                ],
              ),
              content: const Text(
                'Este usuário já possui registros de análise vinculados e não pode ser excluído.\n\n'
                    'Nesse caso, apenas a inativação é permitida.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendi'),
                ),
              ],
            );
          },
        );

        return;
      }
    } catch (e) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 10),
                Text('Erro ao validar exclusão'),
              ],
            ),
            content: Text('Não foi possível validar os vínculos do usuário.\n\n$e'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );

      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 10),
              Text('Excluir usuário'),
            ],
          ),
          content: Text(
            'Deseja realmente excluir "$name"?\n\n'
                'Essa ação remove o documento do usuário no Firestore.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() => _savingAction = true);

      await _db.collection('users').doc(userId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário excluído com sucesso.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir usuário: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingAction = false);
      }
    }
  }

  Future<bool> _userHasAnalysisRequests(String userId) async {
    final analysisSnap = await _db
        .collection('analysis_requests')
        .where('user_id', isEqualTo: userId)
        .limit(1)
        .get();

    return analysisSnap.docs.isNotEmpty;
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Clientes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Gerencie usuários, permissões e status de acesso.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        if (_savingAction)
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
      ],
    );
  }

  Widget _buildFilters({
    required int totalFiltered,
    required String roleFilter,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou e-mail',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: roleFilter,
                    borderRadius: BorderRadius.circular(14),
                    items: const [
                      DropdownMenuItem(value: 'todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'user', child: Text('Clientes')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _roleFilterNotifier.value = value;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statChip(Icons.people_alt_outlined, '$totalFiltered usuário(s)'),
              const SizedBox(width: 10),
              _statChip(Icons.verified_user_outlined, 'Filtro: ${_labelRole(roleFilter)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _labelRole(String role) {
    switch (role) {
      case 'admin':
        return 'Admins';
      case 'user':
        return 'Clientes';
      default:
        return 'Todos';
    }
  }

  Widget _roleChip(String role) {
    final isAdmin = role.toLowerCase() == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Cliente',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isAdmin ? const Color(0xFF2E7D32) : const Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _statusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: active ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Ativo' : 'Inativo',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsCell(String userId, Map<String, dynamic> user) {
    final role = (user['role'] ?? 'user').toString().toLowerCase();
    final isAdmin = role == 'admin';
    final isActive = user['active'] == true;
    final isSelf = _auth.currentUser?.uid == userId;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ação de editar ainda não implementada nesta tela.'),
              ),
            );
          },
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Editar'),
        ),
        OutlinedButton.icon(
          onPressed: _savingAction ? null : () => _toggleActive(userId, user),
          icon: Icon(
            isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
            size: 18,
          ),
          label: Text(isActive ? 'Desativar' : 'Ativar'),
        ),
        if (!isAdmin)
          FilledButton.icon(
            onPressed: _savingAction ? null : () => _makeAdmin(userId, user),
            icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
            label: const Text('Tornar admin'),
          )
        else
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.verified_user_outlined, size: 18),
            label: const Text('Já é admin'),
          ),
        if (!isSelf)
          TextButton.icon(
            onPressed: _savingAction ? null : () => _deleteUser(userId, user),
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            label: const Text(
              'Excluir',
              style: TextStyle(color: Colors.red),
            ),
          )
        else
          Tooltip(
            message: 'Você não pode excluir sua própria conta.',
            child: TextButton.icon(
              onPressed: null,
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Somente inativar'),
            ),
          ),
      ],
    );
  }

  Widget _buildTable(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
          dataRowMinHeight: 76,
          dataRowMaxHeight: 96,
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('E-mail')),
            DataColumn(label: Text('Perfil')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: docs.map((doc) {
            final data = doc.data();
            final name = (data['name'] ?? '-').toString();
            final email = (data['email'] ?? '-').toString();
            final role = (data['role'] ?? 'user').toString();
            final active = data['active'] == true;

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                DataCell(Text(email)),
                DataCell(_roleChip(role)),
                DataCell(_statusChip(active)),
                DataCell(_actionsCell(doc.id, data)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildError(Object? error) {
    final text = error?.toString() ?? 'Erro desconhecido';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5C2C7)),
      ),
      child: Text(
        'Erro ao carregar usuários: $text',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenu: 'clientes',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _usersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildError(snapshot.error);
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              return ValueListenableBuilder<String>(
                valueListenable: _searchNotifier,
                builder: (context, searchValue, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _roleFilterNotifier,
                    builder: (context, roleFilterValue, __) {
                      final filteredDocs = _applyFilters(
                        docs,
                        search: searchValue,
                        roleFilter: roleFilterValue,
                      );

                      return Column(
                        children: [
                          _buildFilters(
                            totalFiltered: filteredDocs.length,
                            roleFilter: roleFilterValue,
                          ),
                          const SizedBox(height: 18),
                          if (filteredDocs.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 44, color: Color(0xFF9CA3AF)),
                                  SizedBox(height: 12),
                                  Text(
                                    'Nenhum usuário encontrado.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Tente ajustar a busca ou o filtro selecionado.',
                                    style: TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            )
                          else
                            _buildTable(filteredDocs),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}