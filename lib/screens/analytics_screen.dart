import 'package:flutter/material.dart';
import '../widgets/new_analysis_card.dart';
import '../widgets/analysis_item.dart';
import '../widgets/bottom_nav_custom.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.grass),
            SizedBox(width: 8),
            Text('Forrageira'),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.person_outline),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const NewAnalysisCard(),
              const SizedBox(height: 18),
              Text(
                'MINHAS ANÁLISES',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: const [
                  AnalysisItem(
                    title: 'Brachiaria Brizantha',
                    date: '21:00 11/01/2026',
                    status: 'Finalizado',
                  ),
                  SizedBox(height: 8),
                  AnalysisItem(
                    title: 'Brachiaria Brizantha',
                    date: '21:00 11/01/2026',
                    status: 'Em análise',
                  ),
                  SizedBox(height: 8),
                  AnalysisItem(
                    title: 'Brachiaria Brizantha',
                    date: '21:00 11/01/2026',
                    status: 'Finalizado',
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavCustom(
        currentIndex: 1,
        onTap: (i) {},
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
      ),
    );
  }
}