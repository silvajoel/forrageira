import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forrageira/models/app_notification.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'package:forrageira/services/app_notification_service.dart';
import 'package:forrageira/services/user_service.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = AppNotificationService();
  bool _markingAll = false;

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _markAllAsRead(String uid, bool isAdmin) async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await _service.markAllAsRead(userId: uid, includeAdminRole: isAdmin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todas foram marcadas como lidas.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atualizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data?.data();
        final isAdmin = UserService.isAdminRole(profile);

        return StreamBuilder<List<AppNotification>>(
          stream: _service.watchUserNotifications(userId: uid),
          builder: (context, userSnapshot) {
            final userItems = userSnapshot.data ?? <AppNotification>[];

            if (!isAdmin) {
              return _scaffold(
                context,
                uid: uid,
                isAdmin: false,
                notifications: userItems,
              );
            }

            return StreamBuilder<List<AppNotification>>(
              stream: _service.watchAdminRoleNotifications(),
              builder: (context, adminSnapshot) {
                final adminItems = adminSnapshot.data ?? <AppNotification>[];
                final all = [...userItems, ...adminItems]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return _scaffold(
                  context,
                  uid: uid,
                  isAdmin: true,
                  notifications: all,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _scaffold(
    BuildContext context, {
    required String uid,
    required bool isAdmin,
    required List<AppNotification> notifications,
  }) {
    final forageService = context.read<IForageService>();
    final theme = Theme.of(context);
    final unread = notifications.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: _markingAll ? null : () => _markAllAsRead(uid, isAdmin),
              icon: _markingAll
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all),
              label: const Text('Marcar lidas'),
            ),
          PopupMenuButton<String>(
            enabled: !_markingAll,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all',
                child: ListTile(
                  leading: Icon(Icons.done_all),
                  title: Text('Marcar todas como lidas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Sobre limpar notificações'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'mark_all') {
                await _markAllAsRead(uid, isAdmin);
              } else if (value == 'help' && mounted) {
                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Limpar notificações'),
                    content: const Text(
                      'Para remover documentos do Firestore seria preciso alterar as regras '
                      '(hoje delete em app_notifications está desabilitado). '
                      'Use "Marcar lidas" para zerar o contador e esvaziar a caixa de não lidas.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('Nenhuma notificação.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: item.read
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                      : theme.colorScheme.primary.withValues(alpha: 0.07),
                  child: InkWell(
                    onTap: () async {
                      try {
                        await _service.markAsRead(item.id);
                      } catch (_) {}
                      final analysisId = item.analysisId;
                      if (analysisId == null || analysisId.isEmpty) return;
                      final analysis = await forageService.getById(analysisId);
                      if (!context.mounted) return;
                      final mainScreen = context.findAncestorStateOfType<MainScreenState>();
                      mainScreen?.openAnalysisDetail(analysis);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            item.read ? Icons.notifications_none : Icons.notifications_active,
                            color: item.read ? theme.disabledColor : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(item.message),
                                const SizedBox(height: 6),
                                Text(
                                  _formatDate(item.createdAt),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (!item.read)
                            IconButton(
                              tooltip: 'Marcar como lida',
                              icon: const Icon(Icons.check_circle_outline),
                              onPressed: () async {
                                try {
                                  await _service.markAsRead(item.id);
                                } catch (_) {}
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
