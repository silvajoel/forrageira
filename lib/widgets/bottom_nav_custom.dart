import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BottomNavCustom extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const BottomNavCustom({
    Key? key,
    this.currentIndex = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.greenDark,
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                isSelected: currentIndex == 0,
                icon: Icons.home_outlined,
                label: 'Inicio',
                onTap: () => onTap?.call(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                isSelected: currentIndex == 1,
                icon: Icons.analytics_outlined,
                label: 'Analises',
                onTap: () => onTap?.call(1),
              ),
            ),
            Expanded(
              child: _NavItem(
                isSelected: currentIndex == 2,
                icon: Icons.add_box_outlined,
                label: 'Nova',
                onTap: () => onTap?.call(2),
              ),
            ),
            Expanded(
              child: _NavItem(
                isSelected: currentIndex == 3,
                icon: Icons.person_outline,
                label: 'Perfil',
                onTap: () => onTap?.call(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : Colors.white70;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
