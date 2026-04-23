import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_smart_image.dart';
import 'rounded_card.dart';

class AnalysisItem extends StatelessWidget {
  final String title;
  final String date;
  final String status;
  final VoidCallback? onTap;
  final String? coverImageUrl;

  const AnalysisItem({
    Key? key,
    required this.title,
    required this.date,
    required this.status,
    this.onTap,
    this.coverImageUrl,
  }) : super(key: key);

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'finalizado':
        return const Color(0xFF2E7D32);
      case 'em an\u00e1lise':
        return const Color(0xFFF9A825);
      case 'aguardando internet':
        return const Color(0xFF1565C0);
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
            _buildCover(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: getStatusColor().withValues(alpha: 0.12),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    final hasUrl = coverImageUrl != null && coverImageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: hasUrl
            ? AppSmartImage(
                source: coverImageUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey.shade200,
      child: const Icon(Icons.grass, color: Colors.grey, size: 32),
    );
  }
}
