import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String selected;
  const AdminSidebar({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF24302B),
      padding: const EdgeInsets.only(top: 14),
      child: ListView(
        children: [
          _item(context, Icons.home_outlined, 'Dashboard', '/admin', keyName: 'dashboard'),
          _item(context, Icons.hourglass_empty, 'Solicitações Pendentes', '/admin/requests', keyName: 'pendentes'),
          _item(context, Icons.inventory_2_outlined, 'Banco de Espécies', '/admin/species', keyName: 'banco'),
          _item(context, Icons.history, 'Histórico de Laudos', '/admin/history', keyName: 'historico'),
          _item(context, Icons.groups_outlined, 'Gestão de Clientes', '/admin/clients', keyName: 'clientes'),
          _item(context, Icons.settings_outlined, 'Configurações', '/admin/settings', keyName: 'config'),
          const Divider(color: Colors.white24),
          _logout(context),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String route, {required String keyName}) {
    final isSel = selected == keyName;
    final fg = isSel ? Colors.white : Colors.white70;
    final bg = isSel ? Colors.white12 : Colors.transparent;

    return InkWell(
      onTap: () => Navigator.pushReplacementNamed(context, route),
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logout(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushReplacementNamed(context, '/admin-login'),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.white70),
            SizedBox(width: 12),
            Text('Logout', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}