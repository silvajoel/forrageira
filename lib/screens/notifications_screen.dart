import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forrageira/models/app_notification.dart';
import 'package:forrageira/services/app_notification_service.dart';
import 'package:forrageira/services/notification_service.dart';
import 'package:forrageira/services/user_service.dart';
import 'package:forrageira/theme/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = AppNotificationService();
  bool _markingAll = false;

  String _formatDate(DateTime date) {
    try {
      return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(date);
    } catch (_) {
      return "${date.day}/${date.month}/${date.year} "
          "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }
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
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
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
    final unread = notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: AppColors.greenLight,
      appBar: AppBar(
        backgroundColor: AppColors.greenDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.notifications_outlined, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Notificações',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed:
                  _markingAll ? null : () => _markAllAsRead(uid, isAdmin),
              icon: _markingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  : const Icon(Icons.done_all, color: Colors.white70, size: 18),
              label: const Text(
                'Marcar lidas',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          PopupMenuButton<String>(
            enabled: !_markingAll,
            icon: const Icon(Icons.more_vert, color: Colors.white70),
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
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return _NotificationCard(
                  item: item,
                  formatDate: _formatDate,
                  onTap: () async {
                    try {
                      await _service.markAsRead(item.id);
                    } catch (_) {}
                    final analysisId = item.analysisId;
                    if (analysisId == null || analysisId.isEmpty) return;
                    await NotificationService().openAnalysisFromNotification(
                      analysisId,
                    );
                  },
                  onMarkRead: () async {
                    try {
                      await _service.markAsRead(item.id);
                    } catch (_) {}
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.green.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none_outlined,
              size: 56,
              color: AppColors.green.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma notificação',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Você será avisado sobre suas análises aqui.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const _NotificationCard({
    required this.item,
    required this.formatDate,
    required this.onTap,
    required this.onMarkRead,
  });

  IconData get _icon {
    final title = item.title.toLowerCase();
    if (title.contains('recebida') || title.contains('enviada')) {
      return Icons.upload_file_outlined;
    }
    if (title.contains('concluída') || title.contains('finalizada')) {
      return Icons.check_circle_outline;
    }
    if (title.contains('nova análise') || title.contains('cadastrada')) {
      return Icons.science_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _iconColor(bool isRead) {
    if (isRead) return AppColors.gray;
    final title = item.title.toLowerCase();
    if (title.contains('concluída') || title.contains('finalizada')) {
      return Colors.green.shade700;
    }
    if (title.contains('nova análise') || title.contains('cadastrada')) {
      return AppColors.green;
    }
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              color: item.read ? Colors.white : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.read
                    ? Colors.transparent
                    : AppColors.green.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.read
                      ? Colors.black.withValues(alpha: 0.04)
                      : AppColors.green.withValues(alpha: 0.1),
                  blurRadius: item.read ? 4 : 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.read
                          ? AppColors.greenLight
                          : AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _icon,
                      color: _iconColor(item.read),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Conteúdo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: item.read
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (!item.read)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: item.read
                                ? AppColors.gray
                                : AppColors.textPrimary.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatDate(item.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.gray,
                              ),
                            ),
                            if (!item.read)
                              GestureDetector(
                                onTap: onMarkRead,
                                child: Text(
                                  'Marcar como lida',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
