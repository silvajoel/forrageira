import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forrageira/models/app_notification.dart';
import 'package:forrageira/services/app_notification_service.dart';
import 'package:forrageira/services/user_service.dart';
import 'package:forrageira/widgets/notifications_modal.dart';

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onOpenSettings;

  const AdminTopBar({super.key, this.onOpenSettings});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
        if (user != null) _AdminNotificationBell(uid: user.uid),

        if (user != null)
          StreamBuilder<Map<String, dynamic>?>(
            stream: UserService().streamProfile(user.uid),
            builder: (context, snapshot) {
              String nome = 'Admin';

              final data = snapshot.data;
              if (data != null) {
                nome = (data['name'] ?? 'Admin').toString();
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: PopupMenuButton<String>(
                  offset: const Offset(0, 50),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(nome, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/admin-login');
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'logout', child: Text('Sair')),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _AdminNotificationBell extends StatelessWidget {
  final String uid;

  const _AdminNotificationBell({required this.uid});

  @override
  Widget build(BuildContext context) {
    final service = AppNotificationService();

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
  }
}