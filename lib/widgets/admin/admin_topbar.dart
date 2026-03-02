import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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

        if (user != null)
          StreamBuilder(
            stream: UserService().streamProfile(user.uid),
            builder: (context, snapshot) {
              String nome = 'Admin';

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data();
                nome = data?['name'] ?? 'Admin';
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        nome,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  onSelected: (value) async {
                    if (value == 'settings') {
                      Navigator.pushNamed(context, '/admin-config');
                    }
                    if (value == 'logout') {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/admin-login');
                      }
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
              );
            },
          ),
      ],
    );
  }
}