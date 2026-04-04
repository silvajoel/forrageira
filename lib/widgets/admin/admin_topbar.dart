import 'package:cloud_firestore/cloud_firestore.dart';
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
      title: const Row(
        children: [
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

/// Sino com badge de não lidas para o painel admin.
class _AdminNotificationBell extends StatelessWidget {
  final String uid;
  const _AdminNotificationBell({required this.uid});

  @override
  Widget build(BuildContext context) {
    final service = AppNotificationService();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, profileSnap) {
        final isAdmin = UserService.isAdminRole(profileSnap.data?.data());

        return StreamBuilder<List<AppNotification>>(
          stream: service.watchAdminRoleNotifications(),
          builder: (context, adminSnap) {
            final adminItems = adminSnap.data ?? [];
            final unread = adminItems.where((n) => !n.read).length;

            return IconButton(
              tooltip: 'Notificações',
              onPressed: () => showNotificationsModal(context),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white),
                  if (unread > 0)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}