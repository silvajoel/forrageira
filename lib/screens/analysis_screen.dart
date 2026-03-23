import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:forrageira/services/forage_service.dart';
import 'package:provider/provider.dart';
import '../widgets/new_analysis_card.dart';
import '../widgets/analysis_item.dart';
import '../widgets/bottom_nav_custom.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

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
    final forageService = context.read<ForageService>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('Minhas Análises'),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.person_outline),
          ),
        ],
      ),

      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            /// 🔹 Seção principal (Nova análise)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 20),

                    /// 🔹 Título da lista
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Minhas Análises',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            /// Lista dinâmica
            StreamBuilder<QuerySnapshot>(
              stream: forageService.connectStreamAllForages(),
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
          ],
        ),
      ),
    );
  }
}