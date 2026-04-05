import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'rounded_card.dart';

class AnalysisItem extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final VoidCallback? onTap;
  final String imageAsset;

  const AnalysisItem({
    Key? key,
    required this.title,
    required this.date,
    required this.status,
    this.onTap,
    this.imageAsset = 'assets/images/grass.jpg',
  }) : super(key: key);

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'finalizado':
        return Colors.green;
      case 'em análise':
        return Colors.orange;
      default:
        return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      padding: const EdgeInsets.all(8),
      radius: 14,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(imageAsset, width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: getStatusColor().withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: getStatusColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}