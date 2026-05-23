import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Color riskColor(int risk) {
  if (risk <= 30) {
    return AppColors.meterGreen;
  }
  if (risk <= 70) {
    return AppColors.meterYellow;
  }
  return AppColors.meterRed;
}

Color riskTint(int risk) {
  return riskColor(risk).withValues(alpha: 0.12);
}

Color riskShade(int risk) {
  return riskColor(risk);
}

IconData riskIcon(int risk) {
  if (risk > 70) {
    return Icons.shield_outlined;
  }
  if (risk > 30) {
    return Icons.warning_amber_rounded;
  }
  return Icons.verified_user_outlined;
}

String riskLabel(int risk) {
  if (risk <= 30) {
    return 'Low Risk';
  }
  if (risk <= 70) {
    return 'Medium Risk';
  }
  return 'High Risk';
}
