import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initials,
    this.radius = 28,
    this.seed,
  });

  final String initials;
  final double radius;
  final String? seed;

  static const _palette = [
    AppColors.primary,
    AppColors.terracotta,
    Color(0xFF1F6F8B),
    Color(0xFF7A5C2E),
    Color(0xFF2E6B4F),
    Color(0xFFB45309),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[(seed ?? initials).hashCode.abs() % _palette.length];
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, AppColors.ink, 0.28)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.62,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
