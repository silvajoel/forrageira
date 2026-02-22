import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BottomNavCustom extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNavCustom({Key? key, this.currentIndex = 0, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.greenDark,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () => onTap?.call(0), // Chama o índice 0
              icon: const Icon(Icons.home),
              color: currentIndex == 0 ? Colors.white : Colors.white54,
            ),
            IconButton(
              onPressed: () => onTap?.call(1), // Chama o índice 1
              icon: const Icon(Icons.analytics_outlined),
              color: currentIndex == 1 ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 48), // Espaço central para FAB
            IconButton(
              onPressed: () => onTap?.call(2), // Chama o índice 2
              icon: const Icon(Icons.person_outline),
              color: currentIndex == 2 ? Colors.white : Colors.white54,
            ),
            IconButton(
              onPressed: () => onTap?.call(3), // Chama o índice 3
              icon: const Icon(Icons.notifications_none),
              color: currentIndex == 3 ? Colors.white : Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}