import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.verifiedDoctor() {
    return const StatusBadge(
      text: 'PMDC Verified',
      backgroundColor: Color(0xFFE0F2FE),
      textColor: Color(0xFF0369A1),
      icon: Icons.verified_rounded,
    );
  }

  factory StatusBadge.online() {
    return const StatusBadge(
      text: 'Online Now',
      backgroundColor: AppColors.successLight,
      textColor: AppColors.successDark,
      icon: Icons.circle,
    );
  }

  factory StatusBadge.offline() {
    return const StatusBadge(
      text: 'Offline',
      backgroundColor: Color(0xFFF1F5F9),
      textColor: AppColors.textMuted,
      icon: Icons.circle_outlined,
    );
  }

  factory StatusBadge.emergencyActive() {
    return const StatusBadge(
      text: 'Urgent',
      backgroundColor: AppColors.emergencyLight,
      textColor: AppColors.emergencyDark,
      icon: Icons.warning_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: icon == Icons.circle ? 8 : 14,
              color: textColor,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
