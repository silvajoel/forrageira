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
              onPressed: () => onTap?.call(0),
              icon: const Icon(Icons.home),
              color: Colors.white,
            ),
            IconButton(
              onPressed: () => onTap?.call(1),
              icon: const Icon(Icons.analytics_outlined),
              color: Colors.white,
            ),
            const SizedBox(width: 48), // espaço central para FAB
            IconButton(
              onPressed: () => onTap?.call(2),
              icon: const Icon(Icons.person_outline),
              color: Colors.white,
            ),
            IconButton(
              onPressed: () => onTap?.call(3),
              icon: const Icon(Icons.notifications_none),
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}