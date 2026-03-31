import 'package:flutter/material.dart';
import 'package:forrageira/models/analysis_request.dart';
import 'package:forrageira/screens/analysis_detail_screen.dart';
import 'package:forrageira/screens/analysis_screen.dart';
import 'package:forrageira/screens/main_screen.dart';
import 'package:forrageira/screens/notifications_screen.dart';
import 'package:forrageira/services/auth_service.dart';
import 'package:forrageira/services/i_forage_service.dart';
import 'package:provider/provider.dart';
import '../widgets/analysis_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':   return 'Em análise';
      case 'completed': return 'Finalizado';
      default:          return 'Desconhecido';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')} "
        "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final authService  = context.watch<AuthService>();
    final forageService = context.read<IForageService>();

    final user     = authService.currentUser;
    final username = user?.displayName ?? "Usuário";
    final userId   = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('Forrageiras'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              final mainScreen =
              context.findAncestorStateOfType<MainScreenState>();
              mainScreen?.openNotifications();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Card de boas-vindas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.grass, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bem-vindo, $username!",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Veja suas análises recentes abaixo.",
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Título da lista
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Minhas Análises',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final mainScreen =
                            context.findAncestorStateOfType<MainScreenState>();
                            mainScreen?.setIndex(1);
                          },
                          child: const Text("Ver todas"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Lista de análises recentes
            StreamBuilder<List<AnalysisRequest>>(
              stream: forageService.watchUserForages(userId),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text("Nenhuma análise enviada ainda."),
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
                            // Primeira imagem como capa
                            coverImageUrl: item.imageUrls.isNotEmpty
                                ? item.imageUrls.first
                                : null,
                            onTap: () {
                              final mainScreen =
                              context.findAncestorStateOfType<MainScreenState>();
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
}