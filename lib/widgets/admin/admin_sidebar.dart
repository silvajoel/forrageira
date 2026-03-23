import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSidebar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const AdminSidebar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF24302B),
      padding: const EdgeInsets.only(top: 14),
      child: ListView(
        children: [
          _item(Icons.home_outlined, 'Dashboard', 'dashboard'),
          _item(Icons.hourglass_empty, 'Solicitações Pendentes', 'pendentes'),
          _item(Icons.inventory_2_outlined, 'Banco de Espécies', 'banco'),
          _item(Icons.history, 'Histórico de Laudos', 'historico'),
          _item(Icons.groups_outlined, 'Gestão de Clientes', 'clientes'),
          _item(Icons.settings_outlined, 'Configurações', 'config'),
          const Divider(color: Colors.white24),
          _logout(context),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, String keyName) {
    final isSel = selected == keyName;
    final fg = isSel ? Colors.white : Colors.white70;
    final bg = isSel ? Colors.white12 : Colors.transparent;

    return InkWell(
      onTap: () {
        if (!isSel) onSelect(keyName);
      },
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logout(BuildContext context) {
    return InkWell(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/admin-login',
          (route) => false,
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.white70),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
