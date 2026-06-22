import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:forrageira/services/pending_analysis_queue_service.dart';
import 'package:forrageira/widgets/notification_bell_button.dart';
import 'package:provider/provider.dart';

import '../widgets/analysis_item.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Em an\u00e1lise';
      case 'completed':
        return 'Finalizado';
      case 'queued_offline':
        return 'Aguardando internet';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} '
        '${date.day}/${date.month}/${date.year}';
  }

  List<AnalysisRequest> _buildOfflineAnalyses(
    PendingAnalysisQueueService queueService,
    String userId,
  ) {
    if (userId.isEmpty) return const [];

    return queueService.itemsForUser(userId).map((item) {
      return AnalysisRequest(
        id: 'offline:${item.localId}',
        name: item.name,
        notes: item.notes,
        userId: item.userId,
        latitude: item.latitude,
        longitude: item.longitude,
        status: 'queued_offline',
        imageUrls: item.imagePaths,
        createdAt: item.createdAt,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forageService = context.read<IForageService>();
    final queueService = context.watch<PendingAnalysisQueueService>();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final offlineItems = _buildOfflineAnalyses(queueService, userId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.analytics),
            SizedBox(width: 8),
            Text('Minhas análises'),
          ],
        ),
        actions: [
          if (userId.isNotEmpty) NotificationBellButton(userId: userId),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Minhas análises',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (offlineItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${offlineItems.length} análise(s) estão aguardando internet.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<AnalysisRequest>>(
              stream: forageService.watchAllUserForages(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final remoteItems = snapshot.data ?? [];
                final items = [...offlineItems, ...remoteItems]..sort((a, b) {
                    final aDate =
                        a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final bDate =
                        b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return bDate.compareTo(aDate);
                  });

                if (items.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('Nenhuma an\u00e1lise enviada ainda.'),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AnalysisItem(
                            title: item.name,
                            date: _formatDate(item.createdAt),
                            status: _statusLabel(item.status),
                            coverImageUrl: item.imageUrls.isNotEmpty
                                ? item.imageUrls.first
                                : null,
                            onTap: () {
                              final mainScreen = context
                                  .findAncestorStateOfType<MainScreenState>();
                              mainScreen?.openAnalysisDetail(item);
                            },
                          ),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
