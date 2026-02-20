import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'rounded_card.dart';

class NewAnalysisCard extends StatelessWidget {
  final VoidCallback? onTap;
  const NewAnalysisCard({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      radius: 20,
      color: AppColors.greenLight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('NOVA ANÁLISE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Identifique sua forrageira',
                    style: TextStyle(fontSize: 12))
              ],
            )
          ],
        ),
      ),
    );
  }
}