import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:forrageira/models/app_notification.dart';
import 'package:forrageira/screens/admin/admin_request_analysis_dialog.dart';
import 'package:forrageira/services/app_notification_service.dart';
import 'package:forrageira/services/notification_service.dart';
import 'package:forrageira/services/user_service.dart';
import 'package:forrageira/theme/app_colors.dart';

/// Abre o painel de notificações como um overlay/modal lateral.
/// Funciona tanto no web (sem BottomNavigation) quanto no mobile.
void showNotificationsModal(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar notificações',
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const _NotificationsOverlay(),
    transitionBuilder: (_, anim, __, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
      return SlideTransition(position: slide, child: child);
    },
  );
}

class _NotificationsOverlay extends StatefulWidget {
  const _NotificationsOverlay();

  @override
  State<_NotificationsOverlay> createState() => _NotificationsOverlayState();
}

class _NotificationsOverlayState extends State<_NotificationsOverlay> {
  final _service = AppNotificationService();
  final _userService = UserService();
  bool _markingAll = false;

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _markAllAsRead(String uid, bool isAdmin) async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await _service.markAllAsRead(userId: uid, includeAdminRole: isAdmin);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final screenWidth = MediaQuery.of(context).size.width;
    // Painel lateral em telas grandes, tela cheia em mobile
    final panelWidth = screenWidth >= 600 ? 380.0 : screenWidth;

    if (uid == null) return const SizedBox();

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: panelWidth,
          height: double.infinity,
          color: AppColors.greenLight,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  color: AppColors.greenDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Notificações',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white70, size: 20),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Fechar',
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: StreamBuilder<Map<String, dynamic>?>(
                    stream: _userService.streamProfile(uid),
                    builder: (context, profileSnap) {
                      final profile = profileSnap.data;
                      final isAdmin = UserService.isAdminRole(profile);

                      return StreamBuilder<List<AppNotification>>(
                        stream: _service.watchUserNotifications(userId: uid),
                        builder: (context, userSnap) {
                          final userItems = userSnap.data ?? [];

                          if (!isAdmin) {
                            return _body(
                              context,
                              uid: uid,
                              isAdmin: false,
                              notifications: userItems,
                            );
                          }

                          return StreamBuilder<List<AppNotification>>(
                            stream: _service.watchAdminRoleNotifications(),
                            builder: (context, adminSnap) {
                              final adminItems = adminSnap.data ?? [];
                              final all = [...userItems, ...adminItems]..sort(
                                  (a, b) => b.createdAt.compareTo(a.createdAt));
                              return _body(
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required String uid,
    required bool isAdmin,
    required List<AppNotification> notifications,
  }) {
    final unread = notifications.where((n) => !n.read).length;

    return Column(
      children: [
        // Barra de ações
        if (unread > 0)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    '$unread não lida${unread > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed:
                      _markingAll ? null : () => _markAllAsRead(uid, isAdmin),
                  icon: _markingAll
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.done_all, size: 16),
                  label: const Text('Marcar lidas',
                      style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.green),
                ),
              ],
            ),
          ),

        // Lista
        Expanded(
          child: notifications.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return _NotifTile(
                      item: item,
                      formatDate: _formatDate,
                      onTap: () async {
                        try {
                          await _service.markAsRead(item.id);
                        } catch (_) {}

                        final analysisId = item.analysisId;
                        if (analysisId == null || analysisId.isEmpty) return;

                        if (isAdmin) {
                          if (!context.mounted) return;
                          await showDialog<bool>(
                            context: context,
                            barrierDismissible: true,
                            builder: (_) => AdminRequestAnalysisDialog(
                                requestId: analysisId),
                          );
                          return;
                        }

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        await NotificationService()
                            .openAnalysisFromNotification(analysisId);
                      },
                      onMarkRead: () async {
                        try {
                          await _service.markAsRead(item.id);
                        } catch (_) {}
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 48,
            color: AppColors.green.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma notificação',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Você será avisado sobre suas análises aqui.',
            style: TextStyle(fontSize: 13, color: AppColors.gray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final AppNotification item;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const _NotifTile({
    required this.item,
    required this.formatDate,
    required this.onTap,
    required this.onMarkRead,
  });

  IconData get _icon {
    final t = item.title.toLowerCase();
    if (t.contains('recebida') || t.contains('enviada')) {
      return Icons.upload_file_outlined;
    }
    if (t.contains('concluida') ||
        t.contains('finalizada') ||
        t.contains('conclu')) {
      return Icons.check_circle_outline;
    }
    if (t.contains('nova analise') ||
        t.contains('cadastrada') ||
        t.contains('analise')) {
      return Icons.science_outlined;
    }
    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.read
                    ? Colors.transparent
                    : AppColors.green.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.read
                          ? AppColors.greenLight
                          : AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _icon,
                      size: 20,
                      color: item.read ? AppColors.gray : AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (!item.read)
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.message,
                          style: TextStyle(
                            fontSize: 12,
                            color: item.read
                                ? AppColors.gray
                                : AppColors.textPrimary.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formatDate(item.createdAt),
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.gray),
                            ),
                            if (!item.read)
                              GestureDetector(
                                onTap: onMarkRead,
                                child: Text(
                                  'Marcar lida',
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
