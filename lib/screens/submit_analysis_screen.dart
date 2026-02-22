import 'package:flutter/material.dart';
import '../widgets/new_analysis_card.dart';
import '../widgets/analysis_item.dart';
import '../widgets/bottom_nav_custom.dart';

class SubmitAnalysisScreen extends StatelessWidget {
  const SubmitAnalysisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('TESTE TESTE'),
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

                    Text(
                      "Envie suas Forrageiras",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const SizedBox(height: 20),

                    const NewAnalysisCard(),

                    const SizedBox(height: 28),

                    const SizedBox(height: 12),
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
        onPressed: () {},
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}