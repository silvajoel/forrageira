import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/user_service.dart';

class AdminTopBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onOpenSettings;

  const AdminTopBar({
    super.key,
    this.onOpenSettings,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<AdminTopBar> createState() => _AdminTopBarState();
}

class _AdminTopBarState extends State<AdminTopBar> {
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();

  String _nome = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _userService.getProfile(user.uid);
      if (!mounted) return;

      setState(() {
        _nome = (doc?['name'] ?? 'Admin').toString();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1F5B3F),
      elevation: 0,
      title: Row(
        children: const [
          Icon(Icons.eco, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'FORRAGEIRA • ADMIN',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 50),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  _nome,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            onSelected: (value) async {
              if (value == 'settings') {
                widget.onOpenSettings?.call();
              }
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/admin-login');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'settings',
                child: Text('Configurações'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Sair'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}