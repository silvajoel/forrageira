import 'package:flutter/material.dart';

import '../../widgets/admin/admin_shell.dart';
import 'admin_clients_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_history_page.dart';
import 'admin_requests_page.dart';
import 'admin_settings_page.dart';
import 'admin_species_page.dart';

class AdminHomePage extends StatefulWidget {
  final String initialMenu;

  const AdminHomePage({
    super.key,
    this.initialMenu = 'dashboard',
  });

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late String _selectedMenu;

  @override
  void initState() {
    super.initState();
    _selectedMenu = _normalizeMenu(widget.initialMenu);
  }

  void _handleMenuSelected(String menu) {
    final normalized = _normalizeMenu(menu);
    if (_selectedMenu == normalized) return;
    setState(() => _selectedMenu = normalized);
  }

  String _normalizeMenu(String value) {
    switch (value) {
      case 'dashboard':
      case 'pendentes':
      case 'banco':
      case 'historico':
      case 'clientes':
      case 'config':
        return value;
      default:
        return 'dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedMenu: _selectedMenu,
      onMenuSelected: _handleMenuSelected,
      onOpenSettings: () => _handleMenuSelected('config'),
      child: IndexedStack(
        index: _menuIndex(_selectedMenu),
        children: const [
          AdminDashboardPage(),
          AdminRequestsPage(),
          AdminSpeciesPage(),
          AdminHistoryPage(),
          AdminClientsPage(),
          AdminSettingsPage(),
        ],
      ),
    );
  }

  int _menuIndex(String menu) {
    switch (menu) {
      case 'dashboard':
        return 0;
      case 'pendentes':
        return 1;
      case 'banco':
        return 2;
      case 'historico':
        return 3;
      case 'clientes':
        return 4;
      case 'config':
        return 5;
      default:
        return 0;
    }
  }
}
