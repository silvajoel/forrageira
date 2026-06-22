import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'package:forrageira/services/auth_service.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:forrageira/services/pending_analysis_queue_service.dart';
import 'package:forrageira/services/plesk_image_storage_service.dart';
import 'package:forrageira/widgets/notification_bell_button.dart';
import 'package:provider/provider.dart';

import '../widgets/analysis_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<void> _syncPendingAnalyses(
    BuildContext context,
    PendingAnalysisQueueService queueService,
  ) async {
    await queueService.syncPendingAnalyses(
      forageService: context.read<IForageService>(),
      imageStorageService: PleskImageStorageService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final forageService = context.read<IForageService>();
    final queueService = context.watch<PendingAnalysisQueueService>();

    final user = authService.currentUser;
    final username = user?.displayName ?? 'Usu\u00e1rio';
    final userId = user?.uid ?? '';
    final offlineItems = _buildOfflineAnalyses(queueService, userId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.home),
            SizedBox(width: 8),
            Text('Que capim é esse?'),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/icon.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bem-vindo, $username!',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Veja suas an\u00e1lises recentes abaixo.',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (offlineItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildOfflineSyncCard(
                        context,
                        theme,
                        offlineItems.length,
                        queueService,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Minhas An\u00e1lises',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final mainScreen = context
                                .findAncestorStateOfType<MainScreenState>();
                            mainScreen?.setIndex(1);
                          },
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            StreamBuilder<List<AnalysisRequest>>(
              stream: forageService.watchUserForages(userId),
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
            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineSyncCard(
    BuildContext context,
    ThemeData theme,
    int pendingCount,
    PendingAnalysisQueueService queueService,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1C062)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: Color(0xFF8A6B14),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$pendingCount an\u00e1lise(s) aguardando internet para envio.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            queueService.isSyncing
                ? 'Estamos tentando sincronizar suas an\u00e1lises pendentes.'
                : 'Toque abaixo para tentar sincronizar assim que a conex\u00e3o voltar.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: queueService.isSyncing
                ? null
                : () => _syncPendingAnalyses(context, queueService),
            icon: queueService.isSyncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(
              queueService.isSyncing
                  ? 'Sincronizando'
                  : 'Tentar sincronizar agora',
            ),
          ),
        ],
      ),
    );
  }
}
