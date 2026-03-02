import 'package:flutter/material.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';

class AdminShell extends StatelessWidget {
  final Widget child;
  final String selectedMenu;

  const AdminShell({
    super.key,
    required this.child,
    required this.selectedMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: const AdminTopBar(),
      drawer: isDesktop ? null : Drawer(child: AdminSidebar(selected: selectedMenu)),
      body: Row(
        children: [
          if (isDesktop) AdminSidebar(selected: selectedMenu),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}