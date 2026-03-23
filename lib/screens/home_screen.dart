import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:forrageira/screens/analysis_screen.dart';
import 'package:forrageira/services/auth_service.dart';
import 'package:forrageira/services/forage_service.dart';
import 'package:provider/provider.dart';
import '../widgets/analysis_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  String getStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Em análise';
      case 'completed':
        return 'Finalizado';
      default:
        return 'Desconhecido';
    }
  }

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')} "
        "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.watch<AuthService>();
    final forageService = context.read<ForageService>();

    final user = authService.currentUser;
    final username = user?.displayName ?? "Usuário";

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('Forrageiras'),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            /// Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Card de boas-vindas
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

                    /// Título da lista
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AnalysisScreen(),
                              ),
                            );
                          },
                          child: const Text("Ver todas"),
                        )
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            /// Lista de análises
            StreamBuilder<QuerySnapshot>(
              stream: forageService.connectStreamForages(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text("Nenhuma análise enviada ainda."),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {

                        final data =
                        docs[index].data() as Map<String, dynamic>;

                        final name = data['name'] ?? 'Sem nome';
                        final status = getStatus(data['status'] ?? '');
                        final timestamp = data['created_at'];

                        final date = timestamp != null
                            ? formatDate(timestamp)
                            : '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AnalysisItem(
                            title: name,
                            date: date,
                            status: status,
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }
}