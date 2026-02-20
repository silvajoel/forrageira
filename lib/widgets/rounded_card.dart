import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RoundedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;

  const RoundedCard({
    Key? key,
    required this.child,
    this.padding,
    this.radius = 16,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? AppColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}