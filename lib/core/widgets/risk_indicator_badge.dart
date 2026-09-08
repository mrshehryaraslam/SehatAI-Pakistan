import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum TriageRiskLevel { low, moderate, high }

class RiskIndicatorBadge extends StatelessWidget {
  final TriageRiskLevel riskLevel;
  final bool isLarge;

  const RiskIndicatorBadge({
    super.key,
    required this.riskLevel,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    String label;
    IconData icon;

    switch (riskLevel) {
      case TriageRiskLevel.low:
        bg = AppColors.successLight;
        fg = AppColors.successDark;
        border = AppColors.success.withOpacity(0.3);
        label = 'LOW RISK';
        icon = Icons.check_circle_outline_rounded;
        break;
      case TriageRiskLevel.moderate:
        bg = AppColors.warningLight;
        fg = AppColors.warningDark;
        border = AppColors.warning.withOpacity(0.3);
        label = 'MODERATE RISK';
        icon = Icons.warning_amber_rounded;
        break;
      case TriageRiskLevel.high:
        bg = AppColors.emergencyLight;
        fg = AppColors.emergencyDark;
        border = AppColors.emergency.withOpacity(0.4);
        label = 'HIGH RISK';
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isLarge ? 18 : 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 13 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
