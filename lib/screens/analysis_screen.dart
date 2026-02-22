import 'package:flutter/material.dart';
import '../widgets/new_analysis_card.dart';
import '../widgets/analysis_item.dart';
import '../widgets/bottom_nav_custom.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

            /// 🔹 Lista de análises
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  const [
                    AnalysisItem(
                      title: 'Brachiaria Brizantha',
                      date: '21:00 11/01/2026',
                      status: 'Finalizado',
                    ),
                    SizedBox(height: 10),
                    AnalysisItem(
                      title: 'Brachiaria Brizantha',
                      date: '21:00 11/01/2026',
                      status: 'Em análise',
                    ),
                    SizedBox(height: 10),
                    AnalysisItem(
                      title: 'Brachiaria Brizantha',
                      date: '21:00 11/01/2026',
                      status: 'Finalizado',
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavCustom(
        currentIndex: 0,
        onTap: (i) {},
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //print("FAB: tentando navegar para /submitanalysis");
          Navigator.pushNamed(context, '/submitanalysis');
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}