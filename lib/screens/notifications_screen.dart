import 'package:flutter/material.dart';
import 'package:forrageira/models/app_notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // MOCK (depois você liga com backend)
    final List<AppNotification> notifications = [
      AppNotification(
        id: '1',
        title: 'Análise finalizada',
        message: 'Sua análise foi concluída com sucesso.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: '2',
        title: 'Nova análise em andamento',
        message: 'Sua solicitação está em análise.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
      ),
      body: notifications.isEmpty
          ? const Center(
        child: Text("Nenhuma notificação."),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.read
                  ? Colors.grey.shade100
                  : theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  item.read
                      ? Icons.notifications_none
                      : Icons.notifications,
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
              ],
            ),
          );
        },
      ),
    );
  }
}